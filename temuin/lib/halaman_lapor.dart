import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'barang.dart';
import 'barang_service.dart';
import 'draf.dart';
import 'kartu_barang.dart';

/// Pilihan pengguna saat menekan Kembali padahal isian belum dikirim.
enum _PilihanKeluar { simpanDraf, buang }

class HalamanLapor extends StatefulWidget {
  const HalamanLapor({
    super.key,
    required this.service,
    required this.penyimpananDraf,
    this.jenisAwal = 'Hilang',
  });

  final BarangService service;
  final PenyimpananDraf penyimpananDraf;
  final String jenisAwal;

  @override
  State<HalamanLapor> createState() => _HalamanLaporState();
}

class _HalamanLaporState extends State<HalamanLapor> {
  static const _kategori = [
    'Elektronik',
    'Dompet & Kartu',
    'Kunci',
    'Tas',
    'Buku & Alat Tulis',
    'Lainnya',
  ];
  static const _maksDeskripsi = 200;
  static const _maksDigitHp = 13;

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kontakController = TextEditingController();
  late String _jenis = widget.jenisAwal;
  String _kategoriDipilih = 'Elektronik';
  bool _tampilkanKontak = true;
  bool _mengirim = false;
  int? _idDraf; // terisi jika form berasal dari draf
  int _jumlahDraf = 0; // angka pada badge ikon draf
  bool _kotor = false; // true = ada isian yang belum dikirim / disimpan

  /// Pesan error per field dari server (respons 400).
  Map<String, dynamic> _salahServer = {};

  /// Isi field saat server menolaknya. Pesan server hanya ditampilkan selama isi
  /// field masih sama; begitu pengguna memperbaikinya, pesan hilang dengan sendirinya.
  final Map<String, String> _nilaiDitolak = {};

