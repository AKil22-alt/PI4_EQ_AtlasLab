// Arquivo responsável por realizar as requisições com a API em Django do AtlasLab

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String mensagem;

  ApiException(this.mensagem, [this.statusCode]);

  @override
  String toString() => mensagem;
}

class ApiService {
  /// URL padrão para conexão com a API Django:
  /// - Dispositivo físico (mesma rede): 'http://10.109.84.20:8000/api/'
  /// - Emulador Android padrão: 'http://10.0.2.2:8000/api/'
  /// - Web / Windows / Testes: 'http://127.0.0.1:8000/api/'
  static String baseUrl = 'http://127.0.0.1:8000/api/';

  final String? _instanceBaseUrl;
  final http.Client _client;

  String? _token;
  Map<String, dynamic>? _usuarioLogado;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : _instanceBaseUrl = baseUrl,
        _client = client ?? http.Client();

  String get activeBaseUrl {
    final url = _instanceBaseUrl ?? ApiService.baseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

  String? get token => _token;
  Map<String, dynamic>? get usuarioLogado => _usuarioLogado;
  bool get isAutenticado => _token != null;

  String _url(String caminho) {
    final base = activeBaseUrl;
    final path = caminho.startsWith('/') ? caminho.substring(1) : caminho;
    return '$base$path';
  }

  /// Realiza o login enviando email e senha para /api/auth/login/.
  /// Retorna o mapa contendo token e dados do usuário.
  Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      final resposta = await _client.post(
        Uri.parse(_url('auth/login/')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'senha': senha,
        }),
      );

      final corpo = _decodificarCorpo(resposta);

      if (resposta.statusCode == 200 && corpo is Map<String, dynamic>) {
        _token = corpo['token'] as String?;
        _usuarioLogado = corpo['usuario'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(corpo['usuario'] as Map)
            : null;
        return corpo;
      }

      final mensagem = _extrairMensagemErro(corpo, resposta.statusCode);
      throw ApiException(mensagem, resposta.statusCode);
    } on SocketException catch (_) {
      throw ApiException(
        'Não foi possível conectar ao servidor backend em $activeBaseUrl. Verifique se a API Django está em execução.',
      );
    } on http.ClientException catch (_) {
      throw ApiException(
        'Falha de comunicação com o servidor ($activeBaseUrl). Verifique sua conexão de rede.',
      );
    }
  }

  /// Envia os dados para a fila de aprovação de cadastro em /api/auth/cadastro/.
  /// O backend armazena em SolicitacaoCadastro e aguarda aprovação pelo administrador.
  Future<String> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await _client.post(
        Uri.parse(_url('auth/cadastro/')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome.trim(),
          'email': email.trim().toLowerCase(),
          'senha': senha,
        }),
      );

      final corpo = _decodificarCorpo(resposta);

      if (resposta.statusCode == 201) {
        if (corpo is Map && corpo['detail'] != null) {
          return corpo['detail'].toString();
        }
        return 'Cadastro enviado. Aguarde a aprovação do administrador.';
      }

      final mensagem = _extrairMensagemErro(corpo, resposta.statusCode);
      throw ApiException(mensagem, resposta.statusCode);
    } on SocketException catch (_) {
      throw ApiException(
        'Não foi possível conectar ao servidor backend em $activeBaseUrl. Verifique se a API Django está em execução.',
      );
    } on http.ClientException catch (_) {
      throw ApiException(
        'Falha de comunicação com o servidor ($activeBaseUrl). Verifique sua conexão de rede.',
      );
    }
  }

  /// Alias conveniente para cadastro
  Future<String> solicitarCadastro({
    required String nome,
    required String email,
    required String senha,
  }) =>
      cadastrar(nome: nome, email: email, senha: senha);

  /// Encerra a sessão no backend e limpa o token local
  Future<void> logout() async {
    if (_token != null) {
      try {
        await _client.post(
          Uri.parse(_url('auth/logout/')),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
        );
      } catch (_) {}
    }
    _token = null;
    _usuarioLogado = null;
  }

  /// Obtém os dados do usuário autenticado a partir de /api/auth/me/
  Future<Map<String, dynamic>> obterUsuarioAtual() async {
    final resp = await _enviar('GET', 'auth/me/');
    final dados =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    _usuarioLogado = dados;
    return dados;
  }

  /// Envia requisições autenticadas para os endpoints da API
  Future<http.Response> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? dados,
  }) async {
    final uri = Uri.parse(_url(caminho));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Token $_token',
    };
    final corpo = dados == null ? null : jsonEncode(dados);

    http.Response resposta;
    try {
      switch (metodo.toUpperCase()) {
        case 'GET':
          resposta = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          resposta = await _client.post(uri, headers: headers, body: corpo);
          break;
        case 'PUT':
          resposta = await _client.put(uri, headers: headers, body: corpo);
          break;
        case 'PATCH':
          resposta = await _client.patch(uri, headers: headers, body: corpo);
          break;
        case 'DELETE':
          resposta = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Método HTTP não suportado: $metodo');
      }
    } on SocketException catch (_) {
      throw ApiException(
        'Não foi possível conectar ao servidor backend em $activeBaseUrl.',
      );
    } on http.ClientException catch (_) {
      throw ApiException(
        'Falha de comunicação com o servidor ($activeBaseUrl).',
      );
    }

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final decodificado = _decodificarCorpo(resposta);
      final mensagem = _extrairMensagemErro(decodificado, resposta.statusCode);
      throw ApiException(mensagem, resposta.statusCode);
    }

    return resposta;
  }

  dynamic _decodificarCorpo(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  String _extrairMensagemErro(dynamic corpo, int statusCode) {
    if (corpo is Map) {
      if (corpo['detail'] != null) {
        return corpo['detail'].toString();
      }
      if (corpo['email'] != null) {
        final val = corpo['email'];
        return val is List ? val.first.toString() : val.toString();
      }
      if (corpo['senha'] != null) {
        final val = corpo['senha'];
        return val is List ? val.first.toString() : val.toString();
      }
      if (corpo['nome'] != null) {
        final val = corpo['nome'];
        return val is List ? val.first.toString() : val.toString();
      }
      if (corpo['non_field_errors'] != null) {
        final val = corpo['non_field_errors'];
        return val is List ? val.first.toString() : val.toString();
      }
      if (corpo['mensagem'] != null) {
        return corpo['mensagem'].toString();
      }
      if (corpo['erro'] != null) {
        return corpo['erro'].toString();
      }
    }
    if (statusCode == 401) {
      return 'E-mail ou senha inválidos.';
    }
    if (statusCode == 403) {
      return 'Acesso negado. Você não tem permissão para realizar esta ação.';
    }
    if (statusCode == 404) {
      return 'Recurso não encontrado.';
    }
    if (statusCode == 409) {
      return 'Conflito de dados. Este registro já existe.';
    }
    if (statusCode >= 500) {
      return 'Erro interno do servidor ($statusCode). Tente novamente mais tarde.';
    }
    return 'Erro HTTP $statusCode. Verifique os dados e tente novamente.';
  }
}
