import 'dart:convert';

/// Detalhes da sala/laboratório retornados por `SalaLabSerializer`
class SalaLabDetalhes {
  final int? idSala;
  final String nome;
  final int? numeroTa;
  final String localizacao;
  final String descricao;
  final String responsavelNome;
  final String responsavelCargo;

  const SalaLabDetalhes({
    this.idSala,
    required this.nome,
    this.numeroTa,
    this.localizacao = '',
    this.descricao = '',
    this.responsavelNome = '',
    this.responsavelCargo = '',
  });

  factory SalaLabDetalhes.fromJson(Map<String, dynamic> json) {
    final resp = json['responsavel_detalhes'];
    final respMap = resp is Map ? Map<String, dynamic>.from(resp) : null;

    return SalaLabDetalhes(
      idSala: json['id_sala'] is int
          ? json['id_sala'] as int
          : int.tryParse(json['id_sala']?.toString() ?? ''),
      nome: json['nome']?.toString().trim() ?? '',
      numeroTa: json['numero_ta'] is int
          ? json['numero_ta'] as int
          : int.tryParse(json['numero_ta']?.toString() ?? ''),
      localizacao: json['localizacao']?.toString().trim() ?? '',
      descricao: json['descricao']?.toString().trim() ?? '',
      responsavelNome: respMap?['nome']?.toString().trim() ?? '',
      responsavelCargo: respMap?['cargo']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (idSala != null) 'id_sala': idSala,
        'nome': nome,
        if (numeroTa != null) 'numero_ta': numeroTa,
        'localizacao': localizacao,
        'descricao': descricao,
        if (responsavelNome.isNotEmpty)
          'responsavel_detalhes': {
            'nome': responsavelNome,
            'cargo': responsavelCargo,
          },
      };
}

/// Detalhes do grupo de ativos retornados por `GrupoASerializer`
class GrupoDetalhes {
  final int? idGrupoA;
  final String nome;
  final int? numeroTa;
  final String tipo;
  final String setor;

  const GrupoDetalhes({
    this.idGrupoA,
    required this.nome,
    this.numeroTa,
    this.tipo = '',
    this.setor = '',
  });

  factory GrupoDetalhes.fromJson(Map<String, dynamic> json) {
    return GrupoDetalhes(
      idGrupoA: json['id_grupo_a'] is int
          ? json['id_grupo_a'] as int
          : int.tryParse(json['id_grupo_a']?.toString() ?? ''),
      nome: json['nome']?.toString().trim() ?? '',
      numeroTa: json['numero_ta'] is int
          ? json['numero_ta'] as int
          : int.tryParse(json['numero_ta']?.toString() ?? ''),
      tipo: json['tipo']?.toString().trim() ?? '',
      setor: json['setor']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (idGrupoA != null) 'id_grupo_a': idGrupoA,
        'nome': nome,
        if (numeroTa != null) 'numero_ta': numeroTa,
        'tipo': tipo,
        'setor': setor,
      };
}

/// Modelo de dados compatível com `AtivoSerializer` (API Django) e `dados.json`
class PatrimonioModel {
  final int? idAtivos;
  final String patrimonio;
  final String qrCode;
  final String nome;
  final String origem;
  final String localAtual;
  final String responsavel;
  final String status;
  final bool isAtivo;
  final String manutencao;
  final String descricao;
  final SalaLabDetalhes? localOrigemDetalhes;
  final SalaLabDetalhes? localAtualDetalhes;
  final GrupoDetalhes? grupoDetalhes;

  const PatrimonioModel({
    this.idAtivos,
    required this.patrimonio,
    this.qrCode = '',
    required this.nome,
    required this.origem,
    required this.localAtual,
    required this.responsavel,
    required this.status,
    this.isAtivo = true,
    required this.manutencao,
    this.descricao = '',
    this.localOrigemDetalhes,
    this.localAtualDetalhes,
    this.grupoDetalhes,
  });

