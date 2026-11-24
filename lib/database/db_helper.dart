import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DB {
  DB._();
  static final DB i = DB._();
  Database? _db;
  int _nextStudent = 2, _nextCategory = 6, _nextTransaction = 3;
  final List<Map<String, dynamic>> _students = [];
  final List<Map<String, dynamic>> _categories = [
    {'id_kategori': 1, 'nama_kategori': 'Kas mingguan', 'jenis': 'Pemasukan'},
    {'id_kategori': 2, 'nama_kategori': 'Iuran kegiatan', 'jenis': 'Pemasukan'},
    {'id_kategori': 3, 'nama_kategori': 'Donasi', 'jenis': 'Pemasukan'},
    {'id_kategori': 4, 'nama_kategori': 'Operasional', 'jenis': 'Pengeluaran'},
    {'id_kategori': 5, 'nama_kategori': 'Kegiatan kelas', 'jenis': 'Pengeluaran'},
  ];
  final List<Map<String, dynamic>> _transactions = [];

  Future<Database> get db async {
    if (kIsWeb) throw UnsupportedError('SQLite hanya digunakan pada Android.');
    if (_db != null) return _db!;
    _db = await openDatabase(p.join(await getDatabasesPath(), 'kasku.db'), version: 1,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE siswa(id_siswa INTEGER PRIMARY KEY AUTOINCREMENT, nis TEXT UNIQUE, nama_siswa TEXT NOT NULL, kelas TEXT, jurusan TEXT)');
        await d.execute('CREATE TABLE kategori(id_kategori INTEGER PRIMARY KEY AUTOINCREMENT, nama_kategori TEXT NOT NULL, jenis TEXT NOT NULL)');
        await d.execute('CREATE TABLE transaksi(id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT, id_siswa INTEGER, id_kategori INTEGER NOT NULL, tanggal TEXT NOT NULL, keterangan TEXT, jumlah REAL NOT NULL, FOREIGN KEY(id_siswa) REFERENCES siswa(id_siswa), FOREIGN KEY(id_kategori) REFERENCES kategori(id_kategori))');
        for (final x in [['Kas mingguan', 'Pemasukan'], ['Iuran kegiatan', 'Pemasukan'], ['Donasi', 'Pemasukan'], ['Operasional', 'Pengeluaran'], ['Kegiatan kelas', 'Pengeluaran']]) {
          await d.insert('kategori', {'nama_kategori': x[0], 'jenis': x[1]});
        }
      });
    return _db!;
  }

  Future<List<Map<String, dynamic>>> all(String table) async {
    if (kIsWeb) {
      final source = table == 'siswa' ? _students : _categories;
      return source.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return (await db).query(table);
  }

  Future<int> add(String table, Map<String, Object?> values) async {
    if (kIsWeb) {
      final source = table == 'siswa' ? _students : table == 'kategori' ? _categories : _transactions;
      final idKey = table == 'siswa' ? 'id_siswa' : table == 'kategori' ? 'id_kategori' : 'id_transaksi';
      final id = table == 'siswa' ? _nextStudent++ : table == 'kategori' ? _nextCategory++ : _nextTransaction++;
      source.add({...values, idKey: id});
      return id;
    }
    return (await db).insert(table, values);
  }

  Future<int> edit(String table, String key, int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final source = table == 'siswa' ? _students : table == 'kategori' ? _categories : _transactions;
      final index = source.indexWhere((e) => e[key] == id);
      if (index < 0) return 0;
      source[index] = {...source[index], ...values};
      return 1;
    }
    return (await db).update(table, values, where: '$key = ?', whereArgs: [id]);
  }

  Future<int> del(String table, String key, int id) async {
    if (kIsWeb) {
      final source = table == 'siswa' ? _students : table == 'kategori' ? _categories : _transactions;
      final before = source.length;
      source.removeWhere((e) => e[key] == id);
      return before - source.length;
    }
    return (await db).delete(table, where: '$key = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> tx({String? type}) async {
    if (kIsWeb) {
      final result = _transactions.map((t) {
        final categoryMatches = _categories.where((c) => c['id_kategori'] == t['id_kategori']);
        final studentMatches = _students.where((s) => s['id_siswa'] == t['id_siswa']);
        final category = categoryMatches.isEmpty ? null : categoryMatches.first;
        final student = studentMatches.isEmpty ? null : studentMatches.first;
        return {...t, 'nama_kategori': category?['nama_kategori'] ?? 'Kategori', 'jenis': category?['jenis'] ?? 'Pemasukan', 'nama_siswa': student?['nama_siswa']};
      }).toList()..sort((a, b) => ('${b['tanggal']}').compareTo('${a['tanggal']}'));
      return type == null ? result : result.where((e) => e['jenis'] == type).toList();
    }
    final result = await (await db).rawQuery('SELECT t.*, k.nama_kategori, k.jenis, s.nama_siswa FROM transaksi t JOIN kategori k ON k.id_kategori = t.id_kategori LEFT JOIN siswa s ON s.id_siswa = t.id_siswa ORDER BY t.tanggal DESC, t.id_transaksi DESC');
    return type == null ? result : result.where((e) => e['jenis'] == type).toList();
  }

  Future<Map<String, double>> totals() async {
    double income = 0, expense = 0;
    for (final item in await tx()) {
      final amount = (item['jumlah'] as num).toDouble();
      if (item['jenis'] == 'Pemasukan') { income += amount; } else { expense += amount; }
    }
    return {'in': income, 'out': expense, 'balance': income - expense};
  }
}
