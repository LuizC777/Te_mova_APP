import 'dart:async';

import '../models/rota.dart';

/// Contrato do serviço de rotas.
///
/// A tela de navegação só conhece esta interface. Quando o backend real
/// entrar, escreva um `ServicoRotaApi implements ServicoRota` e troque a
/// instância — nenhuma tela precisa mudar.
abstract class ServicoRota {
  /// Calcula a rota da posição atual até o destino.
  Future<Rota> calcularRota({
    required PontoGeo origem,
    required PontoGeo destino,
  });

  /// Emite a posição da equipe enquanto ela se desloca.
  /// Na versão real isso vem do GPS do aparelho.
  Stream<PosicaoNavegacao> acompanhar(Rota rota);
}

// ---------------------------------------------------------------------------
// Implementação mockada
// ---------------------------------------------------------------------------

/// Simula o deslocamento percorrendo o trajeto em [duracaoSimulada].
class ServicoRotaMock implements ServicoRota {
  const ServicoRotaMock({this.duracaoSimulada = const Duration(seconds: 90)});

  /// Quanto tempo o percurso inteiro leva na simulação.
  final Duration duracaoSimulada;

  @override
  Future<Rota> calcularRota({
    required PontoGeo origem,
    required PontoGeo destino,
  }) async {
    // Simula a latência de uma chamada de rede.
    await Future.delayed(const Duration(milliseconds: 700));
    return rotaMockada;
  }

  @override
  Stream<PosicaoNavegacao> acompanhar(Rota rota) async* {
    const intervalo = Duration(milliseconds: 500);
    final totalTicks =
        duracaoSimulada.inMilliseconds ~/ intervalo.inMilliseconds;
    final distanciaTotal = rota.distanciaTotal;

    for (var tick = 0; tick <= totalTicks; tick++) {
      final progresso = (tick / totalTicks).clamp(0.0, 1.0);

      yield PosicaoNavegacao(
        posicaoAtual: _pontoNoTrajeto(rota.trajeto, progresso),
        progresso: progresso,
        distanciaRestante: distanciaTotal * (1 - progresso),
        tempoRestante: rota.duracaoEstimada * (1 - progresso),
        passoAtual: _passoEm(rota, progresso),
      );

      if (progresso >= 1.0) return;
      await Future.delayed(intervalo);
    }
  }

  /// Interpola a posição ao longo da polilinha.
  /// Com GPS real isso é substituído pela leitura do sensor.
  PontoGeo _pontoNoTrajeto(List<PontoGeo> trajeto, double progresso) {
    if (progresso <= 0) return trajeto.first;
    if (progresso >= 1) return trajeto.last;

    final posicao = progresso * (trajeto.length - 1);
    final indice = posicao.floor();
    final fracao = posicao - indice;

    final a = trajeto[indice];
    final b = trajeto[indice + 1];

    return PontoGeo(
      a.lat + (b.lat - a.lat) * fracao,
      a.lng + (b.lng - a.lng) * fracao,
    );
  }

  /// Escolhe a instrução vigente conforme a fração já percorrida.
  PassoRota _passoEm(Rota rota, double progresso) {
    final restante = rota.distanciaTotal * (1 - progresso);
    var acumulado = 0.0;

    for (final passo in rota.passos.reversed) {
      acumulado += passo.distanciaMetros;
      if (restante <= acumulado) return passo;
    }
    return rota.passos.first;
  }
}

// ---------------------------------------------------------------------------
// Dados mockados — coordenadas aproximadas da SP-270
// ---------------------------------------------------------------------------

const _base = PontoGeo(-23.5641, -47.3892);
const _destino = PontoGeo(-23.5489, -47.4310);

final rotaMockada = Rota(
  origem: _base,
  destino: _destino,
  rodovia: 'SP-270',
  km: 142.3,
  duracaoEstimada: const Duration(minutes: 14),
  trajeto: const [
    PontoGeo(-23.5641, -47.3892),
    PontoGeo(-23.5628, -47.3931),
    PontoGeo(-23.5602, -47.3968),
    PontoGeo(-23.5589, -47.4021),
    PontoGeo(-23.5571, -47.4074),
    PontoGeo(-23.5548, -47.4118),
    PontoGeo(-23.5531, -47.4165),
    PontoGeo(-23.5512, -47.4214),
    PontoGeo(-23.5498, -47.4268),
    PontoGeo(-23.5489, -47.4310),
  ],
  passos: const [
    PassoRota(
      manobra: Manobra.seguirReto,
      instrucao: 'Siga pela via de acesso até a SP-270',
      distanciaMetros: 850,
    ),
    PassoRota(
      manobra: Manobra.viraDireita,
      instrucao: 'Entre à direita na SP-270, sentido oeste',
      distanciaMetros: 3200,
    ),
    PassoRota(
      manobra: Manobra.seguirReto,
      instrucao: 'Siga na faixa da direita até o km 142',
      distanciaMetros: 1100,
    ),
    PassoRota(
      manobra: Manobra.chegada,
      instrucao: 'Encoste no acostamento — local do serviço',
      distanciaMetros: 300,
    ),
  ],
);
