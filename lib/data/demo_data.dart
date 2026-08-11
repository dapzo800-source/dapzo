/// Dapzo Demo Data
/// All shops, categories and products that will be seeded into Firestore.
library;

// ─────────────────────────────────────────────────────────────────────────────
// SHOPS
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoShops = [
  // ── Food Shops ──────────────────────────────────────────────────────────────
  {
    'id': 'shop_scottzone',
    'name': 'Scottzone',
    'mode': 'food',
    'tagline': 'Crispy, Spicy & Absolutely Delicious',
    'rating': 4.6,
    'ratingCount': 2380,
    'deliveryTimeMin': 25,
    'deliveryTimeMax': 40,
    'deliveryFee': 29,
    'minOrder': 99,
    'latitude': 12.9716,
    'longitude': 77.5946,
    'deliveryRadiusKm': 8.0,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1552566626-52f8b828329e?w=800&q=80',
  },
  {
    'id': 'shop_gopi_anna_kada',
    'name': 'Gopi Anna Kada',
    'mode': 'food',
    'tagline': 'Authentic South Indian Flavours',
    'rating': 4.4,
    'ratingCount': 1750,
    'deliveryTimeMin': 30,
    'deliveryTimeMax': 50,
    'deliveryFee': 19,
    'minOrder': 79,
    'latitude': 12.9352,
    'longitude': 77.6245,
    'deliveryRadiusKm': 6.0,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&q=80',
  },
  // ── Meat Shops ──────────────────────────────────────────────────────────────
  {
    'id': 'shop_fresh_meat_hub',
    'name': 'Fresh Meat Hub',
    'mode': 'meat',
    'tagline': 'Farm Fresh · Hygienically Packed',
    'rating': 4.5,
    'ratingCount': 980,
    'deliveryTimeMin': 30,
    'deliveryTimeMax': 55,
    'deliveryFee': 39,
    'minOrder': 149,
    'latitude': 12.9450,
    'longitude': 77.5700,
    'deliveryRadiusKm': 7.0,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=800&q=80',
  },
  {
    'id': 'shop_royal_meat_market',
    'name': 'Royal Meat Market',
    'mode': 'meat',
    'tagline': 'Premium Quality · Daily Fresh',
    'rating': 4.3,
    'ratingCount': 720,
    'deliveryTimeMin': 35,
    'deliveryTimeMax': 60,
    'deliveryFee': 49,
    'minOrder': 199,
    'latitude': 12.9600,
    'longitude': 77.6100,
    'deliveryRadiusKm': 6.0,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=800&q=80',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORIES — FOOD (8)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoFoodCategories = [
  {
    'name': 'Biryani',
    'mode': 'food',
    'order': 1,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80',
    'colorHex': 'F59E0B',
  },
  {
    'name': 'Pizzas',
    'mode': 'food',
    'order': 2,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
    'colorHex': 'DC2626',
  },
  {
    'name': 'Crispy Chicken',
    'mode': 'food',
    'order': 3,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1562967914-608f82629710?w=400&q=80',
    'colorHex': 'D97706',
  },
  {
    'name': 'Juice',
    'mode': 'food',
    'order': 4,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1600718374662-0483d2b9da44?w=400&q=80',
    'colorHex': '16A34A',
  },
  {
    'name': 'Grills',
    'mode': 'food',
    'order': 5,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
    'colorHex': '92400E',
  },
  {
    'name': 'Breakfast',
    'mode': 'food',
    'order': 6,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=400&q=80',
    'colorHex': 'FBBF24',
  },
  {
    'name': 'Chats',
    'mode': 'food',
    'order': 7,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400&q=80',
    'colorHex': '7C3AED',
  },
  {
    'name': 'Desserts',
    'mode': 'food',
    'order': 8,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400&q=80',
    'colorHex': 'DB2777',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORIES — MEAT (5)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoMeatCategories = [
  {
    'name': 'Chicken',
    'mode': 'meat',
    'order': 1,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400&q=80',
    'colorHex': 'D97706',
  },
  {
    'name': 'Mutton',
    'mode': 'meat',
    'order': 2,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=400&q=80',
    'colorHex': '78350F',
  },
  {
    'name': 'Sheep',
    'mode': 'meat',
    'order': 3,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400&q=80',
    'colorHex': '6B7280',
  },
  {
    'name': 'Beef',
    'mode': 'meat',
    'order': 4,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1558030006-450675393462?w=400&q=80',
    'colorHex': '7F1D1D',
  },
  {
    'name': 'Sea Foods',
    'mode': 'meat',
    'order': 5,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=400&q=80',
    'colorHex': '0284C7',
    'subCategories': ['Sea Fish', 'Lake Fish'],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS — FOOD (Scottzone)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoFoodProductsScottzone = [
  // ── Biryani ─────────────────────────────────────────────────────────────────
  {
    'name': 'Chicken Dum Biryani',
    'nameLowercase': 'chicken dum biryani',
    'description':
        'Slow-cooked Basmati rice layered with juicy chicken pieces, saffron, and crispy fried onions. A true feast!',
    'category': 'Biryani',
    'subCategory': '',
    'mode': 'food',
    'price': 220.0,
    'unit': 'plate',
    'shopId': 'shop_scottzone',
    'rating': 4.7,
    'ratingCount': 843,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=800&q=90', // Rich Biryani
  },
  {
    'name': 'Hyderabadi Chicken Biryani',
    'nameLowercase': 'hyderabadi chicken biryani',
    'description':
        'Authentic Hyderabadi-style biryani with marinated chicken, star anise, and fresh mint.',
    'category': 'Biryani',
    'subCategory': '',
    'mode': 'food',
    'price': 250.0,
    'unit': 'plate',
    'shopId': 'shop_scottzone',
    'rating': 4.8,
    'ratingCount': 621,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800&q=90', // Hyderabadi Biryani
  },
  // ── Crispy Chicken ────────────────────────────────────────────────────────
  {
    'name': 'Crispy Chicken Bucket',
    'nameLowercase': 'crispy chicken bucket',
    'description':
        '8-piece golden-fried crispy chicken with our signature spice blend. Comes with dipping sauce.',
    'category': 'Crispy Chicken',
    'subCategory': '',
    'mode': 'food',
    'price': 399.0,
    'unit': 'bucket',
    'shopId': 'shop_scottzone',
    'rating': 4.6,
    'ratingCount': 512,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800&q=90', // Golden Fried Chicken
  },
  {
    'name': 'Crispy Chicken Wings',
    'nameLowercase': 'crispy chicken wings',
    'description':
        'Buffalo-style crispy wings with a smoky, tangy glaze. 6 pieces per serving.',
    'category': 'Crispy Chicken',
    'subCategory': '',
    'mode': 'food',
    'price': 249.0,
    'unit': 'plate',
    'shopId': 'shop_scottzone',
    'rating': 4.5,
    'ratingCount': 389,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=800&q=80',
  },
  // ── Pizzas ────────────────────────────────────────────────────────────────
  {
    'name': 'Margherita Pizza',
    'nameLowercase': 'margherita pizza',
    'description':
        'Classic Italian pizza with hand-stretched dough, rich tomato sauce, and fresh mozzarella.',
    'category': 'Pizzas',
    'subCategory': '',
    'mode': 'food',
    'price': 199.0,
    'unit': 'pizza',
    'shopId': 'shop_scottzone',
    'rating': 4.4,
    'ratingCount': 290,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=90', // Craving Pizza
  },
  {
    'name': 'Pepperoni Pizza',
    'nameLowercase': 'pepperoni pizza',
    'description':
        'Loaded with premium pepperoni slices on a bed of creamy mozzarella and tangy tomato.',
    'category': 'Pizzas',
    'subCategory': '',
    'mode': 'food',
    'price': 279.0,
    'unit': 'pizza',
    'shopId': 'shop_scottzone',
    'rating': 4.6,
    'ratingCount': 415,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80',
  },
  // ── Juice ─────────────────────────────────────────────────────────────────
  {
    'name': 'Mango Lassi',
    'nameLowercase': 'mango lassi',
    'description':
        'Thick, creamy mango yoghurt drink blended with cardamom. Chilled and refreshing.',
    'category': 'Juice',
    'subCategory': '',
    'mode': 'food',
    'price': 89.0,
    'unit': 'glass',
    'shopId': 'shop_scottzone',
    'rating': 4.7,
    'ratingCount': 234,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1546173159-315724a31696?w=800&q=80',
  },
  {
    'name': 'Watermelon Cooler',
    'nameLowercase': 'watermelon cooler',
    'description':
        'Freshly blended watermelon with a hint of lime and mint. Perfect summer drink.',
    'category': 'Juice',
    'subCategory': '',
    'mode': 'food',
    'price': 79.0,
    'unit': 'glass',
    'shopId': 'shop_scottzone',
    'rating': 4.5,
    'ratingCount': 178,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1600718374662-0483d2b9da44?w=800&q=80',
  },
  // ── Desserts ──────────────────────────────────────────────────────────────
  {
    'name': 'Gulab Jamun',
    'nameLowercase': 'gulab jamun',
    'description':
        'Soft milk-solid balls soaked in rose-flavoured sugar syrup. Served warm.',
    'category': 'Desserts',
    'subCategory': '',
    'mode': 'food',
    'price': 99.0,
    'unit': 'plate',
    'shopId': 'shop_scottzone',
    'rating': 4.8,
    'ratingCount': 567,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1666270431688-ecf8e21b3517?w=800&q=80',
  },
  {
    'name': 'Chocolate Lava Cake',
    'nameLowercase': 'chocolate lava cake',
    'description':
        'Warm chocolate cake with a molten, gooey centre. Served with vanilla ice-cream.',
    'category': 'Desserts',
    'subCategory': '',
    'mode': 'food',
    'price': 149.0,
    'unit': 'piece',
    'shopId': 'shop_scottzone',
    'rating': 4.7,
    'ratingCount': 321,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS — FOOD (Gopi Anna Kada)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoFoodProductsGopiAnna = [
  // ── Biryani ─────────────────────────────────────────────────────────────────
  {
    'name': 'Chicken Donne Biryani',
    'nameLowercase': 'chicken donne biryani',
    'description':
        'Karnataka-style biryani served in a donne (areca leaf bowl). Seeraga samba rice with spiced chicken.',
    'category': 'Biryani',
    'subCategory': '',
    'mode': 'food',
    'price': 199.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.6,
    'ratingCount': 712,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?w=800&q=80',
  },
  {
    'name': 'Mutton Biryani',
    'nameLowercase': 'mutton biryani',
    'description':
        'Tender mutton slow-cooked with aromatic spices and long-grain basmati. Rich and flavourful.',
    'category': 'Biryani',
    'subCategory': '',
    'mode': 'food',
    'price': 320.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.7,
    'ratingCount': 489,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=800&q=80',
  },
  // ── Crispy Chicken ────────────────────────────────────────────────────────
  {
    'name': 'Chicken Lollipop',
    'nameLowercase': 'chicken lollipop',
    'description':
        'Juicy chicken lollipops marinated in Indo-Chinese spices, deep-fried to perfection.',
    'category': 'Crispy Chicken',
    'subCategory': '',
    'mode': 'food',
    'price': 199.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.5,
    'ratingCount': 356,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=800&q=80',
  },
  // ── Pizzas ────────────────────────────────────────────────────────────────
  {
    'name': 'Paneer Tikka Pizza',
    'nameLowercase': 'paneer tikka pizza',
    'description':
        'Fusion pizza loaded with tandoori paneer, capsicum, onion, and mint chutney drizzle.',
    'category': 'Pizzas',
    'subCategory': '',
    'mode': 'food',
    'price': 249.0,
    'unit': 'pizza',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.3,
    'ratingCount': 198,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
  },
  {
    'name': 'BBQ Chicken Pizza',
    'nameLowercase': 'bbq chicken pizza',
    'description':
        'Smoky BBQ sauce base with grilled chicken, red onion, and loads of cheese.',
    'category': 'Pizzas',
    'subCategory': '',
    'mode': 'food',
    'price': 299.0,
    'unit': 'pizza',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.5,
    'ratingCount': 267,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=800&q=80',
  },
  // ── Juice ─────────────────────────────────────────────────────────────────
  {
    'name': 'Fresh Orange Juice',
    'nameLowercase': 'fresh orange juice',
    'description':
        'Cold-pressed oranges with no added sugar. Pure, fresh and energising.',
    'category': 'Juice',
    'subCategory': '',
    'mode': 'food',
    'price': 99.0,
    'unit': 'glass',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.6,
    'ratingCount': 145,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=800&q=80',
  },
  // ── Chats ─────────────────────────────────────────────────────────────────
  {
    'name': 'Pani Puri',
    'nameLowercase': 'pani puri',
    'description':
        'Crispy hollow puris filled with spiced potatoes, chana, and tangy mint-tamarind water. 6 pieces.',
    'category': 'Chats',
    'subCategory': '',
    'mode': 'food',
    'price': 69.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.7,
    'ratingCount': 892,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=800&q=80',
  },
  {
    'name': 'Masala Puri',
    'nameLowercase': 'masala puri',
    'description':
        'Crushed puris topped with spiced peas, chutneys, sev and fresh coriander. Bangalore favourite!',
    'category': 'Chats',
    'subCategory': '',
    'mode': 'food',
    'price': 79.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.6,
    'ratingCount': 654,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&q=80',
  },
  // ── Grills ────────────────────────────────────────────────────────────────
  {
    'name': 'Chicken Grill Platter',
    'nameLowercase': 'chicken grill platter',
    'description':
        'Half-chicken marinated in smoky tikka spices, grilled over charcoal. Served with naan and raita.',
    'category': 'Grills',
    'subCategory': '',
    'mode': 'food',
    'price': 349.0,
    'unit': 'platter',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.7,
    'ratingCount': 423,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
  },
  // ── Breakfast ─────────────────────────────────────────────────────────────
  {
    'name': 'Masala Dosa',
    'nameLowercase': 'masala dosa',
    'description':
        'Crispy golden dosa with spiced potato filling. Served with coconut chutney and sambar.',
    'category': 'Breakfast',
    'subCategory': '',
    'mode': 'food',
    'price': 80.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.8,
    'ratingCount': 1203,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=800&q=80',
  },
  {
    'name': 'Idli Sambar',
    'nameLowercase': 'idli sambar',
    'description':
        'Soft steamed rice cakes with hot lentil sambar and fresh coconut chutney. 4 pieces.',
    'category': 'Breakfast',
    'subCategory': '',
    'mode': 'food',
    'price': 60.0,
    'unit': 'plate',
    'shopId': 'shop_gopi_anna_kada',
    'rating': 4.7,
    'ratingCount': 987,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1630851840628-2e444a9b394f?w=800&q=80',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS — MEAT (Fresh Meat Hub)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoMeatProductsFreshMeatHub = [
  // ── Chicken ───────────────────────────────────────────────────────────────
  {
    'name': 'Chicken Curry Cut',
    'nameLowercase': 'chicken curry cut',
    'description':
        'Fresh farm chicken cut into curry pieces. Skin-on, bone-in. Cleaned and ready to cook.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 180.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.5,
    'ratingCount': 412,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 95.0},
      {'label': '1 kg', 'price': 180.0},
      {'label': '2 kg', 'price': 350.0},
    ],
  },
  {
    'name': 'Chicken Breast',
    'nameLowercase': 'chicken breast',
    'description':
        'Boneless, skinless chicken breast. High protein, low fat. Ideal for grilling and curries.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 260.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.6,
    'ratingCount': 289,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 135.0},
      {'label': '1 kg', 'price': 260.0},
    ],
  },
  {
    'name': 'Chicken Boneless',
    'nameLowercase': 'chicken boneless',
    'description':
        'Fresh boneless chicken pieces with no skin. Perfect for stir fries, curries, and biryani.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 300.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.7,
    'ratingCount': 356,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1612187647310-7fd3d56b66b9?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 155.0},
      {'label': '1 kg', 'price': 300.0},
    ],
  },
  {
    'name': 'Chicken Drumsticks',
    'nameLowercase': 'chicken drumsticks',
    'description':
        'Meaty drumsticks — perfect for grilling, roasting or making spicy fry.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 220.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.4,
    'ratingCount': 198,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1599893453568-b24b6b43f2d5?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 115.0},
      {'label': '1 kg', 'price': 220.0},
    ],
  },
  // ── Mutton ────────────────────────────────────────────────────────────────
  {
    'name': 'Mutton Curry Cut',
    'nameLowercase': 'mutton curry cut',
    'description':
        'Fresh goat meat cut into medium curry pieces. Bone-in for rich flavour.',
    'category': 'Mutton',
    'subCategory': '',
    'mode': 'meat',
    'price': 550.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.6,
    'ratingCount': 267,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 285.0},
      {'label': '1 kg', 'price': 550.0},
    ],
  },
  {
    'name': 'Mutton Boneless',
    'nameLowercase': 'mutton boneless',
    'description':
        'Premium boneless goat meat. Tender and lean — great for korma, keema, and rogan josh.',
    'category': 'Mutton',
    'subCategory': '',
    'mode': 'meat',
    'price': 650.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.7,
    'ratingCount': 189,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 335.0},
      {'label': '1 kg', 'price': 650.0},
    ],
  },
  // ── Sea Foods (Sea Fish) ──────────────────────────────────────────────────
  {
    'name': 'Prawns (Large)',
    'nameLowercase': 'prawns large',
    'description':
        'Fresh tiger prawns — cleaned, deveined and ready to cook. Sourced daily from coastal markets.',
    'category': 'Sea Foods',
    'subCategory': 'Sea Fish',
    'mode': 'meat',
    'price': 400.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.7,
    'ratingCount': 324,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=800&q=80',
    'weightOptions': [
      {'label': '250g', 'price': 105.0},
      {'label': '500g', 'price': 200.0},
      {'label': '1 kg', 'price': 400.0},
    ],
  },
  {
    'name': 'Salmon Fillet',
    'nameLowercase': 'salmon fillet',
    'description':
        'Norwegian Atlantic salmon fillet — rich in Omega-3. Skin-on, scaled and ready to pan-sear.',
    'category': 'Sea Foods',
    'subCategory': 'Sea Fish',
    'mode': 'meat',
    'price': 550.0,
    'unit': 'kg',
    'shopId': 'shop_fresh_meat_hub',
    'rating': 4.8,
    'ratingCount': 156,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=800&q=80',
    'weightOptions': [
      {'label': '300g', 'price': 170.0},
      {'label': '500g', 'price': 280.0},
      {'label': '1 kg', 'price': 550.0},
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS — MEAT (Royal Meat Market)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> demoMeatProductsRoyalMeat = [
  // ── Chicken ───────────────────────────────────────────────────────────────
  {
    'name': 'Chicken Lollipop Cut',
    'nameLowercase': 'chicken lollipop cut',
    'description':
        'Wings cut and shaped into lollipop style. Ready to marinate and fry at home.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 240.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.4,
    'ratingCount': 178,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 125.0},
      {'label': '1 kg', 'price': 240.0},
    ],
  },
  {
    'name': 'Chicken Wings',
    'nameLowercase': 'chicken wings',
    'description':
        'Meaty whole chicken wings. Great for marinating and baking or deep-frying.',
    'category': 'Chicken',
    'subCategory': '',
    'mode': 'meat',
    'price': 200.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.3,
    'ratingCount': 145,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1612187647310-7fd3d56b66b9?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 105.0},
      {'label': '1 kg', 'price': 200.0},
    ],
  },
  // ── Sheep ─────────────────────────────────────────────────────────────────
  {
    'name': 'Sheep Curry Cut',
    'nameLowercase': 'sheep curry cut',
    'description':
        'Tender sheep meat with bone, cut into medium pieces. Ideal for spicy curries.',
    'category': 'Sheep',
    'subCategory': '',
    'mode': 'meat',
    'price': 500.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.5,
    'ratingCount': 212,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 260.0},
      {'label': '1 kg', 'price': 500.0},
    ],
  },
  {
    'name': 'Sheep Ribs',
    'nameLowercase': 'sheep ribs',
    'description':
        'Rack of sheep ribs — perfect for slow-cooking or BBQ grilling.',
    'category': 'Sheep',
    'subCategory': '',
    'mode': 'meat',
    'price': 580.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.6,
    'ratingCount': 134,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 300.0},
      {'label': '1 kg', 'price': 580.0},
    ],
  },
  // ── Beef ──────────────────────────────────────────────────────────────────
  {
    'name': 'Beef Curry Cut',
    'nameLowercase': 'beef curry cut',
    'description':
        'Fresh beef cut into curry-sized pieces. Bone-in for rich, flavourful gravies.',
    'category': 'Beef',
    'subCategory': '',
    'mode': 'meat',
    'price': 420.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.4,
    'ratingCount': 189,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1558030006-450675393462?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 215.0},
      {'label': '1 kg', 'price': 420.0},
    ],
  },
  {
    'name': 'Beef Boneless',
    'nameLowercase': 'beef boneless',
    'description':
        'Lean boneless beef — great for keema, steaks, and beef stir-fries.',
    'category': 'Beef',
    'subCategory': '',
    'mode': 'meat',
    'price': 480.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.5,
    'ratingCount': 156,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 245.0},
      {'label': '1 kg', 'price': 480.0},
    ],
  },
  // ── Sea Foods (Lake Fish) ─────────────────────────────────────────────────
  {
    'name': 'Rohu Fish',
    'nameLowercase': 'rohu fish',
    'description':
        'Fresh lake Rohu fish — cleaned, scaled and cut into steaks. Classic Bengali and North Indian favourite.',
    'category': 'Sea Foods',
    'subCategory': 'Lake Fish',
    'mode': 'meat',
    'price': 220.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.5,
    'ratingCount': 278,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1485704686097-ed47f7263ca4?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 115.0},
      {'label': '1 kg', 'price': 220.0},
    ],
  },
  {
    'name': 'Catla Fish',
    'nameLowercase': 'catla fish',
    'description':
        'Fresh water Catla fish — mild, sweet flavour. Cleaned and cut into fillet-style pieces.',
    'category': 'Sea Foods',
    'subCategory': 'Lake Fish',
    'mode': 'meat',
    'price': 200.0,
    'unit': 'kg',
    'shopId': 'shop_royal_meat_market',
    'rating': 4.3,
    'ratingCount': 198,
    'isAvailable': true,
    'isActive': true,
    'imageUrl':
        'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=800&q=80',
    'weightOptions': [
      {'label': '500g', 'price': 105.0},
      {'label': '1 kg', 'price': 200.0},
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// AGGREGATED
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> get demoAllCategories => [
      ...demoFoodCategories,
      ...demoMeatCategories,
    ];

List<Map<String, dynamic>> get demoAllProducts => [
      ...demoFoodProductsScottzone,
      ...demoFoodProductsGopiAnna,
      ...demoMeatProductsFreshMeatHub,
      ...demoMeatProductsRoyalMeat,
    ];
