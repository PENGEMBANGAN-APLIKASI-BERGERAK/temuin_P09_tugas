# Temuin P9 - Tugas + Inovasi

Isi ZIP: `temuin/` (aplikasi Flutter) dan `temuin_api/` (server Dart). Keduanya melanjutkan
`temuin_P09_selesai.zip` dan `temuin_api_P09.zip`.

## Tugas dasar

| No. | Permintaan | Letak kode |
|---|---|---|
| 1 | Server: deskripsi maks. 200 karakter, kontak (jika diisi) diawali 08, uji dengan curl | `temuin_api/lib/validasi.dart`, `temuin_api/uji_curl.sh` / `.ps1` |
| 2 | Kolom Nomor HP muncul hanya saat saklar aktif; validator angka, diawali 08, 10-13 digit; dikirim sebagai `kontak` | `temuin/lib/halaman_lapor.dart` (`_validasiKontak`, `AnimatedSize`) |
| 3 | Badge jumlah draf pada ikon draf | `temuin/lib/halaman_lapor.dart` (`Badge`, `_muatJumlahDraf`) |
| 4 | Screenshot + log `POST [201]` dan `POST [400]` | lihat "Cara mengambil bukti" di bawah |

## Inovasi

1. **Tanya sebelum keluar.** Menekan Kembali saat ada isian yang belum dikirim memunculkan dialog
   Simpan draf / Buang / Lanjut mengisi (`PopScope`). Masalah nyatanya: sinyal di kampus sering buruk,
   dan isian yang sudah diketik tidak boleh hilang hanya karena salah tekan.
2. **Nomor HP ikut tersimpan di draf.** Tabel SQLite naik ke versi 2 dengan `onUpgrade`
   (`ALTER TABLE ... ADD COLUMN kontak`), sehingga draf lama di HP tidak rusak.
3. **Pesan error server tidak menempel.** Di versi hands-on, pesan 400 tetap tampil walau pengguna
   sudah memperbaiki isiannya. Sekarang pesan hanya tampil selama isi field masih sama dengan yang ditolak.
4. **Perbaikan bug draf.** Jika draf yang sedang dibuka dihapus lewat daftar draf, tombol
   "Simpan sebagai draf" tidak lagi meng-update baris yang sudah tidak ada.
5. **Nomor HP dinormalkan di server.** `0812-3456-7890` disimpan sebagai `081234567890`, dan validasi
   dipisah ke `validasi.dart` agar bisa diuji tanpa menjalankan server.
6. Kolom Nomor HP otomatis membuang huruf/spasi/tanda hubung (juga saat paste) dan dibatasi 13 digit.

Catatan keputusan: saat saklar "Tampilkan nomor HP saya" aktif, nomor HP **wajib** diisi (kalau tidak,
saklar aktif tapi tidak ada nomor yang ditampilkan). Matikan saklar jika tidak ingin menampilkan nomor.

## Cara menjalankan

```bash
# Server
cd temuin_api
dart pub get
dart test
dart run bin/server.dart          # tambahkan --lambat untuk melihat tombol "Mengirim..."

# Aplikasi
cd temuin
flutter pub get
flutter test                      # 17 test
adb reverse tcp:8080 tcp:8080
flutter run
```

Jika sudah pernah menjalankan versi P9 sebelumnya di HP, tidak perlu uninstall: migrasi database
v1 ke v2 berjalan otomatis.

## Cara mengambil bukti (tugas no. 4)

1. Jalankan server, lalu di terminal lain `bash uji_curl.sh` (Windows: `.\uji_curl.ps1`).
   Log server akan menampilkan `POST [400] /api/barang` (kasus 1-4) dan `POST [201] /api/barang` (kasus 5-6).
2. Screenshot validasi: buka form, tekan Kirim Laporan tanpa isian; ketik `0712345678` pada Nomor HP.
3. Screenshot terkirim: isi form valid, kirim, lalu ambil layar beranda dengan snackbar "terkirim (id ...)".
4. Screenshot draf: simpan 2 draf, buka form lagi; badge menunjukkan angka 2, lalu buka daftar draf.
