import 'package:flutter/foundation.dart';

/// Porta fixa do Flutter web — o dashboard procura o app neste endereço.
const appPort = 5050;

/// URL pública do app te-mova (sempre a mesma, sem porta aleatória).
const appBase = 'http://127.0.0.1:$appPort';

/// Dashboard gerencial (Vite) — de onde saem os comandos das equipes.
const dashBase = 'http://127.0.0.1:5173';

/// API do Modelo 1, compartilhada com o dashboard (`/ops`).
const apiBase = 'http://127.0.0.1:8000';

/// Proxy `/api` do dashboard (`prototype/dashboard/vite.config.ts`).
const dashApiBase = '$dashBase/api';

const equipeDoApp = 'Equipe Delta';

/// Override: `flutter run --dart-define=APP_BASE=http://192.168.0.10:5050`
String resolveAppBase() {
  const fromEnv = String.fromEnvironment('APP_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  return appBase;
}

/// Override: `flutter run --dart-define=API_BASE=http://192.168.0.10:8000`
String resolveApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return apiBase;
}

/// Endereços tentados até o app achar o mesmo `/ops` do dashboard.
List<String> apiBasesCandidatas() {
  const fromEnv = String.fromEnvironment('API_BASE');
  // Em release (Render) usa só a URL injetada no build — sem localhost.
  if (fromEnv.isNotEmpty && kReleaseMode) {
    return [fromEnv];
  }
  final bases = <String>[
    if (fromEnv.isNotEmpty) fromEnv,
    resolveApiBase(),
    apiBase,
    'http://localhost:8000',
    dashApiBase,
    'http://localhost:5173/api',
    'http://10.0.2.2:8000',
    'http://10.0.2.2:5173/api',
  ];
  final vistos = <String>{};
  return [
    for (final base in bases)
      if (vistos.add(base)) base,
  ];
}

