import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../models/rota.dart';
import '../servicos/servico_rota.dart';
import '../widgets/mapa_mock.dart';

class RotaPage extends StatefulWidget {
  const RotaPage({
    super.key,
    required this.solicitacao,
    required this.onChegou,
    required this.onCancelar,
    this.servico = const ServicoRotaMock(),
  });

  final Solicitacao solicitacao;

  /// Equipe chegou ao local: começa a poda.
  final VoidCallback onChegou;

  /// Deslocamento abortado: o serviço vira interrompido.
  final VoidCallback onCancelar;

  /// Injetado para permitir trocar o mock pelo serviço real sem tocar na tela.
  final ServicoRota servico;

  @override
  State<RotaPage> createState() => _RotaPageState();
}

class _RotaPageState extends State<RotaPage> {
  Rota? _rota;
  PosicaoNavegacao? _posicao;
  StreamSubscription<PosicaoNavegacao>? _inscricao;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final rota = await widget.servico.calcularRota(
        origem: rotaMockada.origem,
        destino: rotaMockada.destino,
      );
      if (!mounted) return;

      setState(() => _rota = rota);

      _inscricao = widget.servico
          .acompanhar(rota)
          .listen(
            (posicao) => setState(() => _posicao = posicao),
            onError: (e) => setState(() => _erro = e.toString()),
          );
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível calcular a rota.');
    }
  }

  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15111D),
        title: const Text('Encerrar deslocamento?'),
        content: const Text(
          'O serviço vai constar como interrompido no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (sair == true) widget.onCancelar();
  }

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return _Aviso(
        icone: Icons.wifi_off,
        titulo: 'Rota indisponível',
        descricao: _erro!,
        acao: TextButton(
          onPressed: () {
            setState(() => _erro = null);
            _iniciar();
          },
          child: const Text('Tentar de novo'),
        ),
      );
    }

    final rota = _rota;
    if (rota == null) {
      return const _Aviso(
        icone: Icons.route_outlined,
        titulo: 'Calculando rota',
        descricao: 'Traçando o caminho até o local do serviço.',
        carregando: true,
      );
    }

    final posicao = _posicao;

    return Column(
      children: [
        _FaixaInstrucao(
          passo: posicao?.passoAtual ?? rota.passos.first,
          distancia: posicao?.distanciaRestante ?? rota.distanciaTotal,
        ),
        Expanded(
          child: MapaMock(
            rota: rota,
            posicaoAtual: posicao?.posicaoAtual ?? rota.origem,
            progresso: posicao?.progresso ?? 0,
          ),
        ),
        _PainelInferior(
          rota: rota,
          posicao: posicao,
          solicitacao: widget.solicitacao,
          onCancelar: _confirmarSaida,
          onChegou: widget.onChegou,
        ),
      ],
    );
  }
}

/// Faixa superior com a próxima manobra, no estilo dos apps de navegação.
class _FaixaInstrucao extends StatelessWidget {
  const _FaixaInstrucao({required this.passo, required this.distancia});

  final PassoRota passo;
  final double distancia;

  IconData get _icone => switch (passo.manobra) {
    Manobra.seguirReto => Icons.straight,
    Manobra.viraEsquerda => Icons.turn_left,
    Manobra.viraDireita => Icons.turn_right,
    Manobra.retorno => Icons.u_turn_left,
    Manobra.chegada => Icons.place,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.primary,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          Icon(_icone, color: Colors.white, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distanciaLegivel(distancia),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  passo.instrucao,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel com destino, tempo restante e o botão de encerrar.
class _PainelInferior extends StatelessWidget {
  const _PainelInferior({
    required this.rota,
    required this.posicao,
    required this.solicitacao,
    required this.onCancelar,
    required this.onChegou,
  });

  final Rota rota;
  final PosicaoNavegacao? posicao;
  final Solicitacao solicitacao;
  final VoidCallback onCancelar;
  final VoidCallback onChegou;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final restante = posicao?.tempoRestante ?? rota.duracaoEstimada;
    final chegou = posicao?.chegou ?? false;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF15111D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rota.rodovia} · km ${kmFormatado(rota.km)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      solicitacao.sentido,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _ChipUrgenciaCompacto(urgencia: solicitacao.urgencia),
            ],
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              _Metrica(
                valor: chegou ? '—' : tempoLegivel(restante),
                rotulo: 'restante',
              ),
              _divisor(),
              _Metrica(
                valor: distanciaLegivel(
                  posicao?.distanciaRestante ?? rota.distanciaTotal,
                ),
                rotulo: 'distância',
              ),
              _divisor(),
              _Metrica(
                valor: chegou
                    ? 'no local'
                    : chegadaPrevista(restante, DateTime.now()),
                rotulo: 'chegada',
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: chegou
                ? FilledButton.icon(
                    onPressed: onChegou,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text(
                      'Cheguei — iniciar poda',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onCancelar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Encerrar deslocamento'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _divisor() => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: 0.08),
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipUrgenciaCompacto extends StatelessWidget {
  const _ChipUrgenciaCompacto({required this.urgencia});

  final Urgencia urgencia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: urgencia.cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        urgencia.label,
        style: TextStyle(
          color: urgencia.cor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Estado de carregamento ou erro, ocupando a tela toda.
class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.carregando = false,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool carregando;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (carregando)
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              )
            else
              Icon(icone, size: 34, color: scheme.onSurfaceVariant),
            const SizedBox(height: 18),
            Text(
              titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5),
            ),
            if (acao != null) ...[const SizedBox(height: 10), acao!],
          ],
        ),
      ),
    );
  }
}
