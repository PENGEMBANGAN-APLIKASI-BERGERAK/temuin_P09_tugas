import 'package:flutter/material.dart';

import 'barang.dart';
import 'halaman_detail.dart';
import 'kartu_barang.dart';

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key, required this.futureDaftar, required this.onMuatUlang});

  final Future<List<Barang>> futureDaftar;
  final VoidCallback onMuatUlang;

  void _bukaDetail(BuildContext context, Barang barang) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetail(barang: barang)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temuin'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: onMuatUlang,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Image.asset('assets/images/logo_temuin.png', height: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari barang...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Barang>>(
              future: futureDaftar,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _PesanError(pesan: '${snapshot.error}', onCobaLagi: onMuatUlang);
                }

                final daftar = snapshot.data!;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Laporan terbaru',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text('${daftar.length} laporan'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                        itemCount: daftar.length,
                        itemBuilder: (context, index) {
                          final barang = daftar[index];
                          return KartuBarang(
                            barang: barang,
                            onTap: () => _bukaDetail(context, barang),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PesanError extends StatelessWidget {
  const _PesanError({required this.pesan, required this.onCobaLagi});

  final String pesan;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCobaLagi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
