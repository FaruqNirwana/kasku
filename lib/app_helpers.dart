import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const navy = Color(0xFF142B55);
const blue = Color(0xFF3266D8);
const bg = Color(0xFFF4F6FB);
const green = Color(0xFF25A56A);
const red = Color(0xFFD95762);
final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

Widget heading(String title, String sub, {Widget? action}) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
  child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: navy)),
      Text(sub, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
    ])),
    if (action != null) action,
  ]),
);

Widget card(Widget child) => Container(
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
    boxShadow: [BoxShadow(color: navy.withOpacity(.035), blurRadius: 14, offset: const Offset(0, 4))]),
  child: child,
);

Widget label(String s) => Padding(
  padding: const EdgeInsets.only(top: 18, bottom: 8),
  child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, color: navy, fontSize: 13)),
);

Widget btn(String s, VoidCallback f) => SizedBox(
  height: 49, child: FilledButton(onPressed: f,
    style: FilledButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
    child: Text(s)),
);

void msg(BuildContext c, String s) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

Future<bool> confirm(BuildContext c, String s) async => await showDialog<bool>(
  context: c, builder: (x) => AlertDialog(title: Text(s),
    content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('Batal')),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: red), onPressed: () => Navigator.pop(x, true), child: const Text('Hapus')),
    ])) ?? false;
