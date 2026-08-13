import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';

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

/// Estado compartilhado entre a Home e o Histórico.
///
/// É um ChangeNotifier: quem quiser reagir usa ListenableBuilder.
/// Quando o app crescer, isto vira um Provider/Riverpod sem mudar a lógica.
class EstadoChamado extends ChangeNotifier {
  EstadoChamado(this.solicitacao);

  final Solicitacao solicitacao;

  TelaHome _tela = TelaHome.chamado;
  StatusPoda? _status;
  DateTime? _aceitoEm;
  DateTime? _inicioPoda;
  Duration _decorrido = Duration.zero;
  String? _fotoConclusao;
  Timer? _cronometro;

  /// Registros gerados nesta sessão. O mais recente primeiro.
  final List<RegistroServico> _registros = [];

  TelaHome get tela => _tela;
  StatusPoda? get status => _status;
  Duration get decorrido => _decorrido;
  DateTime? get inicioPoda => _inicioPoda;
  List<RegistroServico> get registros => List.unmodifiable(_registros);

  /// Quantas vezes este chamado já foi aceito. Útil no histórico.
  int get tentativas => _registros.length;

  // --- transições -----------------------------------------------------------

  /// Chamado aceito: começa o deslocamento.
  void aceitar() {
    _aceitoEm = DateTime.now();
    _status = StatusPoda.emRota;
    _tela = TelaHome.rota;

    _registros.insert(
      0,
      RegistroServico(
        id: DateTime.now().microsecondsSinceEpoch,
        status: StatusPoda.emRota,
        inicio: _aceitoEm!,
        rodovia: solicitacao.rodovia,
        km: solicitacao.km,
        equipe: equipeDelta.nome,
      ),
    );
    notifyListeners();
  }

  /// Equipe chegou ao local: começa a poda e o cronômetro.
  void iniciarPoda() {
    _inicioPoda = DateTime.now();
    _decorrido = Duration.zero;
    _status = StatusPoda.emProgresso;
    _tela = TelaHome.execucao;

    _atualizarRegistroAtual((r) => r.copiarCom(status: StatusPoda.emProgresso));

    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      _decorrido = DateTime.now().difference(_inicioPoda!);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Serviço abortado — em deslocamento ou já em execução.
  void cancelar() {
    _pararCronometro();
    _status = StatusPoda.interrompida;
    _tela = TelaHome.chamado;

    _atualizarRegistroAtual(
      (r) => r.copiarCom(
        status: StatusPoda.interrompida,
        fim: DateTime.now(),
        duracao: _decorrido > Duration.zero ? _decorrido : null,
      ),
    );

    _inicioPoda = null;
    _decorrido = Duration.zero;
    notifyListeners();
  }

  /// Poda finalizada com foto de comprovação.
  void concluir({required String foto, required double alturaFinal}) {
    _pararCronometro();
    _fotoConclusao = foto;
    _status = StatusPoda.concluida;
    _tela = TelaHome.chamado;

    _atualizarRegistroAtual(
      (r) => r.copiarCom(
        status: StatusPoda.concluida,
        fim: DateTime.now(),
        duracao: _decorrido,
        alturaFinal: alturaFinal,
        foto: foto,
      ),
    );

    _inicioPoda = null;
    _decorrido = Duration.zero;
    notifyListeners();
  }

  // --- internos -------------------------------------------------------------

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
/// Global por simplicidade nesta fase; vira Provider quando houver login,
/// múltiplos chamados ou sincronização com servidor.
final estadoChamado = EstadoChamado(solicitacaoAtual);
