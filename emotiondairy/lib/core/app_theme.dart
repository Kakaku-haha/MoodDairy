import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFFBF6EF);
  static const backgroundDeep = Color(0xFFF7EDE3);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceWarm = Color(0xFFF9EEE4);
  static const primary = Color(0xFFB96F52);
  static const primaryDeep = Color(0xFF9C573E);
  static const primarySoft = Color(0xFFF4DFD3);
  static const peach = Color(0xFFE9B183);
  static const apricot = Color(0xFFF5D2B4);
  static const sage = Color(0xFF87937A);
  static const sageSoft = Color(0xFFE9EDE3);
  static const rose = Color(0xFFD99A8C);
  static const roseSoft = Color(0xFFF7E4DF);
  static const ink = Color(0xFF3F3631);
  static const inkSoft = Color(0xFF6E6159);
  static const muted = Color(0xFF97877C);
  static const line = Color(0xFFEDE2D6);
  static const white = Color(0xFFFFFEFC);
  static const warning = Color(0xFFB15D4F);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9E8D8), Color(0xFFF4D9CC), Color(0xFFF7E7DB)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC98363), Color(0xFFB36A4E)],
  );

  static const sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0F2E8), Color(0xFFE5EADB)],
  );
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x130F0906), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const lifted = [
    BoxShadow(color: Color(0x1A6E4A35), blurRadius: 36, offset: Offset(0, 16)),
  ];
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDeep,
    secondary: AppColors.sage,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.sageSoft,
    onSecondaryContainer: Color(0xFF4C5744),
    tertiary: AppColors.rose,
    onTertiary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.warning,
    onError: Colors.white,
    outline: AppColors.line,
    outlineVariant: Color(0xFFF2E8DE),
    shadow: Color(0xFF6E4A35),
    scrim: Color(0xFF2C211B),
  );

  final baseText = ThemeData.light().textTheme;
  final textTheme = baseText.copyWith(
    displayLarge: baseText.displayLarge?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.6,
      height: 1.05,
    ),
    displayMedium: baseText.displayMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.08,
    ),
    displaySmall: baseText.displaySmall?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.12,
    ),
    headlineLarge: baseText.headlineLarge?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.2,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.25,
    ),
    headlineSmall: baseText.headlineSmall?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleLarge: baseText.titleLarge?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleMedium: baseText.titleMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleSmall: baseText.titleSmall?.copyWith(
      color: AppColors.inkSoft,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    bodyLarge: baseText.bodyLarge?.copyWith(
      color: AppColors.ink,
      height: 1.65,
      letterSpacing: 0.1,
    ),
    bodyMedium: baseText.bodyMedium?.copyWith(
      color: AppColors.inkSoft,
      height: 1.6,
      letterSpacing: 0.1,
    ),
    bodySmall: baseText.bodySmall?.copyWith(
      color: AppColors.muted,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    labelLarge: baseText.labelLarge?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: baseText.labelMedium?.copyWith(
      color: AppColors.inkSoft,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
    labelSmall: baseText.labelSmall?.copyWith(
      color: AppColors.muted,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primarySoft,
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.inkSoft,
        highlightColor: AppColors.primarySoft,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAF4ED),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF0E5D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF0E5D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.peach, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      modalBarrierColor: Color(0x663A2A21),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceWarm,
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: Colors.transparent),
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.primaryDeep,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
