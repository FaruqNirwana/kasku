import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_helpers.dart';
import 'database/db_helper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/siswa_screen.dart';
import 'screens/laporan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) await DB.i.db;
  runApp(const KasKu());
}

class KasKu extends StatelessWidget {
  const KasKu({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'KasKu',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: navy, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none))),
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0, refresh = 0;
  void reload() => setState(() => refresh++);
  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(key: ValueKey('d$refresh'), go: (value) => setState(() => tab = value)),
      Transactions(key: ValueKey('t$refresh'), changed: reload),
      Students(key: ValueKey('s$refresh'), changed: reload),
      Reports(key: ValueKey('r$refresh')),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (value) => setState(() => tab = value),
        backgroundColor: Colors.white, indicatorColor: blue.withOpacity(.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Siswa'),
          NavigationDestination(icon: Icon(Icons.insert_chart_outlined), label: 'Laporan'),
        ],
      ),
    );
  }
}
