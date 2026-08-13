import 'dart:math' as math;

/// Um ponto no mundo real. Mesma forma do LatLng do google_maps_flutter,
/// então a troca depois é direta.
class PontoGeo {
  const PontoGeo(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Distância em metros até outro ponto (fórmula de Haversine).
  /// Esse cálculo é real e continua valendo com dados de GPS.
  double distanciaPara(PontoGeo outro) {
    const raioTerra = 6371000.0;
    final dLat = _rad(outro.lat - lat);
    final dLng = _rad(outro.lng - lng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(outro.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return raioTerra * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double graus) => graus * math.pi / 180;

  @override
  String toString() => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

/// Tipo de manobra de uma instrução de navegação.
enum Manobra { seguirReto, viraEsquerda, viraDireita, retorno, chegada }

class PassoRota {
  const PassoRota({
    required this.manobra,
    required this.instrucao,
    required this.distanciaMetros,
  });

  final Manobra manobra;
  final String instrucao;
  final double distanciaMetros;
}

/// Uma rota calculada da posição atual até o local do serviço.
class Rota {
  const Rota({
    required this.origem,
    required this.destino,
    required this.trajeto,
    required this.passos,
    required this.duracaoEstimada,
    required this.rodovia,
    required this.km,
  });

  final PontoGeo origem;
  final PontoGeo destino;

  /// Polilinha do caminho. Vem pronta da API de rotas.
  final List<PontoGeo> trajeto;

  final List<PassoRota> passos;
  final Duration duracaoEstimada;
  final String rodovia;
  final double km;

  /// Comprimento total do trajeto em metros.
  double get distanciaTotal {
    var total = 0.0;
    for (var i = 0; i < trajeto.length - 1; i++) {
      total += trajeto[i].distanciaPara(trajeto[i + 1]);
    }
    return total;
  }
}

/// Estado da navegação num instante. É isso que o app recebe
/// repetidamente enquanto a equipe se desloca.
class PosicaoNavegacao {
  const PosicaoNavegacao({
    required this.posicaoAtual,
    required this.progresso,
    required this.distanciaRestante,
    required this.tempoRestante,
    required this.passoAtual,
  });

  final PontoGeo posicaoAtual;

  /// 0.0 no início do trajeto, 1.0 na chegada.
  final double progresso;

  final double distanciaRestante;
  final Duration tempoRestante;
  final PassoRota passoAtual;

  bool get chegou => progresso >= 1.0;
}

// ---------------------------------------------------------------------------
// Formatação
// ---------------------------------------------------------------------------

/// 1250 -> "1,2 km"  |  380 -> "380 m"
String distanciaLegivel(double metros) {
  if (metros >= 1000) {
    return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }
  return '${metros.round()} m';
}

/// Duration -> "12 min"
String tempoLegivel(Duration d) {
  if (d.inMinutes < 1) return 'menos de 1 min';
  if (d.inHours == 0) return '${d.inMinutes} min';
  return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
}

/// Horário de chegada previsto a partir de agora.
String chegadaPrevista(Duration restante, DateTime agora) {
  final chegada = agora.add(restante);
  return '${chegada.hour.toString().padLeft(2, '0')}:'
      '${chegada.minute.toString().padLeft(2, '0')}';
}
