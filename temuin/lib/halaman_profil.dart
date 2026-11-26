import 'package:flutter/material.dart';

class HalamanProfil extends StatelessWidget {
  const HalamanProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          const Text(
            'Mahasiswa Telkom University',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Belum login', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _KotakStatistik(angka: '0', label: 'Laporan saya'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _KotakStatistik(angka: '0', label: 'Barang kembali'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Temuin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Temuin',
              applicationVersion: '1.0.0',
              children: const [Text('Hands-on Pengembangan Aplikasi Bergerak')],
            ),
          ),
        ],
      ),
    );
  }
}

class _KotakStatistik extends StatelessWidget {
  const _KotakStatistik({required this.angka, required this.label});

  final String angka;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(angka, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }
}
