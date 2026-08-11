import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../models.dart';

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final porMes = _agruparPorMes(historicoPodas);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final mes in porMes.entries) ...[
          // Cabeçalho do mês
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14),
            child: Row(
              children: [
                Text(
                  mesAno(mes.value.first.first.inicio).toUpperCase(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ],
            ),
          ),

          // Dias dentro do mês
          for (final podasDoDia in mes.value) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _rotuloDia(podasDoDia.first.inicio),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final poda in podasDoDia) _CardPoda(poda: poda),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

/// Agrupa as podas em: mês -> lista de dias -> lista de podas do dia.
/// Ordena do mais recente para o mais antigo.
Map<String, List<List<Poda>>> _agruparPorMes(List<Poda> podas) {
  final ordenadas = [...podas]..sort((a, b) => b.inicio.compareTo(a.inicio));

  final porDia = <String, List<Poda>>{};
  for (final poda in ordenadas) {
    final chave = '${poda.inicio.year}-${poda.inicio.month}-${poda.inicio.day}';
    porDia.putIfAbsent(chave, () => []).add(poda);
  }

  final porMes = <String, List<List<Poda>>>{};
  for (final dia in porDia.values) {
    final chave = '${dia.first.inicio.year}-${dia.first.inicio.month}';
    porMes.putIfAbsent(chave, () => []).add(dia);
  }

  return porMes;
}

String _rotuloDia(DateTime data) {
  final hoje = DateTime(
    2026,
    8,
    11,
  ); // trocar por DateTime.now() com dados reais
  final dia = DateTime(data.year, data.month, data.day);
  final diferenca = hoje.difference(dia).inDays;

  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';
  return diaSemana(data);
}

class _CardPoda extends StatelessWidget {
  const _CardPoda({required this.poda});

  final Poda poda;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 19,
              color: Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${poda.rodovia} · km ${kmFormatado(poda.km)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${horaMinuto(poda.inicio)}–${horaMinuto(poda.fim)}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Etiqueta(
                      icone: Icons.grass,
                      texto: '${kmFormatado(poda.alturaFinal)} cm',
                      destaque: true,
                    ),
                    _Etiqueta(icone: Icons.groups_outlined, texto: poda.equipe),
                    _Etiqueta(
                      icone: Icons.timer_outlined,
                      texto: duracaoLegivel(poda.duracao),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icone,
    required this.texto,
    this.destaque = false,
  });

  final IconData icone;
  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = destaque ? const Color(0xFF4ADE80) : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
