
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_helpers.dart';
import '../database/db_helper.dart';

// ======================================================
// LAPORAN HARIAN DAN BULANAN
// ======================================================

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  bool monthly = true;

  DateTime selectedDate = DateTime.now();

  late Future<List<dynamic>> reportFuture;

  final Color borderColor = const Color(0xFFE8EDF5);
  final Color mutedColor = const Color(0xFF8795AD);
  final Color lightBlue = const Color(0xFFEDF2FF);

  @override
  void initState() {
    super.initState();
    reportFuture = DB.i.tx();
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double getAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> selectPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: monthly ? 'Pilih bulan laporan' : 'Pilih tanggal laporan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3165DF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF172F59),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ======================================================
  // BUILD LAPORAN
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 35,
                ),
                const SizedBox(height: 10),
                const Text('Gagal memuat laporan'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      reportFuture = DB.i.tx();
                    });
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        final rows = snapshot.data ?? [];

        // Awal dan akhir periode
        final periodStart = monthly
            ? DateTime(selectedDate.year, selectedDate.month)
            : DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );

        final periodEnd = monthly
            ? DateTime(selectedDate.year, selectedDate.month + 1)
            : periodStart.add(const Duration(days: 1));

        double openingBalance = 0;
        double income = 0;
        double expense = 0;

        int transactionCount = 0;

        // ==================================================
        // HITUNG TRANSAKSI
        // ==================================================

        for (final item in rows) {
          final e = Map<String, dynamic>.from(item);

          final date = parseDate(e['tanggal']);

          if (date == null) continue;

          final amount = getAmount(e['jumlah']);
          final type = (e['jenis'] ?? '').toString().toLowerCase();

          final isIncome = type == 'pemasukan';
          final isExpense = type == 'pengeluaran';

          if (!isIncome && !isExpense) continue;

          // Saldo sebelum periode
          if (date.isBefore(periodStart)) {
            if (isIncome) {
              openingBalance += amount;
            } else {
              openingBalance -= amount;
            }
          }

          // Transaksi dalam periode
          if (!date.isBefore(periodStart) &&
              date.isBefore(periodEnd)) {
            transactionCount++;

            if (isIncome) {
              income += amount;
            } else {
              expense += amount;
            }
          }
        }

        final endingBalance =
            openingBalance + income - expense;

        final periodText = monthly
            ? formatMonth(selectedDate)
            : formatDate(selectedDate);

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            heading(
              'Laporan',
              'Ringkasan kas yang mudah dipahami',
            ),

            const SizedBox(height: 2),

            // ==================================================
            // TAB HARIAN / BULANAN
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _tabButton(
                      'Harian',
                      false,
                    ),
                    _tabButton(
                      'Bulanan',
                      true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 11),

            // ==================================================
            // PILIH TANGGAL
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: InkWell(
                onTap: selectPeriod,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 43,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF3165DF),
                        size: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          monthly ? periodText : periodText,
                          style: const TextStyle(
                            color: Color(0xFF172F59),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        monthly ? 'Bulanan' : 'Harian',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 11),

            // ==================================================
            // KARTU SALDO AKHIR
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF172F59),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALDO AKHIR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      money.format(endingBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Per $periodText',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 11),

            // ==================================================
            // KARTU PEMASUKAN DAN PENGELUARAN
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Total pemasukan',
                      amount: income,
                      icon: Icons.arrow_downward,
                      color: const Color(0xFF159B78),
                      background: const Color(0xFFE7F6F1),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _summaryCard(
                      title: 'Total pengeluaran',
                      amount: expense,
                      icon: Icons.arrow_upward,
                      color: const Color(0xFFE65C60),
                      background: const Color(0xFFFFEEEE),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // JUDUL REKAP KAS
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'Rekap kas',
                    style: TextStyle(
                      color: Color(0xFF172F59),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$transactionCount transaksi',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 9),

            // ==================================================
            // RINCIAN SALDO
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _line(
                      'Saldo awal',
                      openingBalance,
                      const Color(0xFF172F59),
                    ),
                    _divider(),

                    _line(
                      'Total pemasukan',
                      income,
                      const Color(0xFF159B78),
                      prefix: '+',
                    ),
                    _divider(),

                    _line(
                      'Total pengeluaran',
                      expense,
                      const Color(0xFFE65C60),
                      prefix: '-',
                    ),
                    _divider(),

                    _line(
                      'Saldo akhir',
                      endingBalance,
                      const Color(0xFF3165DF),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // TOMBOL TAB
  // ======================================================

  Widget _tabButton(String title, bool value) {
    final active = monthly == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            monthly = value;
          });
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: active
                  ? const Color(0xFF3165DF)
                  : const Color(0xFF7F8CA3),
              fontSize: 10,
              fontWeight:
                  active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // KARTU RINGKASAN
  // ======================================================

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 9, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 12,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.format(amount),
              style: const TextStyle(
                color: Color(0xFF172F59),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // GARIS PEMBATAS
  // ======================================================

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: borderColor,
    );
  }

  // ======================================================
  // BARIS REKAP
  // ======================================================

  Widget _line(
    String title,
    double value,
    Color color, {
    String prefix = '',
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: bold
                    ? const Color(0xFF172F59)
                    : mutedColor,
                fontSize: 10,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix${money.format(value)}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
