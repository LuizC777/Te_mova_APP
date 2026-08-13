import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/rota.dart';

/// Mapa de mentira, desenhado à mão.
///
/// Recebe exatamente os mesmos dados que um mapa real receberia
/// (uma polilinha em lat/lng e uma posição atual), então trocar isto
/// por um GoogleMap é substituir só este widget.
class MapaMock extends StatelessWidget {
  const MapaMock({
    super.key,
    required this.rota,
    required this.posicaoAtual,
    required this.progresso,
  });

  final Rota rota;
  final PontoGeo posicaoAtual;
  final double progresso;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PintorMapa(
            rota: rota,
            posicaoAtual: posicaoAtual,
            progresso: progresso,
            corRota: cor,
          ),
        ),
        // Aviso de que não é mapa de verdade — remover na integração.
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

class _PintorMapa extends CustomPainter {
  _PintorMapa({
    required this.rota,
    required this.posicaoAtual,
    required this.progresso,
    required this.corRota,
  });

  final Rota rota;
  final PontoGeo posicaoAtual;
  final double progresso;
  final Color corRota;

  @override
  void paint(Canvas canvas, Size size) {
    _fundo(canvas, size);
    _grade(canvas, size);

    final projetar = _criarProjecao(rota.trajeto, size);
    final pontos = rota.trajeto.map(projetar).toList();

    _tracado(canvas, pontos);
    _marcadorDestino(canvas, pontos.last);
    _marcadorVeiculo(canvas, projetar(posicaoAtual), pontos);
  }

  // --- camadas de desenho ---------------------------------------------------

  void _fundo(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF161320),
    );
  }

  /// Malha viária genérica ao fundo, só para dar sensação de mapa.
  void _grade(Canvas canvas, Size size) {
    final linha = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linha);
    }
    for (var y = 0.0; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linha);
    }

    // Duas vias mais largas cortando o fundo.
    final via = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height),
      Offset(size.width * 0.62, 0),
      via,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.28),
      Offset(size.width, size.height * 0.52),
      via,
    );
  }

  void _tracado(Canvas canvas, List<Offset> pontos) {
    final caminho = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (final p in pontos.skip(1)) {
      caminho.lineTo(p.dx, p.dy);
    }

    // Contorno escuro, para a rota destacar do fundo.
    canvas.drawPath(
      caminho,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      caminho,
      Paint()
        ..color = corRota
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _marcadorDestino(Canvas canvas, Offset centro) {
    canvas.drawCircle(
      centro,
      13,
      Paint()..color = const Color(0xFFFF5C5C).withValues(alpha: 0.22),
    );
    canvas.drawCircle(centro, 7, Paint()..color = const Color(0xFFFF5C5C));
    canvas.drawCircle(
      centro,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _marcadorVeiculo(Canvas canvas, Offset centro, List<Offset> pontos) {
    // Halo de precisão, como o círculo azul do GPS.
    canvas.drawCircle(
      centro,
      20,
      Paint()..color = corRota.withValues(alpha: 0.16),
    );

    canvas.drawCircle(centro, 9, Paint()..color = Colors.white);
    canvas.drawCircle(centro, 6.5, Paint()..color = corRota);

    // Seta indicando o rumo do deslocamento.
    final rumo = _rumoEm(pontos, progresso);
    final ponta = Offset(
      centro.dx + math.cos(rumo) * 17,
      centro.dy + math.sin(rumo) * 17,
    );
    canvas.drawLine(
      centro,
      ponta,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  // --- geometria ------------------------------------------------------------

  /// Converte lat/lng em coordenada de tela, enquadrando todo o trajeto.
  Offset Function(PontoGeo) _criarProjecao(List<PontoGeo> trajeto, Size size) {
    const margem = 44.0;

    var minLat = trajeto.first.lat, maxLat = trajeto.first.lat;
    var minLng = trajeto.first.lng, maxLng = trajeto.first.lng;

    for (final p in trajeto) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    final larguraGeo = math.max(maxLng - minLng, 1e-9);
    final alturaGeo = math.max(maxLat - minLat, 1e-9);
    final larguraTela = size.width - margem * 2;
    final alturaTela = size.height - margem * 2;

    // Escala única nos dois eixos, para o traçado não ficar deformado.
    final escala = math.min(larguraTela / larguraGeo, alturaTela / alturaGeo);
    final sobraX = (size.width - larguraGeo * escala) / 2;
    final sobraY = (size.height - alturaGeo * escala) / 2;

    return (PontoGeo p) => Offset(
      (p.lng - minLng) * escala + sobraX,
      // Latitude cresce para o norte, y cresce para baixo: inverte.
      (maxLat - p.lat) * escala + sobraY,
    );
  }

  double _rumoEm(List<Offset> pontos, double progresso) {
    final posicao = (progresso * (pontos.length - 1)).clamp(
      0.0,
      pontos.length - 1.001,
    );
    final i = posicao.floor();
    final delta = pontos[i + 1] - pontos[i];
    return math.atan2(delta.dy, delta.dx);
  }

  @override
  bool shouldRepaint(_PintorMapa anterior) =>
      anterior.progresso != progresso || anterior.corRota != corRota;
}
