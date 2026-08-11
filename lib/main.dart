import 'package:flutter/material.dart';

import 'pages/equipe_page.dart';
import 'pages/historico_page.dart';
import 'pages/home_page.dart';

void main() => runApp(const TeMovaApp());

/// Cor da marca. Todo o tema deriva daqui.
const brandPurple = Color(0xFF5E22F3);

const fundoApp = Color(0xFF0E0B14);
const fundoCard = Color(0xFF15111D);

class TeMovaApp extends StatelessWidget {
  const TeMovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'te-mova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          brightness: Brightness.dark,
        ).copyWith(primary: brandPurple, onPrimary: Colors.white),
        scaffoldBackgroundColor: fundoApp,
        appBarTheme: const AppBarTheme(
          backgroundColor: fundoApp,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: fundoCard,
          indicatorColor: brandPurple.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// Casca do app: AppBar fixa + barra de abas embaixo.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _paginas = <Widget>[HomePage(), EquipePage(), HistoricoPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _Logo()),
      // IndexedStack mantém o estado de cada aba viva ao trocar.
      body: SafeArea(
        child: IndexedStack(index: _index, children: _paginas),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Equipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

/// Nome da empresa na esquerda da AppBar.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'te'),
          TextSpan(
            text: '-',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const TextSpan(text: 'mova'),
        ],
      ),
    );
  }
}
