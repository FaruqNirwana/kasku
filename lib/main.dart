
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_helpers.dart';
import 'database/db_helper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/siswa_screen.dart';
import 'screens/laporan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Database hanya dijalankan pada Android/Desktop
  if (!kIsWeb) {
    await DB.i.db;
  }

  runApp(const KasKu());
}

class KasKu extends StatelessWidget {
  const KasKu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KasKu',

      // Bahasa aplikasi
      locale: const Locale('id', 'ID'),

      // Localization Material dan Cupertino
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,

        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: navy,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  int refresh = 0;

  void reload() {
    setState(() {
      refresh++;
    });
  }

  Widget navIcon(String file, Color color) {
    return SvgPicture.asset(
      'assets/icons/$file.svg',
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(
        key: ValueKey('d$refresh'),
        go: (value) {
          setState(() => tab = value);
        },
      ),

      Transactions(
        key: ValueKey('t$refresh'),
        changed: reload,
      ),

      Students(
        key: ValueKey('s$refresh'),
        changed: reload,
      ),

      Reports(
        key: ValueKey('r$refresh'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: pages,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,

        onDestinationSelected: (value) {
          setState(() {
            tab = value;
          });
        },

        backgroundColor: Colors.white,
        indicatorColor: blue.withOpacity(0.12),

        destinations: [
          NavigationDestination(
            icon: navIcon(
              'home',
              const Color(0xFF6C7A90),
            ),
            selectedIcon: navIcon(
              'home',
              const Color(0xFF3168E0),
            ),
            label: 'Dashboard',
          ),

          NavigationDestination(
            icon: navIcon(
              'transaction',
              const Color(0xFF6C7A90),
            ),
            selectedIcon: navIcon(
              'transaction',
              const Color(0xFF3168E0),
            ),
            label: 'Transaksi',
          ),

          NavigationDestination(
            icon: navIcon(
              'users',
              const Color(0xFF6C7A90),
            ),
            selectedIcon: navIcon(
              'users',
              const Color(0xFF3168E0),
            ),
            label: 'Siswa',
          ),

          NavigationDestination(
            icon: navIcon(
              'chart',
              const Color(0xFF6C7A90),
            ),
            selectedIcon: navIcon(
              'chart',
              const Color(0xFF3168E0),
            ),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
