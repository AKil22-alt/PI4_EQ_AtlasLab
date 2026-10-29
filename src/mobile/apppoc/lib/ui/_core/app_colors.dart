// Arquivo para estilizar as cores do aplicativo

import 'package:flutter/material.dart';

// Classe abstrata com as cores padrão do aplicativo
abstract class AppColors {
  // Cores base do projeto
  static const Color backgroundColor = Color.fromARGB(255, 255, 254, 255);
  static const Color mainColor = Color.fromARGB(255, 255, 89, 89);
  static const Color fundoCards = Color.fromARGB(255, 255, 193, 193);

  // Variações e cores complementares para padronização
  static const Color mainColorDark = Color(0xFFD32F2F);
  static const Color mainColorLight = Color(0xFFFF8B8B);
  static const Color fundoCardsClaro = Color(0xFFFFF0F0);
  static const Color borderCard = Color(0xFFFFB4B4);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textOnMain = Colors.white;

  // Status e destaques
  static const Color statusAtivo = Color(0xFF2E7D32);
  static const Color statusAtivoFundo = Color(0xFFE8F5E9);
  static const Color statusInativo = Color(0xFFC62828);
  static const Color statusInativoFundo = Color(0xFFFFEBEE);

  // Cores neutras
  static const Color white = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);
}