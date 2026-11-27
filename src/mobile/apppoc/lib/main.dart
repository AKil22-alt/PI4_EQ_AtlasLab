import 'package:apppoc/services/api_service.dart';
import 'package:apppoc/ui/_core/app_theme.dart';
import 'package:apppoc/ui/splash/splash_screen.dart';
import 'package:flutter/material.dart';

export 'package:apppoc/screen/Home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TelaAppLeitorQRcode());
}

class TelaAppLeitorQRcode extends StatelessWidget {
  final ApiService? api;

  TelaAppLeitorQRcode({super.key, this.api});

  late final ApiService _apiService = api ?? ApiService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Leitor de QR Code de Patrimônio',
      theme: AppTheme.appTheme,
      home: SplashScreen(api: _apiService),
    );
  }
}
