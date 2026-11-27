import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../app_helpers.dart';
import '../database/db_helper.dart';
import '../widgets/tx_tile.dart';

const Color studentMuted = Color(0xFF8491A8);
const Color studentBorder = Color(0xFFE9EDF5);
const Color studentLightBlue = Color(0xFFEDF2FF);
const Color studentRed = Color(0xFFC34F54);
const Color studentRedBg = Color(0xFFFFEEEE);

// ======================================================
// MENU DATA SISWA
// ======================================================

class Students extends StatefulWidget {
  final VoidCallback changed;

  const Students({
    super.key,
    required this.changed,
  });

  @override
  State<Students> createState() => _StudentsState();
}

class _StudentsState extends State<Students> {
  String q = '';
  String filterClass = 'Semua kelas';

  Future<void> form([Map<String, dynamic>? e]) async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentForm(row: e),
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      setState(() {});
      widget.changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        heading(
          'Data siswa',
          'Kelola data peserta pembayaran',
          action: IconButton(
            onPressed: () => form(),
            style: IconButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              fixedSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.add, size: 23),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIS siswa',
              prefixIcon: const Icon(Icons.search, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: studentBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: studentBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: blue),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              DB.i.all('siswa'),
              DB.i.tx(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat data siswa'),
                );
              }

              final allRows =
                  List<Map<String, dynamic>>.from(
                snapshot.data?[0] ?? [],
              );

              final transactions =
                  List<Map<String, dynamic>>.from(
                snapshot.data?[1] ?? [],
              );

              final Map<String, double> totals = {};

              for (final tx in transactions) {
                if (tx['id_siswa'] == null ||
                    tx['jenis'] != 'Pemasukan') {
                  continue;
                }

                final id = tx['id_siswa'].toString();
                final amount =
                    (tx['jumlah'] as num).toDouble();

                totals[id] = (totals[id] ?? 0) + amount;
              }

              final classes = allRows
                  .map((e) => (e['kelas'] ?? '').toString())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              final filteredRows = allRows.where((e) {
                final searchText =
                    '${e['nama_siswa']} ${e['nis']}'
                        .toLowerCase();

                final matchSearch =
                    searchText.contains(q.toLowerCase());

                final matchClass =
                    filterClass == 'Semua kelas' ||
                    e['kelas'] == filterClass;

                return matchSearch && matchClass;
              }).toList();

