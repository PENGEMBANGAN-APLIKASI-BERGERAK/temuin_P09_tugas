import 'package:flutter/material.dart';

import 'barang.dart';
import 'barang_service.dart';
import 'draf.dart';
import 'halaman_beranda.dart';
import 'halaman_lapor.dart';
import 'halaman_profil.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key, required this.service, required this.penyimpananDraf});

  final BarangService service;
  final PenyimpananDraf penyimpananDraf;

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  int _indeks = 0;
  late Future<List<Barang>> _futureDaftar = widget.service.ambilSemua();

  void _muatUlang() {
    setState(() {
      _futureDaftar = widget.service.ambilSemua();
    });
  }

  Future<void> _bukaLapor() async {
    final baru = await Navigator.push<Barang>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HalamanLapor(service: widget.service, penyimpananDraf: widget.penyimpananDraf),
      ),
    );
    if (baru == null || !mounted) return;

    _muatUlang(); // ambil ulang daftar dari server, laporan baru ikut muncul
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Laporan "${baru.nama}" terkirim (id ${baru.id})')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indeks,
        children: [
          HalamanBeranda(futureDaftar: _futureDaftar, onMuatUlang: _muatUlang),
          const HalamanProfil(),
        ],
      ),
      floatingActionButton: _indeks == 0
          ? FloatingActionButton.extended(
              onPressed: _bukaLapor,
              icon: const Icon(Icons.add),
              label: const Text('Lapor'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: (i) => setState(() => _indeks = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
