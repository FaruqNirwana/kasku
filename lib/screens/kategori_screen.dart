import 'package:flutter/material.dart';
import '../app_helpers.dart';
import '../database/db_helper.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});
  @override State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  Future<void> form([Map<String, dynamic>? row]) async {
    final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryForm(row: row)));
    if (ok == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kategori'), actions: [
      IconButton(onPressed: () => form(), icon: const Icon(Icons.add_circle, color: blue)),
    ]),
    body: FutureBuilder(future: DB.i.all('kategori'), builder: (context, snapshot) {
      final rows = snapshot.data ?? [];
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(18), children: [
        for (final type in ['Pemasukan', 'Pengeluaran']) ...[
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          card(Column(children: rows.where((e) => e['jenis'] == type).map((e) => ListTile(
            title: Text(e['nama_kategori']),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => form(e)),
          )).toList())),
          const SizedBox(height: 18),
        ],
      ]);
    }),
  );
}

class CategoryForm extends StatefulWidget{final Map<String,dynamic>? row;const CategoryForm({super.key,this.row});@override State<CategoryForm> createState()=>_CategoryFormState();}
class _CategoryFormState extends State<CategoryForm>{final name=TextEditingController();String type='Pemasukan';@override void initState(){super.initState();if(widget.row!=null){name.text=widget.row!['nama_kategori'];type=widget.row!['jenis'];}}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.row==null?'Tambah kategori':'Edit kategori')),body:ListView(padding:const EdgeInsets.all(18),children:[label('Jenis kategori'),Wrap(spacing:8,children:['Pemasukan','Pengeluaran'].map((v)=>ChoiceChip(label:Text(v),selected:type==v,onSelected:(_)=>setState(()=>type=v))).toList()),label('Nama kategori'),TextField(controller:name),const SizedBox(height:24),btn('Simpan kategori',()async{if(name.text.trim().isEmpty){msg(c,'Nama kategori wajib diisi');return;}final d={'nama_kategori':name.text.trim(),'jenis':type};if(widget.row==null)await DB.i.add('kategori',d);else await DB.i.edit('kategori','id_kategori',widget.row!['id_kategori'],d);if(c.mounted)Navigator.pop(c,true);}),if(widget.row!=null)TextButton(onPressed:()async{if(await confirm(c,'Hapus kategori?')){await DB.i.del('kategori','id_kategori',widget.row!['id_kategori']);if(c.mounted)Navigator.pop(c,true);}},child:const Text('Hapus kategori',style:TextStyle(color:red))) ]));}
