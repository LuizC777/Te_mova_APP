import 'package:flutter/material.dart';

import '../estado/estado_chamado.dart';
import '../models.dart';
import '../widgets/mapa_area.dart';

class ExecucaoPage extends StatelessWidget {
  const ExecucaoPage({super.key, required this.estado});

  final EstadoChamado estado;

  Future<void> _cancelar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15111D),
        title: const Text('Interromper a poda?'),
        content: const Text(
          'O serviço vai constar como interrompido no histórico. '
          'O chamado volta para a lista de disponíveis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar podando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5C5C),
            ),
            child: const Text('Interromper'),
          ),
        ],
      ),
    );
    if (confirmar == true) estado.cancelar();
  }

  Future<void> _concluir(BuildContext context) async {
    final resultado = await showModalBottomSheet<_Conclusao>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FolhaConclusao(),
    );

    if (resultado != null) {
      estado.concluir(
        foto: resultado.caminhoFoto,
        alturaFinal: resultado.alturaFinal,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FaixaStatus(decorrido: estado.decorrido),
        Expanded(
          child: MapaArea(
            area: areaMockada,
            posicaoEquipe: areaMockada.eixo.first,
          ),
        ),
        _PainelExecucao(
          estado: estado,
          onCancelar: () => _cancelar(context),
          onConcluir: () => _concluir(context),
        ),
      ],
    );
  }
}

/// Faixa superior: "Poda em progresso" + cronômetro.
class _FaixaStatus extends StatelessWidget {
  const _FaixaStatus({required this.decorrido});

  final Duration decorrido;

  String get _cronometro {
    final h = decorrido.inHours;
    final m = decorrido.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = decorrido.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const amarelo = Color(0xFFFBBF24);

    return Container(
      width: double.infinity,
      color: amarelo.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          const _PontoPulsante(cor: amarelo),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Poda em progresso',
              style: TextStyle(
                color: amarelo,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _cronometro,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bolinha que pisca devagar, sinalizando serviço ativo.
class _PontoPulsante extends StatefulWidget {
  const _PontoPulsante({required this.cor});

  final Color cor;

  @override
  State<_PontoPulsante> createState() => _PontoPulsanteState();
}

class _PontoPulsanteState extends State<_PontoPulsante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respeita quem desativou animações no sistema.
    final reduzir = MediaQuery.of(context).disableAnimations;

    return FadeTransition(
      opacity: reduzir
          ? const AlwaysStoppedAnimation(1.0)
          : Tween(begin: 0.35, end: 1.0).animate(_controle),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.cor, shape: BoxShape.circle),
      ),
    );
  }
}

class _PainelExecucao extends StatelessWidget {
  const _PainelExecucao({
    required this.estado,
    required this.onCancelar,
    required this.onConcluir,
  });

  final EstadoChamado estado;
  final VoidCallback onCancelar;
  final VoidCallback onConcluir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = estado.solicitacao;
    final inicio = estado.inicioPoda;

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
                      '${s.rodovia} · km ${kmFormatado(s.km)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inicio == null
                          ? s.sentido
                          : 'Início às ${horaMinuto(inicio)} · ${s.sentido}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Equipe ${equipeDelta.nome}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onCancelar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5C5C),
                      side: BorderSide(
                        color: const Color(0xFFFF5C5C).withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Interromper'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onConcluir,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text(
                      'Concluir poda',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Folha de conclusão: foto + altura final
// ---------------------------------------------------------------------------

class _Conclusao {
  const _Conclusao({required this.caminhoFoto, required this.alturaFinal});

  final String caminhoFoto;
  final double alturaFinal;
}

class _FolhaConclusao extends StatefulWidget {
  const _FolhaConclusao();

  @override
  State<_FolhaConclusao> createState() => _FolhaConclusaoState();
}

class _FolhaConclusaoState extends State<_FolhaConclusao> {
  String? _foto;
  double _altura = 4.5;
  bool _capturando = false;

  /// Simula a captura de foto.
  ///
  /// Na versão real: `image_picker` com `ImageSource.camera`, salvando
  /// o arquivo e enviando junto com o registro do serviço.
  Future<void> _tirarFoto() async {
    setState(() => _capturando = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _capturando = false;
      _foto = 'foto_simulada_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final podeConcluir = _foto != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF15111D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Confirmar conclusão',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'A foto do trecho roçado comprova o serviço.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5),
          ),

          const SizedBox(height: 18),
          _AreaFoto(
            foto: _foto,
            capturando: _capturando,
            onTirar: _tirarFoto,
            onRefazer: () => setState(() => _foto = null),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Altura da grama após a poda',
                style: TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${_altura.toStringAsFixed(1).replaceAll('.', ',')} cm',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _altura,
            min: 3,
            max: 8,
            divisions: 10,
            activeColor: scheme.primary,
            label: '${_altura.toStringAsFixed(1)} cm',
            onChanged: (v) => setState(() => _altura = v),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: podeConcluir
                  ? () => Navigator.pop(
                      context,
                      _Conclusao(caminhoFoto: _foto!, alturaFinal: _altura),
                    )
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                podeConcluir ? 'Concluir poda' : 'Tire a foto para concluir',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaFoto extends StatelessWidget {
  const _AreaFoto({
    required this.foto,
    required this.capturando,
    required this.onTirar,
    required this.onRefazer,
  });

  final String? foto;
  final bool capturando;
  final VoidCallback onTirar;
  final VoidCallback onRefazer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (foto != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF1D2A1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
          ),
        ),
        child: Stack(
          children: [
            // Placeholder no lugar da imagem capturada.
            const Center(
              child: Icon(Icons.grass, size: 46, color: Color(0xFF4ADE80)),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF4ADE80),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Foto registrada',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: TextButton.icon(
                onPressed: onRefazer,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Refazer', style: TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: capturando ? null : onTirar,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: capturando
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 30,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tirar foto do trecho',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque para abrir a câmera',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