  /// Código de exibição principal (prioriza `qr_code`, depois `patrimonio`, depois `id_ativos`)
  String get codigoQr => qrCode.isNotEmpty
      ? qrCode
      : (patrimonio.isNotEmpty ? patrimonio : (idAtivos?.toString() ?? ''));

  /// Nome da sala atual priorizando `local_atual_detalhes.nome`
  String get salaAtualNome {
    if (localAtualDetalhes != null && localAtualDetalhes!.nome.isNotEmpty) {
      return localAtualDetalhes!.nome;
    }
    return localAtual;
  }

  /// Nome da sala de origem priorizando `local_origem_detalhes.nome`
  String get salaOrigemNome {
    if (localOrigemDetalhes != null && localOrigemDetalhes!.nome.isNotEmpty) {
      return localOrigemDetalhes!.nome;
    }
    return origem;
  }

  /// Nome do grupo do ativo
  String get grupoNome => grupoDetalhes?.nome ?? '';

  /// Resolve o caminho do modelo 3D `.glb` com base no nome normalizado (minúsculas e sem acentos)
  String? get modelo3dAsset {
    final nomeNormalizado = normalizarTexto(nome);
    if (nomeNormalizado.contains('computador')) {
      return 'assets/models3d/computador.glb';
    }
    if (nomeNormalizado.contains('monitor')) {
      return 'assets/models3d/monitor.glb';
    }
    return null;
  }

  bool get possuiModelo3d => modelo3dAsset != null;

  /// Normaliza texto para minúsculas e remove acentos/diacríticos comuns do português
  static String normalizarTexto(String texto) {
    final lower = texto.trim().toLowerCase();
    const comAcento = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÿ';
    const semAcento = 'aaaaaaeeeeiiiiooooouuuucnyy';
    final buffer = StringBuffer();
    for (var i = 0; i < lower.length; i++) {
      final char = lower[i];
      final idx = comAcento.indexOf(char);
      buffer.write(idx >= 0 ? semAcento[idx] : char);
    }
    return buffer.toString();
  }

  factory PatrimonioModel.fromJson(Map<String, dynamic> json) {
    final idAtivos = json['id_ativos'] is int
        ? json['id_ativos'] as int
        : int.tryParse(json['id_ativos']?.toString() ?? '');

    final rawQrCode = json['qr_code']?.toString().trim() ?? '';
    final rawPatrimonio = json['patrimonio']?.toString().trim() ?? '';
    final patrimonioFinal = rawPatrimonio.isNotEmpty
        ? rawPatrimonio
        : (rawQrCode.isNotEmpty ? rawQrCode : (idAtivos?.toString() ?? ''));

    final origemDetalhes = json['local_origem_detalhes'] is Map
        ? SalaLabDetalhes.fromJson(
            Map<String, dynamic>.from(json['local_origem_detalhes'] as Map),
          )
        : null;
    final atualDetalhes = json['local_atual_detalhes'] is Map
        ? SalaLabDetalhes.fromJson(
            Map<String, dynamic>.from(json['local_atual_detalhes'] as Map),
          )
        : null;
    final grupo = json['grupo_detalhes'] is Map
        ? GrupoDetalhes.fromJson(
            Map<String, dynamic>.from(json['grupo_detalhes'] as Map),
          )
        : null;

    final rawStatus = json['status'];
    late final bool ativoBool;
    late final String statusTexto;
    if (rawStatus is bool) {
      ativoBool = rawStatus;
      statusTexto = rawStatus ? 'Ativo' : 'Inativo';
    } else {
      final texto = rawStatus?.toString().trim() ?? '';
      if (texto.toLowerCase() == 'false' || texto.toLowerCase() == 'inativo') {
        ativoBool = false;
        statusTexto = 'Inativo';
      } else {
        ativoBool = true;
        statusTexto = texto.isNotEmpty ? texto : 'Ativo';
      }
    }

    final rawOrigem = json['origem']?.toString().trim() ?? '';
    final origemFinal = rawOrigem.isNotEmpty
        ? rawOrigem
        : (origemDetalhes?.nome.isNotEmpty == true
            ? origemDetalhes!.nome
            : (origemDetalhes?.localizacao ?? ''));

    final rawLocalAtual = json['localAtual']?.toString().trim() ?? '';
    final localAtualFinal = rawLocalAtual.isNotEmpty
        ? rawLocalAtual
        : (atualDetalhes?.nome.isNotEmpty == true
            ? atualDetalhes!.nome
            : (atualDetalhes?.localizacao ?? ''));

    final rawResponsavel = json['responsavel']?.toString().trim() ?? '';
    final responsavelFinal = rawResponsavel.isNotEmpty
        ? rawResponsavel
        : (atualDetalhes?.responsavelNome.isNotEmpty == true
            ? atualDetalhes!.responsavelNome
            : (origemDetalhes?.responsavelNome ?? ''));

    return PatrimonioModel(
      idAtivos: idAtivos,
      patrimonio: patrimonioFinal,
      qrCode: rawQrCode.isNotEmpty ? rawQrCode : rawPatrimonio,
      nome: json['nome']?.toString().trim() ?? '',
      origem: origemFinal,
      localAtual: localAtualFinal,
      responsavel: responsavelFinal,
      status: statusTexto,
      isAtivo: ativoBool,
      manutencao: json['manutencao']?.toString().trim() ?? '',
      descricao: json['descricao']?.toString().trim() ?? '',
      localOrigemDetalhes: origemDetalhes,
      localAtualDetalhes: atualDetalhes,
      grupoDetalhes: grupo,
    );
  }

