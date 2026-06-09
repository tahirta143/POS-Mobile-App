import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/item_provider.dart';
import 'providers/goods_receipt_provider.dart';
import 'providers/purchase_return_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/sales_return_provider.dart';
import 'providers/sales_invoice_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/items/item_list_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ItemProvider(prefs)),
        ChangeNotifierProvider(create: (_) => GoodsReceiptProvider(prefs)),
        ChangeNotifierProvider(create: (_) => PurchaseReturnProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SalesReturnProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SalesInvoiceProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'POS Mobile System',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Allows API client to navigate on 401
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/items': (context) => const ItemListScreen(),
        '/splash': (context) => const SplashScreen(),
      },
    );
  }
}

// Wrapper to decide which screen to show on app launch
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    debugPrint(
        'AUTH_WRAPPER: isAuthenticated = ${authProvider.isAuthenticated}, loading = ${authProvider.loading}');

    // Show splash/loader if auth status is loading (startup check)
    if (authProvider.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
