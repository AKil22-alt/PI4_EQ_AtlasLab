import 'package:apppoc/ui/_core/app_theme.dart';
import 'package:apppoc/ui/splash/splash_screen.dart';
import 'package:flutter/material.dart';

export 'package:apppoc/screen/Home.dart';

void main() {
  runApp(const TelaAppLeitorQRcode());
}

class TelaAppLeitorQRcode extends StatelessWidget {
  const TelaAppLeitorQRcode({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Leitor de QR Code de Patrimônio',
      theme: AppTheme.appTheme,
      home: const SplashScreen(),
    );
  }
}