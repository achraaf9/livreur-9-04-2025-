import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../services/api_logger.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  String _infoMessage = '';

  @override
  void initState() {
    super.initState();
    // Champs laissés vides - les utilisateurs doivent saisir leurs identifiants
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _infoMessage = 'Tentative de connexion...';
    });
    
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Veuillez remplir tous les champs';
          _infoMessage = '';
        });
        return;
      }
      
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Appel à l'API pour l'authentification
      final agent = await apiService.authAgent(email, password);
      
      if (mounted) {
        if (agent == null) {
          // L'authentification a échoué
          setState(() {
            _isLoading = false;
            _errorMessage = 'Email ou mot de passe incorrect.';
            _infoMessage = '';
          });
          return;
        }
        
        setState(() {
          _infoMessage = 'Authentification réussie !';
        });
        
        // Attendre un court instant pour montrer le message de succès
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Si l'authentification est réussie, naviguer vers l'écran d'accueil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(agent: agent),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Formater le message d'erreur
        String errorMsg = e.toString();
        
        // Supprimer "Exception: " du début du message
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de connexion. Veuillez réessayer.';
          _infoMessage = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou titre
                const Icon(
                  Icons.local_shipping,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Application de Livraison',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Formulaire de connexion
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                
                // Bouton de connexion
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'SE CONNECTER',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                
                // Message d'information (comme "Connexion en cours...")
                if (_infoMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _infoMessage,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Message d'erreur
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 