import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class BankColors {
  static const background = Color(0xFF090B0F);
  static const surface = Color(0xFF181B22);
  static const raised = Color(0xFF222630);
  static const border = Color(0xFF343A46);
  static const text = Color(0xFFF5F6F8);
  static const muted = Color(0xFFB0B7C5);
  static const blue = Color(0xFF8EBBFF);
  static const brandBlue = Color(0xFF1677FF);
  static const success = Color(0xFF82DFB1);
  static const danger = Color(0xFFFFA4AE);
  static const warning = Color(0xFFF6CF87);
}

abstract final class BankTheme {
  static const numbers = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: BankColors.text,
        onPrimary: BankColors.background,
        secondary: BankColors.blue,
        onSecondary: BankColors.background,
        surface: BankColors.surface,
        onSurface: BankColors.text,
        error: BankColors.danger,
        onError: BankColors.background,
        outline: BankColors.border,
      ),
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: BankColors.border),
    );
    return base.copyWith(
      scaffoldBackgroundColor: BankColors.background,
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.8,
          color: BankColors.text,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -0.4,
          color: BankColors.text,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: BankColors.text,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: BankColors.text,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: BankColors.text,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: BankColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BankColors.background,
        foregroundColor: BankColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: BankColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: BankColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BankColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: outline,
        enabledBorder: outline,
        disabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: BankColors.blue, width: 2),
        ),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: BankColors.danger),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: const BorderSide(color: BankColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(color: BankColors.muted),
        floatingLabelStyle: const TextStyle(color: BankColors.blue),
        helperStyle: const TextStyle(color: BankColors.muted),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BankColors.text,
          foregroundColor: BankColors.background,
          disabledBackgroundColor: BankColors.raised,
          disabledForegroundColor: BankColors.muted,
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BankColors.text,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: BankColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BankColors.blue,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: BankColors.text,
          minimumSize: const Size(48, 48),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BankColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BankColors.raised,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? BankColors.text
                : BankColors.muted,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? BankColors.text
                : BankColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BankColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BankColors.raised,
        contentTextStyle: TextStyle(color: BankColors.text),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: BankColors.border,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
