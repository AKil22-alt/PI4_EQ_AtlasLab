import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apppoc/screen/Home.dart';
import 'package:apppoc/screen/cadastro_screen.dart';
import 'package:apppoc/screen/login_screen.dart';
import 'package:apppoc/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    test('cadastrar envia payload correto para auth/cadastro/ e retorna mensagem de sucesso', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/cadastro/');
        expect(request.method, 'POST');
        expect(request.headers['content-type'], contains('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['nome'], 'Mariana Silva');
        expect(body['email'], 'mariana@example.com');
        expect(body['senha'], 'senha-segura-123');

        return http.Response(
          jsonEncode({
            'detail': 'Cadastro enviado. Aguarde a aprovação do administrador.',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);
      final resultado = await api.cadastrar(
        nome: 'Mariana Silva',
        email: 'mariana@example.com',
        senha: 'senha-segura-123',
      );

      expect(
        resultado,
        'Cadastro enviado. Aguarde a aprovação do administrador.',
      );
    });

    test('cadastrar lança ApiException com mensagem do backend quando e-mail já existe', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'email': ['Este e-mail já está cadastrado.'],
          }),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);

      expect(
        () => api.cadastrar(
          nome: 'Mariana Silva',
          email: 'mariana@example.com',
          senha: 'senha-segura-123',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Este e-mail já está cadastrado.',
          ),
        ),
      );
    });

    test('login envia email/senha para auth/login/ e armazena token e dados do usuário', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/login/');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'mariana@example.com');
        expect(body['senha'], 'senha-segura-123');

        return http.Response(
          jsonEncode({
            'token': 'tokendefinido123456',
            'usuario': {
              'id_user': 42,
              'nome': 'Mariana Silva',
              'email': 'mariana@example.com',
              'cargo': 'CLB',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);
      final resposta = await api.login('mariana@example.com', 'senha-segura-123');

      expect(resposta['token'], 'tokendefinido123456');
      expect(api.token, 'tokendefinido123456');
      expect(api.usuarioLogado?['nome'], 'Mariana Silva');
      expect(api.isAutenticado, isTrue);
    });

    test('login lança ApiException quando credenciais são inválidas (401)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'E-mail ou senha inválidos.'}),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);

      expect(
        () => api.login('mariana@example.com', 'senha-errada'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.mensagem,
            'mensagem',
            'E-mail ou senha inválidos.',
          ),
        ),
      );
    });
  });

  group('CadastroScreen Widget Tests', () {
    testWidgets('valida regras de campos obrigatórios, tamanho mínimo e confirmação de senha', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CadastroScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final botaoCadastrar = find.text('Cadastrar');
      expect(botaoCadastrar, findsOneWidget);

      // Clica em cadastrar com campos vazios
      await tester.ensureVisible(botaoCadastrar);
      await tester.tap(botaoCadastrar);
      await tester.pumpAndSettle();

      expect(find.text('Informe seu nome completo'), findsOneWidget);
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Crie uma senha'), findsOneWidget);

      // Preenche dados inválidos
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ab'); // < 3 chars
      await tester.enterText(campos.at(1), 'invalido'); // email sem formato
      await tester.enterText(campos.at(2), '1234'); // < 8 chars
      await tester.enterText(campos.at(3), '123456'); // diferente

      await tester.ensureVisible(botaoCadastrar);
      await tester.tap(botaoCadastrar);
      await tester.pumpAndSettle();

      expect(find.text('O nome deve ter pelo menos 3 caracteres'), findsOneWidget);
      expect(find.text('Informe um e-mail válido'), findsOneWidget);
      expect(find.text('A senha deve ter pelo menos 8 caracteres'), findsOneWidget);
      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('envia cadastro para aprovação e exibe diálogo informativo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': 'Cadastro enviado. Aguarde a aprovação do administrador.',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: CadastroScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Mariana Silva');
      await tester.enterText(campos.at(1), 'mariana@example.com');
      await tester.enterText(campos.at(2), 'senha-segura-123');
      await tester.enterText(campos.at(3), 'senha-segura-123');

      final botaoCadastrar = find.text('Cadastrar');
      await tester.ensureVisible(botaoCadastrar);
      await tester.tap(botaoCadastrar);
      await tester.pumpAndSettle();

      expect(find.text('Solicitação Enviada'), findsOneWidget);
      expect(
        find.text('Cadastro enviado. Aguarde a aprovação do administrador.'),
        findsOneWidget,
      );
      expect(find.text('Entendi'), findsOneWidget);

      // Fecha o diálogo e confirma retorno
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('valida campos obrigatórios no login', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final botaoEntrar = find.text('Entrar');
      expect(botaoEntrar, findsOneWidget);

      await tester.ensureVisible(botaoEntrar);
      await tester.tap(botaoEntrar);
      await tester.pumpAndSettle();

      expect(find.text('Informe o e-mail'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('realiza login e redireciona para TelaHome exibindo o nome do usuário', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'tokendefinido123456',
            'usuario': {
              'id_user': 10,
              'nome': 'Mariana Silva',
              'email': 'mariana@example.com',
              'cargo': 'CLB',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(baseUrl: 'http://teste/api/', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'mariana@example.com');
      await tester.enterText(campos.at(1), 'senha-segura-123');

      final botaoEntrar = find.text('Entrar');
      await tester.ensureVisible(botaoEntrar);
      await tester.tap(botaoEntrar);
      await tester.pumpAndSettle();

      // Confirma que foi para a TelaHome e exibe a saudação com o nome
      expect(find.byType(TelaHome), findsOneWidget);
      expect(find.text('Bem-vindo, Mariana Silva!'), findsOneWidget);
    });
  });
}
