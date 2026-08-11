import 'package:flutter/material.dart';

import '../models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _aceito = false;

  void _aceitarChamado() {
    setState(() => _aceito = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Chamado aceito — ${solicitacaoAtual.rodovia}, '
            'km ${kmFormatado(solicitacaoAtual.km)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chamado disponível',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Equipe ${equipeDelta.nome}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CardSolicitacao(
          solicitacao: solicitacaoAtual,
          aceito: _aceito,
          onAceitar: _aceitarChamado,
        ),
      ],
    );
  }
}

class _CardSolicitacao extends StatelessWidget {
  const _CardSolicitacao({
    required this.solicitacao,
    required this.aceito,
    required this.onAceitar,
  });

  final Solicitacao solicitacao;
  final bool aceito;
  final VoidCallback onAceitar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = solicitacao;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faixa superior: urgência + horário da solicitação
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                _ChipUrgencia(urgencia: s.urgencia),
                const Spacer(),
                Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Solicitado às ${horaMinuto(s.solicitadoEm)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Localização
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.rodovia,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'km ${kmFormatado(s.km)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.sentido,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _MedidorAltura(solicitacao: s),

          // Botão
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: aceito
                  ? FilledButton.tonalIcon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Chamado aceito'),
                    )
                  : FilledButton(
                      onPressed: onAceitar,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Aceitar chamado'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipUrgencia extends StatelessWidget {
  const _ChipUrgencia({required this.urgencia});

  final Urgencia urgencia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: urgencia.cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: urgencia.cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Urgência ${urgencia.label}',
            style: TextStyle(
              color: urgencia.cor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra que mostra a altura da grama em relação ao limite permitido.
class _MedidorAltura extends StatelessWidget {
  const _MedidorAltura({required this.solicitacao});

  final Solicitacao solicitacao;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = solicitacao;
    final proximoDoLimite = s.proporcaoLimite >= 0.8;
    final cor = proximoDoLimite ? const Color(0xFFFBBF24) : scheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Altura da grama',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${kmFormatado(s.alturaGrama)} cm',
                style: TextStyle(
                  color: cor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                ' / ${kmFormatado(s.alturaLimite)} cm',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.proporcaoLimite,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(cor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            proximoDoLimite
                ? 'Próximo do limite de ${kmFormatado(s.alturaLimite)} cm'
                : 'Dentro do limite de ${kmFormatado(s.alturaLimite)} cm',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
