// ignore_for_file: file_names
import 'dart:convert';
import 'package:apppoc/models/patrimonio_model.dart';
import 'package:apppoc/screen/Home.dart';
import 'package:apppoc/screen/Scanner.dart';
import 'package:apppoc/services/api_service.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannerScreen extends StatefulWidget {
  final String? initialContent;
  final ApiService? api;

  const ScannerScreen({
    super.key,
    this.initialContent,
    this.api,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? _ultimoConteudo;
  PatrimonioModel? _ativoSelecionado;
  bool _mostrarJsonBruto = false;
  bool _carregandoAtivos = false;
  String? _erroAtivos;
  List<PatrimonioModel> _ativos = const [];

  final TextEditingController _pesquisaController = TextEditingController();
  String _filtroPesquisa = '';

  @override
  void initState() {
    super.initState();
    _ultimoConteudo = widget.initialContent;
    if (widget.initialContent != null) {
      _ativoSelecionado = PatrimonioModel.tryParse(widget.initialContent!);
    }

    if (widget.api != null && widget.api!.isAutenticado) {
      _carregarAtivosApi();
    } else {
      _ativos = PatrimonioModel.exemplos;
    }
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAtivosApi() async {
    final api = widget.api;
    if (api == null) return;

    setState(() {
      _carregandoAtivos = true;
      _erroAtivos = null;
    });

    try {
      final lista = await api.listarAtivos();
      if (!mounted) return;
      setState(() {
        _ativos = lista;
        _carregandoAtivos = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroAtivos = e.mensagem;
        _carregandoAtivos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroAtivos = 'Erro ao carregar ativos: $e';
        _carregandoAtivos = false;
      });
    }
  }

  Future<void> _abrirLeitor({PatrimonioModel? ativoInicial}) async {
    final resultado = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerPage(
          api: widget.api,
          ativoInicial: ativoInicial,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    if (resultado is PatrimonioModel) {
      setState(() {
        _ativoSelecionado = resultado;
        _ultimoConteudo =
            const JsonEncoder.withIndent('    ').convert(resultado.toJson());
        _mostrarJsonBruto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ativo validado: ${resultado.nome}'),
              ),
            ],
          ),
          backgroundColor: AppColors.mainColor,
        ),
      );
    } else if (resultado is String && resultado.isNotEmpty) {
      setState(() {
        _ultimoConteudo = resultado;
        _ativoSelecionado = PatrimonioModel.tryParse(resultado);
        _mostrarJsonBruto = false;
      });
    }
  }

  void _selecionarAtivo(PatrimonioModel item) {
    setState(() {
      _ativoSelecionado = item;
      _ultimoConteudo =
          const JsonEncoder.withIndent('    ').convert(item.toJson());
      _mostrarJsonBruto = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patrimônio carregado: ${item.codigoQr} (${item.nome})'),
        backgroundColor: AppColors.mainColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemPatrimonio = _ativoSelecionado ??
        (_ultimoConteudo != null
            ? PatrimonioModel.tryParse(_ultimoConteudo!)
            : null);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Leitor de Patrimônio'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.textOnMain),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TelaHome(api: widget.api)),
              );
            }
          },
        ),
        actions: [
          if (widget.api != null && widget.api!.isAutenticado)
            IconButton(
              tooltip: 'Atualizar ativos',
              onPressed: _carregandoAtivos ? null : _carregarAtivosApi,
              icon: const Icon(Icons.sync_rounded, color: AppColors.textOnMain),
            ),
          if (_ultimoConteudo != null || _ativoSelecionado != null)
            IconButton(
              tooltip: 'Limpar leitura',
              onPressed: () => setState(() {
                _ultimoConteudo = null;
                _ativoSelecionado = null;
                _mostrarJsonBruto = false;
              }),
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textOnMain),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área de exibição do resultado lido
              if (_ultimoConteudo == null && itemPatrimonio == null)
                _buildEmptyState()
              else if (itemPatrimonio != null)
                _buildPatrimonioCard(itemPatrimonio)
              else
                _buildGenericResultCard(_ultimoConteudo!),

              const SizedBox(height: 14),

              // Botões de ação principais
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: AppColors.textOnMain,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _abrirLeitor(),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        itemPatrimonio == null && _ultimoConteudo == null
                            ? 'Abrir Câmera'
                            : 'Escanear Novamente',
                        style: const TextStyle(
                          fontSize: 15,
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
                              content:
                                  Text('Copiado para a área de transferência'),
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

              const SizedBox(height: 16),

              // Seção de pesquisa e listagem de patrimônios (API ou exemplos)
              _buildSecaoPesquisaPatrimonios(itemPatrimonio),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCard, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 42,
              color: AppColors.mainColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nenhum QR Code lido ainda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Toque no botão abaixo para abrir a câmera ou pesquise um patrimônio na lista abaixo',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card formatado com os dados do ativo (AtivoSerializer ou dados.json)
  Widget _buildPatrimonioCard(PatrimonioModel item) {
    final statusCor =
        item.isAtivo ? AppColors.statusAtivo : AppColors.statusInativo;
    final statusFundo = item.isAtivo
        ? AppColors.statusAtivoFundo
        : AppColors.statusInativoFundo;

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
                  child: Icon(
                    item.possuiModelo3d
                        ? Icons.view_in_ar_rounded
                        : Icons.devices_rounded,
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
                              color: statusFundo,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusCor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: statusCor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.status.isNotEmpty
                                      ? item.status
                                      : 'Ativo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusCor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.possuiModelo3d) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '3D Disponível',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainColorDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de campos detalhados
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.tag_rounded,
                  label: item.idAtivos != null ? 'QR Code' : 'Patrimônio',
                  value: item.codigoQr,
                  isHighlight: true,
                ),
                if (item.idAtivos != null) ...[
                  const Divider(color: AppColors.borderCard, height: 20),
                  _buildInfoRow(
                    icon: Icons.numbers_rounded,
                    label: 'ID do Ativo',
                    value: '#${item.idAtivos}',
                  ),
                ],
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'Origem',
                  value: item.salaOrigemNome,
                ),
                const Divider(color: AppColors.borderCard, height: 20),
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Local Atual',
                  value: item.salaAtualNome,
                  valueColor: AppColors.mainColorDark,
                ),
                if (item.grupoNome.isNotEmpty) ...[
                  const Divider(color: AppColors.borderCard, height: 20),
                  _buildInfoRow(
                    icon: Icons.category_rounded,
                    label: 'Grupo',
                    value: item.grupoNome,
                  ),
                ],
                if (item.responsavel.isNotEmpty || item.idAtivos == null) ...[
                  const Divider(color: AppColors.borderCard, height: 20),
                  _buildInfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Responsável',
                    value: item.responsavel,
                  ),
                ],
                if (item.descricao.isNotEmpty) ...[
                  const Divider(color: AppColors.borderCard, height: 20),
                  _buildInfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Descrição',
                    value: item.descricao,
                  ),
                ],
                if (item.manutencao.isNotEmpty || item.idAtivos == null) ...[
                  const Divider(color: AppColors.borderCard, height: 20),
                  _buildInfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Última Manutenção',
                    value: item.manutencao,
                  ),
                ],
                if (item.possuiModelo3d) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColorDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _abrirLeitor(ativoInicial: item),
                      icon: const Icon(Icons.view_in_ar_rounded),
                      label: const Text(
                        'Visualizar Modelo 3D na Câmera',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Seção expansível para ver o JSON original
          if (_ultimoConteudo != null)
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
                            _mostrarJsonBruto
                                ? 'Ocultar JSON'
                                : 'Ver JSON Bruto',
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

  /// Seção de pesquisa e listagem de patrimônios (API `/api/ativos/` ou exemplos locais)
  Widget _buildSecaoPesquisaPatrimonios(PatrimonioModel? itemSelecionado) {
    final termo = _filtroPesquisa.trim().toLowerCase();
    final itensFiltrados = _ativos.where((item) {
      if (termo.isEmpty) return true;
      return item.codigoQr.toLowerCase().contains(termo) ||
          item.patrimonio.toLowerCase().contains(termo) ||
          item.nome.toLowerCase().contains(termo) ||
          item.salaAtualNome.toLowerCase().contains(termo) ||
          item.grupoNome.toLowerCase().contains(termo);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da seção de pesquisa
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.fundoCardsClaro,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.mainColor,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesquisar Patrimônio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Pesquise pelo código, nome ou selecione um ativo da lista',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Campo de busca
          TextField(
            controller: _pesquisaController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Digite o patrimônio (ex: 1236654)...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.mainColor,
                size: 20,
              ),
              suffixIcon: _filtroPesquisa.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: AppColors.textSecondary,
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        setState(() {
                          _pesquisaController.clear();
                          _filtroPesquisa = '';
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
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderCard),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderCard),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.mainColor,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (valor) {
              setState(() {
                _filtroPesquisa = valor.trim();
              });
            },
          ),
          const SizedBox(height: 14),

          if (_carregandoAtivos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              ),
            )
          else if (_erroAtivos != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusInativoFundo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Column(
                children: [
                  Text(
                    _erroAtivos!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.statusInativo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _carregarAtivosApi,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (itensFiltrados.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 36,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum patrimônio encontrado com "$_filtroPesquisa"',
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
              itemCount: itensFiltrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = itensFiltrados[index];
                final bool isSelected =
                    itemSelecionado?.codigoQr == item.codigoQr &&
                        item.codigoQr.isNotEmpty;

                return InkWell(
                  onTap: () => _selecionarAtivo(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.fundoCardsClaro
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.mainColor
                            : AppColors.borderCard.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.mainColor
                                : AppColors.fundoCards,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.possuiModelo3d
                                ? Icons.view_in_ar_rounded
                                : Icons.devices_rounded,
                            color: isSelected
                                ? AppColors.textOnMain
                                : AppColors.mainColorDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.mainColor
                                                .withValues(alpha: 0.15)
                                            : AppColors.fundoCardsClaro,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.mainColor
                                              : AppColors.borderCard,
                                        ),
                                      ),
                                      child: Text(
                                        'Patrimônio: ${item.codigoQr}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mainColorDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: item.isAtivo
                                          ? AppColors.statusAtivo
                                          : AppColors.statusInativo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.nome,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.grupoNome.isNotEmpty
                                    ? 'Sala: ${item.salaAtualNome} • Grupo: ${item.grupoNome}'
                                    : 'Local: ${item.salaAtualNome} • Resp: ${item.responsavel}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: isSelected
                              ? AppColors.mainColor
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Aliases para conveniência
typedef TelaScannerScreen = ScannerScreen;
typedef ScannerPage = ScannerScreen;
