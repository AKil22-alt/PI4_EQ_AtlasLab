// Arquivo responsável por realizar as requisições com a API em Django do AtlasLab

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apppoc/models/patrimonio_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String mensagem;

  ApiException(this.mensagem, [this.statusCode]);

  @override
  String toString() => mensagem;
}

class ApiService {
  /// URL base centralizada do backend Django REST Framework.
  /// - Local / Emulador ou dispositivo Android via `adb reverse tcp:8000 tcp:8000`:
  ///   'http://127.0.0.1:8000/api'
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';
  static String baseUrl = defaultBaseUrl;

  static const String _tokenStorageKey = 'atlaslab_token';
  static const String _usuarioStorageKey = 'atlaslab_usuario';

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
    final raw = (_instanceBaseUrl ?? ApiService.baseUrl).trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  String? get token => _token;
  Map<String, dynamic>? get usuarioLogado => _usuarioLogado;
  bool get isAutenticado => _token != null && _token!.isNotEmpty;

  String _url(String caminho) {
    final base = activeBaseUrl;
    final path = caminho.startsWith('/') ? caminho.substring(1) : caminho;
    return '$base/$path';
  }

  Future<void> _salvarSessaoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null && _token!.isNotEmpty) {
        await prefs.setString(_tokenStorageKey, _token!);
      } else {
        await prefs.remove(_tokenStorageKey);
      }

      if (_usuarioLogado != null) {
        await prefs.setString(_usuarioStorageKey, jsonEncode(_usuarioLogado));
      } else {
        await prefs.remove(_usuarioStorageKey);
      }
    } catch (_) {
      // Ignora falhas de storage em ambientes de teste sem canal nativo
    }
  }

  Future<void> _limparSessaoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenStorageKey);
      await prefs.remove(_usuarioStorageKey);
    } catch (_) {
      // Ignora falhas de storage em ambientes de teste sem canal nativo
    }
  }

  /// Restaura token/usuário do armazenamento local e valida a sessão via `GET /api/auth/me/`.
  Future<bool> restaurarSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenSalvo = prefs.getString(_tokenStorageKey);
      if (tokenSalvo == null || tokenSalvo.trim().isEmpty) {
        return false;
      }

      _token = tokenSalvo.trim();
      final usuarioJson = prefs.getString(_usuarioStorageKey);
      if (usuarioJson != null && usuarioJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(usuarioJson);
          if (decoded is Map) {
            _usuarioLogado = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      await obterUsuarioAtual();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        _token = null;
        _usuarioLogado = null;
        await _limparSessaoLocal();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Realiza o login enviando email e senha para `POST /api/auth/login/`.
  /// Salva o token e dados do usuário localmente em `SharedPreferences`.
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
        _usuarioLogado = corpo['usuario'] is Map
            ? Map<String, dynamic>.from(corpo['usuario'] as Map)
            : null;
        await _salvarSessaoLocal();
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

  /// Envia solicitação de cadastro para `POST /api/auth/cadastro/`.
  /// O backend cria uma `SolicitacaoCadastro` pendente para aprovação no painel web.
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

      if (resposta.statusCode == 201 || resposta.statusCode == 200) {
        if (corpo is Map && corpo['detail'] != null) {
          return corpo['detail'].toString();
        }
        return 'Solicitação enviada! Aguarde a aprovação de um administrador no painel web para acessar o app.';
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

  /// Encerra a sessão no backend (`POST /api/auth/logout/`) e limpa o token local
  Future<void> logout() async {
    if (_token != null && _token!.isNotEmpty) {
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
    await _limparSessaoLocal();
  }

  /// Obtém e valida os dados do usuário autenticado a partir de `GET /api/auth/me/`
  Future<Map<String, dynamic>> obterUsuarioAtual() async {
    final resp = await _enviar('GET', 'auth/me/');
    final dados =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    _usuarioLogado = dados;
    await _salvarSessaoLocal();
    return dados;
  }

  /// Lista todos os ativos em `GET /api/ativos/`, percorrendo páginas DRF (`results`/`next`)
  /// ou tratando resposta em formato `List`.
  Future<List<PatrimonioModel>> listarAtivos({String? search}) async {
    final ativos = <PatrimonioModel>[];
    var page = 1;
    var hasNext = true;

    while (hasNext && page <= 200) {
      final queryParams = <String, String>{
        'page': '$page',
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };
      final query = Uri(queryParameters: queryParams).query;
      final resp = await _enviar('GET', 'ativos/?$query');
      final corpo = _decodificarCorpo(resp);

      if (corpo is List) {
        for (final item in corpo) {
          if (item is Map) {
            ativos.add(
              PatrimonioModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        hasNext = false;
      } else if (corpo is Map) {
        final results = corpo['results'];
        if (results is List) {
          for (final item in results) {
            if (item is Map) {
              ativos.add(
                PatrimonioModel.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
        final next = corpo['next'];
        hasNext = next != null && next.toString().trim().isNotEmpty;
        page += 1;
      } else {
        hasNext = false;
      }
    }

    return ativos;
  }

  /// Consulta `GET /api/ativos/` (percorrendo páginas se necessário) e localiza o ativo
  /// cujo `qr_code` (ou `id_ativos` como fallback) corresponda ao código lido.
  Future<PatrimonioModel?> buscarAtivoPorQrCode(String codigoLido) async {
    final codigoNormalizado =
        PatrimonioModel.extrairCodigoDeLeitura(codigoLido).trim();
    if (codigoNormalizado.isEmpty) return null;

    final ativos = await listarAtivos();
    final codigoLower = codigoNormalizado.toLowerCase();

    for (final ativo in ativos) {
      if (ativo.qrCode.trim().toLowerCase() == codigoLower) {
        return ativo;
      }
    }

    for (final ativo in ativos) {
      if (ativo.idAtivos != null &&
          ativo.idAtivos.toString() == codigoNormalizado) {
        return ativo;
      }
      if (ativo.patrimonio.trim().toLowerCase() == codigoLower) {
        return ativo;
      }
    }

    return null;
  }

  /// Envia requisições autenticadas para os endpoints da API com `Authorization: Token <token>`
  Future<http.Response> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? dados,
  }) async {
    final uri = Uri.parse(_url(caminho));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Token $_token',
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

  String? _primeiroValor(dynamic campo) {
    if (campo == null) return null;
    if (campo is List) {
      if (campo.isEmpty) return null;
      return campo.first.toString();
    }
    return campo.toString();
  }

  /// Inspeciona mensagens de erro de validação do DRF na ordem:
  /// `senha[0]`, `email[0]`, `nome[0]`, `erro`, `detail`, `mensagem`.
  String _extrairMensagemErro(dynamic corpo, int statusCode) {
    if (corpo is Map) {
      final senhaErro = _primeiroValor(corpo['senha']);
      if (senhaErro != null && senhaErro.isNotEmpty) return senhaErro;

      final emailErro = _primeiroValor(corpo['email']);
      if (emailErro != null && emailErro.isNotEmpty) return emailErro;

      final nomeErro = _primeiroValor(corpo['nome']);
      if (nomeErro != null && nomeErro.isNotEmpty) return nomeErro;

      if (corpo['erro'] != null && corpo['erro'].toString().isNotEmpty) {
        return corpo['erro'].toString();
      }
      if (corpo['detail'] != null && corpo['detail'].toString().isNotEmpty) {
        return corpo['detail'].toString();
      }
      if (corpo['mensagem'] != null &&
          corpo['mensagem'].toString().isNotEmpty) {
        return corpo['mensagem'].toString();
      }
      final nonField = _primeiroValor(corpo['non_field_errors']);
      if (nonField != null && nonField.isNotEmpty) return nonField;
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
