# Temuin API

REST API sederhana untuk hands-on Pengembangan Aplikasi Bergerak (studi kasus Temuin).

```bash
dart pub get
dart run bin/server.dart            # port 8080
dart run bin/server.dart --lambat   # setiap respons ditunda 1,5 detik (uji loading)
```

HP Android lewat kabel USB: jalankan `adb reverse tcp:8080 tcp:8080`, lalu aplikasi memakai `http://127.0.0.1:8080`.

Data disimpan di `data/barang.json` (dibuat otomatis dari `data/seed.json`). Hapus file itu untuk mengembalikan data awal.

| Metode | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/barang` | Daftar semua laporan |
| GET | `/api/barang/{id}` | Satu laporan |
| POST | `/api/barang` | Tambah laporan (body JSON: nama, jenis, kategori, lokasi, deskripsi, pelapor, kontak) |

### Aturan validasi POST (lib/validasi.dart)

| Field | Aturan | Kode error |
|---|---|---|
| `nama` | minimal 3 karakter | 400 |
| `jenis` | `Hilang` atau `Ditemukan` | 400 |
| `kategori`, `lokasi` | wajib diisi | 400 |
| `deskripsi` | maksimal 200 karakter | 400 |
| `kontak` | boleh kosong; jika diisi: angka saja, diawali `08`, 10-13 digit | 400 |

Spasi dan tanda hubung pada `kontak` dibuang otomatis, jadi `0812-3456-7890` tersimpan sebagai `081234567890`.

### Menguji

```bash
dart test             # uji aturan validasi dan penyimpanan
bash uji_curl.sh      # 6 permintaan curl: 4 x 400 dan 2 x 201 (Windows: .\uji_curl.ps1)
```

