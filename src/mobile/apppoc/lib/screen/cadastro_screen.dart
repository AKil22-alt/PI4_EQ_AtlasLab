import 'package:apppoc/services/api_service.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/material.dart';

class CadastroScreen extends StatefulWidget {
  final ApiService? api;
  const CadastroScreen({super.key, this.api});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();

  bool _carregando = false;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;

  @override
  void dispose() {
    _nome.dispose();
    _usuario.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      // ===================================================================
      // INTEGRAÇÃO COM CADASTRO:
      // Aqui você poderá chamar a API para registrar o novo usuário.
      // Ex: await widget.api?.cadastrarUsuario(...);
      // ===================================================================
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro concluído com sucesso! Faça login.'),
          backgroundColor: AppColors.statusAtivo,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: AppColors.statusInativo,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 0;

    // Altura proporcional para a onda inferior
    final bottomHeight = (screenHeight * 0.72).clamp(540.0, 700.0);

    // Espaçamento superior para descer os campos abaixo da curva da onda
    final waveTopPadding = isKeyboardOpen
        ? 36.0
        : (bottomHeight * 0.16 + 32.0).clamp(100.0, 135.0);

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

          // Retângulo da onda com o formulário de cadastro
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
                // Imagem de fundo da onda
                Image.asset(
                  'assets/rectangle_splash.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),

                // Conteúdo do formulário de cadastro
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
                                          'Cadastro',
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
                                          'Preencha os dados para criar seu acesso',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextFormField(
                                          controller: _nome,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Nome Completo',
                                            hintText: 'Digite seu nome',
                                            prefixIcon: const Icon(
                                              Icons.badge_outlined,
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
                                                  ? 'Informe seu nome'
                                                  : null,
                                        ),
                                        const SizedBox(height: 12),
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
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _senha,
                                          obscureText: _obscureSenha,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Senha',
                                            hintText: 'Crie uma senha',
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
                                          validator: (v) => v == null ||
                                                  v.length < 4
                                              ? 'A senha deve ter ao menos 4 caracteres'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _confirmarSenha,
                                          obscureText: _obscureConfirmarSenha,
                                          textInputAction: TextInputAction.done,
                                          decoration: InputDecoration(
                                            labelText: 'Confirmar Senha',
                                            hintText: 'Repita sua senha',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              color: AppColors.mainColor,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureConfirmarSenha
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                color: AppColors.textSecondary,
                                              ),
                                              onPressed: () => setState(() =>
                                                  _obscureConfirmarSenha =
                                                      !_obscureConfirmarSenha),
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
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Confirme sua senha';
                                            }
                                            if (v != _senha.text) {
                                              return 'As senhas não coincidem';
                                            }
                                            return null;
                                          },
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
                                                : _cadastrar,
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
                                                    Icons.person_add_rounded),
                                            label: Text(
                                              _carregando
                                                  ? 'Cadastrando...'
                                                  : 'Cadastrar',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Já tem uma conta? ',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Entrar',
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
