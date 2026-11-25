import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_helpers.dart';
import '../database/db_helper.dart';

/// Halaman utama KasKu.
/// File ini hanya mengatur tampilan Dashboard, bukan database atau form transaksi.
class Dashboard extends StatelessWidget {
  final void Function(int) go;

  const Dashboard({super.key, required this.go});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([DB.i.totals(), DB.i.tx()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat dashboard: ${snapshot.error}'));
        }

        final totals = snapshot.data![0] as Map<String, double>;
        final transactions =
            snapshot.data![1] as List<Map<String, dynamic>>;

        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _DashboardHeader(),
            _BalanceCard(balance: totals['balance'] ?? 0),
            _IncomeExpenseCards(
              income: totals['in'] ?? 0,
              expense: totals['out'] ?? 0,
            ),
            _CashFlowCard(transactions: transactions),
            _LatestTransactions(
              transactions: transactions.take(5).toList(),
              onSeeAll: () => go(1),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KasKu',
            style: TextStyle(
              color: navy,
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Kas rapi, kegiatan lancar.',
            style: TextStyle(color: Color(0xFF7D8BA5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = _indonesianMonths[now.month - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL SALDO KAS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 19,
              )
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: Colors.white.withOpacity(0.14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kas XI RPL 1',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                '$month ${now.year}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseCards extends StatelessWidget {
  final double income;
  final double expense;

  const _IncomeExpenseCards({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: _SmallTotalCard(
              title: 'Pemasukan',
              amount: income,
              color: green,
              icon: Icons.south,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SmallTotalCard(
              title: 'Pengeluaran',
              amount: expense,
              color: red,
              icon: Icons.north,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTotalCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SmallTotalCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF71809B),
                    fontSize: 10,
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
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowCard extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const _CashFlowCard({required this.transactions});

  @override
  State<_CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends State<_CashFlowCard> {
  String _period = 'Bulanan';

  @override
  Widget build(BuildContext context) {
    final data = _makeCashFlow(widget.transactions, _period);
    final subtitle = _period == 'Bulanan'
        ? '6 bulan terakhir'
        : _period == 'Mingguan'
            ? '6 minggu terakhir'
            : '6 tahun terakhir';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arus kas', style: TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF8491A8), fontSize: 10)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                initialValue: _period,
                onSelected: (value) => setState(() => _period = value),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Mingguan', child: Text('Mingguan')),
                  PopupMenuItem(value: 'Bulanan', child: Text('Bulanan')),
                  PopupMenuItem(value: 'Tahunan', child: Text('Tahunan')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_period, style: const TextStyle(color: navy, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 7),
                      const Icon(Icons.keyboard_arrow_down, size: 15, color: navy),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: Row(
              children: [
                const SizedBox(
                  width: 27,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('4 jt', style: TextStyle(color: Color(0xFF8491A8), fontSize: 9)),
                      Text('2 jt', style: TextStyle(color: Color(0xFF8491A8), fontSize: 9)),
                      Text('0', style: TextStyle(color: Color(0xFF8491A8), fontSize: 9)),
                    ],
                  ),
                ),
                Expanded(child: _CashFlowBars(data: data)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 27),
              ...data.map((item) => Expanded(
                    child: Text(item.label, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF7D8BA5), fontSize: 9)),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: blue, label: 'Pemasukan'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFAFC5FF), label: 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowBars extends StatelessWidget {
  final List<_MonthCashFlow> data;

  const _CashFlowBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final highest = data.fold<double>(
      0,
      (value, item) => math.max(value, math.max(item.income, item.expense)).toDouble(),
    );
    final double maxValue = math.max(4000000.0, (highest / 1000000).ceil() * 1000000.0).toDouble();

    return CustomPaint(
      painter: _CashFlowPainter(data: data, maxValue: maxValue),
      child: const SizedBox.expand(),
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<_MonthCashFlow> data;
  final double maxValue;

  _CashFlowPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF5)
      ..strokeWidth = 1;
    final incomePaint = Paint()..color = blue;
    final expensePaint = Paint()..color = const Color(0xFFAFC5FF);

    for (var line = 0; line < 3; line++) {
      final y = size.height * line / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final groupWidth = size.width / data.length;
    final barWidth = math.min(9.0, groupWidth * 0.23).toDouble();
    for (var i = 0; i < data.length; i++) {
      final center = groupWidth * (i + 0.5);
      final incomeHeight = (data[i].income / maxValue) * size.height;
      final expenseHeight = (data[i].expense / maxValue) * size.height;
      final incomeRect = Rect.fromLTWH(
        center - barWidth - 1,
        size.height - incomeHeight,
        barWidth,
        incomeHeight,
      );
      final expenseRect = Rect.fromLTWH(
        center + 1,
        size.height - expenseHeight,
        barWidth,
        expenseHeight,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(incomeRect, const Radius.circular(3)),
          incomePaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(expenseRect, const Radius.circular(3)),
          expensePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.maxValue != maxValue;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Color(0xFF8491A8), fontSize: 8)),
      ],
    );
  }
}

class _LatestTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onSeeAll;

  const _LatestTransactions({
    required this.transactions,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
          child: Row(
            children: [
              const Expanded(
                child: Text('Transaksi terbaru',
                    style: TextStyle(
                        color: navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Lihat semua',
                    style: TextStyle(color: blue, fontSize: 10)),
              ),
            ],
          ),
        ),
        if (transactions.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: const Text('Belum ada transaksi',
                style: TextStyle(color: Color(0xFF8491A8), fontSize: 12)),
          )
        else
          ...transactions.map((item) => _LatestTransactionTile(item: item)),
      ],
    );
  }
}

class _LatestTransactionTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _LatestTransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isIncome = item['jenis'] == 'Pemasukan';
    final color = isIncome ? green : red;
    final date = DateTime.tryParse('${item['tanggal']}');
    final dateLabel = date == null
        ? '${item['tanggal']}'
        : '${date.day} ${_indonesianMonths[date.month - 1].substring(0, 3)}';
    final student = item['nama_siswa'];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isIncome ? Icons.south : Icons.north,
                color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['nama_kategori'] ?? 'Transaksi'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${student ?? item['keterangan'] ?? 'Tanpa keterangan'} · $dateLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF8491A8), fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isIncome ? '+' : '−'}${money.format(item['jumlah'])}',
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MonthCashFlow {
  final String label;
  final double income;
  final double expense;

  const _MonthCashFlow(this.label, this.income, this.expense);
}

List<_MonthCashFlow> _makeCashFlow(
    List<Map<String, dynamic>> transactions, String period) {
  final now = DateTime.now();
  final result = <_MonthCashFlow>[];

  for (var offset = 5; offset >= 0; offset--) {
    DateTime start;
    DateTime end;
    String label;

    if (period == 'Mingguan') {
      final currentWeekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      start = currentWeekStart.subtract(Duration(days: 7 * offset));
      end = start.add(const Duration(days: 7));
      label = '${start.day}/${start.month}';
    } else if (period == 'Tahunan') {
      start = DateTime(now.year - offset, 1, 1);
      end = DateTime(now.year - offset + 1, 1, 1);
      label = '${start.year}';
    } else {
      start = DateTime(now.year, now.month - offset, 1);
      end = DateTime(start.year, start.month + 1, 1);
      label = _indonesianMonths[start.month - 1].substring(0, 3);
    }

    double income = 0;
    double expense = 0;
    for (final item in transactions) {
      final date = DateTime.tryParse('${item['tanggal']}');
      if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;
      final amount = (item['jumlah'] as num).toDouble();
      if (item['jenis'] == 'Pemasukan') {
        income += amount;
      } else {
        expense += amount;
      }
    }
    result.add(_MonthCashFlow(label, income, expense));
  }
  return result;
}

const _indonesianMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
