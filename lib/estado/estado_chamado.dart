import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/api.dart';
import '../models.dart';
import '../servicos/servico_sync.dart';

/// Situação de um serviço, do aceite até a conclusão.
enum StatusPoda {
  emRota,
  emProgresso,
  interrompida,
  concluida;

  String get rotulo => switch (this) {
    StatusPoda.emRota => 'Em deslocamento',
    StatusPoda.emProgresso => 'Em progresso',
    StatusPoda.interrompida => 'Interrompida',
    StatusPoda.concluida => 'Concluída',
  };
}

/// Onde a Home está no fluxo.
enum TelaHome { chamado, rota, execucao }

StatusPoda? _statusDeRemote(String status) => switch (status) {
  'confirmada' => StatusPoda.emRota,
  'em_andamento' => StatusPoda.emProgresso,
  'interrompida' => StatusPoda.interrompida,
  'concluida' => StatusPoda.concluida,
  _ => null,
};

String _remoteDeStatus(StatusPoda status) => switch (status) {
  StatusPoda.emRota => 'confirmada',
  StatusPoda.emProgresso => 'em_andamento',
  StatusPoda.interrompida => 'interrompida',
  StatusPoda.concluida => 'concluida',
};

/// Estado compartilhado entre a Home, o Histórico e o dashboard.
class EstadoChamado extends ChangeNotifier {
  EstadoChamado({ServicoSync? sync}) : _sync = sync ?? ServicoSync() {
    _iniciarSync();
  }

  final ServicoSync _sync;
  Timer? _poll;
  int _versao = 0;
  String _assinatura = '';
  bool _primeiroSnapshot = true;
  final Set<String> _vistos = {};

  List<ChamadoRemoto> _disponiveis = [];
  List<String> _recemChegados = [];
  ChamadoRemoto? _ativo;
  bool _conectado = false;
  String? _erroSync;

  TelaHome _tela = TelaHome.chamado;
  StatusPoda? _status;
  DateTime? _aceitoEm;
  DateTime? _inicioPoda;
  Duration _decorrido = Duration.zero;
  Timer? _cronometro;

  /// Registros gerados nesta sessão. O mais recente primeiro.
  final List<RegistroServico> _registros = [];

  List<ChamadoRemoto> get disponiveis => List.unmodifiable(_disponiveis);
  List<String> get recemChegados => List.unmodifiable(_recemChegados);
  ChamadoRemoto? get ativo => _ativo;
  bool get conectado => _conectado;
  String? get erroSync => _erroSync;
  String get apiBase => _sync.base;
  String get dashUrl => dashBase;

  TelaHome get tela => _tela;
  StatusPoda? get status => _status;
  Duration get decorrido => _decorrido;
  DateTime? get inicioPoda => _inicioPoda;
  List<RegistroServico> get registros => List.unmodifiable(_registros);

  Solicitacao get solicitacao =>
      _ativo?.solicitacao ??
      (_disponiveis.isNotEmpty
          ? _disponiveis.first.solicitacao
          : solicitacaoAtual);

  int get tentativas => _registros.length;

