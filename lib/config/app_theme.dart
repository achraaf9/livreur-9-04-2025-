import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF2563EB); // Bleu principal
  static const Color secondaryColor = Color(0xFF3B82F6); // Bleu secondaire
  static const Color accentColor = Color(0xFF60A5FA); // Bleu accent
  static const Color darkColor = Color(0xFF1E293B); // Bleu sombre
  static const Color lightColor = Color(0xFFF1F5F9); // Couleur claire
  static const Color backgroundColor = Color(0xFFFFFFFF); // Fond blanc

  // Couleurs d'état
  static const Color successColor = Color(0xFF10B981); // Vert pour succès
  static const Color warningColor = Color(0xFFF59E0B); // Orange pour avertissement
  static const Color errorColor = Color(0xFFEF4444); // Rouge pour erreur
  static const Color pendingColor = Color(0xFFF472B6); // Rose pour en attente

  // Espacement
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Rayon des bordures
  static const double borderRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Ombres
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Thème complet
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: lightColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkColor,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkColor,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  // Styles de cartes spécifiques pour différents statuts
  static BoxDecoration statusCardDecoration(String status) {
    Color color;
    switch (status) {
      case 'en_attente':
        color = pendingColor;
        break;
      case 'livre':
        color = successColor;
        break;
      case 'non_livre':
        color = errorColor;
        break;
      default:
        color = warningColor;
    }
    
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    );
  }
  
  // Style pour les boutons de statut
  static ButtonStyle statusButtonStyle(String status) {
    Color color;
    switch (status) {
      case 'en_attente':
        color = pendingColor;
        break;
      case 'livre':
        color = successColor;
        break;
      case 'non_livre':
        color = errorColor;
        break;
      default:
        color = warningColor;
    }
    
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    );
  }
} 