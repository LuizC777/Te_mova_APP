import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../estado/estado_chamado.dart';
import '../models.dart';

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reconstrói quando um chamado é aceito, interrompido ou concluído.
    return ListenableBuilder(
      listenable: estadoChamado,
      builder: (context, _) {
        final registros = [...estadoChamado.registros, ..._historicoConvertido]
          ..sort((a, b) => b.inicio.compareTo(a.inicio));

        return _Linha(registros: registros);
      },
    );
  }
}

/// As podas mockadas viram RegistroServico para caber na mesma lista.
List<RegistroServico> get _historicoConvertido => [
  for (final (i, poda) in historicoPodas.indexed)
    RegistroServico(
      id: -(i + 1), // negativo: não colide com os registros ao vivo
      status: StatusPoda.concluida,
      inicio: poda.inicio,
      fim: poda.fim,
      duracao: poda.duracao,
      alturaFinal: poda.alturaFinal,
      rodovia: poda.rodovia,
      km: poda.km,
      equipe: poda.equipe,
    ),
];

class _Linha extends StatelessWidget {
  const _Linha({required this.registros});

  final List<RegistroServico> registros;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final porMes = _agruparPorMes(registros);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final mes in porMes.entries) ...[
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
          for (final dia in mes.value) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _rotuloDia(dia.first.inicio),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final registro in dia) _CardRegistro(registro: registro),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

/// Agrupa em: mês -> dias -> registros do dia, do mais recente ao mais antigo.
Map<String, List<List<RegistroServico>>> _agruparPorMes(
  List<RegistroServico> registros,
) {
  final porDia = <String, List<RegistroServico>>{};
  for (final r in registros) {
    final chave = '${r.inicio.year}-${r.inicio.month}-${r.inicio.day}';
    porDia.putIfAbsent(chave, () => []).add(r);
  }

  final porMes = <String, List<List<RegistroServico>>>{};
  for (final dia in porDia.values) {
    final chave = '${dia.first.inicio.year}-${dia.first.inicio.month}';
    porMes.putIfAbsent(chave, () => []).add(dia);
  }
  return porMes;
}

String _rotuloDia(DateTime data) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(data.year, data.month, data.day);
  final diferenca = hoje.difference(dia).inDays;

  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';
  return diaSemana(data);
}

// ---------------------------------------------------------------------------
// Aparência por status
// ---------------------------------------------------------------------------

({Color cor, IconData icone}) _visualDe(StatusPoda status) => switch (status) {
  StatusPoda.concluida => (
    cor: const Color(0xFF4ADE80),
    icone: Icons.check_rounded,
  ),
  StatusPoda.emProgresso => (cor: const Color(0xFFFBBF24), icone: Icons.grass),
  StatusPoda.emRota => (
    cor: const Color(0xFFFBBF24),
    icone: Icons.navigation_outlined,
  ),
  StatusPoda.interrompida => (
    cor: const Color(0xFFFF5C5C),
    icone: Icons.close_rounded,
  ),
};

class _CardRegistro extends StatelessWidget {
  const _CardRegistro({required this.registro});

  final RegistroServico registro;

  bool get _ativo =>
      registro.status == StatusPoda.emRota ||
      registro.status == StatusPoda.emProgresso;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = _visualDe(registro.status);
    final r = registro;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ativo
              ? visual.cor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: visual.cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(visual.icone, size: 19, color: visual.cor),
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
                        '${r.rodovia} · km ${kmFormatado(r.km)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      r.fim == null
                          ? 'desde ${horaMinuto(r.inicio)}'
                          : '${horaMinuto(r.inicio)}–${horaMinuto(r.fim!)}',
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
                      icone: visual.icone,
                      texto: r.status.rotulo,
                      cor: visual.cor,
                      destaque: true,
                    ),
                    if (r.alturaFinal != null)
                      _Etiqueta(
                        icone: Icons.grass,
                        texto: '${kmFormatado(r.alturaFinal!)} cm',
                      ),
                    _Etiqueta(icone: Icons.groups_outlined, texto: r.equipe),
                    if (r.duracao != null)
                      _Etiqueta(
                        icone: Icons.timer_outlined,
                        texto: duracaoLegivel(r.duracao!),
                      ),
                    if (r.foto != null)
                      const _Etiqueta(
                        icone: Icons.photo_camera_outlined,
                        texto: 'com foto',
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
    this.cor,
    this.destaque = false,
  });

  final IconData icone;
  final String texto;
  final Color? cor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final tinta = cor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: destaque
            ? tinta.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: tinta),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: tinta,
              fontSize: 12,
              fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
