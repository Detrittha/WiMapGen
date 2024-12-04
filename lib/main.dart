import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
// import 'menu/wifi_info_screen.dart';
// import 'menu/loginPage.dart';
// import 'menu/index.dart';
import 'menu/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, 
  ]);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
       home :const SplashScreen(),
      // home: const WifiInfoScreen(),
      // home:  LoginPage(),
      // home :const WelcomeScreenPage(),
 
    );
  }
}


