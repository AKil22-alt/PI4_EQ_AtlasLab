// ignore_for_file: file_names
import 'package:apppoc/screen/ScannerScreen.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/material.dart';

export 'package:apppoc/screen/ScannerScreen.dart';

/// Modelo representativo para as últimas atividades realizadas
class AtividadeItem {
  final String id;
  final String titulo;
  final String descricao;
  final String dataHora;
  final String categoria; // 'scanner', 'ordem', 'laboratorio', 'reporte'
  final String status;
  final IconData icone;
  final Color statusCor;
  final Color statusFundo;

  const AtividadeItem({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataHora,
    required this.categoria,
    required this.status,
    required this.icone,
    required this.statusCor,
    required this.statusFundo,
  });
}

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  int _indiceAbaSelecionada = 0;
  final TextEditingController _pesquisaAtividadesController =
      TextEditingController();
  String _filtroAtividades = '';

  // =======================================================================
  // ÁREA DE INTEGRAÇÃO COM LOGIN / AUTENTICAÇÃO:
  // Quando implementar a tela e o fluxo de login, utilize ou descomente a
  // variável abaixo para exibir dinamicamente o nome da pessoa logada.
  //
  // Exemplo futuro:
  // final String? nomeUsuarioLogado = AuthService.currentUser?.nome;
  // =======================================================================
  final String? _nomeUsuarioLogado = null; // Em comentário/preparado para login

  // Lista de atividades recentes no sistema de patrimônio do AtlasLab
  final List<AtividadeItem> _todasAtividades = const [
    AtividadeItem(
      id: 'ACT-101',
      titulo: 'Scan de Monitor Dell 24',
      descricao: 'Patrimônio #1236654 verificado no Lab B-111',
      dataHora: 'Hoje, 14:32',
      categoria: 'scanner',
      status: 'Concluído',
      icone: Icons.qr_code_scanner_rounded,
      statusCor: AppColors.statusAtivo,
      statusFundo: AppColors.statusAtivoFundo,
    ),
    AtividadeItem(
      id: 'ACT-102',
      titulo: 'Ordem de Serviço #1042',
      descricao: 'Calibração preventiva da Estufa de Secagem - Lab B-101',
      dataHora: 'Hoje, 10:15',
      categoria: 'ordem',
      status: 'Em andamento',
      icone: Icons.assignment_rounded,
      statusCor: Color(0xFFE65100),
      statusFundo: Color(0xFFFFF3E0),
    ),
    AtividadeItem(
      id: 'ACT-103',
      titulo: 'Transferência de Equipamento',
      descricao: 'Workstation Dell (#1359867) movida de B-102 para B-101',
      dataHora: 'Ontem, 16:40',
      categoria: 'laboratorio',
      status: 'Concluído',
      icone: Icons.swap_horiz_rounded,
      statusCor: AppColors.statusAtivo,
      statusFundo: AppColors.statusAtivoFundo,
    ),
    AtividadeItem(
      id: 'ACT-104',
      titulo: 'Reporte de Falha #89',
      descricao: 'Teclado e leitor ótico com defeito - Lab B-105',
      dataHora: '26/10/2026',
      categoria: 'reporte',
      status: 'Pendente',
      icone: Icons.report_problem_rounded,
      statusCor: Color(0xFFC62828),
      statusFundo: Color(0xFFFFEBEE),
    ),
    AtividadeItem(
      id: 'ACT-105',
      titulo: 'Inspeção Semanal',
      descricao: 'Conferência de bancadas do Laboratório de Química Analítica',
      dataHora: '25/10/2026',
      categoria: 'laboratorio',
      status: 'Concluído',
      icone: Icons.science_rounded,
      statusCor: AppColors.statusAtivo,
      statusFundo: AppColors.statusAtivoFundo,
    ),
  ];

  @override
  void dispose() {
    _pesquisaAtividadesController.dispose();
    super.dispose();
  }

  void _navegarParaScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  void _abrirMinhasOrdensModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildMinhasOrdensSheet(ctx),
    );
  }

  void _abrirLaboratoriosModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildLaboratoriosSheet(ctx),
    );
  }

  void _abrirReporteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildReporteSheet(ctx),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _indiceAbaSelecionada = index;
    });

    switch (index) {
      case 0:
        // Início - permanece na Home
        break;
      case 1:
        // Minhas ordens
        _abrirMinhasOrdensModal();
        break;
      case 2:
        // Escanear
        _navegarParaScanner();
        break;
      case 3:
        // Laboratórios
        _abrirLaboratoriosModal();
        break;
      case 4:
        // Reporte
        _abrirReporteModal();
        break;
    }
  }

  List<AtividadeItem> get _atividadesFiltradas {
    final query = _filtroAtividades.trim().toLowerCase();
    if (query.isEmpty) return _todasAtividades;

    return _todasAtividades.where((item) {
      return item.titulo.toLowerCase().contains(query) ||
          item.descricao.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo rectangle_splash.png
          Positioned.fill(
            child: Image.asset(
              'assets/rectangle_splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),

          // Overlay suave para contraste com os cards e textos
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),

          // Conteúdo principal da Home
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Navbar Superior com Degradê em Vermelho Intenso
                  _buildTopNavbar(),

                  const SizedBox(height: 20),

                  // Seção dos 4 Botões Principais de Navegação com Ícones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBotoesPrincipais(),
                  ),

                  const SizedBox(height: 24),

                  // Seção: Últimas Atividades com Campo de Pesquisa
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSecaoUltimasAtividades(),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),

      // Navbar Inferior (Bottom Navigation Bar) com os mesmos botões principais
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  /// Navbar do Topo com vermelho mais vermelho em degradê e mensagem de boas-vindas
  Widget _buildTopNavbar() {
    return Container(
      decoration: BoxDecoration(
        // Degradê com tons mais vivos e profundos de vermelho
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B0000), // Dark Red profundo
            Color(0xFFB71C1C), // Vermelho vivo escuro
            Color(0xFFC62828), // Carmesim vibrante
            Color(0xFFD32F2F), // Vermelho forte
            Color(0xFFE53935), // Vermelho coral vibrante
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo / Identificação AtlasLab
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.science_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AtlasLab',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Ícone de Perfil / Notificações
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Perfil',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Login em desenvolvimento. Em breve perfil do usuário!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Mensagem de Boas-vindas
              Text(
                'Olá,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),

              // =======================================================================
              // MENSAGEM COM NOME DO USUÁRIO (COMENTADO PARA IMPLEMENTAÇÃO DO LOGIN)
              // Quando o login estiver pronto, utilize:
              // Text('Bem-vindo, $_nomeUsuarioLogado!', ...)
              // =======================================================================
              Text(
                _nomeUsuarioLogado != null
                    ? 'Bem-vindo, $_nomeUsuarioLogado!'
                    : 'Bem-vindo!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 4),
              Text(
                'Gerencie patrimônios, ordens e laboratórios',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grade de botões principais com ícones: Minhas ordens, Laboratórios, Escanear, Reporte
  Widget _buildBotoesPrincipais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Acesso Rápido',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          children: [
            // Botão 1: Minhas ordens
            Expanded(
              child: _buildCardBotao(
                titulo: 'Minhas ordens',
                subtitulo: 'Consultar e criar OS',
                icone: Icons.assignment_rounded,
                corIcone: const Color(0xFFC62828),
                corFundoIcone: const Color(0xFFFFEBEE),
                onTap: _abrirMinhasOrdensModal,
              ),
            ),
            const SizedBox(width: 12),

            // Botão 2: Laboratórios
            Expanded(
              child: _buildCardBotao(
                titulo: 'Laboratórios',
                subtitulo: 'Salas e bancadas',
                icone: Icons.science_rounded,
                corIcone: const Color(0xFF1565C0),
                corFundoIcone: const Color(0xFFE3F2FD),
                onTap: _abrirLaboratoriosModal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Botão 3: Escanear (Destaque Principal)
            Expanded(
              child: _buildCardBotao(
                titulo: 'Escanear',
                subtitulo: 'Leitor de QR Code',
                icone: Icons.qr_code_scanner_rounded,
                corIcone: Colors.white,
                corFundoIcone: const Color(0xFFB71C1C),
                isDestacado: true,
                onTap: _navegarParaScanner,
              ),
            ),
            const SizedBox(width: 12),

            // Botão 4: Reporte
            Expanded(
              child: _buildCardBotao(
                titulo: 'Reporte',
                subtitulo: 'Avisar defeito ou falha',
                icone: Icons.report_problem_rounded,
                corIcone: const Color(0xFFD84315),
                corFundoIcone: const Color(0xFFFBE9E7),
                onTap: _abrirReporteModal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card individual para botão de ação rápida
  Widget _buildCardBotao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color corIcone,
    required Color corFundoIcone,
    required VoidCallback onTap,
    bool isDestacado = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDestacado
                ? const Color(0xFFFFF2F2)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDestacado
                  ? const Color(0xFFB71C1C).withValues(alpha: 0.6)
                  : AppColors.borderCard.withValues(alpha: 0.6),
              width: isDestacado ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDestacado
                    ? const Color(0xFFB71C1C).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: corFundoIcone,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icone, color: corIcone, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDestacado
                        ? const Color(0xFFB71C1C)
                        : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDestacado
                      ? const Color(0xFF8B0000)
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção de Últimas Atividades com Barra de Pesquisa Integrada
  Widget _buildSecaoUltimasAtividades() {
    final atividades = _atividadesFiltradas;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderCard.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título da seção e contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFB71C1C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Últimas Atividades',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.fundoCardsClaro,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Text(
                  '${atividades.length} ${atividades.length == 1 ? "item" : "itens"}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Campo de Pesquisa em Tempo Real
          TextField(
            controller: _pesquisaAtividadesController,
            decoration: InputDecoration(
              hintText: 'Pesquisar em atividades...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFB71C1C),
                size: 20,
              ),
              suffixIcon: _filtroAtividades.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: AppColors.textSecondary,
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        setState(() {
                          _pesquisaAtividadesController.clear();
                          _filtroAtividades = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.fundoCardsClaro,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderCard),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderCard),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFB71C1C),
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (valor) {
              setState(() {
                _filtroAtividades = valor;
              });
            },
          ),

          const SizedBox(height: 16),

          // Lista de atividades filtradas ou Estado vazio
          if (atividades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma atividade encontrada com "$_filtroAtividades"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: atividades.length,
              separatorBuilder: (_, __) => const Divider(
                height: 18,
                color: Color(0xFFF1F1F1),
              ),
              itemBuilder: (context, index) {
                final item = atividades[index];
                return _buildItemAtividade(item);
              },
            ),
        ],
      ),
    );
  }

  /// Item individual na lista de últimas atividades
  Widget _buildItemAtividade(AtividadeItem item) {
    return InkWell(
      onTap: () {
        // Exibe detalhes da atividade selecionada
        _mostrarDetalhesAtividade(item);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.fundoCardsClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderCard.withValues(alpha: 0.6)),
              ),
              child: Icon(
                item.icone,
                color: const Color(0xFFB71C1C),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.statusFundo,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.statusCor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.statusCor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.descricao,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.dataHora,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navbar inferior (Bottom Navigation Bar) com os botões solicitados
  Widget _buildBottomNavbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAbaSelecionada,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFB71C1C), // Vermelho degradê
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Minhas ordens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Escanear',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science_rounded),
              label: 'Laboratórios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem_rounded),
              label: 'Reporte',
            ),
          ],
        ),
      ),
    );
  }

  /// Modal de detalhes de uma atividade
  void _mostrarDetalhesAtividade(AtividadeItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.statusFundo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.statusCor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.descricao,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Registro: ${item.dataHora}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Sheet com lista e ações de Minhas Ordens
  Widget _buildMinhasOrdensSheet(BuildContext ctx) {
    return Container(
      height: MediaQuery.sizeOf(ctx).height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_rounded, color: Color(0xFFB71C1C)),
                  SizedBox(width: 8),
                  Text(
                    'Minhas Ordens de Serviço',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                _buildCardOrdemExemplo(
                  codigo: 'OS #1042',
                  titulo: 'Calibração da Estufa de Secagem',
                  lab: 'Lab B-101',
                  status: 'Em andamento',
                  data: '28/10/2026',
                  cor: const Color(0xFFE65100),
                ),
                const SizedBox(height: 10),
                _buildCardOrdemExemplo(
                  codigo: 'OS #1039',
                  titulo: 'Manutenção Preventiva Microscópio',
                  lab: 'Lab Biologia',
                  status: 'Concluído',
                  data: '20/10/2026',
                  cor: AppColors.statusAtivo,
                ),
                const SizedBox(height: 10),
                _buildCardOrdemExemplo(
                  codigo: 'OS #1035',
                  titulo: 'Troca de cabos de rede e fonte',
                  lab: 'Lab B-111',
                  status: 'Concluído',
                  data: '15/10/2026',
                  cor: AppColors.statusAtivo,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nova ordem de serviço em desenvolvimento'),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Criar Nova Ordem',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOrdemExemplo({
    required String codigo,
    required String titulo,
    required String lab,
    required String status,
    required String data,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                codigo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFB71C1C),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$lab • Abertura: $data',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Sheet com lista de laboratórios
  Widget _buildLaboratoriosSheet(BuildContext ctx) {
    final laboratorios = [
      {'nome': 'Laboratório B-101', 'equipamentos': '14 equipamentos', 'status': 'Ativo'},
      {'nome': 'Laboratório B-102', 'equipamentos': '9 equipamentos', 'status': 'Ativo'},
      {'nome': 'Laboratório B-111', 'equipamentos': '18 equipamentos', 'status': 'Ativo'},
      {'nome': 'Química Analítica', 'equipamentos': '22 equipamentos', 'status': 'Em manutenção'},
      {'nome': 'Biologia Celular', 'equipamentos': '11 equipamentos', 'status': 'Ativo'},
    ];

    return Container(
      height: MediaQuery.sizeOf(ctx).height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_rounded, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Text(
                    'Laboratórios Cadastrados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: laboratorios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lab = laboratorios[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.meeting_room_rounded,
                          color: Color(0xFF1565C0),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lab['nome']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              lab['equipamentos']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        lab['status']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: lab['status'] == 'Ativo'
                              ? AppColors.statusAtivo
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Sheet para registrar reporte de defeito / manutenção
  Widget _buildReporteSheet(BuildContext ctx) {
    final TextEditingController descController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Color(0xFFD84315)),
                    SizedBox(width: 8),
                    Text(
                      'Reportar Ocorrência',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Descreva o problema identificado no patrimônio ou no laboratório para nossa equipe técnica:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Equipamento não liga após oscilação de energia...',
                filled: true,
                fillColor: AppColors.fundoCardsClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderCard),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte enviado com sucesso!'),
                    backgroundColor: Color(0xFFB71C1C),
                  ),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'Enviar Reporte',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aliases para facilitar compatibilidade
typedef Home = TelaHome;
typedef HomeScreen = TelaHome;
