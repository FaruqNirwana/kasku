
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_helpers.dart';
import '../database/db_helper.dart';
import '../widgets/tx_tile.dart';

class Transactions extends StatefulWidget {
  final VoidCallback changed;

  const Transactions({super.key, required this.changed});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  String filter = 'Semua';
  String query = '';

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Future<void> form([Map<String, dynamic>? row]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TxForm(row: row)),
    );

    if (result == true) {
      setState(() {});
      widget.changed();
    }
  }

  String monthName(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi',
                      style: TextStyle(
                        color: navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Catatan kas dalam satu tempat',
                      style: TextStyle(
                        color: Color(0xFF8491A8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: FilledButton(
                  onPressed: () => form(),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 23),
                ),
              ),
            ],
          ),
        ),

        // PENCARIAN
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (value) {
              setState(() => query = value);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: 'Cari keterangan atau kategori',
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8491A8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // FILTER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['Semua', 'Pemasukan', 'Pengeluaran'].map((value) {
                final selected = filter == value;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => filter = value);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? blue : const Color(0xFF71809B),
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 13),

        // DROPDOWN BULAN
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MonthDropdown(
                selectedMonth: selectedMonth,
                monthName: monthName,
                onChanged: (value) {
                  setState(() => selectedMonth = value);
                },
              ),
              const Spacer(),
              const Text(
                'Riwayat transaksi',
                style: TextStyle(
                  color: Color(0xFF8491A8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // DATA TRANSAKSI
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DB.i.tx(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Gagal memuat transaksi: ${snapshot.error}'),
                );
              }

              final allRows = snapshot.data ?? [];

              final monthRows = allRows.where((row) {
                final date = DateTime.tryParse('${row['tanggal']}');

                return date != null &&
                    date.year == selectedMonth.year &&
                    date.month == selectedMonth.month;
              }).toList();

              final rows = monthRows.where((row) {
                final matchesType =
                    filter == 'Semua' || row['jenis'] == filter;

                final text =
                    '${row['nama_kategori'] ?? ''} ${row['keterangan'] ?? ''}'
                        .toLowerCase();

                final matchesSearch =
                    text.contains(query.toLowerCase());

                return matchesType && matchesSearch;
              }).toList();

              double income = 0;
              double expense = 0;

              for (final row in monthRows) {
                final amount = (row['jumlah'] as num).toDouble();

                if (row['jenis'] == 'Pemasukan') {
                  income += amount;
                } else {
                  expense += amount;
                }
              }

              rows.sort((a, b) {
                return '${b['tanggal']}'.compareTo('${a['tanggal']}');
              });

              final grouped = <String, List<Map<String, dynamic>>>{};

              for (final row in rows) {
                final date = '${row['tanggal']}';
                grouped.putIfAbsent(date, () => []).add(row);
              }

              return Column(
                children: [
                  // RINGKASAN PEMASUKAN DAN PENGELUARAN
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            title: 'Pemasukan',
                            amount: income,
                            color: blue,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 34,
                          color: const Color(0xFFD4DDF0),
                        ),
                        Expanded(
                          child: _SummaryItem(
                            title: 'Pengeluaran',
                            amount: expense,
                            color: navy,
                            leftPadding: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // JUMLAH TRANSAKSI
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          '${rows.length} transaksi',
                          style: const TextStyle(
                            color: Color(0xFF8491A8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DAFTAR TRANSAKSI
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                color: Color(0xFF8491A8),
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                            children: grouped.entries.map((entry) {
                              final date = DateTime.tryParse(entry.key);

                              final dateLabel = date == null
                                  ? entry.key
                                  : date.day == DateTime.now().day &&
                                          date.month == DateTime.now().month &&
                                          date.year == DateTime.now().year
                                      ? 'Hari ini · ${date.day} ${DateFormat('MMMM', 'id_ID').format(date)}'
                                      : '${date.day} ${DateFormat('MMMM', 'id_ID').format(date)}';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 5,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF71809B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      children: entry.value.map((row) {
                                        return InkWell(
                                          onTap: () => form(row),
                                          child: TxTile(row),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
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

// DROPDOWN BULAN KUSTOM

class _MonthDropdown extends StatefulWidget {
  final DateTime selectedMonth;
  final String Function(DateTime) monthName;
  final ValueChanged<DateTime> onChanged;

  const _MonthDropdown({
    required this.selectedMonth,
    required this.monthName,
    required this.onChanged,
  });

  @override
  State<_MonthDropdown> createState() => _MonthDropdownState();
}

class _MonthDropdownState extends State<_MonthDropdown> {
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(5),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withOpacity(0.10),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 5),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 0)),
      ),
      menuChildren: [
        for (var index = 0; index < 12; index++)
          Builder(
            builder: (context) {
              final date = DateTime(
                DateTime.now().year,
                DateTime.now().month - index,
              );

              final selected =
                  date.year == widget.selectedMonth.year &&
                  date.month == widget.selectedMonth.month;

              return MenuItemButton(
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  ),
                  minimumSize: const WidgetStatePropertyAll(
                    Size(0, 34),
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    blue.withOpacity(0.06),
                  ),
                ),
                onPressed: () {
                  widget.onChanged(date);
                },
                child: SizedBox(
                  width: 125,
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.calendar_month_outlined,
                        size: 14,
                        color: selected ? blue : const Color(0xFF8491A8),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.monthName(date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? blue : navy,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 14,
                  color: blue,
                ),
                const SizedBox(width: 7),
                Text(
                  widget.monthName(widget.selectedMonth),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: navy,
                  size: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// RINGKASAN PEMASUKAN DAN PENGELUARAN

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final double leftPadding;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
    this.leftPadding = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
        right: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8491A8),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money.format(amount),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FORM TAMBAH DAN EDIT TRANSAKSI

class TxForm extends StatefulWidget {
  final Map<String, dynamic>? row;

  const TxForm({super.key, this.row});

  @override
  State<TxForm> createState() => _TxFormState();
}

class _TxFormState extends State<TxForm> {
  final amount = TextEditingController();
  final note = TextEditingController();

  String type = 'Pemasukan';
  String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

  int? cat;
  int? student;

  @override
  void initState() {
    super.initState();

    final row = widget.row;

    if (row != null) {
      type = row['jenis'];
      amount.text = '${row['jumlah']}';
      note.text = row['keterangan'] ?? '';
      date = row['tanggal'];
      cat = row['id_kategori'];
      student = row['id_siswa'];
    }
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        DB.i.all('kategori'),
        DB.i.all('siswa'),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = (snapshot.data![0] as List)
            .where((e) => e['jenis'] == type)
            .toList();

        final students = snapshot.data![1] as List;

        if (cat != null &&
            !categories.any((e) => e['id_kategori'] == cat)) {
          cat = null;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.row == null
                  ? 'Tambah transaksi'
                  : 'Edit transaksi',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              label('Jenis transaksi'),
              Wrap(
                spacing: 8,
                children: ['Pemasukan', 'Pengeluaran'].map((value) {
                  return ChoiceChip(
                    label: Text(value),
                    selected: type == value,
                    onSelected: (_) {
                      setState(() {
                        type = value;
                        cat = null;
                      });
                    },
                  );
                }).toList(),
              ),

              label('Jumlah'),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '50000',
                ),
              ),

              label('Kategori'),
              DropdownButtonFormField<int>(
                value: cat,
                isExpanded: true,
                items: categories.map((e) {
                  return DropdownMenuItem<int>(
                    value: e['id_kategori'],
                    child: Text(
                      e['nama_kategori'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => cat = value),
                decoration: const InputDecoration(
                  hintText: 'Pilih kategori',
                ),
              ),

              label('Tanggal'),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (selected != null) {
                    setState(() {
                      date = DateFormat('yyyy-MM-dd').format(selected);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(date),
              ),

              label('Keterangan'),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  hintText: 'Masukkan keterangan',
                ),
              ),

              label('Pembayaran siswa (opsional)'),
              DropdownButtonFormField<int>(
                value: student,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Tidak terkait siswa'),
                  ),
                  ...students.map((e) {
                    return DropdownMenuItem<int>(
                      value: e['id_siswa'],
                      child: Text(
                        e['nama_siswa'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) => setState(() => student = value),
              ),

              const SizedBox(height: 24),

              btn('Simpan transaksi', () async {
                final number = double.tryParse(
                  amount.text.replaceAll('.', '').replaceAll(',', '.'),
                );

                if (cat == null || number == null || number <= 0) {
                  msg(context, 'Isi kategori dan jumlah dengan benar');
                  return;
                }

                final data = {
                  'id_siswa': student,
                  'id_kategori': cat,
                  'tanggal': date,
                  'keterangan': note.text,
                  'jumlah': number,
                };

                if (widget.row == null) {
                  await DB.i.add('transaksi', data);
                } else {
                  await DB.i.edit(
                    'transaksi',
                    'id_transaksi',
                    widget.row!['id_transaksi'],
                    data,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }),

              if (widget.row != null)
                TextButton(
                  onPressed: () async {
                    if (await confirm(context, 'Hapus transaksi?')) {
                      await DB.i.del(
                        'transaksi',
                        'id_transaksi',
                        widget.row!['id_transaksi'],
                      );

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  child: const Text(
                    'Hapus transaksi',
                    style: TextStyle(color: red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