  @override
  void initState() {
    super.initState();
    _muatJumlahDraf();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  // ---------- Validasi di HP ----------
  String? _validasiNama(String? nilai) {
    final teks = nilai?.trim() ?? '';
    if (teks.isEmpty) return 'Nama barang wajib diisi';
    if (teks.length < 3) return 'Minimal 3 karakter';
    return _salahDariServer('nama', nilai);
  }

  String? _validasiLokasi(String? nilai) {
    if ((nilai?.trim() ?? '').isEmpty) return 'Lokasi wajib diisi';
    return _salahDariServer('lokasi', nilai);
  }

  String? _validasiDeskripsi(String? nilai) {
    if ((nilai?.trim().runes.length ?? 0) > _maksDeskripsi) {
      return 'Deskripsi maksimal $_maksDeskripsi karakter';
    }
    return _salahDariServer('deskripsi', nilai);
  }

  /// Nomor HP: angka saja, diawali 08, panjang 10-13 digit.
  String? _validasiKontak(String? nilai) {
    if (!_tampilkanKontak) return null;
    final angka = nilai?.trim() ?? '';
    if (angka.isEmpty) return 'Nomor HP wajib diisi';
    if (!RegExp(r'^\d+$').hasMatch(angka)) return 'Nomor HP hanya boleh berisi angka';
    if (!angka.startsWith('08')) return 'Nomor HP harus diawali 08';
    if (angka.length < 10 || angka.length > _maksDigitHp) return 'Nomor HP harus 10-13 digit';
    return _salahDariServer('kontak', angka);
  }

  String? _salahDariServer(String field, String? nilai) {
    final pesan = _salahServer[field];
    if (pesan is! String) return null;
    return (nilai ?? '').trim() == _nilaiDitolak[field] ? pesan : null;
  }

  String _teksField(String field) => switch (field) {
    'nama' => _namaController.text.trim(),
    'lokasi' => _lokasiController.text.trim(),
    'deskripsi' => _deskripsiController.text.trim(),
    'kontak' => _kontakController.text.trim(),
    _ => '',
  };

  // ---------- Kirim ke server ----------
  Future<void> _kirim() async {
    _salahServer = {};
    _nilaiDitolak.clear();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _mengirim = true);
    try {
      final hasil = await widget.service.kirim(
        Barang(
          id: 0, // diabaikan server
          nama: _namaController.text.trim(),
          jenis: _jenis,
          kategori: _kategoriDipilih,
          lokasi: _lokasiController.text.trim(),
          tanggal: DateTime.now(),
          deskripsi: _deskripsiController.text.trim(),
          pelapor: 'Saya',
          kontak: _tampilkanKontak ? _kontakController.text.trim() : '',
        ),
      );
      if (_idDraf != null) await widget.penyimpananDraf.hapus(_idDraf!);
      if (!mounted) return;
      _kotor = false;
      Navigator.pop(context, hasil);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _salahServer = e.detail;
        _nilaiDitolak
          ..clear()
          ..addAll({for (final field in e.detail.keys) field: _teksField(field)});
      });
      _formKey.currentState!.validate(); // tampilkan pesan dari server di bawah field
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.pesan)));
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  // ---------- Draf di SQLite ----------
  Future<void> _muatJumlahDraf() async {
    try {
      final daftar = await widget.penyimpananDraf.semua();
      if (!mounted) return;
      setState(() => _jumlahDraf = daftar.length);
    } catch (_) {
      // badge hanya pelengkap; jika database gagal dibuka, form tetap bisa dipakai
    }
  }

  Future<void> _simpanDraf() async {
    final id = await widget.penyimpananDraf.simpan(
      Draf(
        id: _idDraf,
        nama: _namaController.text.trim(),
        jenis: _jenis,
        kategori: _kategoriDipilih,
        lokasi: _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kontak: _tampilkanKontak ? _kontakController.text.trim() : '',
        dibuat: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _idDraf = id;
      _kotor = false;
    });
    _muatJumlahDraf();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Draf disimpan di HP')));
  }

  void _isiDariDraf(Draf d) {
    // controller diisi di luar setState: pengisian ini memicu Form.onChanged
    _namaController.text = d.nama;
    _lokasiController.text = d.lokasi;
    _deskripsiController.text = d.deskripsi;
    _kontakController.text = d.kontak;
    setState(() {
      _idDraf = d.id;
      _jenis = d.jenis;
      _kategoriDipilih = d.kategori;
      _tampilkanKontak = d.kontak.isNotEmpty;
      _kotor = false; // isian baru saja dimuat dari draf, belum ada yang diubah
    });
  }

  Future<void> _bukaDaftarDraf() async {
    final daftar = await widget.penyimpananDraf.semua();
    if (!mounted) return;
    int? idDihapus;
    final dipilih = await showModalBottomSheet<Draf>(
      context: context,
      showDragHandle: true,
      builder: (context) => daftar.isEmpty
          ? const SizedBox(height: 120, child: Center(child: Text('Belum ada draf')))
          : ListView(
              shrinkWrap: true,
              children: [
                for (final d in daftar)
                  ListTile(
                    leading: Icon(ikonKategori(d.kategori)),
                    title: Text(d.nama.isEmpty ? '(tanpa nama)' : d.nama),
                    subtitle: Text('${d.jenis} · ${formatTanggal(d.dibuat)}'),
                    trailing: IconButton(
                      tooltip: 'Hapus draf',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await widget.penyimpananDraf.hapus(d.id!);
                        idDihapus = d.id;
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    onTap: () => Navigator.pop(context, d),
                  ),
              ],
            ),
    );
    if (!mounted) return;
    // Jika draf yang sedang dibuka dihapus, form dianggap isian baru. Tanpa ini,
    // "Simpan sebagai draf" akan meng-update baris yang sudah tidak ada.
    if (idDihapus != null && idDihapus == _idDraf) setState(() => _idDraf = null);
    _muatJumlahDraf();
    if (dipilih != null) _isiDariDraf(dipilih);
  }

  // ---------- Keluar dari form ----------
  Future<_PilihanKeluar?> _tanyaKeluar() {
    return showDialog<_PilihanKeluar>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan isian sebagai draf?'),
        content: const Text(
          'Laporan ini belum dikirim. Jika keluar sekarang, isiannya akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _PilihanKeluar.buang),
            child: const Text('Buang'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Lanjut mengisi')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _PilihanKeluar.simpanDraf),
            child: const Text('Simpan draf'),
          ),
        ],
      ),
    );
  }

  Future<void> _saatKembali(bool sudahKeluar, Object? hasil) async {
    if (sudahKeluar) return;
    final pilihan = await _tanyaKeluar();
    if (!mounted || pilihan == null) return; // "Lanjut mengisi": tetap di form
    if (pilihan == _PilihanKeluar.simpanDraf) {
      await _simpanDraf();
      if (!mounted) return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // Jika ada isian yang belum aman, Kembali ditahan dulu dan pengguna ditanya.
      canPop: !_kotor,
      onPopInvokedWithResult: _saatKembali,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lapor Barang'),
          actions: [
            IconButton(
              tooltip: 'Draf tersimpan',
              onPressed: _bukaDaftarDraf,
              icon: Badge(
                isLabelVisible: _jumlahDraf > 0,
                label: Text('$_jumlahDraf'),
                child: const Icon(Icons.drafts_outlined),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          // setelah ada error, pesan diperbarui setiap kali pengguna mengetik
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          onChanged: () {
            if (!_kotor) setState(() => _kotor = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Hilang',
                    label: Text('Hilang'),
                    icon: Icon(Icons.search_off),
                  ),
                  ButtonSegment(
                    value: 'Ditemukan',
                    label: Text('Ditemukan'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_jenis},
                onSelectionChanged: (pilihan) => setState(() => _jenis = pilihan.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _validasiNama,
                decoration: const InputDecoration(
                  labelText: 'Nama barang *',
                  hintText: 'Contoh: Dompet cokelat',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lokasiController,
                textInputAction: TextInputAction.next,
                validator: _validasiLokasi,
                decoration: const InputDecoration(
                  labelText: 'Lokasi *',
                  hintText: 'Contoh: Perpustakaan lantai 2',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                maxLength: _maksDeskripsi,
                textCapitalization: TextCapitalization.sentences,
                validator: _validasiDeskripsi,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Ciri-ciri barang, warna, isi, dll.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Kategori'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final k in _kategori)
                    ChoiceChip(
                      label: Text(k),
                      selected: _kategoriDipilih == k,
                      onSelected: (_) => setState(() => _kategoriDipilih = k),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan nomor HP saya'),
                value: _tampilkanKontak,
                onChanged: (v) => setState(() {
                  _tampilkanKontak = v;
                  _kotor = true;
                }),
              ),
              // Kolom Nomor HP hanya ada selama saklar aktif, dengan animasi tinggi halus.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _tampilkanKontak
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: _kontakController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          // huruf, spasi, dan tanda hubung otomatis dibuang (juga saat paste)
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_maksDigitHp),
                          ],
                          validator: _validasiKontak,
                          decoration: const InputDecoration(
                            labelText: 'Nomor HP *',
                            hintText: 'Contoh: 081234567890',
                            helperText: '10-13 digit, diawali 08',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _mengirim ? null : _kirim,
                icon: _mengirim
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_mengirim ? 'Mengirim...' : 'Kirim Laporan'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _mengirim ? null : _simpanDraf,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan sebagai draf'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
