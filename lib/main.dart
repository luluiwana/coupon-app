// package
import 'package:flutter/material.dart';
//database
import 'core/database/database_helper.dart';
//pages
import 'features/home/pages/main_page.dart';
import 'features/coupon/pages/generate_coupons_form.dart';
import 'features/coupon/pages/production_log_report.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // Ensure the database is initialized before running the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
      title: 'Coupon Generator',
      routes: {
          '/': (context) => const MainPage(),
          '/generate-coupons-form': (context) => const GenerateCouponsForm(),
          '/production-log-report': (context) => const ProductionLogReport(),
      },
    );
  }
}


