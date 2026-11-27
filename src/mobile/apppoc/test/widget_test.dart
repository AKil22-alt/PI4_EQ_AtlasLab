import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apppoc/models/patrimonio_model.dart';
import 'package:apppoc/screen/Home.dart';
import 'package:apppoc/screen/Scanner.dart';

void main() {
  test('PatrimonioModel parses dados.json correctly', () {
    const rawJson = '''{
      "patrimonio": "1236654",
      "nome": "Monitor Dell 24",
      "origem": "B-101",
      "localAtual": "B-111",
      "responsavel": "Thainara",
      "status": "Ativo",
      "manutencao": "10/09/2026"
    }''';

    final model = PatrimonioModel.tryParse(rawJson);
    expect(model, isNotNull);
    expect(model!.patrimonio, '1236654');
    expect(model.nome, 'Monitor Dell 24');
    expect(model.origem, 'B-101');
    expect(model.localAtual, 'B-111');
    expect(model.responsavel, 'Thainara');
    expect(model.status, 'Ativo');
    expect(model.manutencao, '10/09/2026');
  });

  group('ScannerScreen Tests', () {
    testWidgets('ScannerScreen exibe estado vazio e atalhos de teste', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      expect(find.text('Leitor de Patrimônio'), findsOneWidget);
      expect(find.text('Nenhum QR Code lido ainda'), findsOneWidget);
      expect(find.text('Abrir Câmera'), findsOneWidget);
      expect(find.text('Monitor Dell 24'), findsOneWidget);
    });

    testWidgets('ScannerScreen possui botão de voltar com ícone', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      final backButton = find.byTooltip('Voltar');
      expect(backButton, findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('ScannerScreen carrega dados ao clicar no exemplo', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      // Toca no chip do exemplo "Monitor Dell 24"
      await tester.tap(find.text('Monitor Dell 24'));
      await tester.pumpAndSettle();

      // Verifica se os campos formatados aparecem
      expect(find.text('Patrimônio'), findsOneWidget);
      expect(find.text('1236654'), findsOneWidget);
      expect(find.text('Origem'), findsOneWidget);
      expect(find.text('B-101'), findsOneWidget);
      expect(find.text('Local Atual'), findsOneWidget);
      expect(find.text('B-111'), findsOneWidget);
      expect(find.text('Responsável'), findsOneWidget);
      expect(find.text('Thainara'), findsOneWidget);
      expect(find.text('Última Manutenção'), findsOneWidget);
      expect(find.text('10/09/2026'), findsOneWidget);
    });

    testWidgets('ScannerScreen filtra patrimônios pelo número digitado no campo de pesquisa', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

      expect(find.text('Monitor Dell 24'), findsOneWidget);
      expect(find.text('Workstation Corporativo Dell'), findsOneWidget);

      final campoPesquisa = find.byType(TextField);
      expect(campoPesquisa, findsOneWidget);
      await tester.enterText(campoPesquisa, '1236654');
      await tester.pumpAndSettle();

      expect(find.text('Monitor Dell 24'), findsOneWidget);
      expect(find.text('Workstation Corporativo Dell'), findsNothing);

      await tester.enterText(campoPesquisa, '9999999');
      await tester.pumpAndSettle();

      expect(find.text('Monitor Dell 24'), findsNothing);
      expect(find.text('Workstation Corporativo Dell'), findsNothing);
      expect(find.text('Nenhum patrimônio encontrado com "9999999"'), findsOneWidget);
    });
  });

  group('TelaHome Tests', () {
    testWidgets('TelaHome exibe mensagem de boas-vindas e identificação do AtlasLab', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaHome()));

      expect(find.text('AtlasLab'), findsOneWidget);
      expect(find.text('Bem-vindo!'), findsOneWidget);
    });

    testWidgets('TelaHome exibe botões principais: Minhas ordens, Laboratórios, Escanear e Reporte', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaHome()));

      // Verifica botões de acesso rápido e navbar inferior
      expect(find.text('Minhas ordens'), findsWidgets);
      expect(find.text('Laboratórios'), findsWidgets);
      expect(find.text('Escanear'), findsWidgets);
      expect(find.text('Reporte'), findsWidgets);
      expect(find.text('Início'), findsOneWidget);

      // Verifica ícones
      expect(find.byIcon(Icons.assignment_rounded), findsWidgets);
      expect(find.byIcon(Icons.science_rounded), findsWidgets);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsWidgets);
      expect(find.byIcon(Icons.report_problem_rounded), findsWidgets);
    });

    testWidgets('TelaHome exibe seção de últimas atividades e permite pesquisar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaHome()));

      expect(find.text('Últimas Atividades'), findsOneWidget);
      expect(find.text('Scan de Monitor Dell 24'), findsOneWidget);
      expect(find.text('Ordem de Serviço #1042'), findsOneWidget);

      final campoPesquisa = find.byType(TextField);
      expect(campoPesquisa, findsOneWidget);

      // Filtra por 'Monitor'
      await tester.enterText(campoPesquisa, 'Monitor');
      await tester.pumpAndSettle();

      expect(find.text('Scan de Monitor Dell 24'), findsOneWidget);
      expect(find.text('Ordem de Serviço #1042'), findsNothing);

      // Filtra por termo inexistente
      await tester.enterText(campoPesquisa, 'inexistente_xyz');
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma atividade encontrada com "inexistente_xyz"'), findsOneWidget);
    });
  });

  group('AtivoSerializer & 3D Model Tests', () {
    test('mapeia campos do AtivoSerializer e resolve modelos 3D com normalização de acentos', () {
      final computador = PatrimonioModel.fromJson({
        'id_ativos': 15,
        'nome': 'Micro-Computador Ágil Lab',
        'qr_code': 'ATLASLAB-PC15',
        'status': true,
        'descricao': 'Desktop de análise',
        'local_origem_detalhes': {'id_sala': 1, 'nome': 'Depósito'},
        'local_atual_detalhes': {'id_sala': 4, 'nome': 'Lab Informática 02'},
        'grupo_detalhes': {'id_grupo_a': 2, 'nome': 'Estações de Trabalho'},
      });

      expect(computador.idAtivos, 15);
      expect(computador.qrCode, 'ATLASLAB-PC15');
      expect(computador.status, 'Ativo');
      expect(computador.isAtivo, isTrue);
      expect(computador.salaOrigemNome, 'Depósito');
      expect(computador.salaAtualNome, 'Lab Informática 02');
      expect(computador.grupoNome, 'Estações de Trabalho');
      expect(computador.modelo3dAsset, 'assets/models3d/computador.glb');

      final monitor = PatrimonioModel.fromJson({
        'id_ativos': 16,
        'nome': 'MONITÓR 27 Polegadas',
        'qr_code': 'ATLASLAB-MON16',
        'status': false,
        'local_atual_detalhes': {'id_sala': 4, 'nome': 'Lab Informática 02'},
        'grupo_detalhes': {'id_grupo_a': 3, 'nome': 'Periféricos'},
      });
      expect(monitor.status, 'Inativo');
      expect(monitor.isAtivo, isFalse);
      expect(monitor.modelo3dAsset, 'assets/models3d/monitor.glb');

      final outro = PatrimonioModel.fromJson({
        'id_ativos': 17,
        'nome': 'Estufa de Secagem',
        'qr_code': 'ATLASLAB-EST17',
        'status': true,
      });
      expect(outro.modelo3dAsset, isNull);
    });

    testWidgets('QRScannerPage exibe modelo 3D, controles e card de verificação para Computador', (tester) async {
      final computador = PatrimonioModel.fromJson({
        'id_ativos': 15,
        'nome': 'Computador Dell OptiPlex',
        'qr_code': 'ATLASLAB-PC15',
        'status': true,
        'local_atual_detalhes': {'id_sala': 4, 'nome': 'Lab B-101'},
        'grupo_detalhes': {'id_grupo_a': 2, 'nome': 'Computadores'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: QRScannerPage(
            ativoInicial: computador,
            modelViewerBuilder: (_, path, escala, autoRotate) =>
                Text('3D:$path:${escala.toStringAsFixed(2)}:$autoRotate'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('3D:assets/models3d/computador.glb:1.00:true'),
        findsOneWidget,
      );
      expect(find.text('Computador Dell OptiPlex'), findsOneWidget);
      expect(find.text('QR: ATLASLAB-PC15'), findsOneWidget);
      expect(find.text('Lab B-101'), findsOneWidget);
      expect(find.text('Computadores'), findsOneWidget);
      expect(find.text('Ler outro QR Code'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.byTooltip('Aumentar modelo 3D'));
      await tester.pump();
      expect(
        find.text('3D:assets/models3d/computador.glb:1.15:true'),
        findsOneWidget,
      );
    });
  });
}
