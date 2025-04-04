import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/agent.dart';
import 'package:flutter/foundation.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'dart:developer' as developer;
import 'utils/permission_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activer le mode verbose pour le débogage en développement
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        developer.log(message, name: 'App');
      }
    };
  }
  
  debugPrint('====== DÉMARRAGE DE L\'APPLICATION ======');
  debugPrint('Mode connexion à la base de données activé');
  
  // Afficher la configuration de l'API au démarrage
  debugPrint('URL de base de l\'API: ${ApiConfig.baseUrl}');
  debugPrint('URLs de login: ${ApiConfig.loginUrls.join(', ')}');
  
  // Initialiser le service API
  final apiService = ApiService();
  
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
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      home: const PermissionsWrapper(child: LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        // Les routes vers HomeScreen et autres écrans qui nécessitent un agent
        // sont gérées dynamiquement après la connexion
      },
    );
  }
}

/// Widget wrapper qui gère l'affichage des informations sur les permissions
class PermissionsWrapper extends StatefulWidget {
  final Widget child;
  
  const PermissionsWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  State<PermissionsWrapper> createState() => _PermissionsWrapperState();
}

class _PermissionsWrapperState extends State<PermissionsWrapper> {
  @override
  void initState() {
    super.initState();
    // Vérifier les permissions après construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.checkAllPermissions(context);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 