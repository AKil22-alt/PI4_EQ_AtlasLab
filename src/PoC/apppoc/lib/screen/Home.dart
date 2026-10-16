// ignore_for_file: file_names
import 'dart:convert';
import 'package:apppoc/models/patrimonio_model.dart';
import 'package:apppoc/screen/Scanner.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:apppoc/ui/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelaHome extends StatefulWidget {
  final String? initialContent;

  const TelaHome({super.key, this.initialContent});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  String? _ultimoConteudo;
  bool _mostrarJsonBruto = false;

  @override
  void initState() {
    super.initState();
    _ultimoConteudo = widget.initialContent;
  }

  Future<void> _abrirLeitor() async {
    // Abre a câmera QRScannerPage e aguarda a leitura
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (!mounted) return;

    if (resultado != null && resultado.isNotEmpty) {
      setState(() {
        _ultimoConteudo = resultado;
        _mostrarJsonBruto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('QR Code lido com sucesso!'),
            ],
          ),
          backgroundColor: AppColors.mainColor,
        ),
      );
    }
  }

  void _carregarExemplo(PatrimonioModel item) {
    setState(() {
      _ultimoConteudo = const JsonEncoder.withIndent('    ').convert(item.toJson());
      _mostrarJsonBruto = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exemplo carregado: ${item.nome}'),
        backgroundColor: AppColors.mainColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemPatrimonio = _ultimoConteudo != null
        ? PatrimonioModel.tryParse(_ultimoConteudo!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Leitor de Patrimônio'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textOnMain),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            }
          },
        ),
        actions: [
          if (_ultimoConteudo != null)
            IconButton(
              tooltip: 'Limpar leitura',
              onPressed: () => setState(() {
                _ultimoConteudo = null;
                _mostrarJsonBruto = false;
              }),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textOnMain),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área de exibição do resultado lido
              if (_ultimoConteudo == null)
                _buildEmptyState()
              else if (itemPatrimonio != null)
                _buildPatrimonioCard(itemPatrimonio)
              else
                _buildGenericResultCard(_ultimoConteudo!),

              const SizedBox(height: 20),

              // Botões de ação principais
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: AppColors.textOnMain,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _abrirLeitor,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        _ultimoConteudo == null
                            ? 'Abrir Câmera'
                            : 'Escanear Novamente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_ultimoConteudo != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.fundoCards,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'Copiar informações',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: _ultimoConteudo!),
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Copiado para a área de transferência'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.mainColorDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Seção de atalho para dados de teste (dados.json)
              _buildExemplosSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado vazio quando nada foi lido ainda
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: AppColors.mainColor,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Nenhum QR Code lido ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque no botão abaixo para abrir a câmera ou use os exemplos de teste do dados.json',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card formatado com os dados amigáveis do JSON de patrimônio (dados.json)
  Widget _buildPatrimonioCard(PatrimonioModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do Card com nome do equipamento e status
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.fundoCards,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: AppColors.textOnMain,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome.isNotEmpty ? item.nome : 'Equipamento',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusAtivoFundo,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.statusAtivo),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.statusAtivo,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.status.isNotEmpty ? item.status : 'Ativo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.statusAtivo,
                                  ),
                                ),
                              ],
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

          // Lista de campos detalhados com nomes corrigidos e amigáveis
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.tag_rounded,
                  label: 'Patrimônio',
                  value: item.patrimonio,
                  isHighlight: true,
                ),
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'Origem',
                  value: item.origem,
                ),
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Local Atual',
                  value: item.localAtual,
                  valueColor: AppColors.mainColorDark,
                ),
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Responsável',
                  value: item.responsavel,
                ),
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Última Manutenção',
                  value: item.manutencao,
                ),
              ],
            ),
          ),

          // Seção expansível para ver o JSON original
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _mostrarJsonBruto = !_mostrarJsonBruto;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _mostrarJsonBruto
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.code_rounded,
                          color: AppColors.mainColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _mostrarJsonBruto ? 'Ocultar JSON' : 'Ver JSON Bruto',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_mostrarJsonBruto) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderCard),
                    ),
                    child: SelectableText(
                      _ultimoConteudo!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Linha de informação individual com ícone, rótulo e valor
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.mainColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: TextStyle(
                  fontSize: isHighlight ? 16 : 15,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card genérico para caso o QR Code contenha outro formato ou texto puro
  Widget _buildGenericResultCard(String conteudo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCard, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.mainColor),
              SizedBox(width: 8),
              Text(
                'Conteúdo Lido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: SelectableText(
              conteudo,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Atalhos para testar com itens do dados.json
  Widget _buildExemplosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: AppColors.mainColor,
              ),
              SizedBox(width: 8),
              Text(
                'Testar com dados do dados.json:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PatrimonioModel.exemplos.map((item) {
              return ActionChip(
                backgroundColor: AppColors.fundoCardsClaro,
                side: const BorderSide(color: AppColors.borderCard),
                avatar: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: AppColors.mainColor,
                ),
                label: Text(
                  item.nome,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onPressed: () => _carregarExemplo(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Alias para conveniência
typedef Home = TelaHome;
typedef HomeScreen = TelaHome;
