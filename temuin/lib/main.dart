import 'package:flutter/material.dart';

import 'barang_service.dart';
import 'draf.dart';
import 'halaman_utama.dart';
import 'tema.dart';

void main() {
  runApp(TemuinApp(service: BarangService(), penyimpananDraf: DrafSqlite()));
}

class TemuinApp extends StatelessWidget {
  const TemuinApp({super.key, required this.service, required this.penyimpananDraf});

  final BarangService service;
  final PenyimpananDraf penyimpananDraf;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temuin',
      debugShowCheckedModeBanner: false,
      theme: buatTema(Brightness.light),
      darkTheme: buatTema(Brightness.dark),
      themeMode: ThemeMode.system,
      home: HalamanUtama(service: service, penyimpananDraf: penyimpananDraf),
    );
  }
}
