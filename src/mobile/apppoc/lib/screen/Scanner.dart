// ignore_for_file: file_names
import 'package:apppoc/models/patrimonio_model.dart';
import 'package:apppoc/services/api_service.dart';
import 'package:apppoc/ui/_core/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef Model3DWidgetBuilder = Widget Function(
  BuildContext context,
  String assetPath,
  double escala,
  bool autoRotate,
);

class QRScannerPage extends StatefulWidget {
  final ApiService? api;
  final PatrimonioModel? ativoInicial;
  final Model3DWidgetBuilder? modelViewerBuilder;

  const QRScannerPage({
    super.key,
    this.api,
    this.ativoInicial,
    this.modelViewerBuilder,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionTimeoutMs: 600,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isTorchOn = false;
  bool _buscandoAtivo = false;
  String? _codigoLido;
  PatrimonioModel? _ativoEncontrado;
  String? _mensagemNaoEncontrado;
  String? _mensagemErroApi;

  // Controles de interatividade 3D
  double _escala3d = 1.0;
  bool _autoRotate = true;
  WebViewController? _modelWebViewController;
  int _modelViewerRevision = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ativoInicial != null) {
      _ativoEncontrado = widget.ativoInicial;
      _codigoLido = widget.ativoInicial!.codigoQr;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_buscandoAtivo ||
        _ativoEncontrado != null ||
        _mensagemNaoEncontrado != null ||
        _mensagemErroApi != null) {
      return;
    }

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    await _processarCodigoLido(raw);
  }

  Future<void> _processarCodigoLido(String raw) async {
    setState(() {
      _buscandoAtivo = true;
      _codigoLido = raw;
      _mensagemNaoEncontrado = null;
      _mensagemErroApi = null;
    });

    try {
      PatrimonioModel? ativo;
      if (widget.api != null) {
        ativo = await widget.api!.buscarAtivoPorQrCode(raw);
      } else {
        ativo = _buscarLocalmente(raw);
      }

      if (!mounted) return;

      if (ativo == null) {
        setState(() {
          _buscandoAtivo = false;
          _mensagemNaoEncontrado = 'Ativo não encontrado';
        });
        return;
      }

      setState(() {
        _buscandoAtivo = false;
        _ativoEncontrado = ativo;
        _escala3d = 1.0;
        _autoRotate = true;
        _modelWebViewController = null;
        _modelViewerRevision += 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _buscandoAtivo = false;
        _mensagemErroApi = e.mensagem;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscandoAtivo = false;
        _mensagemErroApi = 'Erro ao consultar o ativo: $e';
      });
    }
  }

  PatrimonioModel? _buscarLocalmente(String raw) {
    final parsed = PatrimonioModel.tryParse(raw);
    if (parsed != null) return parsed;

    final codigo = PatrimonioModel.extrairCodigoDeLeitura(raw).toLowerCase();
    for (final item in PatrimonioModel.exemplos) {
      if (item.qrCode.toLowerCase() == codigo ||
          item.patrimonio.toLowerCase() == codigo) {
        return item;
      }
    }
    return null;
  }

  void _escanearNovamente() {
    setState(() {
      _buscandoAtivo = false;
      _codigoLido = null;
      _ativoEncontrado = null;
      _mensagemNaoEncontrado = null;
      _mensagemErroApi = null;
      _escala3d = 1.0;
      _autoRotate = true;
      _modelWebViewController = null;
    });
  }

