import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/group_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/theme.dart';
import 'package:borrowcircle/pages/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider makes every controller available to every page.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => LoanController()),
        ChangeNotifierProvider(create: (_) => ReviewController()),
        ChangeNotifierProvider(create: (_) => GroupController()),
      ],
      child: MaterialApp(
        title: 'BorrowCircle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
