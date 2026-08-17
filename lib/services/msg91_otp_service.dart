import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

/// Service dedicated to MSG91 OTP Widget integration with automatic
/// Cloudflare Worker proxy fallback and resilience.
///
/// Configured with:
/// - widgetId: 366865677a4c393738333833
/// - authToken: 557300TG9qQLew6a72e347P1
class Msg91OtpService {
  static const String _defaultWidgetId = '366865677a4c393738333833';
  static const String _defaultAuthToken = '557300TG9qQLew6a72e347P1';

  static const String _baseUrl = 'https://api.msg91.com/api/v5/widget';

  static String get widgetId =>
      dotenv.env['MSG91_WIDGET_ID']?.trim().isNotEmpty == true
          ? dotenv.env['MSG91_WIDGET_ID']!.trim()
          : _defaultWidgetId;

  static String get authToken =>
      dotenv.env['MSG91_AUTH_TOKEN']?.trim().isNotEmpty == true
          ? dotenv.env['MSG91_AUTH_TOKEN']!.trim()
          : _defaultAuthToken;

  static String? get backendApiUrl => dotenv.env['DAPZO_API_URL'];

  static bool _initialized = false;

  /// Initializes the MSG91 OTP SDK Widget.
  static void init() {
    if (_initialized) return;
    try {
      OTPWidget.initializeWidget(widgetId, authToken);
      _initialized = true;
      debugPrint('[MSG91] OTPWidget initialized with widgetId: $widgetId');
    } catch (e) {
      debugPrint('[MSG91] OTPWidget.initializeWidget note: $e');
    }
  }

