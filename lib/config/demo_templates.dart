
class DemoData {
  final String industry;
  final String brandName;
  final List<String> competitors;
  final List<String> platforms;
  final Map<String, dynamic> sampleOrders;
  final Map<String, dynamic> sampleAnalytics;
  final List<Map<String, dynamic>> sampleProducts;

  const DemoData({
    required this.industry,
    required this.brandName,
    required this.competitors,
    required this.platforms,
    required this.sampleOrders,
    required this.sampleAnalytics,
    required this.sampleProducts,
  });
}

class DemoTemplates {
  static final Map<String, DemoData> templates = {
    'fashion': DemoData(
      industry: 'Fashion/Streetwear',
      brandName: 'BENNY',
      competitors: ['KAWS', 'HUMAN MADE', 'Supreme', 'Off-White'],
      platforms: ['Shopify', 'Instagram Shop', 'TikTok Shop', 'Depop'],
      sampleOrders: {
        'orderPrefix': 'BENNY-2024-',
        'customerNames': ['Alex Chen', 'Maya Rodriguez', 'Jordan Kim', 'Taylor Swift', 'Drake'],
        'addresses': [
          {'street': '123 Fashion Ave', 'city': 'New York', 'state': 'NY', 'zip': '10001'},
          {'street': '456 Streetwear Blvd', 'city': 'Los Angeles', 'state': 'CA', 'zip': '90210'},
          {'street': '789 Urban St', 'city': 'Chicago', 'state': 'IL', 'zip': '60601'},
        ],
        'products': [
          {'sku': 'BENNY-HOODIE-001', 'name': 'BENNY Signature Hoodie', 'price': 89.99},
          {'sku': 'BENNY-TEE-002', 'name': 'BENNY Logo Tee', 'price': 39.99},
          {'sku': 'BENNY-CAP-003', 'name': 'BENNY Dad Hat', 'price': 29.99},
          {'sku': 'BENNY-JACKET-004', 'name': 'BENNY Denim Jacket', 'price': 129.99},
          {'sku': 'BENNY-PANTS-005', 'name': 'BENNY Cargo Pants', 'price': 79.99},
          {'sku': 'BENNY-BEANIE-006', 'name': 'BENNY Beanie', 'price': 24.99},
        ],
      },
      sampleAnalytics: {
        'metrics': {
          'totalOrders': 127,
          'totalRevenue': 18450.75,
          'averageOrderValue': 145.28,
          'totalProducts': 8,
          'totalCustomers': 89,
          'fulfillmentRate': 0.94,
          'averageDeliveryTime': 2.1,
          'returnRate': 0.08,
          'customerSatisfaction': 4.6,
        },
        'salesByPlatform': {
          'shopify': 0.70,
          'instagram': 0.20,
          'tiktok': 0.10,
        },
        'competitorMetrics': {
          'KAWS': {'avgOrderValue': 180.0, 'socialFollowers': 2.5, 'brandRecognition': 4.2},
          'HUMAN MADE': {'avgOrderValue': 220.0, 'socialFollowers': 1.8, 'brandRecognition': 4.5},
          'Supreme': {'avgOrderValue': 150.0, 'socialFollowers': 3.2, 'brandRecognition': 4.8},
          'Off-White': {'avgOrderValue': 280.0, 'socialFollowers': 2.1, 'brandRecognition': 4.3},
        },
      },
      sampleProducts: [
        {'name': 'BENNY Signature Hoodie', 'sku': 'BENNY-HOODIE-001', 'stock': 45, 'price': 89.99, 'status': 'In Stock'},
        {'name': 'BENNY Logo Tee', 'sku': 'BENNY-TEE-002', 'stock': 78, 'price': 39.99, 'status': 'In Stock'},
        {'name': 'BENNY Dad Hat', 'sku': 'BENNY-CAP-003', 'stock': 56, 'price': 29.99, 'status': 'In Stock'},
        {'name': 'BENNY Denim Jacket', 'sku': 'BENNY-JACKET-004', 'stock': 23, 'price': 129.99, 'status': 'Low Stock'},
        {'name': 'BENNY Cargo Pants', 'sku': 'BENNY-PANTS-005', 'stock': 34, 'price': 79.99, 'status': 'In Stock'},
        {'name': 'BENNY Beanie', 'sku': 'BENNY-BEANIE-006', 'stock': 12, 'price': 24.99, 'status': 'Low Stock'},
      ],
    ),
    'electronics': DemoData(
      industry: 'Electronics',
      brandName: 'TECHNO',
      competitors: ['Apple', 'Samsung', 'Sony', 'Bose'],
      platforms: ['Shopify', 'Amazon', 'Best Buy', 'Newegg'],
      sampleOrders: {
        'orderPrefix': 'TECHNO-2024-',
        'customerNames': ['John Smith', 'Sarah Johnson', 'Mike Wilson', 'Lisa Brown', 'David Lee'],
        'addresses': [
          {'street': '123 Tech Ave', 'city': 'San Francisco', 'state': 'CA', 'zip': '94102'},
          {'street': '456 Innovation Blvd', 'city': 'Austin', 'state': 'TX', 'zip': '73301'},
          {'street': '789 Digital St', 'city': 'Seattle', 'state': 'WA', 'zip': '98101'},
        ],
        'products': [
          {'sku': 'TECHNO-PHONE-001', 'name': 'TECHNO Pro Phone', 'price': 899.99},
          {'sku': 'TECHNO-LAPTOP-002', 'name': 'TECHNO Ultra Laptop', 'price': 1299.99},
          {'sku': 'TECHNO-HEADPHONES-003', 'name': 'TECHNO Noise Canceling Headphones', 'price': 299.99},
          {'sku': 'TECHNO-TABLET-004', 'name': 'TECHNO Pro Tablet', 'price': 599.99},
          {'sku': 'TECHNO-SPEAKER-005', 'name': 'TECHNO Smart Speaker', 'price': 199.99},
        ],
      },
      sampleAnalytics: {
        'metrics': {
          'totalOrders': 89,
          'totalRevenue': 45650.25,
          'averageOrderValue': 512.92,
          'totalProducts': 5,
          'totalCustomers': 67,
          'fulfillmentRate': 0.97,
          'averageDeliveryTime': 1.8,
          'returnRate': 0.05,
          'customerSatisfaction': 4.8,
        },
        'salesByPlatform': {
          'shopify': 0.50,
          'amazon': 0.30,
          'bestbuy': 0.15,
          'newegg': 0.05,
        },
        'competitorMetrics': {
          'Apple': {'avgOrderValue': 800.0, 'marketShare': 0.25, 'brandRecognition': 4.9},
          'Samsung': {'avgOrderValue': 650.0, 'marketShare': 0.20, 'brandRecognition': 4.7},
          'Sony': {'avgOrderValue': 450.0, 'marketShare': 0.15, 'brandRecognition': 4.5},
          'Bose': {'avgOrderValue': 350.0, 'marketShare': 0.10, 'brandRecognition': 4.3},
        },
      },
      sampleProducts: [
        {'name': 'TECHNO Pro Phone', 'sku': 'TECHNO-PHONE-001', 'stock': 25, 'price': 899.99, 'status': 'In Stock'},
        {'name': 'TECHNO Ultra Laptop', 'sku': 'TECHNO-LAPTOP-002', 'stock': 15, 'price': 1299.99, 'status': 'In Stock'},
        {'name': 'TECHNO Noise Canceling Headphones', 'sku': 'TECHNO-HEADPHONES-003', 'stock': 45, 'price': 299.99, 'status': 'In Stock'},
        {'name': 'TECHNO Pro Tablet', 'sku': 'TECHNO-TABLET-004', 'stock': 8, 'price': 599.99, 'status': 'Low Stock'},
        {'name': 'TECHNO Smart Speaker', 'sku': 'TECHNO-SPEAKER-005', 'stock': 32, 'price': 199.99, 'status': 'In Stock'},
      ],
    ),
    'beauty': DemoData(
      industry: 'Beauty/Cosmetics',
      brandName: 'GLOW',
      competitors: ['Fenty Beauty', 'Glossier', 'Rare Beauty', 'Charlotte Tilbury'],
      platforms: ['Shopify', 'Sephora', 'Ulta', 'Instagram Shop'],
      sampleOrders: {
        'orderPrefix': 'GLOW-2024-',
        'customerNames': ['Emma Davis', 'Sophie Martinez', 'Olivia Chen', 'Ava Wilson', 'Isabella Brown'],
        'addresses': [
          {'street': '123 Beauty Ave', 'city': 'Los Angeles', 'state': 'CA', 'zip': '90210'},
          {'street': '456 Glow Blvd', 'city': 'Miami', 'state': 'FL', 'zip': '33101'},
          {'street': '789 Cosmetics St', 'city': 'New York', 'state': 'NY', 'zip': '10001'},
        ],
        'products': [
          {'sku': 'GLOW-FOUNDATION-001', 'name': 'GLOW Perfect Foundation', 'price': 45.99},
          {'sku': 'GLOW-LIPSTICK-002', 'name': 'GLOW Matte Lipstick', 'price': 24.99},
          {'sku': 'GLOW-PALETTE-003', 'name': 'GLOW Eyeshadow Palette', 'price': 39.99},
          {'sku': 'GLOW-SKINCARE-004', 'name': 'GLOW Vitamin C Serum', 'price': 59.99},
          {'sku': 'GLOW-MASCARA-005', 'name': 'GLOW Volume Mascara', 'price': 19.99},
        ],
      },
      sampleAnalytics: {
        'metrics': {
          'totalOrders': 203,
          'totalRevenue': 12450.75,
          'averageOrderValue': 61.33,
          'totalProducts': 12,
          'totalCustomers': 156,
          'fulfillmentRate': 0.95,
          'averageDeliveryTime': 2.5,
          'returnRate': 0.12,
          'customerSatisfaction': 4.4,
        },
        'salesByPlatform': {
          'shopify': 0.60,
          'sephora': 0.25,
          'ulta': 0.10,
          'instagram': 0.05,
        },
        'competitorMetrics': {
          'Fenty Beauty': {'avgOrderValue': 55.0, 'socialFollowers': 4.2, 'brandRecognition': 4.6},
          'Glossier': {'avgOrderValue': 45.0, 'socialFollowers': 2.8, 'brandRecognition': 4.4},
          'Rare Beauty': {'avgOrderValue': 50.0, 'socialFollowers': 3.5, 'brandRecognition': 4.5},
          'Charlotte Tilbury': {'avgOrderValue': 75.0, 'socialFollowers': 1.9, 'brandRecognition': 4.7},
        },
      },
      sampleProducts: [
        {'name': 'GLOW Perfect Foundation', 'sku': 'GLOW-FOUNDATION-001', 'stock': 67, 'price': 45.99, 'status': 'In Stock'},
        {'name': 'GLOW Matte Lipstick', 'sku': 'GLOW-LIPSTICK-002', 'stock': 89, 'price': 24.99, 'status': 'In Stock'},
        {'name': 'GLOW Eyeshadow Palette', 'sku': 'GLOW-PALETTE-003', 'stock': 34, 'price': 39.99, 'status': 'In Stock'},
        {'name': 'GLOW Vitamin C Serum', 'sku': 'GLOW-SKINCARE-004', 'stock': 12, 'price': 59.99, 'status': 'Low Stock'},
        {'name': 'GLOW Volume Mascara', 'sku': 'GLOW-MASCARA-005', 'stock': 56, 'price': 19.99, 'status': 'In Stock'},
      ],
    ),
  };

  static DemoData getTemplate(String industry) {
    return templates[industry.toLowerCase()] ?? templates['fashion']!;
  }

  static List<String> getAvailableIndustries() {
    return templates.keys.toList();
  }
}