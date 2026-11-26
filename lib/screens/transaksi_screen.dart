import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

                return matchesType && text.contains(query.toLowerCase());
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

// DROPDOWN BULAN

class _MonthDropdown extends StatelessWidget {
  final DateTime selectedMonth;
  final String Function(DateTime) monthName;
  final ValueChanged<DateTime> onChanged;

  const _MonthDropdown({
    required this.selectedMonth,
    required this.monthName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(5),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 5),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      menuChildren: [
        for (var index = 0; index < 12; index++)
          Builder(
            builder: (context) {
              final date = DateTime(
                DateTime.now().year,
                DateTime.now().month - index,
              );

              final selected = date.year == selectedMonth.year &&
                  date.month == selectedMonth.month;

              return MenuItemButton(
                onPressed: () => onChanged(date),
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
                          monthName(date),
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
            controller.isOpen ? controller.close() : controller.open();
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
                  monthName(selectedMonth),
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

// RINGKASAN

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
      padding: EdgeInsets.only(left: leftPadding, right: 2),
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

  static const Color background = Color(0xFFF5F7FB);
  static const Color muted = Color(0xFF8491A8);
  static const Color border = Color(0xFFE5EAF2);
  static const Color income = Color(0xFF159B72);
  static const Color expense = Color(0xFFE45D65);

  bool get isEditing => widget.row != null;

  @override
  void initState() {
    super.initState();

    final row = widget.row;

    if (row != null) {
      type = row['jenis']?.toString() ?? 'Pemasukan';
      amount.text = _formatAmount(row['jumlah']);
      note.text = row['keterangan']?.toString() ?? '';
      date = row['tanggal']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      cat = row['id_kategori'] as int?;
      student = row['id_siswa'] as int?;
    }
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '';

    final number = value is num
        ? value
        : double.tryParse(value.toString()) ?? 0;

    return NumberFormat('#,##0', 'id_ID')
        .format(number)
        .replaceAll(',', '.');
  }

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    return DateFormat('dd MMMM yyyy', 'id_ID').format(parsed);
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B9C8),
        fontSize: 12,
      ),
      prefixIcon: prefix,
      prefixIconConstraints:
          const BoxConstraints(minWidth: 38, minHeight: 45),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: blue, width: 1.2),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF53617A),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(title)),
              if (trailing != null) trailing,
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _typeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _typeButton(
            title: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            selected: type == 'Pemasukan',
            color: income,
          ),
          const SizedBox(width: 5),
          _typeButton(
            title: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            selected: type == 'Pengeluaran',
            color: expense,
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (type == title) return;

          setState(() {
            type = title;
            cat = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected ? color : muted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : const Color(0xFF71809B),
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(date) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: blue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        date = DateFormat('yyyy-MM-dd').format(selected);
      });
    }
  }

  Future<void> _save() async {
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
      'keterangan': note.text.trim(),
      'jumlah': number,
    };

    try {
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

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        msg(context, 'Gagal menyimpan transaksi: $e');
      }
    }
  }

  Future<void> _delete() async {
    if (widget.row == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/delete.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(height: 17),
                const Text(
                  'Hapus transaksi?',
                  style: TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Transaksi ini akan dihapus dari catatan kas. Periksa kembali sebelum melanjutkan.',
                  style: TextStyle(
                    color: Color(0xFF8491A8),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F5F9),
                            foregroundColor: navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC34F54),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 11,
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
          ),
        );
      },
    );

    if (result == true) {
      try {
        await DB.i.del(
          'transaksi',
          'id_transaksi',
          widget.row!['id_transaksi'],
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          msg(context, 'Gagal menghapus transaksi: $e');
        }
      }
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
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              title: const Text('Transaksi'),
              backgroundColor: background,
            ),
            body: Center(
              child: Text('Gagal memuat data: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: background,
            body: Center(
              child: CircularProgressIndicator(color: blue),
            ),
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
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 54,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 19,
                color: navy,
              ),
            ),
            titleSpacing: 0,
            title: Text(
              isEditing ? 'Edit transaksi' : 'Tambah transaksi',
              style: const TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 18),
                  children: [
                    _section(
                      title: 'Jenis transaksi',
                      child: _typeSelector(),
                    ),
                    _section(
                      title: 'Jumlah',
                      child: TextField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _inputDecoration(
                          hint: '0',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                'Rp',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Kategori',
                      child: DropdownButtonFormField<int>(
                        value: cat,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: muted,
                          size: 19,
                        ),
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Pilih kategori',
                        ),
                        items: categories.map<DropdownMenuItem<int>>((e) {
                          return DropdownMenuItem<int>(
                            value: e['id_kategori'] as int,
                            child: Text(
                              e['nama_kategori']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => cat = value);
                        },
                      ),
                    ),
                    _section(
                      title: 'Tanggal',
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 45,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _displayDate(date),
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                'assets/icons/calendar.svg',
                                width: 17,
                                height: 9,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Keterangan',
                      child: TextField(
                        controller: note,
                        minLines: 1,
                        maxLines: 3,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Masukkan keterangan',
                        ),
                      ),
                    ),
                    _section(
                      title: 'Pembayaran siswa',
                      trailing: const Padding(
                        padding: EdgeInsets.only(bottom: 7),
                        child: Text(
                          'Opsional',
                          style: TextStyle(
                            color: Color(0xFF8491A8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: student,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: muted,
                          size: 19,
                        ),
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Tidak terkait siswa',
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text(
                              'Tidak terkait siswa',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ...students.map<DropdownMenuItem<int>>((e) {
                            return DropdownMenuItem<int>(
                              value: e['id_siswa'] as int,
                              child: Text(
                                e['nama_siswa']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => student = value);
                        },
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 1),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: expense,
                            backgroundColor: const Color(0xFFFFEEEE),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/delete.svg',
                                width: 17,
                                height: 17,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hapus transaksi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.035),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 17,
                      ),
                      label: Text(
                        isEditing
                            ? 'Simpan perubahan'
                            : 'Simpan transaksi',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}