  Future<void> _executarJsModelViewer(String script) async {
    final controller = _modelWebViewController;
    if (controller == null) return;
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  void _atualizarEscala(double novaEscala) {
    final clamped = novaEscala.clamp(0.4, 2.5);
    setState(() {
      _escala3d = clamped;
    });
    final s = clamped.toStringAsFixed(2);
    _executarJsModelViewer('''
      (() => {
        const mv = document.querySelector('model-viewer');
        if (mv) {
          mv.scale = '$s $s $s';
          if (typeof mv.updateFraming === 'function') {
            mv.updateFraming();
          }
        }
      })();
    ''');
  }

  void _alternarAutoRotate() {
    final novoValor = !_autoRotate;
    setState(() {
      _autoRotate = novoValor;
    });
    _executarJsModelViewer('''
      (() => {
        const mv = document.querySelector('model-viewer');
        if (mv) {
          mv.autoRotate = $novoValor;
        }
      })();
    ''');
  }

  void _resetarVisualizacao3d() {
    setState(() {
      _escala3d = 1.0;
      _autoRotate = true;
    });
    if (_modelWebViewController != null) {
      _executarJsModelViewer('''
        (() => {
          const mv = document.querySelector('model-viewer');
          if (mv) {
            mv.scale = '1 1 1';
            mv.cameraOrbit = 'auto auto auto';
            mv.cameraTarget = 'auto auto auto';
            mv.fieldOfView = 'auto';
            mv.autoRotate = true;
            if (typeof mv.updateFraming === 'function') {
              mv.updateFraming();
            }
          }
        })();
      ''');
    } else {
      setState(() {
        _modelViewerRevision += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _ativoEncontrado;
    final modelo3d = ativo?.modelo3dAsset;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: AppColors.textOnMain,
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textOnMain),
          onPressed: () => Navigator.pop(context, ativo),
        ),
        title: Text(
          ativo != null ? 'Visualização do Ativo' : 'Escanear QR Code',
          style: const TextStyle(
            color: AppColors.textOnMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isTorchOn ? 'Desligar lanterna' : 'Ligar lanterna',
            onPressed: () async {
              await _controller.toggleTorch();
              if (mounted) {
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              }
            },
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amberAccent : AppColors.textOnMain,
            ),
          ),
          IconButton(
            tooltip: 'Alternar câmera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch,
              color: AppColors.textOnMain,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Preview ao vivo da câmera no fundo do Stack
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: const Color(0xFF141414),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: AppColors.fundoCards,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Câmera indisponível no momento.\nVerifique as permissões de acesso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (ativo == null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Retângulo guia quando aguardando leitura
          if (!_buscandoAtivo &&
              ativo == null &&
              _mensagemNaoEncontrado == null &&
              _mensagemErroApi == null) ...[
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.mainColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.mainColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.mainColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Aponte para o QR Code de patrimônio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // 3. Indicador de carregamento durante consulta à API
          if (_buscandoAtivo)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.mainColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Validando ativo...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_codigoLido != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _codigoLido!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // 4. Modelo 3D transparente sobreposto à câmera quando mapeado (.glb)
          if (ativo != null && modelo3d != null)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              bottom: 245,
              child: _buildModelViewerLayer(ativo, modelo3d),
            ),

          // 5. Barra superior de controles 3D (sobreposta no Stack acima do ModelViewer)
          if (ativo != null && modelo3d != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildControles3dTopo(ativo, modelo3d),
            ),

          // 6. Card de verificação do ativo na parte inferior
          if (ativo != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildCardVerificacao(ativo, modelo3d),
            ),

          // 7. Feedback de "Ativo não encontrado" ou erro de API
          if (!_buscandoAtivo &&
              (_mensagemNaoEncontrado != null || _mensagemErroApi != null))
            _buildFeedbackNaoEncontrado(),
        ],
      ),
    );
  }

  Widget _buildModelViewerLayer(PatrimonioModel ativo, String modelo3d) {
    if (widget.modelViewerBuilder != null) {
      return widget.modelViewerBuilder!(
        context,
        modelo3d,
        _escala3d,
        _autoRotate,
      );
    }

    // Em testes headless sem WebViewPlatform registrado, evita AssertionError do WebViewWidget
    if (!kIsWeb && WebViewPlatform.instance == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.mainColor),
          ),
          child: Text(
            'Modelo 3D: $modelo3d (${(_escala3d * 100).round()}%)',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final escalaStr =
        '${_escala3d.toStringAsFixed(2)} ${_escala3d.toStringAsFixed(2)} ${_escala3d.toStringAsFixed(2)}';

    return ModelViewer(
      key: ValueKey('mv_${ativo.codigoQr}_$_modelViewerRevision'),
      id: 'atlaslab-model-viewer',
      src: modelo3d,
      alt: 'Modelo 3D de ${ativo.nome}',
      backgroundColor: Colors.transparent,
      cameraControls: true,
      disableZoom: false,
      autoRotate: _autoRotate,
      autoRotateDelay: 1200,
      ar: true,
      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
      scale: escalaStr,
      shadowIntensity: 0.6,
      debugLogging: false,
      onWebViewCreated: (controller) {
        _modelWebViewController = controller;
      },
    );
  }

  Widget _buildControles3dTopo(PatrimonioModel ativo, String modelo3d) {
    final tipoModelo =
        modelo3d.contains('computador') ? 'Computador 3D' : 'Monitor 3D';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.mainColor.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: AppColors.mainColorLight,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '$tipoModelo • 360°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildBotaoControleTopo(
              tooltip: _autoRotate
                  ? 'Pausar rotação automática'
                  : 'Ativar rotação automática',
              icon: _autoRotate
                  ? Icons.pause_circle_outline_rounded
                  : Icons.rotate_right_rounded,
              ativo: _autoRotate,
              onPressed: _alternarAutoRotate,
            ),
            const SizedBox(width: 8),
            _buildBotaoControleTopo(
              tooltip: 'Resetar posição e tamanho',
              icon: Icons.restart_alt_rounded,
              ativo: false,
              onPressed: _resetarVisualizacao3d,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotaoControleTopo({
    required String tooltip,
    required IconData icon,
    required bool ativo,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: ativo
          ? AppColors.mainColor.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCardVerificacao(PatrimonioModel ativo, String? modelo3d) {
    final salaAtual = ativo.salaAtualNome;
    final grupo = ativo.grupoNome;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Controles de redimensionamento (Slider + botões - / +) quando há modelo 3D
          if (modelo3d != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fundoCardsClaro,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.zoom_in_rounded,
                    color: AppColors.mainColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Diminuir modelo 3D',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _atualizarEscala(_escala3d - 0.15),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.mainColorDark,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _escala3d,
                      min: 0.4,
                      max: 2.5,
                      divisions: 21,
                      activeColor: AppColors.mainColor,
                      inactiveColor: AppColors.borderCard,
                      label: '${(_escala3d * 100).round()}%',
                      onChanged: _atualizarEscala,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aumentar modelo 3D',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _atualizarEscala(_escala3d + 0.15),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.mainColorDark,
                      size: 22,
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${(_escala3d * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Cabeçalho com nome do ativo validado e status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  modelo3d != null
                      ? Icons.view_in_ar_rounded
                      : Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.nome.isNotEmpty ? ativo.nome : 'Ativo Validado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'QR: ${ativo.codigoQr}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColorDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ativo.isAtivo
                      ? AppColors.statusAtivoFundo
                      : AppColors.statusInativoFundo,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ativo.isAtivo
                        ? AppColors.statusAtivo
                        : AppColors.statusInativo,
                  ),
                ),
                child: Text(
                  ativo.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ativo.isAtivo
                        ? AppColors.statusAtivo
                        : AppColors.statusInativo,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Informações de Sala Atual e Grupo
          Row(
            children: [
              Expanded(
                child: _buildChipInfo(
                  icon: Icons.location_on_rounded,
                  label: 'Sala Atual',
                  valor: salaAtual.isNotEmpty ? salaAtual : 'Não informada',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChipInfo(
                  icon: Icons.category_rounded,
                  label: 'Grupo',
                  valor: grupo.isNotEmpty ? grupo : 'Não informado',
                ),
              ),
            ],
          ),

          if (modelo3d == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Este ativo não possui modelo 3D (.glb) associado.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Botões de ação do card de verificação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mainColorDark,
                    side: const BorderSide(color: AppColors.mainColor),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _escanearNovamente,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text(
                    'Ler outro QR Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, ativo),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Fechar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipInfo({
    required IconData icon,
    required String label,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.fundoCardsClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderCard.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mainColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackNaoEncontrado() {
    final isNaoEncontrado = _mensagemNaoEncontrado != null;
    final titulo = isNaoEncontrado
        ? _mensagemNaoEncontrado!
        : 'Falha ao consultar ativo';
    final subtitulo = isNaoEncontrado
        ? 'Nenhum ativo cadastrado corresponde ao código "${_codigoLido ?? ''}".'
        : (_mensagemErroApi ?? 'Erro inesperado na comunicação com a API.');

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderCard, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.statusInativoFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNaoEncontrado
                      ? Icons.search_off_rounded
                      : Icons.wifi_off_rounded,
                  size: 36,
                  color: AppColors.statusInativo,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderCard),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _escanearNovamente,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Escanear novamente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
