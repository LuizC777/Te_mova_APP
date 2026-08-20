import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models.dart';

class ChamadoRemoto {
  const ChamadoRemoto({
    required this.id,
    required this.solicitacao,
    required this.status,
    required this.equipe,
    required this.idPonto,
    required this.situacao,
  });

  final String id;
  final Solicitacao solicitacao;
  final String status;
  final String equipe;
  final String idPonto;
  final String situacao;

  ChamadoRemoto copiarCom({Solicitacao? solicitacao, String? status}) {
    return ChamadoRemoto(
      id: id,
      solicitacao: solicitacao ?? this.solicitacao,
      status: status ?? this.status,
      equipe: equipe,
      idPonto: idPonto,
      situacao: situacao,
    );
  }

  factory ChamadoRemoto.fromJson(Map<String, dynamic> json) {
    final nivel = json['nivelAlerta'] as String? ?? 'amarelo';
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    final idPonto = json['idPonto'] as String? ?? '';
    final local = json['local'] as String? ?? '';
    final sentido = json['sentido'] as String? ?? '';

    return ChamadoRemoto(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'enviada',
      equipe: json['equipe'] as String? ?? equipeDoApp,
      idPonto: idPonto,
      situacao: json['situacao'] as String? ?? '',
      solicitacao: Solicitacao(
        solicitadoEm: created.toLocal(),
        alturaGrama: (json['crescimentoCm'] as num?)?.toDouble() ?? 0,
        alturaLimite: (json['limitePodaCm'] as num?)?.toDouble() ?? 10,
        urgencia: urgenciaDeNivel(nivel),
        rodovia: json['titulo'] as String? ?? json['road'] as String? ?? idPonto,
        km: (json['km'] as num?)?.toDouble() ?? 0,
        sentido: sentido.isNotEmpty
            ? sentido
            : (local.isNotEmpty ? local : idPonto),
      ),
    );
  }
}

class SnapshotOps {
  const SnapshotOps({
    required this.version,
    required this.chamados,
  });

  final int version;
  final List<ChamadoRemoto> chamados;
}

class ServicoSync {
  ServicoSync({String? base}) : base = base ?? resolveApiBase();

  String base;

  Future<SnapshotOps> buscar() async {
    Object? ultimoErro;
    final tentativas = [
      base,
      ...apiBasesCandidatas().where((url) => url != base),
    ];
    for (final candidato in tentativas) {
      try {
        final snap = await _buscarDe('$candidato/ops/inbox');
        base = candidato;
        return snap;
      } catch (inboxErro) {
        try {
          final snap = await _buscarDe('$candidato/ops/state');
          base = candidato;
          return snap;
        } catch (stateErro) {
          ultimoErro = stateErro;
        }
      }
    }
    throw ultimoErro ?? Exception('Sem conexão com o dashboard em $dashBase');
  }

  Future<void> anunciar() async {
    final res = await http
        .post(
          Uri.parse('$base/ops/presence'),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'url': resolveAppBase(),
            'equipe': equipeDoApp,
            'client': 'app',
          }),
        )
        .timeout(const Duration(seconds: 2));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Falha ao anunciar o app (${res.statusCode})');
    }
  }

  Future<SnapshotOps> _buscarDe(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
    if (res.statusCode != 200) {
      throw Exception('Sync falhou (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = body['dispatches'];
    final chamados = <ChamadoRemoto>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          chamados.add(ChamadoRemoto.fromJson(item));
        } else if (item is Map) {
          chamados.add(ChamadoRemoto.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SnapshotOps(
      version: (body['version'] as num?)?.toInt() ?? 0,
      chamados: chamados,
    );
  }

  Future<void> atualizar({
    required String id,
    required String status,
    double? alturaFinal,
    String? foto,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'source': 'app',
      'alturaFinal': ?alturaFinal,
      'foto': ?foto,
    };
    final res = await http
        .patch(
          Uri.parse('$base/ops/dispatches/$id'),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 2));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Falha ao atualizar chamado (${res.statusCode})');
    }
  }
}
