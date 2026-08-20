import 'package:flutter/material.dart';

import '../estado/estado_chamado.dart';
import '../models.dart';
import '../servicos/servico_sync.dart';
import 'execucao_page.dart';
import 'rota_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // ListenableBuilder reconstrói sempre que o estado do chamado muda.
    return ListenableBuilder(
      listenable: estadoChamado,
      builder: (context, _) {
        final tela = switch (estadoChamado.tela) {
          TelaHome.chamado => _ListaChamados(
            key: const ValueKey('chamados'),
            statusAnterior: estadoChamado.status,
            conectado: estadoChamado.conectado,
            erroSync: estadoChamado.erroSync,
            apiBase: estadoChamado.apiBase,
            dashUrl: estadoChamado.dashUrl,
            chamados: estadoChamado.disponiveis,
            recemChegados: estadoChamado.recemChegados,
            onAceitar: estadoChamado.aceitar,
          ),
          TelaHome.rota => RotaPage(
            key: const ValueKey('rota'),
            solicitacao: estadoChamado.solicitacao,
            onChegou: estadoChamado.iniciarPoda,
            onCancelar: estadoChamado.cancelar,
          ),
          TelaHome.execucao => ExecucaoPage(
            key: const ValueKey('execucao'),
            estado: estadoChamado,
          ),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: tela,
        );
      },
    );
  }
}

class _ListaChamados extends StatelessWidget {
  const _ListaChamados({
    super.key,
    required this.onAceitar,
    required this.chamados,
    required this.conectado,
    required this.apiBase,
    required this.dashUrl,
    this.recemChegados = const [],
    this.statusAnterior,
    this.erroSync,
  });

  final void Function([ChamadoRemoto? chamado]) onAceitar;
  final List<ChamadoRemoto> chamados;
  final List<String> recemChegados;
  final bool conectado;
  final String apiBase;
  final String dashUrl;
  final StatusPoda? statusAnterior;
  final String? erroSync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              chamados.isEmpty
                  ? 'Nenhum chamado'
                  : chamados.length == 1
                  ? 'Chamado disponível'
                  : '${chamados.length} chamados disponíveis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Comandos do dashboard',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FaixaSync(
          conectado: conectado,
          erro: erroSync,
          apiBase: apiBase,
          dashUrl: dashUrl,
        ),
        if (recemChegados.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AvisoNovoComando(quantidade: recemChegados.length),
        ],
        if (statusAnterior != null) ...[
          const SizedBox(height: 12),
          _AvisoStatusAnterior(status: statusAnterior!),
        ],
        const SizedBox(height: 12),
        if (chamados.isEmpty)
          const _VazioDashboard()
        else
          for (final chamado in chamados) ...[
            _CardSolicitacao(
              solicitacao: chamado.solicitacao,
              situacao: chamado.situacao,
              equipe: chamado.equipe,
              novo: recemChegados.contains(chamado.id),
              onAceitar: () => onAceitar(chamado),
              reaceite:
                  statusAnterior == StatusPoda.interrompida &&
                  chamado.status == 'interrompida',
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _FaixaSync extends StatelessWidget {
  const _FaixaSync({
    required this.conectado,
    required this.apiBase,
    required this.dashUrl,
    this.erro,
  });

  final bool conectado;
  final String apiBase;
  final String dashUrl;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final cor = conectado ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            conectado ? Icons.sync : Icons.sync_disabled,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              conectado
                  ? 'Sincronizado com o dashboard ($dashUrl) via $apiBase'
                  : (erro ?? 'Aguardando o dashboard em $dashUrl'),
              style: TextStyle(color: cor, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _VazioDashboard extends StatelessWidget {
  const _VazioDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inbox_outlined, color: scheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma tarefa enviada',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'No dashboard, selecione um trecho e toque em Enviar ao app da equipe. '
            'O chamado aparece aqui na hora, com a equipe, o KM e a altura prevista.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoNovoComando extends StatelessWidget {
  const _AvisoNovoComando({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    const cor = Color(0xFF5E22F3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quantidade == 1
                  ? 'Novo comando recebido do dashboard.'
                  : '$quantidade novos comandos recebidos do dashboard.',
              style: const TextStyle(color: cor, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoStatusAnterior extends StatelessWidget {
  const _AvisoStatusAnterior({required this.status});

  final StatusPoda status;

  @override
  Widget build(BuildContext context) {
    final (cor, icone, texto) = switch (status) {
      StatusPoda.interrompida => (
        const Color(0xFFFF5C5C),
        Icons.error_outline,
        'Atendimento anterior interrompido. O chamado segue aberto.',
      ),
      StatusPoda.concluida => (
        const Color(0xFF4ADE80),
        Icons.check_circle_outline,
        'Poda concluída e registrada no histórico.',
      ),
      _ => (
        const Color(0xFFFBBF24),
        Icons.info_outline,
        'Atendimento em andamento.',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: cor, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSolicitacao extends StatelessWidget {
  const _CardSolicitacao({
    required this.solicitacao,
    required this.onAceitar,
    this.situacao = '',
    this.equipe = '',
    this.novo = false,
    this.reaceite = false,
  });

  final Solicitacao solicitacao;
  final VoidCallback onAceitar;
  final String situacao;
  final String equipe;
  final bool novo;

  /// Verdadeiro quando o chamado já foi aceito e interrompido antes.
  final bool reaceite;

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
                if (novo) ...[
                  const SizedBox(width: 8),
                  _ChipNovo(),
                ],
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
                if (equipe.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    equipe,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (situacao.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    situacao,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
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
              child: FilledButton.icon(
                onPressed: onAceitar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5E22F3),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.navigation_outlined, size: 20),
                label: Text(reaceite ? 'Retomar chamado' : 'Aceitar chamado'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipNovo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5E22F3).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'NOVO',
        style: TextStyle(
          color: Color(0xFF5E22F3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
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
