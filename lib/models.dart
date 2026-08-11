import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------

enum Urgencia { baixa, media, alta }

extension UrgenciaInfo on Urgencia {
  String get label => switch (this) {
    Urgencia.baixa => 'BAIXA',
    Urgencia.media => 'MÉDIA',
    Urgencia.alta => 'ALTA',
  };

  Color get cor => switch (this) {
    Urgencia.baixa => const Color(0xFF4ADE80),
    Urgencia.media => const Color(0xFFFBBF24),
    Urgencia.alta => const Color(0xFFFF5C5C),
  };
}

class Solicitacao {
  const Solicitacao({
    required this.solicitadoEm,
    required this.alturaGrama,
    required this.alturaLimite,
    required this.urgencia,
    required this.rodovia,
    required this.km,
    required this.sentido,
  });

  final DateTime solicitadoEm;
  final double alturaGrama;
  final double alturaLimite;
  final Urgencia urgencia;
  final String rodovia;
  final double km;
  final String sentido;

  /// Quanto da altura limite já foi atingido (0.0 a 1.0).
  double get proporcaoLimite => (alturaGrama / alturaLimite).clamp(0.0, 1.0);
}

class Operador {
  const Operador({
    required this.nome,
    required this.funcao,
    this.encarregado = false,
  });

  final String nome;
  final String funcao;
  final bool encarregado;

  /// Iniciais para o avatar, ex: "Anderson Rocha" -> "AR".
  String get iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

class Equipe {
  const Equipe({
    required this.nome,
    required this.veiculoModelo,
    required this.veiculoPlaca,
    required this.operadores,
  });

  final String nome;
  final String veiculoModelo;
  final String veiculoPlaca;
  final List<Operador> operadores;
}

class Poda {
  const Poda({
    required this.inicio,
    required this.fim,
    required this.alturaFinal,
    required this.equipe,
    required this.rodovia,
    required this.km,
  });

  final DateTime inicio;
  final DateTime fim;
  final double alturaFinal;
  final String equipe;
  final String rodovia;
  final double km;

  Duration get duracao => fim.difference(inicio);
}

// ---------------------------------------------------------------------------
// Dados mockados — trocar por chamadas de API depois
// ---------------------------------------------------------------------------

final solicitacaoAtual = Solicitacao(
  solicitadoEm: DateTime(2026, 8, 11, 7, 42),
  alturaGrama: 8,
  alturaLimite: 10,
  urgencia: Urgencia.alta,
  rodovia: 'SP-270',
  km: 142.3,
  sentido: 'Sentido oeste',
);

const equipeDelta = Equipe(
  nome: 'DELTA',
  veiculoModelo: 'Ford Ranger XL 2.2 — 2022',
  veiculoPlaca: 'RGT4B21',
  operadores: [
    Operador(
      nome: 'Anderson Rocha',
      funcao: 'Operador de roçadeira',
      encarregado: true,
    ),
    Operador(nome: 'Juliana Prado', funcao: 'Sinalizadora'),
    Operador(nome: 'Wesley Tavares', funcao: 'Operador de roçadeira'),
    Operador(nome: 'Diego Nakamura', funcao: 'Motorista'),
  ],
);

final historicoPodas = <Poda>[
  Poda(
    inicio: DateTime(2026, 8, 11, 6, 10),
    fim: DateTime(2026, 8, 11, 9, 25),
    alturaFinal: 4,
    equipe: 'DELTA',
    rodovia: 'SP-270',
    km: 138.0,
  ),
  Poda(
    inicio: DateTime(2026, 8, 10, 7, 0),
    fim: DateTime(2026, 8, 10, 10, 40),
    alturaFinal: 5,
    equipe: 'DELTA',
    rodovia: 'SP-270',
    km: 131.5,
  ),
  Poda(
    inicio: DateTime(2026, 8, 10, 13, 15),
    fim: DateTime(2026, 8, 10, 16, 5),
    alturaFinal: 4.5,
    equipe: 'BRAVO',
    rodovia: 'SP-280',
    km: 62.8,
  ),
  Poda(
    inicio: DateTime(2026, 8, 8, 6, 30),
    fim: DateTime(2026, 8, 8, 11, 10),
    alturaFinal: 4,
    equipe: 'DELTA',
    rodovia: 'SP-330',
    km: 214.2,
  ),
  Poda(
    inicio: DateTime(2026, 8, 7, 7, 20),
    fim: DateTime(2026, 8, 7, 10, 0),
    alturaFinal: 5,
    equipe: 'DELTA',
    rodovia: 'SP-270',
    km: 126.9,
  ),
  Poda(
    inicio: DateTime(2026, 8, 7, 14, 0),
    fim: DateTime(2026, 8, 7, 17, 35),
    alturaFinal: 4.5,
    equipe: 'ÔMEGA',
    rodovia: 'SP-270',
    km: 119.4,
  ),
  Poda(
    inicio: DateTime(2026, 7, 31, 6, 45),
    fim: DateTime(2026, 7, 31, 9, 50),
    alturaFinal: 4,
    equipe: 'DELTA',
    rodovia: 'SP-280',
    km: 71.0,
  ),
  Poda(
    inicio: DateTime(2026, 7, 30, 8, 0),
    fim: DateTime(2026, 7, 30, 12, 15),
    alturaFinal: 5,
    equipe: 'DELTA',
    rodovia: 'SP-330',
    km: 208.6,
  ),
];

// ---------------------------------------------------------------------------
// Formatação em pt-BR sem depender do pacote intl
// ---------------------------------------------------------------------------

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const _diasSemana = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

/// "07:42"
String horaMinuto(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "agosto de 2026"
String mesAno(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';

/// "terça-feira, 11"
String diaSemana(DateTime d) => '${_diasSemana[d.weekday - 1]}, ${d.day}';

/// "3h 15min"
String duracaoLegivel(Duration d) {
  final h = d.inHours;
  final min = d.inMinutes.remainder(60);
  if (h == 0) return '${min}min';
  return min == 0 ? '${h}h' : '${h}h ${min}min';
}

/// 142.3 -> "142,3"  |  138.0 -> "138"
String kmFormatado(double km) {
  final texto = km == km.roundToDouble()
      ? km.toStringAsFixed(0)
      : km.toStringAsFixed(1);
  return texto.replaceAll('.', ',');
}

/// "RGT4B21" -> "RGT 4B21"
String placaFormatada(String placa) =>
    '${placa.substring(0, 3)} ${placa.substring(3)}';
