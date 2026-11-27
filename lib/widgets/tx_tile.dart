
import 'package:flutter/material.dart';
import '../app_helpers.dart';

class TxTile extends StatelessWidget {
  final Map<String, dynamic> row;

  const TxTile(this.row, {super.key});

  @override
  Widget build(BuildContext context) {
    final pemasukan = row['jenis'] == 'Pemasukan';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: pemasukan
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          pemasukan ? Icons.arrow_downward : Icons.arrow_upward,
          color: pemasukan ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        row['nama_kategori'] ?? 'Transaksi',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${row['tanggal'] ?? ''} • ${row['keterangan'] ?? ''}',
      ),
      trailing: Text(
        '${pemasukan ? '+' : '-'}${money.format((row['jumlah'] as num).toDouble())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: pemasukan ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
