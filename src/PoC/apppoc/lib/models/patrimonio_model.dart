import 'dart:convert';

/// Modelo de dados correspondente à estrutura de patrimônio definida em dados.json
class PatrimonioModel {
  final String patrimonio;
  final String nome;
  final String origem;
  final String localAtual;
  final String responsavel;
  final String status;
  final String manutencao;

  const PatrimonioModel({
    required this.patrimonio,
    required this.nome,
    required this.origem,
    required this.localAtual,
    required this.responsavel,
    required this.status,
    required this.manutencao,
  });

  factory PatrimonioModel.fromJson(Map<String, dynamic> json) {
    return PatrimonioModel(
      patrimonio: json['patrimonio']?.toString().trim() ?? '',
      nome: json['nome']?.toString().trim() ?? '',
      origem: json['origem']?.toString().trim() ?? '',
      localAtual: json['localAtual']?.toString().trim() ?? '',
      responsavel: json['responsavel']?.toString().trim() ?? '',
      status: json['status']?.toString().trim() ?? 'Ativo',
      manutencao: json['manutencao']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'patrimonio': patrimonio,
        'nome': nome,
        'origem': origem,
        'localAtual': localAtual,
        'responsavel': responsavel,
        'status': status,
        'manutencao': manutencao,
      };

  /// Tenta interpretar uma string bruta lida pelo scanner como PatrimonioModel
  static PatrimonioModel? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PatrimonioModel.fromJson(decoded);
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        return PatrimonioModel.fromJson(decoded.first as Map<String, dynamic>);
      }
    } catch (_) {
      // Conteúdo não é JSON válido
    }
    return null;
  }

  /// Itens de exemplo baseados no dados.json para testes rápidos
  static const List<PatrimonioModel> exemplos = [
    PatrimonioModel(
      patrimonio: '1236654',
      nome: 'Monitor Dell 24',
      origem: 'B-101',
      localAtual: 'B-111',
      responsavel: 'Thainara',
      status: 'Ativo',
      manutencao: '10/09/2026',
    ),
    PatrimonioModel(
      patrimonio: '1359867',
      nome: 'Workstation Corporativo Dell',
      origem: 'B-102',
      localAtual: 'B-101',
      responsavel: 'Guilherme',
      status: 'Ativo',
      manutencao: '25/09/2026',
    ),
  ];
}
