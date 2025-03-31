import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/utils/theme.dart';
import 'package:foodkie_express/api/auth_service.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/api/profile_service.dart';

import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/screens/menu_management/controllers/menu_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb){
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDJu7mqM6ioebiN8eNFfQe1uMSO55FhXb4",
          projectId: "foodkie-express",
          storageBucket: "foodkie-express.firebasestorage.app",
          messagingSenderId: "326810023670",
          appId: "1:326810023670:android:112e7d7e9223ef2a929ed7",
      ),
    );
  }else{
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    // For Android
    androidProvider: AndroidProvider.debug,
    // For iOS
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('appSettings');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<MenuService>(
          create: (_) => MenuService(),
        ),
        Provider<OrderService>(
          create: (_) => OrderService(),
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),

        // App-specific providers
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => MenuProvider(
            context.read<MenuService>(),
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Foodkie Express',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light, // Default to light theme
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            navigatorKey: AppRoutes.navigatorKey,
          );
        },
      ),
    );
  }
}