  void _iniciarSync() {
    _poll?.cancel();
    unawaited(_puxar());
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_puxar());
    });
  }

  Future<void> _puxar() async {
    try {
      final snapshot = await _sync.buscar();
      _conectado = true;
      _erroSync = null;
      unawaited(_sync.anunciar().then((_) {}, onError: (_) {}));
      final assinatura = snapshot.chamados
          .map(
            (c) =>
                '${c.id}:${c.status}:${c.solicitacao.alturaGrama}:${c.equipe}',
          )
          .join('|');
      if (snapshot.version != _versao ||
          _versao == 0 ||
          assinatura != _assinatura) {
        _versao = snapshot.version;
        _assinatura = assinatura;
        _aplicarChamados(snapshot.chamados);
      }
      notifyListeners();
    } catch (err) {
      _conectado = false;
      _erroSync =
          'Sem conexão com o dashboard ($dashBase) pela API (${_sync.base}).';
      notifyListeners();
    }
  }

  void _aplicarChamados(List<ChamadoRemoto> todos) {
    if (_ativo != null) {
      final atualizado = todos.where((c) => c.id == _ativo!.id).firstOrNull;
      if (atualizado != null) {
        _ativo = _ativo!.copiarCom(
          solicitacao: atualizado.solicitacao,
          status: atualizado.status,
        );
      }
    } else {
      final emCurso = todos
          .where(
            (c) => c.status == 'confirmada' || c.status == 'em_andamento',
          )
          .firstOrNull;
      if (emCurso != null) {
        _retomar(emCurso);
      }
    }

    _disponiveis = [
      for (final chamado in todos)
        if ((chamado.status == 'enviada' || chamado.status == 'interrompida') &&
            chamado.id != _ativo?.id)
          chamado,
    ];

    final idsAgora = {for (final chamado in _disponiveis) chamado.id};
    if (_primeiroSnapshot) {
      _vistos.addAll(idsAgora);
      _recemChegados = [];
      _primeiroSnapshot = false;
    } else {
      _recemChegados = [
        for (final id in idsAgora)
          if (!_vistos.contains(id)) id,
      ];
      _vistos.addAll(idsAgora);
    }
  }

  void _retomar(ChamadoRemoto chamado) {
    _ativo = chamado;
    _status = _statusDeRemote(chamado.status);
    if (chamado.status == 'em_andamento') {
      _tela = TelaHome.execucao;
      _inicioPoda ??= DateTime.now();
      _iniciarCronometro();
    } else {
      _tela = TelaHome.rota;
    }
  }

  Future<void> _empurrar({
    required String status,
    double? alturaFinal,
    String? foto,
  }) async {
    final id = _ativo?.id;
    if (id == null) return;
    try {
      await _sync.atualizar(
        id: id,
        status: status,
        alturaFinal: alturaFinal,
        foto: foto,
      );
      _conectado = true;
      _erroSync = null;
    } catch (_) {
      _conectado = false;
      _erroSync = 'Não foi possível enviar o status ao dashboard.';
    }
  }

  /// Chamado aceito: começa o deslocamento.
  void aceitar([ChamadoRemoto? chamado]) {
    final alvo = chamado ?? (_disponiveis.isNotEmpty ? _disponiveis.first : null);
    if (alvo == null) return;

    _ativo = alvo.copiarCom(status: 'confirmada');
    _aceitoEm = DateTime.now();
    _status = StatusPoda.emRota;
    _tela = TelaHome.rota;
    _disponiveis = [
      for (final item in _disponiveis)
        if (item.id != alvo.id) item,
    ];

    _registros.insert(
      0,
      RegistroServico(
        id: DateTime.now().microsecondsSinceEpoch,
        status: StatusPoda.emRota,
        inicio: _aceitoEm!,
        rodovia: alvo.solicitacao.rodovia,
        km: alvo.solicitacao.km,
        equipe: alvo.equipe.replaceFirst(RegExp(r'^Equipe\s+', caseSensitive: false), ''),
      ),
    );
    notifyListeners();
    unawaited(_empurrar(status: _remoteDeStatus(StatusPoda.emRota)));
  }

  /// Equipe chegou ao local: começa a poda e o cronômetro.
  void iniciarPoda() {
    _inicioPoda = DateTime.now();
    _decorrido = Duration.zero;
    _status = StatusPoda.emProgresso;
    _tela = TelaHome.execucao;
    _ativo = _ativo?.copiarCom(status: 'em_andamento');

    _atualizarRegistroAtual((r) => r.copiarCom(status: StatusPoda.emProgresso));
    _iniciarCronometro();

    notifyListeners();
    unawaited(_empurrar(status: _remoteDeStatus(StatusPoda.emProgresso)));
  }

  /// Serviço abortado — em deslocamento ou já em execução.
  void cancelar() {
    _pararCronometro();
    _status = StatusPoda.interrompida;
    _tela = TelaHome.chamado;
    _ativo = _ativo?.copiarCom(status: 'interrompida');

    _atualizarRegistroAtual(
      (r) => r.copiarCom(
        status: StatusPoda.interrompida,
        fim: DateTime.now(),
        duracao: _decorrido > Duration.zero ? _decorrido : null,
      ),
    );

    unawaited(_empurrar(status: _remoteDeStatus(StatusPoda.interrompida)));

    _inicioPoda = null;
    _decorrido = Duration.zero;
    _ativo = null;
    notifyListeners();
    unawaited(_puxar());
  }

  /// Poda finalizada com foto de comprovação.
  void concluir({required String foto, required double alturaFinal}) {
    _pararCronometro();
    _status = StatusPoda.concluida;
    _tela = TelaHome.chamado;
    _ativo = _ativo?.copiarCom(status: 'concluida');

    _atualizarRegistroAtual(
      (r) => r.copiarCom(
        status: StatusPoda.concluida,
        fim: DateTime.now(),
        duracao: _decorrido,
        alturaFinal: alturaFinal,
        foto: foto,
      ),
    );

    unawaited(
      _empurrar(
        status: _remoteDeStatus(StatusPoda.concluida),
        alturaFinal: alturaFinal,
        foto: foto,
      ),
    );

    _inicioPoda = null;
    _decorrido = Duration.zero;
    _ativo = null;
    notifyListeners();
    unawaited(_puxar());
  }

  void _iniciarCronometro() {
    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_inicioPoda == null) return;
      _decorrido = DateTime.now().difference(_inicioPoda!);
      notifyListeners();
    });
  }

  /// Aplica uma alteração no registro mais recente (o que está em andamento).
  void _atualizarRegistroAtual(
    RegistroServico Function(RegistroServico) mudanca,
  ) {
    if (_registros.isEmpty) return;
    _registros[0] = mudanca(_registros[0]);
  }

  void _pararCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _pararCronometro();
    super.dispose();
  }
}

/// Um serviço registrado — aparece no histórico com a cor do status.
class RegistroServico {
  const RegistroServico({
    required this.id,
    required this.status,
    required this.inicio,
    required this.rodovia,
    required this.km,
    required this.equipe,
    this.fim,
    this.duracao,
    this.alturaFinal,
    this.foto,
  });

  final int id;
  final StatusPoda status;
  final DateTime inicio;
  final String rodovia;
  final double km;
  final String equipe;

  final DateTime? fim;
  final Duration? duracao;
  final double? alturaFinal;
  final String? foto;

  RegistroServico copiarCom({
    StatusPoda? status,
    DateTime? fim,
    Duration? duracao,
    double? alturaFinal,
    String? foto,
  }) {
    return RegistroServico(
      id: id,
      status: status ?? this.status,
      inicio: inicio,
      rodovia: rodovia,
      km: km,
      equipe: equipe,
      fim: fim ?? this.fim,
      duracao: duracao ?? this.duracao,
      alturaFinal: alturaFinal ?? this.alturaFinal,
      foto: foto ?? this.foto,
    );
  }
}

/// Instância única usada pelo app.
final estadoChamado = EstadoChamado();
