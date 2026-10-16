import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apppoc/models/patrimonio_model.dart';
import 'package:apppoc/screen/Home.dart';

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

  testWidgets('TelaHome exibe estado vazio e atalhos de teste', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaHome()));

    expect(find.text('Leitor de Patrimônio'), findsOneWidget);
    expect(find.text('Nenhum QR Code lido ainda'), findsOneWidget);
    expect(find.text('Abrir Câmera'), findsOneWidget);
    expect(find.text('Monitor Dell 24'), findsOneWidget);
  });

  testWidgets('TelaHome possui botão de voltar com ícone', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaHome()));

    final backButton = find.byTooltip('Voltar');
    expect(backButton, findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('TelaHome carrega dados ao clicar no exemplo', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaHome()));

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
}
