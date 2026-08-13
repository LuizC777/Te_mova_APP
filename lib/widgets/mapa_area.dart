import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/rota.dart';

/// Trecho de acostamento a ser roçado.
class AreaServico {
  const AreaServico({
    required this.eixo,
    required this.larguraMetros,
    required this.kmInicial,
    required this.kmFinal,
    required this.rodovia,
  });

  /// Linha central do trecho — o eixo da pista.
  final List<PontoGeo> eixo;

  /// Faixa de acostamento a roçar, em metros a partir do eixo.
  final double larguraMetros;

  final double kmInicial;
  final double kmFinal;
  final String rodovia;

  /// Extensão do trecho em metros.
  double get extensao {
    var total = 0.0;
    for (var i = 0; i < eixo.length - 1; i++) {
      total += eixo[i].distanciaPara(eixo[i + 1]);
    }
    return total;
  }
}

/// Trecho mockado — o mesmo destino da rota.
const areaMockada = AreaServico(
  rodovia: 'SP-270',
  kmInicial: 142.3,
  kmFinal: 143.1,
  larguraMetros: 6,
  eixo: [
    PontoGeo(-23.5489, -47.4310),
    PontoGeo(-23.5481, -47.4348),
    PontoGeo(-23.5476, -47.4389),
    PontoGeo(-23.5468, -47.4427),
  ],
);

/// Mapa focado na área de trabalho: mostra o trecho a roçar e onde a
/// equipe está parada. Sem traçado de rota — o deslocamento já acabou.
///
/// Recebe dados geográficos reais, então trocar por um GoogleMap com
/// Polygon é substituir só este widget.
class MapaArea extends StatelessWidget {
  const MapaArea({
    super.key,
    required this.area,
    required this.posicaoEquipe,
    this.progresso = 0,
  });

  final AreaServico area;
  final PontoGeo posicaoEquipe;

  /// Fração do trecho já roçada, se houver como medir. 0 desativa.
  final double progresso;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PintorArea(
            area: area,
            posicaoEquipe: posicaoEquipe,
            progresso: progresso,
            corDestaque: cor,
          ),
        ),
        Positioned(top: 12, left: 12, child: _Legenda(area: area)),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'MAPA SIMULADO',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.area});

  final AreaServico area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRECHO DESIGNADO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'km ${_num(area.kmInicial)} – ${_num(area.kmFinal)}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            '${_num(area.extensao / 1000)} km · faixa de '
            '${area.larguraMetros.round()} m',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _num(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}

class _PintorArea extends CustomPainter {
  _PintorArea({
    required this.area,
    required this.posicaoEquipe,
    required this.progresso,
    required this.corDestaque,
  });

  final AreaServico area;
  final PontoGeo posicaoEquipe;
  final double progresso;
  final Color corDestaque;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF161320),
    );
    _vegetacao(canvas, size);

    final projetar = _criarProjecao(area.eixo, size);
    final eixo = area.eixo.map(projetar).toList();

    _pista(canvas, eixo);
    _faixaDeTrabalho(canvas, eixo);
    _marcosQuilometricos(canvas, eixo);
    _equipe(canvas, projetar(posicaoEquipe));
  }

  /// Textura de fundo sugerindo mato dos dois lados da pista.
  void _vegetacao(Canvas canvas, Size size) {
    final tinta = Paint()..color = const Color(0xFF1D2A1E);
    final aleatorio = math.Random(7); // semente fixa: não pisca ao repintar

    for (var i = 0; i < 90; i++) {
      final x = aleatorio.nextDouble() * size.width;
      final y = aleatorio.nextDouble() * size.height;
      final r = 6 + aleatorio.nextDouble() * 14;
      canvas.drawCircle(Offset(x, y), r, tinta);
    }
  }

  void _pista(Canvas canvas, List<Offset> eixo) {
    final caminho = _caminhoDe(eixo);

    // Asfalto
    canvas.drawPath(
      caminho,
      Paint()
        ..color = const Color(0xFF2A2A32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Faixa central tracejada
    canvas.drawPath(
      _tracejar(caminho, traco: 12, vao: 12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  /// Faixa lateral destacada: é o que a equipe tem que roçar.
  void _faixaDeTrabalho(Canvas canvas, List<Offset> eixo) {
    final caminho = _caminhoDe(eixo);
    const deslocamento = 18.0;

    // Desenha a faixa deslocada para o lado do acostamento.
    canvas.save();
    canvas.translate(0, deslocamento);

    canvas.drawPath(
      caminho,
      Paint()
        ..color = corDestaque.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      caminho,
      Paint()
        ..color = corDestaque
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  /// Marcos de início e fim do trecho.
  void _marcosQuilometricos(Canvas canvas, List<Offset> eixo) {
    _marco(canvas, eixo.first, area.kmInicial);
    _marco(canvas, eixo.last, area.kmFinal);
  }

  void _marco(Canvas canvas, Offset centro, double km) {
    canvas.drawCircle(
      centro,
      5.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      centro,
      5.5,
      Paint()
        ..color = const Color(0xFF161320)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final texto = TextPainter(
      text: TextSpan(
        text: 'km ${km.toStringAsFixed(1).replaceAll('.', ',')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final caixa = Rect.fromLTWH(
      centro.dx - texto.width / 2 - 5,
      centro.dy - 26,
      texto.width + 10,
      17,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(caixa, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    texto.paint(canvas, Offset(caixa.left + 5, caixa.top + 2.5));
  }

  void _equipe(Canvas canvas, Offset centro) {
    canvas.drawCircle(
      centro,
      19,
      Paint()..color = corDestaque.withValues(alpha: 0.18),
    );
    canvas.drawCircle(centro, 10, Paint()..color = Colors.white);
    canvas.drawCircle(centro, 7, Paint()..color = corDestaque);
  }

  // --- utilitários ----------------------------------------------------------

  Path _caminhoDe(List<Offset> pontos) {
    final caminho = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (final p in pontos.skip(1)) {
      caminho.lineTo(p.dx, p.dy);
    }
    return caminho;
  }

  /// Converte um caminho contínuo em tracejado.
  Path _tracejar(Path origem, {required double traco, required double vao}) {
    final destino = Path();
    for (final metrica in origem.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < metrica.length) {
        final fim = math.min(distancia + traco, metrica.length);
        destino.addPath(metrica.extractPath(distancia, fim), Offset.zero);
        distancia = fim + vao;
      }
    }
    return destino;
  }

  Offset Function(PontoGeo) _criarProjecao(List<PontoGeo> pontos, Size size) {
    const margem = 60.0;

    var minLat = pontos.first.lat, maxLat = pontos.first.lat;
    var minLng = pontos.first.lng, maxLng = pontos.first.lng;
    for (final p in pontos) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    final larguraGeo = math.max(maxLng - minLng, 1e-9);
    final alturaGeo = math.max(maxLat - minLat, 1e-9);
    final escala = math.min(
      (size.width - margem * 2) / larguraGeo,
      (size.height - margem * 2) / alturaGeo,
    );
    final sobraX = (size.width - larguraGeo * escala) / 2;
    final sobraY = (size.height - alturaGeo * escala) / 2;

    return (PontoGeo p) => Offset(
      (p.lng - minLng) * escala + sobraX,
      (maxLat - p.lat) * escala + sobraY,
    );
  }

  @override
  bool shouldRepaint(_PintorArea anterior) =>
      anterior.progresso != progresso ||
      anterior.corDestaque != corDestaque ||
      anterior.posicaoEquipe != posicaoEquipe;
}
