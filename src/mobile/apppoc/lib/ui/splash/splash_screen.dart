import 'package:apppoc/screen/Home.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExpanded = false;

  void _onScreenTapped() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Altura da parte inferior calculada para manter a proporção do retângulo original (~47% da tela)
    final bottomHeight = (screenHeight * 0.48).clamp(340.0, 480.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onScreenTapped,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem de fundo splash (tela cheia)
            Image.asset(
              'assets/splash.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
            ),

            // Imagem rectangle_splash.png com os textos e o botão sobrepostos na parte inferior
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOutCubic,
              left: 0,
              right: 0,
              bottom: _isExpanded ? 0 : -bottomHeight,
              height: bottomHeight,
              child: IgnorePointer(
                ignoring: !_isExpanded,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagem da onda / retângulo inferior
                    Image.asset(
                      'assets/rectangle_splash.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),

                    // Conteúdo com textos de bem-vindo e botão
                    SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    28,
                                    bottomHeight * 0.18,
                                    28,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 40.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'Bem-Vindo',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Gerencie laboratórios, ativos e ordens de serviço em um só lugar.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.mainColor,
                                            foregroundColor:
                                                AppColors.textOnMain,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            elevation: 4,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const TelaHome(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                          ),
                                          label: const Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Logo com animação para diminuir e ir ao canto superior direito
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOutCubic,
                  alignment:
                      _isExpanded ? Alignment.topRight : Alignment.center,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutCubic,
                      width: _isExpanded ? 85 : 190,
                      height: _isExpanded ? 85 : 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _isExpanded ? 0.10 : 0.15,
                            ),
                            blurRadius: _isExpanded ? 10 : 20,
                            offset: Offset(0, _isExpanded ? 4 : 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Botão de voltar ao estado inicial quando expandido
            if (_isExpanded)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      tooltip: 'Voltar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.all(10),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
