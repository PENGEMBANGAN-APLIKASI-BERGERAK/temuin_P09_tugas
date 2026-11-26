import 'package:flutter/material.dart';

import 'barang.dart';
import 'tema.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String formatTanggal(DateTime t) => '${t.day} ${_bulan[t.month - 1]} ${t.year}';

IconData ikonKategori(String kategori) => switch (kategori) {
  'Elektronik' => Icons.devices_other,
  'Dompet & Kartu' => Icons.wallet,
  'Kunci' => Icons.key,
  'Tas' => Icons.backpack,
  'Buku & Alat Tulis' => Icons.menu_book,
  _ => Icons.category,
};

class KartuBarang extends StatelessWidget {
  const KartuBarang({super.key, required this.barang, this.onTap});

  final Barang barang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final status = Theme.of(context).extension<WarnaStatus>()!;
    final warnaJenis = barang.jenis == 'Hilang' ? status.hilang : status.ditemukan;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: skema.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ikonKategori(barang.kategori),
                      size: 28,
                      color: skema.onSurfaceVariant,
                    ),
                  ),
                  if (barang.selesai)
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Icon(Icons.check_circle, color: status.selesai, size: 22),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barang.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(barang.lokasi, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTanggal(barang.tanggal),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: warnaJenis.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  barang.jenis,
                  style: TextStyle(color: warnaJenis, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
