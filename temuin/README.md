# Temuin - Flutter Client

Aplikasi mobile pelaporan barang hilang dan ditemukan menggunakan Flutter & Material Design 3. Terhubung ke backend REST API (`temuin_api`) dan database lokal SQLite (`sqflite`).

Dokumentasi lengkap, arsitektur, tangkapan layar, dan panduan menjalankan seluruh proyek dapat dilihat pada **[README Utama Proyek](../README.md)**.

## Cara Menjalankan

```bash
flutter pub get
adb reverse tcp:8080 tcp:8080
flutter run
```

## Menjalankan Test

```bash
flutter test
```