  /// Normalizes phone number to format required by MSG91 (country code without '+', e.g. 919876543210).
  static String formatIdentifier(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '91$cleaned';
    }
    return cleaned;
  }

  /// Helper to check if a response indicates success or already-verified state
  static bool isVerificationSuccess(Map<String, dynamic> resMap) {
    final type = resMap['type']?.toString().toLowerCase();
    final code = resMap['code'];
    final message = resMap['message']?.toString().toLowerCase() ?? '';

    if (type == 'success') return true;
    if (code == 703 || code == '703') return true;
    if (message.contains('already verif') || message.contains('already verified')) {
      return true;
    }
    return false;
  }

  /// Sends OTP to the target phone number.
  /// Returns the `reqId` required for subsequent verification or retry.
  static Future<String> sendOtp({required String phoneNumber}) async {
    init();
    final identifier = formatIdentifier(phoneNumber);

    debugPrint('[MSG91] Sending OTP to identifier: $identifier');

    // 1. Try with Flutter SDK
    try {
      final dynamic response = await OTPWidget.sendOTP({'identifier': identifier});
      debugPrint('[MSG91] SDK sendOTP response: $response');

      if (response != null && response is Map) {
        final resMap = Map<String, dynamic>.from(response);
        final type = resMap['type']?.toString().toLowerCase();
        if (type == 'success') {
          final reqId = resMap['reqId']?.toString() ??
              resMap['message']?.toString() ??
              '';
          return reqId;
        } else {
          final errMsg = resMap['message']?.toString() ??
              'Failed to send OTP via MSG91.';
          debugPrint('[MSG91] SDK reported non-success: $errMsg');
          if (errMsg == 'IPBlocked' || resMap['code'] == 408) {
            debugPrint('[MSG91] Direct client IP blocked. Attempting proxy fallback...');
          } else {
            throw Exception(errMsg);
          }
        }
      }
    } catch (e) {
      debugPrint('[MSG91] SDK sendOTP note: $e. Trying REST / Proxy...');
    }

    // 2. HTTP Direct REST
    try {
      final url = Uri.parse('$_baseUrl/sendOtp');
      final headers = {
        'Content-Type': 'application/json',
        'authkey': authToken,
        'tokenAuth': authToken,
      };
      final body = jsonEncode({
        'widgetId': widgetId,
        'tokenAuth': authToken,
        'identifier': identifier,
      });

      final res = await http.post(url, headers: headers, body: body);
      debugPrint('[MSG91] HTTP direct sendOtp status: ${res.statusCode}, body: ${res.body}');

      final dynamic data = jsonDecode(res.body);
      if (data != null && data is Map) {
        final resMap = Map<String, dynamic>.from(data);
        final type = resMap['type']?.toString().toLowerCase();
        if (type == 'success' || res.statusCode == 200) {
          final reqId = resMap['reqId']?.toString() ??
              resMap['message']?.toString() ??
              '';
          return reqId;
        } else if (resMap['message'] == 'IPBlocked' || resMap['code'] == 408) {
          debugPrint('[MSG91] Direct IP blocked. Proceeding to backend proxy...');
        } else {
          throw Exception(resMap['message'] ?? 'Failed to send OTP.');
        }
      }
    } catch (e) {
      debugPrint('[MSG91] HTTP direct sendOtp note: $e');
    }

    // 3. Backend Proxy Fallback (via Cloudflare Worker)
    final proxyBase = backendApiUrl;
    if (proxyBase != null && proxyBase.isNotEmpty) {
      try {
        final url = Uri.parse('$proxyBase/api/auth/send-otp');
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'widgetId': widgetId,
          'tokenAuth': authToken,
          'identifier': identifier,
        });

        final res = await http.post(url, headers: headers, body: body);
        debugPrint('[MSG91] Proxy sendOtp status: ${res.statusCode}, body: ${res.body}');

        final dynamic data = jsonDecode(res.body);
        if (data != null && data is Map) {
          final resMap = Map<String, dynamic>.from(data);
          final type = resMap['type']?.toString().toLowerCase();
          if (type == 'success' || res.statusCode == 200) {
            final reqId = resMap['reqId']?.toString() ??
                resMap['message']?.toString() ??
                '';
            return reqId;
          } else {
            throw Exception(resMap['message'] ?? 'Failed to send OTP.');
          }
        }
      } catch (e) {
        debugPrint('[MSG91] Proxy sendOtp error: $e');
        rethrow;
      }
    }

    throw Exception(
      'MSG91 returned IPBlocked (Error 408). Please disable IP restriction in MSG91 dashboard.',
    );
  }

  /// Verifies OTP code entered by the user.
  /// Returns true if verification succeeds or was already verified.
  static Future<bool> verifyOtp({
    required String reqId,
    required String otp,
    required String phoneNumber,
  }) async {
    init();
    debugPrint('[MSG91] Verifying OTP: $otp for reqId: $reqId');

    // 1. Try with Flutter SDK
    try {
      final payload = {
        'reqId': reqId,
        'otp': otp.trim(),
      };
      final dynamic response = await OTPWidget.verifyOTP(payload);
      debugPrint('[MSG91] SDK verifyOTP response: $response');

      if (response != null && response is Map) {
        final resMap = Map<String, dynamic>.from(response);
        if (isVerificationSuccess(resMap)) {
          return true;
        } else {
          final message = resMap['message']?.toString() ??
              'Invalid OTP. Please check the code and try again.';
          if (message != 'IPBlocked') {
            throw Exception(message);
          }
        }
      }
    } catch (e) {
      debugPrint('[MSG91] SDK verifyOTP note: $e');
      final str = e.toString().toLowerCase();
      if (str.contains('already verif') || str.contains('703')) {
        return true;
      }
    }

    // 2. HTTP Direct REST
    try {
      final url = Uri.parse('$_baseUrl/verifyOtp');
      final headers = {
        'Content-Type': 'application/json',
        'authkey': authToken,
        'tokenAuth': authToken,
      };
      final body = jsonEncode({
        'widgetId': widgetId,
        'tokenAuth': authToken,
        'reqId': reqId,
        'otp': otp.trim(),
      });

      final res = await http.post(url, headers: headers, body: body);
      debugPrint('[MSG91] HTTP direct verifyOtp status: ${res.statusCode}, body: ${res.body}');

      final dynamic data = jsonDecode(res.body);
      if (data != null && data is Map) {
        final resMap = Map<String, dynamic>.from(data);
        if (isVerificationSuccess(resMap)) {
          return true;
        } else if (resMap['message'] != 'IPBlocked') {
          throw Exception(resMap['message'] ?? 'Invalid OTP.');
        }
      }
    } catch (e) {
      debugPrint('[MSG91] HTTP direct verifyOtp note: $e');
      final str = e.toString().toLowerCase();
      if (str.contains('already verif') || str.contains('703')) {
        return true;
      }
    }

    // 3. Backend Proxy Fallback
    final proxyBase = backendApiUrl;
    if (proxyBase != null && proxyBase.isNotEmpty) {
      try {
        final url = Uri.parse('$proxyBase/api/auth/verify-otp');
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'widgetId': widgetId,
          'tokenAuth': authToken,
          'reqId': reqId,
          'otp': otp.trim(),
        });

        final res = await http.post(url, headers: headers, body: body);
        debugPrint('[MSG91] Proxy verifyOtp status: ${res.statusCode}, body: ${res.body}');

        final dynamic data = jsonDecode(res.body);
        if (data != null && data is Map) {
          final resMap = Map<String, dynamic>.from(data);
          if (isVerificationSuccess(resMap)) {
            return true;
          } else {
            throw Exception(resMap['message'] ?? 'Invalid OTP.');
          }
        }
      } catch (e) {
        debugPrint('[MSG91] Proxy verifyOtp error: $e');
        final str = e.toString().toLowerCase();
        if (str.contains('already verif') || str.contains('703')) {
          return true;
        }
        rethrow;
      }
    }

    return false;
  }

  /// Retries/Resends OTP to the user.
  static Future<bool> retryOtp({
    required String reqId,
    String? retryChannel,
  }) async {
    init();
    debugPrint('[MSG91] Retrying OTP for reqId: $reqId, channel: $retryChannel');

    // 1. Try with Flutter SDK
    try {
      final payload = {
        'reqId': reqId,
        if (retryChannel != null && retryChannel.isNotEmpty)
          'retryChannel': retryChannel,
      };
      final dynamic response = await OTPWidget.retryOTP(payload);
      debugPrint('[MSG91] SDK retryOTP response: $response');

      if (response != null && response is Map) {
        final resMap = Map<String, dynamic>.from(response);
        final type = resMap['type']?.toString().toLowerCase();
        if (type == 'success') {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[MSG91] SDK retryOTP note: $e');
    }

    // 2. HTTP Direct REST
    try {
      final url = Uri.parse('$_baseUrl/retryOtp');
      final headers = {
        'Content-Type': 'application/json',
        'authkey': authToken,
        'tokenAuth': authToken,
      };
      final body = jsonEncode({
        'widgetId': widgetId,
        'tokenAuth': authToken,
        'reqId': reqId,
        if (retryChannel != null && retryChannel.isNotEmpty)
          'retryChannel': retryChannel,
      });

      final res = await http.post(url, headers: headers, body: body);
      debugPrint('[MSG91] HTTP direct retryOtp status: ${res.statusCode}, body: ${res.body}');

      final dynamic data = jsonDecode(res.body);
      if (data != null && data is Map) {
        final resMap = Map<String, dynamic>.from(data);
        final type = resMap['type']?.toString().toLowerCase();
        if (type == 'success' || res.statusCode == 200) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[MSG91] HTTP direct retryOtp note: $e');
    }

    // 3. Backend Proxy Fallback
    final proxyBase = backendApiUrl;
    if (proxyBase != null && proxyBase.isNotEmpty) {
      try {
        final url = Uri.parse('$proxyBase/api/auth/retry-otp');
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'widgetId': widgetId,
          'tokenAuth': authToken,
          'reqId': reqId,
          if (retryChannel != null && retryChannel.isNotEmpty)
            'retryChannel': retryChannel,
        });

        final res = await http.post(url, headers: headers, body: body);
        final dynamic data = jsonDecode(res.body);
        if (data != null && data is Map) {
          final resMap = Map<String, dynamic>.from(data);
          final type = resMap['type']?.toString().toLowerCase();
          return type == 'success' || res.statusCode == 200;
        }
      } catch (e) {
        debugPrint('[MSG91] Proxy retryOtp error: $e');
      }
    }

    return false;
  }
}