  Map<String, dynamic> toJson() => {
        if (idAtivos != null) 'id_ativos': idAtivos,
        'patrimonio': patrimonio,
        if (qrCode.isNotEmpty) 'qr_code': qrCode,
        'nome': nome,
        'origem': origem,
        'localAtual': localAtual,
        'responsavel': responsavel,
        'status': status,
        'manutencao': manutencao,
        if (descricao.isNotEmpty) 'descricao': descricao,
        if (localOrigemDetalhes != null)
          'local_origem_detalhes': localOrigemDetalhes!.toJson(),
        if (localAtualDetalhes != null)
          'local_atual_detalhes': localAtualDetalhes!.toJson(),
        if (grupoDetalhes != null) 'grupo_detalhes': grupoDetalhes!.toJson(),
      };

  /// Extrai o código de busca a partir de texto puro ou JSON lido por QR Code
  static String extrairCodigoDeLeitura(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final qr = decoded['qr_code']?.toString().trim();
        if (qr != null && qr.isNotEmpty) return qr;
        final pat = decoded['patrimonio']?.toString().trim();
        if (pat != null && pat.isNotEmpty) return pat;
        final id = decoded['id_ativos']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {
      // Conteúdo não é JSON; utiliza string pura lida do QR Code
    }
    return trimmed;
  }

  /// Tenta interpretar uma string bruta lida pelo scanner como PatrimonioModel
  static PatrimonioModel? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PatrimonioModel.fromJson(decoded);
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map<String, dynamic>) {
        return PatrimonioModel.fromJson(decoded.first as Map<String, dynamic>);
      }
    } catch (_) {
      // Conteúdo não é JSON válido
    }
    return null;
  }

  /// Itens de exemplo baseados no dados.json para fallback offline/testes
  static const List<PatrimonioModel> exemplos = [
    PatrimonioModel(
      patrimonio: '1236654',
      qrCode: '1236654',
      nome: 'Monitor Dell 24',
      origem: 'B-101',
      localAtual: 'B-111',
      responsavel: 'Thainara',
      status: 'Ativo',
      isAtivo: true,
      manutencao: '10/09/2026',
    ),
    PatrimonioModel(
      patrimonio: '1359867',
      qrCode: '1359867',
      nome: 'Workstation Corporativo Dell',
      origem: 'B-102',
      localAtual: 'B-101',
      responsavel: 'Guilherme',
      status: 'Ativo',
      isAtivo: true,
      manutencao: '25/09/2026',
    ),
  ];
}
