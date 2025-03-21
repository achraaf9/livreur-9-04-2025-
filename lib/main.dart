import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/agent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Démarrage de l\'application avec données statiques...');
  
  // Initialiser le service API avec des données statiques
  final apiService = await ApiService.getInstance();
  print('Service API avec données statiques initialisé avec succès');
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(
          value: apiService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application de Livraison',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        // Les routes vers HomeScreen et autres écrans qui nécessitent un agent
        // sont gérées dynamiquement après la connexion
      },
    );
  }
} 