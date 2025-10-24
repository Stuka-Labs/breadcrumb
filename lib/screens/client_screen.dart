import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/theme.dart';
import '../widgets/shop_connect_dialog.dart';
import '../services/ai_insights_service.dart';
import '../services/shopify_service.dart';
import 'shopify_connect_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;
import '../services/auth_service.dart';
import 'new_sale_order_screen.dart';
import 'new_purchase_order_screen.dart';
import 'products_screen.dart';
import '../config/demo_templates.dart';
import 'client_bin_analytics_screen.dart';
import '../services/competitor_service.dart';
import '../widgets/competitor_url_dialog.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCompetitor = 'KAWS';
  List<String> competitors = ['KAWS', 'HUMAN MADE', 'Supreme', 'Off-White'];
  String aiInsight = '';
  bool loadingInsight = false;
  bool hasConnectedShop = false;
  Map<String, dynamic>? shopData;
  bool isDemoUser = false;
  List<Map<String, dynamic>> demoOrders = [];
  Map<String, dynamic>? demoAnalytics;
  bool isLoadingDemoData = false;
  DemoData? currentTemplate;
  List<String> competitorUrls = [];
  List<Map<String, dynamic>> competitorData = [];
  bool isLoadingCompetitors = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAIInsight();
    _checkIfDemoUser();
    _loadCompetitorData();
    // Detect OAuth callback (web only)
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      if (uri.queryParameters['connected'] == 'success') {
        setState(() {
          hasConnectedShop = true;
        });
        fetchShopData();
      }
    }
  }

  Future<void> _checkIfDemoUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == 'client@gmail.com') {
      // Load fashion template for BENNY brand
      currentTemplate = DemoTemplates.getTemplate('fashion');
      debugPrint('Template loaded: ${currentTemplate?.brandName}');
      debugPrint('Template analytics: ${currentTemplate?.sampleAnalytics}');
      
      setState(() {
        isDemoUser = true;
        hasConnectedShop = true;
        isLoadingDemoData = true;
        competitors = currentTemplate!.competitors;
        selectedCompetitor = competitors.isNotEmpty ? competitors.first : 'Competitor';
      });
      await _loadDemoData();
    }
  }

  Future<void> _loadCompetitorData() async {
    if (isDemoUser) return; // Skip for demo user
    
    setState(() => isLoadingCompetitors = true);
    
    try {
      final urls = await CompetitorService.getCompetitorUrls();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        final data = await CompetitorService.getCompetitorData(userId);
        
        setState(() {
          competitorUrls = urls;
          competitorData = data;
          // Update competitors list with real data
          if (data.isNotEmpty) {
            competitors = data.map((c) => c['name'] as String).toList();
            if (competitors.isNotEmpty && !competitors.contains(selectedCompetitor)) {
              selectedCompetitor = competitors.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading competitor data: $e');
    } finally {
      setState(() => isLoadingCompetitors = false);
    }
  }

  Future<void> _loadDemoData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      debugPrint('Loading demo data for user: $userId');

      // Load demo orders - try multiple approaches
      List<Map<String, dynamic>> orders = [];
      
      try {
        // First try: query by clientId
        final ordersQuery = await FirebaseFirestore.instance
            .collection('orders')
            .where('clientId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        
        orders = ordersQuery.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        
        debugPrint('Found ${orders.length} orders by clientId');
      } catch (e) {
        debugPrint('Error querying by clientId: $e');
        
        // Fallback: get all orders and filter
        try {
          final allOrdersQuery = await FirebaseFirestore.instance
              .collection('orders')
              .get();
          
          orders = allOrdersQuery.docs
              .where((doc) => doc.data()['clientId'] == userId)
              .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              }).toList();
          
          debugPrint('Found ${orders.length} orders by fallback query');
        } catch (e2) {
          debugPrint('Error with fallback query: $e2');
        }
      }

      // If still no orders, create some demo data directly
      if (orders.isEmpty) {
        debugPrint('No orders found, creating demo data directly');
        if (currentTemplate != null) {
          orders = _createFallbackDemoOrders();
        } else {
          debugPrint('No template available, skipping demo data creation');
        }
      }

      // Load demo analytics
      Map<String, dynamic>? analytics;
      try {
        final analyticsDoc = await FirebaseFirestore.instance
            .collection('analytics')
            .doc(userId)
            .get();
        
        if (analyticsDoc.exists) {
          analytics = analyticsDoc.data();
          debugPrint('Found analytics data');
        } else {
          debugPrint('No analytics found, creating fallback');
          if (currentTemplate != null) {
            analytics = _createFallbackDemoAnalytics();
          } else {
            debugPrint('No template available, skipping analytics creation');
            analytics = {};
          }
        }
      } catch (e) {
        debugPrint('Error loading analytics: $e');
        if (currentTemplate != null) {
          analytics = _createFallbackDemoAnalytics();
        } else {
          analytics = {};
        }
      }

      setState(() {
        demoOrders = orders;
        demoAnalytics = analytics;
        isLoadingDemoData = false;
      });
      
      debugPrint('Demo data loaded: ${orders.length} orders, analytics: ${analytics != null}');
      if (analytics != null) {
        debugPrint('Analytics metrics: ${analytics['metrics']}');
        debugPrint('Average order value: ${analytics['metrics']?['averageOrderValue']}');
      }
    } catch (e) {
      debugPrint('Error loading demo data: $e');
      // Create fallback data
      setState(() {
        if (currentTemplate != null) {
          demoOrders = _createFallbackDemoOrders();
          demoAnalytics = _createFallbackDemoAnalytics();
        } else {
          demoOrders = [];
          demoAnalytics = {};
        }
        isLoadingDemoData = false;
      });
    }
  }

  List<Map<String, dynamic>> _createFallbackDemoOrders() {
    if (currentTemplate == null) return [];
    
    final template = currentTemplate!;
    final orderData = template.sampleOrders;
    final orderPrefix = orderData['orderPrefix'] as String;
    final customerNames = orderData['customerNames'] as List<String>;
    final addresses = orderData['addresses'] as List<Map<String, String>>;
    final products = orderData['products'] as List<Map<String, dynamic>>;
    
    return [
      {
        'id': 'demo-order-1',
        'orderNumber': '${orderPrefix}001',
        'customerName': customerNames[0],
        'customerEmail': '${customerNames[0].toLowerCase().replaceAll(' ', '.')}@email.com',
        'customerPhone': '+1-555-0123',
        'shippingAddress': {
          'street': addresses[0]['street'],
          'city': addresses[0]['city'],
          'state': addresses[0]['state'],
          'zipCode': addresses[0]['zip'],
          'country': 'USA'
        },
        'items': [
          {'sku': products[0]['sku'], 'name': products[0]['name'], 'quantity': 1, 'price': products[0]['price']},
          {'sku': products[1]['sku'], 'name': products[1]['name'], 'quantity': 2, 'price': products[1]['price']}
        ],
        'subtotal': (products[0]['price'] as double) + (products[1]['price'] as double) * 2,
        'shipping': 9.99,
        'tax': 14.40,
        'total': (products[0]['price'] as double) + (products[1]['price'] as double) * 2 + 9.99 + 14.40,
        'status': 'pending',
        'queuePosition': null,
        'averageShipTime': null,
        'priority': 'normal',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))
      },
      {
        'id': 'demo-order-2',
        'orderNumber': '${orderPrefix}002',
        'customerName': customerNames[1],
        'customerEmail': '${customerNames[1].toLowerCase().replaceAll(' ', '.')}@email.com',
        'customerPhone': '+1-555-0456',
        'shippingAddress': {
          'street': addresses[1]['street'],
          'city': addresses[1]['city'],
          'state': addresses[1]['state'],
          'zipCode': addresses[1]['zip'],
          'country': 'USA'
        },
        'items': [
          {'sku': products[2]['sku'], 'name': products[2]['name'], 'quantity': 1, 'price': products[2]['price']},
          {'sku': products[3]['sku'], 'name': products[3]['name'], 'quantity': 1, 'price': products[3]['price']}
        ],
        'subtotal': (products[2]['price'] as double) + (products[3]['price'] as double),
        'shipping': 12.99,
        'tax': 13.60,
        'total': (products[2]['price'] as double) + (products[3]['price'] as double) + 12.99 + 13.60,
        'status': 'processing',
        'queuePosition': 3,
        'averageShipTime': 45, // minutes
        'priority': 'high',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.now()
      },
      {
        'id': 'demo-order-3',
        'orderNumber': '${orderPrefix}003',
        'customerName': customerNames[2],
        'customerEmail': '${customerNames[2].toLowerCase().replaceAll(' ', '.')}@email.com',
        'customerPhone': '+1-555-0789',
        'shippingAddress': {
          'street': addresses[2]['street'],
          'city': addresses[2]['city'],
          'state': addresses[2]['state'],
          'zipCode': addresses[2]['zip'],
          'country': 'USA'
        },
        'items': [
          {'sku': products[4]['sku'], 'name': products[4]['name'], 'quantity': 1, 'price': products[4]['price']}
        ],
        'subtotal': products[4]['price'] as double,
        'shipping': 8.99,
        'tax': 7.12,
        'total': (products[4]['price'] as double) + 8.99 + 7.12,
        'status': 'shipped',
        'queuePosition': null,
        'averageShipTime': null,
        'priority': 'normal',
        'trackingNumber': '${template.brandName.toUpperCase()}123456789',
        'shippedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)))
      }
    ];
  }

  Map<String, dynamic> _createFallbackDemoAnalytics() {
    if (currentTemplate == null) return {};
    
    final template = currentTemplate!;
    final analytics = template.sampleAnalytics;
    
    return {
      'clientId': FirebaseAuth.instance.currentUser?.uid,
      'period': 'monthly',
      'date': Timestamp.now(),
      'metrics': analytics['metrics'],
      'salesByPlatform': analytics['salesByPlatform'],
      'topProducts': _generateTopProductsFromTemplate(template),
      'salesTrend': [
        {'date': '2024-01-01', 'revenue': 4200.50},
        {'date': '2024-01-02', 'revenue': 3850.25},
        {'date': '2024-01-03', 'revenue': 5100.75},
        {'date': '2024-01-04', 'revenue': 4650.00},
        {'date': '2024-01-05', 'revenue': 5200.25}
      ],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now()
    };
  }

  List<Map<String, dynamic>> _generateTopProductsFromTemplate(DemoData template) {
    final products = template.sampleProducts;
    return products.take(4).map((product) => {
      'sku': product['sku'],
      'name': product['name'],
      'sales': (product['stock'] as int) + 20, // Add some sales
      'revenue': (product['price'] as double) * ((product['stock'] as int) + 20),
    }).toList();
  }

  Future<void> fetchAIInsight() async {
    setState(() => loadingInsight = true);
    aiInsight = await AIInsightsService.getClientPortalInsight(selectedCompetitor);
    setState(() => loadingInsight = false);
  }

  Future<void> fetchShopData() async {
    setState(() => shopData = null);
    try {
      final orders = await ShopifyService.fetchOrders();
      setState(() {
        shopData = {'orders': orders};
      });
    } catch (e) {
      setState(() {
        shopData = {'error': e.toString()};
      });
    }
  }

  void onShopConnected() async {
    // TODO: Implement real connection logic and fetch data from backend
    setState(() {
      hasConnectedShop = true;
      shopData = null; // Will be set after fetching real data
    });
    // TODO: Fetch real data from APIs and update shopData
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/Breadcrumb.png', height: 36),
            const SizedBox(width: 12),
            const Text('Client Portal'),
          ],
        ),
        elevation: 0,
        backgroundColor: kBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPastelOrange,
          unselectedLabelColor: kTextColor,
          indicatorColor: kPastelOrange,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.compare), text: 'Competitor'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            child: isDemoUser
                ? _buildDemoDashboard()
                : hasConnectedShop
                    ? _buildDashboardWithData()
                    : _buildConnectShopPrompt(),
          );
        },
      ),
    );
  }

  Widget _buildDemoDashboard() {
    if (isLoadingDemoData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentTemplate == null) {
      return const Center(
        child: Text(
          'Template not loaded. Please refresh the page.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDemoDashboardTab(),
        _buildCompetitorTab(context),
      ],
    );
  }

  Widget _buildDemoDashboardTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPastelOrange.withOpacity(0.1), kPastelOrange.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPastelOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.dashboard, color: kPastelOrange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to Your WMS Dashboard',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Monitor your orders, track inventory, and analyze performance in real-time.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Add menu
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Desktop layout - horizontal row
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('New Sale Order'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_business),
                        label: const Text('New Purchase Order'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_box),
                        label: const Text('New Product'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProductsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics),
                        label: const Text('Bin Analytics'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientBinAnalyticsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                );
              } else if (constraints.maxWidth > 600) {
                // Tablet layout - 2x2 grid
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('New Sale Order'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_business),
                            label: const Text('New Purchase Order'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_box),
                            label: const Text('New Product'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProductsScreen()),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.analytics),
                            label: const Text('Bin Analytics'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ClientBinAnalyticsScreen()),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile layout - vertical column
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('New Sale Order'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_business),
                        label: const Text('New Purchase Order'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_box),
                        label: const Text('New Product'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProductsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics),
                        label: const Text('Bin Analytics'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientBinAnalyticsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Shop Connection Status
          _buildShopConnectionStatus(),
          const SizedBox(height: 24),

          // Demo Metrics
          if (demoAnalytics != null) _buildDemoMetrics(),
          const SizedBox(height: 24),

          // Demo Orders
          _buildDemoOrders(),
          const SizedBox(height: 24),

          // Demo Charts
          _buildDemoCharts(),
          const SizedBox(height: 24),

          // Products Overview
          _buildProductsOverview(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopConnectionStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop Connections Active',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTemplate?.platforms.join(' • ') ?? 'Shopify • Instagram Shop • TikTok Shop • Depop',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last sync: ${_formatLastSync()}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'CONNECTED',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSync() {
    final now = DateTime.now();
    final lastSync = now.subtract(const Duration(minutes: 15));
    return '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDemoMetrics() {
    if (demoAnalytics == null) {
      return const SizedBox.shrink();
    }
    
    final metrics = demoAnalytics!['metrics'] as Map<String, dynamic>? ?? {};
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop/Tablet layout - horizontal row
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  metrics['totalOrders']?.toString() ?? '0',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Revenue',
                  '\$${metrics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Avg Order Value',
                  '\$${metrics['averageOrderValue']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Fulfillment Rate',
                  '${((metrics['fulfillmentRate'] ?? 0) * 100).toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          );
        } else {
          // Mobile layout - 2x2 grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Orders',
                      metrics['totalOrders']?.toString() ?? '0',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Revenue',
                      '\$${metrics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Avg Order Value',
                      '\$${metrics['averageOrderValue']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Fulfillment Rate',
                      '${((metrics['fulfillmentRate'] ?? 0) * 100).toStringAsFixed(0)}%',
                      Icons.check_circle,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoOrders() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (demoOrders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No orders found'),
                ),
              )
            else
              ...demoOrders.take(5).map((order) => _buildOrderTile(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final queuePosition = order['queuePosition'] as int?;
    final averageShipTime = order['averageShipTime'] as int?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ${order['orderNumber'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${order['customerName'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: \$${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusDisplayText(status, queuePosition),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (status == 'processing' && averageShipTime != null)
                Text(
                  'Avg ship time: ${_formatShipTime(averageShipTime)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                _formatDate(order['createdAt']),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayText(String status, int? queuePosition) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'processing':
        if (queuePosition != null) {
          return '$queuePosition IN LINE TO BE SHIPPED';
        }
        return 'PROCESSING';
      case 'shipped':
        return 'SHIPPED';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatShipTime(int minutes) {
    if (minutes < 60) {
      return '${minutes} MIN';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours} HOUR${hours > 1 ? 'S' : ''}';
      } else {
        return '${hours}H ${remainingMinutes}M';
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.green;
      case 'delivered':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.month}/${date.day}/${date.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDemoCharts() {
    return Row(
      children: [
        Expanded(child: _buildSalesChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildPlatformChart()),
      ],
    );
  }

  Widget _buildSalesChart() {
    if (demoAnalytics == null) {
      return const SizedBox.shrink();
    }
    
    final salesTrend = demoAnalytics!['salesTrend'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sales Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(
                              days[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesTrend.isNotEmpty 
                        ? salesTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as double? ?? 0.0) / 100)).toList()
                        : [
                            FlSpot(0, 10),
                            FlSpot(1, 30),
                            FlSpot(2, 50),
                            FlSpot(3, 40),
                            FlSpot(4, 80),
                            FlSpot(5, 100),
                            FlSpot(6, 120),
                          ],
                      isCurved: true,
                      color: Colors.blue.shade600,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue.shade600,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Revenue Trend',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Peak: \$1,200',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChart() {
    if (demoAnalytics == null) {
      return const SizedBox.shrink();
    }
    
    final salesByPlatform = demoAnalytics!['salesByPlatform'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sales by Platform',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: (salesByPlatform['shopify'] as double? ?? 0.7) * 100, 
                      color: Colors.blue.shade600, 
                      title: 'Shopify\n70%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 80,
                      titlePositionPercentageOffset: 0.6,
                    ),
                    PieChartSectionData(
                      value: (salesByPlatform['instagram'] as double? ?? 0.2) * 100, 
                      color: Colors.pink.shade600, 
                      title: 'Instagram\n20%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 80,
                      titlePositionPercentageOffset: 0.6,
                    ),
                    PieChartSectionData(
                      value: (salesByPlatform['tiktok'] as double? ?? 0.1) * 100, 
                      color: Colors.red.shade600, 
                      title: 'TikTok\n10%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 80,
                      titlePositionPercentageOffset: 0.6,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  centerSpaceColor: Colors.white,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch events if needed
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Column(
              children: [
                _buildLegendItem('Shopify', Colors.blue.shade600, '70%', '\$12,915'),
                const SizedBox(height: 8),
                _buildLegendItem('Instagram', Colors.pink.shade600, '20%', '\$3,690'),
                const SizedBox(height: 8),
                _buildLegendItem('TikTok', Colors.red.shade600, '10%', '\$1,845'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String platform, Color color, String percentage, String amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            platform,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsOverview() {
    final products = currentTemplate?.sampleProducts ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductsScreen()),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...products.map((product) => _buildProductTile(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    final isLowStock = product['status'] == 'Low Stock';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product['sku']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: kPastelOrange),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product['stock']} units',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product['status'],
                  style: TextStyle(
                    color: isLowStock ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectShopPrompt() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link, color: kPastelOrange, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Connect your shop to get started!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To see your sales, orders, and shipping analytics, connect your Shopify, Etsy, Amazon, WooCommerce, or TikTok Shop account.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('Connect Shop'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => ShopConnectDialog(onConnected: onShopConnected),
                );
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.store),
              label: const Text('Shopify'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopifyConnectScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPastelOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardWithData() {
    if (shopData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shopData != null && shopData!['error'] != null) {
      return Center(child: Text('Error: \\${shopData!['error']}'));
    }
    final orders = shopData!['orders'] as List<dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Add menu for clients
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Desktop layout - horizontal row
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('New Sale Order'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_business),
                      label: const Text('New Purchase Order'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_box),
                      label: const Text('New Product'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              );
            } else {
              // Mobile layout - vertical column
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('New Sale Order'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_business),
                      label: const Text('New Purchase Order'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_box),
                      label: const Text('New Product'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: kPastelOrange, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(32.0),
            itemCount: orders?.length ?? 0,
            itemBuilder: (context, index) {
              final order = orders![index]['node'];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('Order #${order['name']}'),
                  subtitle: Text('Customer: ${order['customer']?['firstName'] ?? ''} ${order['customer']?['lastName'] ?? ''}\nTotal: ${order['totalPriceSet']?['shopMoney']?['amount'] ?? ''} ${order['totalPriceSet']?['shopMoney']?['currencyCode'] ?? ''}'),
                  trailing: Text(order['createdAt'] ?? ''),
                ),
              );
            },
          ),
        ),
      ],
    );
  }







  Widget _buildAIInsightsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: loadingInsight
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  const Icon(Icons.insights, color: kPastelOrange, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      aiInsight,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: kPastelOrange),
                    onPressed: fetchAIInsight,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompetitorTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Competitor URL Management
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, color: Colors.blue, size: 32),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Competitor URLs',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCompetitorUrlDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Competitors'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (competitorUrls.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'No competitor URLs added yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add up to 3 competitor website URLs to analyze their sales data and get competitive insights.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...competitorUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    url,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeCompetitorUrl(index),
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Competitor Selection
          if (competitors.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows, color: kPastelOrange, size: 32),
                    const SizedBox(width: 16),
                    const Text('Compare with competitor:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: selectedCompetitor,
                      items: competitors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCompetitor = val;
                          });
                          fetchAIInsight();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          if (competitors.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildCompetitorChart(),
            const SizedBox(height: 32),
            _buildAIInsightsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompetitorChart() {
    if (currentTemplate == null && competitorData.isEmpty) return Container();
    
    // Use real competitor data if available, otherwise fall back to template data
    Map<String, dynamic> selectedCompetitorData;
    double ourAvgOrderValue;
    
    if (competitorData.isNotEmpty) {
      // Find the selected competitor in real data
      selectedCompetitorData = competitorData.firstWhere(
        (c) => c['name'] == selectedCompetitor,
        orElse: () => competitorData.isNotEmpty ? competitorData.first : {},
      );
      ourAvgOrderValue = 145.28; // Default value for real users
    } else {
      // Use template data for demo users
      final competitorMetrics = currentTemplate!.sampleAnalytics['competitorMetrics'] as Map<String, dynamic>? ?? {};
      selectedCompetitorData = competitorMetrics[selectedCompetitor] ?? {'avgOrderValue': 200.0, 'socialFollowers': 2.0, 'brandRecognition': 4.0};
      final ourMetrics = currentTemplate!.sampleAnalytics['metrics'] as Map<String, dynamic>? ?? {};
      ourAvgOrderValue = ourMetrics['averageOrderValue'] as double? ?? 145.28;
    }
    
    final competitorAvgOrderValue = selectedCompetitorData['avgOrderValue'] as double? ?? 0.0;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Average Order Value: ${currentTemplate?.brandName ?? 'Your Brand'} vs $selectedCompetitor', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${currentTemplate?.brandName ?? 'Your Brand'}: \$${ourAvgOrderValue.toStringAsFixed(2)} | $selectedCompetitor: \$${competitorAvgOrderValue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 300,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: ourAvgOrderValue, color: kPastelOrange)],
                      showingTooltipIndicators: [0]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: competitorAvgOrderValue, color: Colors.grey)],
                      showingTooltipIndicators: [0]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text(currentTemplate?.brandName ?? 'Your Brand');
                            case 1:
                              return Text(selectedCompetitor);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ourAvgOrderValue > competitorAvgOrderValue ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    ourAvgOrderValue > competitorAvgOrderValue ? Icons.trending_up : Icons.trending_down,
                    color: ourAvgOrderValue > competitorAvgOrderValue ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ourAvgOrderValue > competitorAvgOrderValue
                          ? '${currentTemplate?.brandName ?? 'Your Brand'} has a \$${(ourAvgOrderValue - competitorAvgOrderValue).toStringAsFixed(2)} higher average order value than $selectedCompetitor!'
                          : '${currentTemplate?.brandName ?? 'Your Brand'} is \$${(competitorAvgOrderValue - ourAvgOrderValue).toStringAsFixed(2)} below $selectedCompetitor\'s average order value.',
                      style: TextStyle(
                        color: ourAvgOrderValue > competitorAvgOrderValue ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompetitorUrlDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => CompetitorUrlDialog(existingUrls: competitorUrls),
    );
    
    if (result != null) {
      setState(() {
        competitorUrls = result;
      });
      await _loadCompetitorData();
    }
  }

  Future<void> _removeCompetitorUrl(int index) async {
    setState(() {
      competitorUrls.removeAt(index);
    });
    
    try {
      await CompetitorService.saveCompetitorUrls(competitorUrls);
      await _loadCompetitorData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Competitor URL removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error removing URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ShopifyService.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }
        final orders = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index]['node'];
            return ListTile(
              title: Text(order['name']),
              subtitle: Text('Created: ${order['createdAt']}'),
              trailing: Text('${order['totalPriceSet']['shopMoney']['amount']} ${order['totalPriceSet']['shopMoney']['currencyCode']}'),
            );
          },
        );
      },
    );
  }
} 