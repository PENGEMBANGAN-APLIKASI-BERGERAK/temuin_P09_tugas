import 'package:flutter/material.dart';

import 'barang.dart';
import 'kartu_barang.dart';
import 'tema.dart';

class HalamanDetail extends StatelessWidget {
  const HalamanDetail({super.key, required this.barang});

  final Barang barang;

  @override
  Widget build(BuildContext context) {
    final hilang = barang.jenis == 'Hilang';
    final skema = Theme.of(context).colorScheme;
    final status = Theme.of(context).extension<WarnaStatus>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: skema.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(ikonKategori(barang.kategori), size: 72, color: skema.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  hilang ? Icons.search_off : Icons.check_circle_outline,
                  size: 18,
                  color: hilang ? status.hilang : status.ditemukan,
                ),
                label: Text(barang.jenis),
              ),
              Chip(label: Text(barang.kategori)),
              if (barang.selesai)
                Chip(
                  avatar: Icon(Icons.verified, size: 18, color: status.selesai),
                  label: const Text('Sudah kembali'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            barang.nama,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _BarisInfo(ikon: Icons.place_outlined, label: 'Lokasi', isi: barang.lokasi),
          _BarisInfo(ikon: Icons.event, label: 'Tanggal', isi: formatTanggal(barang.tanggal)),
          _BarisInfo(ikon: Icons.person_outline, label: 'Pelapor', isi: barang.pelapor),
          const Divider(height: 32),
          const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(barang.deskripsi.isEmpty ? '-' : barang.deskripsi),
          const SizedBox(height: 24),
          if (barang.kontak.isNotEmpty && !barang.selesai)
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hubungi ${barang.pelapor}: ${barang.kontak}')),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Hubungi pelapor'),
            ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.ikon, required this.label, required this.isi});

  final IconData ikon;
  final String label;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ikon, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: Text(isi, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
