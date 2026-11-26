import 'package:flutter/material.dart';

const warnaKampus = Color(0xFFB6252A);

/// Warna tambahan khusus Temuin yang tidak ada di ColorScheme bawaan.
@immutable
class WarnaStatus extends ThemeExtension<WarnaStatus> {
  const WarnaStatus({required this.hilang, required this.ditemukan, required this.selesai});

  final Color hilang;
  final Color ditemukan;
  final Color selesai;

  static const terang = WarnaStatus(
    hilang: Color(0xFFC62828),
    ditemukan: Color(0xFF2E7D32),
    selesai: Color(0xFF2E7D32),
  );

  static const gelap = WarnaStatus(
    hilang: Color(0xFFFF8A80),
    ditemukan: Color(0xFF81C784),
    selesai: Color(0xFF81C784),
  );

  @override
  WarnaStatus copyWith({Color? hilang, Color? ditemukan, Color? selesai}) => WarnaStatus(
    hilang: hilang ?? this.hilang,
    ditemukan: ditemukan ?? this.ditemukan,
    selesai: selesai ?? this.selesai,
  );

  @override
  WarnaStatus lerp(WarnaStatus? other, double t) {
    if (other == null) return this;
    return WarnaStatus(
      hilang: Color.lerp(hilang, other.hilang, t)!,
      ditemukan: Color.lerp(ditemukan, other.ditemukan, t)!,
      selesai: Color.lerp(selesai, other.selesai, t)!,
    );
  }
}

ThemeData buatTema(Brightness brightness) {
  final skema = ColorScheme.fromSeed(
    seedColor: warnaKampus,
    brightness: brightness,
    // fidelity: warna utama tetap dekat dengan merah kampus (bukan versi pastel)
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  return ThemeData(
    colorScheme: skema,
    fontFamily: 'Poppins',
    extensions: [brightness == Brightness.light ? WarnaStatus.terang : WarnaStatus.gelap],
    appBarTheme: AppBarTheme(
      backgroundColor: skema.surface,
      foregroundColor: skema.onSurface,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: skema.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: skema.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: skema.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: skema.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: const ChipThemeData(shape: StadiumBorder()),
  );
}
