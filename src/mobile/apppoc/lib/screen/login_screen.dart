import 'package:apppoc/screen/Home.dart';
import 'package:apppoc/screen/cadastro_screen.dart';
import 'package:apppoc/services/api_service.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final ApiService? api;
  const LoginScreen({super.key, this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();

  late final ApiService _api;
  bool _carregando = false;
  bool _obscureSenha = true;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
  }

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      await _api.login(_usuario.text.trim(), _senha.text);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaHome()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no Login: $e'),
            backgroundColor: AppColors.statusInativo,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _irParaCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroScreen(api: _api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 0;

    // Altura da onda inferior proporcional para acomodar confortavelmente o formulário
    final bottomHeight = (screenHeight * 0.66).clamp(520.0, 640.0);

    // Espaçamento superior aumentado para descer o título 'Login' e os inputs,
    // garantindo que não fiquem em cima da curva/desenho da imagem de onda
    final waveTopPadding = isKeyboardOpen
        ? 36.0
        : (bottomHeight * 0.18 + 38.0).clamp(110.0, 140.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem splash.png posicionada mais para cima
          Positioned(
            top: -screenHeight * 0.16,
            left: 0,
            right: 0,
            height: screenHeight * 1.16,
            child: Image.asset(
              'assets/splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),

          // Retângulo da onda com os campos de Login
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            left: 0,
            right: 0,
            top: isKeyboardOpen ? 70 : (screenHeight - bottomHeight),
            bottom: 0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagem da onda / retângulo inferior
                Image.asset(
                  'assets/rectangle_splash.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),

                // Conteúdo do formulário de login posicionado abaixo da onda
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
                                waveTopPadding,
                                28,
                                24,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Login',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Acesse com sua conta para continuar',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        TextFormField(
                                          controller: _usuario,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Usuário',
                                            hintText: 'Digite seu usuário',
                                            prefixIcon: const Icon(
                                              Icons.person_outline_rounded,
                                              color: AppColors.mainColor,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white
                                                .withValues(alpha: 0.9),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: AppColors.borderCard,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: AppColors.borderCard
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: AppColors.mainColor,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                                  ? 'Informe o usuário'
                                                  : null,
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _senha,
                                          obscureText: _obscureSenha,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _carregando ? null : _entrar(),
                                          decoration: InputDecoration(
                                            labelText: 'Senha',
                                            hintText: 'Digite sua senha',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              color: AppColors.mainColor,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureSenha
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                color: AppColors.textSecondary,
                                              ),
                                              onPressed: () => setState(() =>
                                                  _obscureSenha =
                                                      !_obscureSenha),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white
                                                .withValues(alpha: 0.9),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: AppColors.borderCard,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: AppColors.borderCard
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: AppColors.mainColor,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                                  ? 'Informe a senha'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.mainColor,
                                              foregroundColor:
                                                  AppColors.textOnMain,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 4,
                                            ),
                                            onPressed: _carregando
                                                ? null
                                                : _entrar,
                                            icon: _carregando
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.login_rounded),
                                            label: Text(
                                              _carregando
                                                  ? 'Entrando...'
                                                  : 'Entrar',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Utilize um usuário cadastrado no Django',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Não tem uma conta? ',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _irParaCadastro,
                                              child: const Text(
                                                'Cadastre-se',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.mainColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

          // Logo no canto superior direito
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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

          // Botão de voltar no canto superior esquerdo
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
