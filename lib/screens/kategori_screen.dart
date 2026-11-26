
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_helpers.dart';
import '../database/db_helper.dart';

const Color muted = Color(0xFF8491A8);
const Color borderColor = Color(0xFFE9EDF5);
const Color greenBg = Color(0xFFE7F5F0);
const Color redBg = Color(0xFFFFEEEE);
const Color redColor = Color(0xFFC34F54);

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  Future<void> form([Map<String, dynamic>? row]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryForm(row: row),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> deleteCategory(Map<String, dynamic> row) async {
    await _showDeleteDialog(
      context,
      row,
      () async {
        await DB.i.del(
          'kategori',
          'id_kategori',
          row['id_kategori'],
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: navy),
        ),
        title: const Text(
          'Kategori',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 38,
              height: 38,
              child: FilledButton(
                onPressed: () => form(),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Icon(Icons.add, size: 23),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: DB.i.all('kategori'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat kategori: ${snapshot.error}',
              ),
            );
          }

          final rows = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            children: [
              const Text(
                'Kelompokkan setiap transaksi',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori lebih rapi, laporan lebih jelas.',
                      style: TextStyle(
                        color: blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Atur kategori sesuai kebutuhan kas kelas.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              for (final type in ['Pemasukan', 'Pengeluaran']) ...[
                Builder(
                  builder: (context) {
                    final categoryRows = rows
                        .where((e) => e['jenis'] == type)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${categoryRows.length} kategori',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: categoryRows.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Text(
                                    'Belum ada kategori',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (int i = 0;
                                        i < categoryRows.length;
                                        i++) ...[
                                      _CategoryTile(
                                        row: categoryRows[i],
                                        isIncome: type == 'Pemasukan',
                                        onEdit: () => form(
                                          Map<String, dynamic>.from(
                                            categoryRows[i],
                                          ),
                                        ),
                                        onDelete: () => deleteCategory(
                                          Map<String, dynamic>.from(
                                            categoryRows[i],
                                          ),
                                        ),
                                      ),

                                      if (i != categoryRows.length - 1)
                                        const Divider(
                                          height: 1,
                                          color: borderColor,
                                        ),
                                    ],
                                  ],
                                ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ITEM KATEGORI

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isIncome;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.row,
    required this.isIncome,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: isIncome ? greenBg : redBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: isIncome ? green : redColor,
              size: 16,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: FutureBuilder(
              future: DB.i.tx(),
              builder: (context, snapshot) {
                final txRows = snapshot.data ?? [];

                final count = txRows.where((tx) {
                  return tx['id_kategori'] == row['id_kategori'];
                }).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['nama_kategori'],
                      style: const TextStyle(
                        color: navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count transaksi',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // TOMBOL EDIT
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              tooltip: 'Edit kategori',
              icon: SvgPicture.asset(
                'assets/icons/edit.svg',
                width: 23,
                height: 23,
              ),
            ),
          ),

          // TOMBOL HAPUS
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              tooltip: 'Hapus kategori',
              icon: SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 23,
                height: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FORM TAMBAH DAN EDIT KATEGORI

class CategoryForm extends StatefulWidget {
  final Map<String, dynamic>? row;

  const CategoryForm({super.key, this.row});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final name = TextEditingController();

  String type = 'Pemasukan';

  bool get isEdit => widget.row != null;

  @override
  void initState() {
    super.initState();

    if (widget.row != null) {
      name.text = widget.row!['nama_kategori'];
      type = widget.row!['jenis'];
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> deleteCurrentCategory() async {
    await _showDeleteDialog(
      context,
      widget.row!,
      () async {
        await DB.i.del(
          'kategori',
          'id_kategori',
          widget.row!['id_kategori'],
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'Pemasukan';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: navy),
        ),
        title: Text(
          isEdit ? 'Edit kategori' : 'Tambah kategori',
          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              children: [
                Text(
                  isEdit
                      ? 'Atur kategori transaksi.'
                      : 'Buat kategori sesuai kebutuhan.',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Pisahkan pemasukan dan pengeluaran.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Jenis kategori',
                  style: TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 9),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7ECF5),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      _TypeButton(
                        title: 'Pemasukan',
                        selected: isIncome,
                        icon: Icons.arrow_downward,
                        color: green,
                        onTap: () {
                          setState(() {
                            type = 'Pemasukan';
                          });
                        },
                      ),
                      _TypeButton(
                        title: 'Pengeluaran',
                        selected: !isIncome,
                        icon: Icons.arrow_upward,
                        color: const Color(0xFF71809B),
                        onTap: () {
                          setState(() {
                            type = 'Pengeluaran';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 27),

                const Text(
                  'Nama kategori',
                  style: TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 9),

                TextField(
                  controller: name,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama kategori',
                    hintStyle: const TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Gunakan nama yang singkat dan mudah dikenali.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 8,
                  ),
                ),

                const SizedBox(height: 27),

                const Text(
                  'Pratinjau kategori',
                  style: TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 9),

                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isIncome ? greenBg : redBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isIncome ? green : redColor,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.text.trim().isEmpty
                                  ? 'Nama kategori'
                                  : name.text,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori ${type.toLowerCase()}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (isEdit) ...[
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: deleteCurrentCategory,
                      icon: SvgPicture.asset(
                        'assets/icons/delete.svg',
                        width: 23,
                        height: 23,
                      ),
                      label: const Text(
                        'Hapus kategori',
                        style: TextStyle(
                          color: redColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: redBg,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // TOMBOL SIMPAN DI BAGIAN BAWAH
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 15),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 43,
              child: FilledButton.icon(
                onPressed: () async {
                  if (name.text.trim().isEmpty) {
                    msg(context, 'Nama kategori wajib diisi');
                    return;
                  }

                  final data = {
                    'nama_kategori': name.text.trim(),
                    'jenis': type,
                  };

                  if (widget.row == null) {
                    await DB.i.add('kategori', data);
                  } else {
                    await DB.i.edit(
                      'kategori',
                      'id_kategori',
                      widget.row!['id_kategori'],
                      data,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.check, size: 15),
                label: Text(
                  isEdit ? 'Simpan perubahan' : 'Simpan kategori',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TOMBOL JENIS KATEGORI

class _TypeButton extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.selected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? color : muted,
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DIALOG KONFIRMASI HAPUS

Future<void> _showDeleteDialog(
  BuildContext context,
  Map<String, dynamic> row,
  Future<void> Function() onDelete,
) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 29,
                height: 29,
              ),

              const SizedBox(height: 19),

              const Text(
                'Hapus kategori?',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Kategori ${row['nama_kategori']} akan dihapus dari daftar kategori.',
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await onDelete();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: redColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
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
}