              filteredRows.sort((a, b) {
                final totalA =
                    totals[a['id_siswa'].toString()] ?? 0;

                final totalB =
                    totals[b['id_siswa'].toString()] ?? 0;

                return totalB.compareTo(totalA);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  20,
                ),
                children: [
                  _ClassDropdown(
                    value: filterClass,
                    classes: classes,
                    onChanged: (v) {
                      setState(() => filterClass = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        '${filteredRows.length} siswa',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Pembayaran terbesar',
                        style: TextStyle(
                          fontSize: 10,
                          color: blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (filteredRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text('Belum ada siswa'),
                      ),
                    )
                  else
                    ...filteredRows.map(
                      (e) => _StudentCard(
                        row: e,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetail(
                                row: e,
                                onEdit: () => form(e),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentStatistics(
                            students: allRows,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: studentLightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Statistik pembayaran',
                            style: TextStyle(
                              color: blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: blue,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================
// DROPDOWN KELAS
// ======================================================

class _ClassDropdown extends StatelessWidget {
  final String value;
  final List<String> classes;
  final ValueChanged<String> onChanged;

  const _ClassDropdown({
    required this.value,
    required this.classes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: studentBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: studentMuted,
          ),
          style: const TextStyle(
            color: navy,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          items: [
            const DropdownMenuItem(
              value: 'Semua kelas',
              child: Text('Semua kelas'),
            ),
            ...classes.map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ======================================================
// KARTU SISWA
// ======================================================

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;

  const _StudentCard({
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: studentBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (row['nama_siswa'] ?? '').toString(),
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS ${row['nis'] ?? '-'}',
                      style: const TextStyle(
                        color: studentMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: studentLightBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (row['kelas'] ?? '-').toString(),
                            style: const TextStyle(
                              color: blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            (row['jurusan'] ?? '-').toString(),
                            style: const TextStyle(
                              color: studentMuted,
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: studentMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ======================================================
// FORM TAMBAH DAN EDIT SISWA
// ======================================================

class StudentForm extends StatefulWidget {
  final Map<String, dynamic>? row;

  const StudentForm({
    super.key,
    this.row,
  });

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final nis = TextEditingController();
  final name = TextEditingController();
  final kelas = TextEditingController();
  final major = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final e = widget.row;

    if (e != null) {
      nis.text = (e['nis'] ?? '').toString();
      name.text = (e['nama_siswa'] ?? '').toString();
      kelas.text = (e['kelas'] ?? '').toString();
      major.text = (e['jurusan'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    nis.dispose();
    name.dispose();
    kelas.dispose();
    major.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: studentMuted,
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: studentBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: studentBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: blue),
      ),
    );
  }

  Widget inputLabel(
    String text,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: fieldDecoration(hint),
          style: const TextStyle(
            color: navy,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // SIMPAN SISWA
  Future<void> save() async {
    if (nis.text.trim().isEmpty ||
        name.text.trim().isEmpty) {
      msg(context, 'NIS dan nama wajib diisi');
      return;
    }

    setState(() => saving = true);

    final data = {
      'nis': nis.text.trim(),
      'nama_siswa': name.text.trim(),
      'kelas': kelas.text.trim(),
      'jurusan': major.text.trim(),
    };

    try {
      if (widget.row == null) {
        await DB.i.add('siswa', data);
      } else {
        await DB.i.edit(
          'siswa',
          'id_siswa',
          widget.row!['id_siswa'],
          data,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      msg(
        context,
        'NIS sudah digunakan atau data gagal disimpan',
      );

      setState(() => saving = false);
    }
  }

  // HAPUS SISWA
  Future<void> deleteStudent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            12,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.string(
                '''
                <svg width="19" height="19" viewBox="0 0 19 19" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0.900024 3.6499H17.4M6.40002 3.6499V0.899902H11.9V3.6499M2.73336 3.6499L3.65002 17.3999H14.65L15.5667 3.6499M7.31669 7.31657V13.7332M10.9834 7.31657V13.7332" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" stroke="#C34F54"/>
                </svg>
                ''',
                width: 19,
                height: 19,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hapus siswa?',
                style: TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Data siswa ini akan dihapus. Pastikan kembali sebelum melanjutkan.',
                style: TextStyle(
                  color: studentMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: studentRed,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    try {
      await DB.i.del(
        'siswa',
        'id_siswa',
        widget.row!['id_siswa'],
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      msg(
        context,
        'Siswa tidak dapat dihapus karena masih memiliki transaksi',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.row != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          editing ? 'Edit siswa' : 'Tambah siswa',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          25,
        ),
        children: [
          Text(
            editing
                ? 'Perbarui informasi siswa.'
                : 'Lengkapi identitas siswa baru.',
            style: const TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pastikan semua data yang dimasukkan sudah benar.',
            style: TextStyle(
              color: studentMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 25),
          inputLabel('NIS', 'Contoh: 12345', nis),
          const SizedBox(height: 19),
          inputLabel(
            'Nama siswa',
            'Masukkan nama lengkap',
            name,
          ),
          const SizedBox(height: 19),
          inputLabel(
            'Kelas',
            'Contoh: XI RPL 1',
            kelas,
          ),
          const SizedBox(height: 19),
          inputLabel(
            'Jurusan',
            'Contoh: Rekayasa Perangkat Lunak',
            major,
          ),
          const SizedBox(height: 30),

          // TOMBOL HAPUS DENGAN SVG ASLI
          if (editing)
            SizedBox(
              height: 43,
              child: OutlinedButton(
                onPressed: deleteStudent,
                style: OutlinedButton.styleFrom(
                  backgroundColor: studentRedBg,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      '''
                      <svg width="19" height="19" viewBox="0 0 19 19" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M0.900024 3.6499H17.4M6.40002 3.6499V0.899902H11.9V3.6499M2.73336 3.6499L3.65002 17.3999H14.65L15.5667 3.6499M7.31669 7.31657V13.7332M10.9834 7.31657V13.7332" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" stroke="#C34F54"/>
                      </svg>
                      ''',
                      width: 19,
                      height: 19,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Hapus siswa',
                      style: TextStyle(
                        color: studentRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // TOMBOL SIMPAN DI BAWAH
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            12,
          ),
          color: bg,
          child: SizedBox(
            height: 49,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.check, size: 17),
              label: Text(
                saving
                    ? 'Menyimpan...'
                    : editing
                        ? 'Simpan perubahan'
                        : 'Simpan siswa',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// DETAIL SISWA
// ======================================================

class StudentDetail extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onEdit;

  const StudentDetail({
    super.key,
    required this.row,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: DB.i.tx(),
      builder: (context, snapshot) {
        final transactions =
            List<Map<String, dynamic>>.from(
          snapshot.data ?? [],
        );

        final rows = transactions.where((e) {
          return e['id_siswa']?.toString() ==
              row['id_siswa']?.toString();
        }).toList();

        final total = rows
            .where((e) => e['jenis'] == 'Pemasukan')
            .fold<double>(
              0,
              (a, e) =>
                  a + (e['jumlah'] as num).toDouble(),
            );

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: const Text('Detail siswa'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            children: [
              // INFORMASI SISWA
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: studentBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: studentLightBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Data siswa',
                        style: TextStyle(
                          color: blue,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (row['nama_siswa'] ?? '-').toString(),
                      style: const TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'NIS ${row['nis'] ?? '-'}',
                      style: const TextStyle(
                        color: studentMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // GARIS PEMBATAS
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: studentBorder,
                    ),

                    const SizedBox(height: 12),

                    // KELAS DAN JURUSAN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kelas',
                                style: TextStyle(
                                  color: studentMuted,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                (row['kelas'] ?? '-').toString(),
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jurusan',
                                style: TextStyle(
                                  color: studentMuted,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                (row['jurusan'] ?? '-').toString(),
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // TOTAL PEMBAYARAN
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money.format(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${rows.length} riwayat transaksi',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Riwayat pembayaran',
                style: TextStyle(
                  color: navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: studentBorder),
                ),
                child: snapshot.connectionState ==
                        ConnectionState.waiting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : snapshot.hasError
                        ? const Text(
                            'Gagal memuat riwayat pembayaran',
                          )
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    'Belum ada riwayat pembayaran',
                                    style: TextStyle(
                                      color: studentMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: rows
                                    .map((e) => TxTile(e))
                                    .toList(),
                              ),
              ),
            ],
          ),

          // TOMBOL EDIT SELALU DI BAWAH LAYAR
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                12,
              ),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit data siswa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// ======================================================
// STATISTIK PEMBAYARAN
// ======================================================

class StudentStatistics extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const StudentStatistics({
    super.key,
    required this.students,
  });

  @override
  State<StudentStatistics> createState() =>
      _StudentStatisticsState();
}

class _StudentStatisticsState extends State<StudentStatistics> {
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool sameMonth(DateTime date, DateTime month) {
    return date.year == month.year &&
        date.month == month.month;
  }

  String monthName(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Statistik pembayaran'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: DB.i.tx(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat statistik'),
            );
          }

          final allTransactions =
              List<Map<String, dynamic>>.from(
            snapshot.data ?? [],
          );

          final transactions = allTransactions.where((e) {
            final date = parseDate(e['tanggal']);

            return date != null &&
                sameMonth(date, selectedMonth) &&
                e['jenis'] == 'Pemasukan';
          }).toList();

          final total = transactions.fold<double>(
            0,
            (sum, e) =>
                sum + (e['jumlah'] as num).toDouble(),
          );

          final Map<String, double> studentTotals = {};

          for (final tx in transactions) {
            if (tx['id_siswa'] == null) continue;

            final id = tx['id_siswa'].toString();

            studentTotals[id] =
                (studentTotals[id] ?? 0) +
                (tx['jumlah'] as num).toDouble();
          }

          final paidCount = studentTotals.values
              .where((amount) => amount > 0)
              .length;

          final unpaidCount =
              (widget.students.length - paidCount)
                  .clamp(0, widget.students.length);

          final sortedStudents = [...widget.students];

          sortedStudents.sort((a, b) {
            final totalA =
                studentTotals[a['id_siswa'].toString()] ?? 0;

            final totalB =
                studentTotals[b['id_siswa'].toString()] ?? 0;

            return totalB.compareTo(totalA);
          });

          final weeklyTotals = List<double>.filled(4, 0);

          for (final tx in transactions) {
            final date = parseDate(tx['tanggal']);
            if (date == null) continue;

            final week = ((date.day - 1) ~/ 7).clamp(0, 3);

            weeklyTotals[week] +=
                (tx['jumlah'] as num).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              24,
            ),
            children: [
              const Text(
                'Pantau pembayaran siswa',
                style: TextStyle(
                  color: studentMuted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 14),

              // PILIH BULAN
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DateTime>(
                    value: selectedMonth,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: studentMuted,
                    ),
                    items: List.generate(12, (index) {
                      final month = DateTime(
                        DateTime.now().year,
                        DateTime.now().month - index,
                      );

                      return DropdownMenuItem<DateTime>(
                        value: month,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: blue,
                              size: 17,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              monthName(month),
                              style: const TextStyle(
                                color: navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOTAL PEMBAYARAN
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PEMBAYARAN SISWA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      money.format(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$paidCount sudah membayar',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 14,
                          color: Colors.white24,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            '$unpaidCount belum membayar',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // GRAFIK MINGGUAN
              _WeeklyPaymentChart(
                values: weeklyTotals,
                subtitle:
                    'Total pemasukan dari siswa ${monthName(selectedMonth)}',
              ),

              const SizedBox(height: 18),

              // TOTAL PER SISWA
              Row(
                children: [
                  const Text(
                    'Total per siswa',
                    style: TextStyle(
                      color: navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'Terbesar ↓',
                    style: TextStyle(
                      color: blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // DAFTAR SISWA
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: sortedStudents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Belum ada data siswa',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: sortedStudents.map((student) {
                          final id =
                              student['id_siswa'].toString();

                          final amount =
                              studentTotals[id] ?? 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: studentBorder,
                                  width: 0.6,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['nama_siswa'] ?? '-',
                                        style: const TextStyle(
                                          color: navy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'NIS ${student['nis'] ?? '-'} • ${student['kelas'] ?? '-'}',
                                        style: const TextStyle(
                                          color: studentMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  money.format(amount),
                                  style: const TextStyle(
                                    color: blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Icon(
                                  Icons.chevron_right,
                                  color: studentMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======================================================
// GRAFIK PEMBAYARAN MINGGUAN
// ======================================================

class _WeeklyPaymentChart extends StatelessWidget {
  final List<double> values;
  final String subtitle;

  const _WeeklyPaymentChart({
    required this.values,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      0,
      (a, b) => a > b ? a : b,
    );

    final chartMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pembayaran mingguan',
            style: TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              color: studentMuted,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 135,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final value = values[index];

                final barHeight = value == 0
                    ? 4.0
                    : (value / chartMax * 75)
                        .clamp(8.0, 75.0);

                final isLargest =
                    maxValue > 0 && value == maxValue;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value == 0
                            ? '0'
                            : NumberFormat.compact(
                                locale: 'id_ID',
                              ).format(value),
                        style: const TextStyle(
                          color: studentMuted,
                          fontSize: 8,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        height: 82,
                        alignment: Alignment.bottomCenter,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: studentBorder,
                            ),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 22,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isLargest
                                  ? blue
                                  : const Color(0xFFA9C1F7),
                              borderRadius:
                                  const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'M${index + 1}',
                        style: const TextStyle(
                          color: studentMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}