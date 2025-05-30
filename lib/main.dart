import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/packer_screen.dart';
import 'services/auth_service.dart';
import 'views/user_management_view.dart';
import 'constants/routes.dart';
import 'screens/new_sale_order_screen.dart';
import 'screens/new_purchase_order_screen.dart';
import 'screens/discrepancy_reports_screen.dart';
import 'screens/customer_screen.dart';
import 'screens/purchase_order_report_screen.dart';
import 'screens/sale_order_report_screen.dart';
import 'screens/stock_movement_report_screen.dart';
import 'screens/customer_stock_report_screen.dart';
import 'screens/bulk_export_purchase_screen.dart';
import 'screens/warning_expiry_stock_report_screen.dart';
import 'screens/bulk_export_sale_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/automation_screen.dart';
import 'screens/usda_e_screen.dart';
import 'screens/bulk_export_screen.dart';
import 'screens/api_client_usage_screen.dart';
import 'screens/parse_file_screen.dart';
import 'screens/users_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/api_clients_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/product_settings_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/users_cv_screen.dart';
import 'screens/cash_on_delivery_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/rate_cards_screen.dart';
import 'screens/warehouse_settings_screen.dart';
import 'screens/organisation_settings_screen.dart';
import 'screens/parse_a_file_screen.dart';
import 'screens/self_managed_integration_screen.dart';
import 'screens/bolt_log_screen.dart';
import 'screens/settings_cv_screen.dart';
import 'screens/import_log_screen.dart';
import 'screens/print_log_screen.dart';
import 'screens/bulk_pallet_label_printing_screen.dart';
import 'screens/products_screen.dart';
import 'screens/purchase_orders_screen.dart';
import 'screens/sale_orders_screen.dart';
import 'screens/stock_takes_screen.dart';
import 'screens/wave_picks_screen.dart';
import 'screens/warehouse_locations_screen.dart';
import 'screens/scan_allocate_screen.dart';
import 'screens/scan_order_screen.dart';
import 'constants/theme.dart';
import 'screens/client_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  runApp(const MyApp());
    } catch (e, stack) {
      debugPrint('Error initializing Firebase: $e');
      debugPrint('Stack trace: $stack');
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ));
    }
  }, (error, stack) {
    debugPrint('Error in main: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breadcrumb',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthWrapper(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/admin': (context) => const AdminScreen(),
        '/packer': (context) => const PackerScreen(),
        '/client': (context) => const ClientScreen(),
        userManagementRoute: (context) => UserManagementView(),
        '/new-sale-order': (context) => const NewSaleOrderScreen(),
        '/new-purchase-order': (context) => const NewPurchaseOrderScreen(),
        '/discrepancy-reports': (context) => const DiscrepancyReportsScreen(),
        '/customer': (context) => const CustomerScreen(),
        '/purchase-order-report': (context) => const PurchaseOrderReportScreen(),
        '/sale-order-report': (context) => const SaleOrderReportScreen(),
        '/stock-movement-report': (context) => const StockMovementReportScreen(),
        '/customer-stock-report': (context) => const CustomerStockReportScreen(),
        '/bulk-export-purchase': (context) => const BulkExportPurchaseScreen(),
        '/warning-expiry-stock-report': (context) => const WarningExpiryStockReportScreen(),
        '/bulk-export-sale': (context) => const BulkExportSaleScreen(),
        '/stats': (context) => const StatsScreen(),
        '/automation': (context) => const AutomationScreen(),
        '/usda-e': (context) => const UsdaEScreen(),
        '/bulk-export': (context) => const BulkExportScreen(),
        '/api-client-usage': (context) => const ApiClientUsageScreen(),
        '/parse-file': (context) => const ParseFileScreen(),
        '/users': (context) => const UsersScreen(),
        '/suppliers': (context) => const SuppliersScreen(),
        '/drivers': (context) => const DriversScreen(),
        '/api-clients': (context) => const ApiClientsScreen(),
        '/addresses': (context) => const AddressesScreen(),
        '/product-settings': (context) => const ProductSettingsScreen(),
        '/documents': (context) => const DocumentsScreen(),
        '/users-cv': (context) => const UsersCVScreen(),
        '/cash-on-delivery': (context) => const CashOnDeliveryScreen(),
        '/invoices': (context) => const InvoicesScreen(),
        '/bills': (context) => const BillsScreen(),
        '/rate-cards': (context) => const RateCardsScreen(),
        '/warehouse-settings': (context) => const WarehouseSettingsScreen(),
        '/organisation-settings': (context) => const OrganisationSettingsScreen(),
        '/parse-a-file': (context) => const ParseAFileScreen(),
        '/self-managed-integration': (context) => const SelfManagedIntegrationScreen(),
        '/bolt-log': (context) => const BoltLogScreen(),
        '/settings-cv': (context) => const SettingsCVScreen(),
        '/import-log': (context) => const ImportLogScreen(),
        '/print-log': (context) => const PrintLogScreen(),
        '/bulk-pallet-label-printing': (context) => const BulkPalletLabelPrintingScreen(),
        '/products': (context) => const ProductsScreen(),
        '/purchase-orders': (context) => const PurchaseOrdersScreen(),
        '/sale-orders': (context) => const SaleOrdersScreen(),
        '/stock-takes': (context) => const StockTakesScreen(),
        '/wave-picks': (context) => const WavePicksScreen(),
        '/warehouse-locations': (context) => const WarehouseLocationsScreen(),
        '/scan-allocate': (context) => const ScanAllocateScreen(),
        '/scan-order': (context) => const ScanOrderScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.email == 'fed@gmail.com') {
            return const AdminScreen();
          } else {
            return FutureBuilder<String?>(
              future: authService.getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (roleSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${roleSnapshot.error}'),
                    ),
                  );
                }
                
                final role = roleSnapshot.data;
                if (role == 'packer') {
                  return const PackerScreen();
                } else if (role == 'client') {
                  return const ClientScreen();
                }
                
                return const SignInScreen();
              },
            );
          }
        }
        
        return const SignInScreen();
      },
    );
  }
}