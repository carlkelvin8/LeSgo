import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const Color brand = Color(0xFF5F2D82);
  static const Color brandDark = Color(0xFFD9B5F5);

  static final light = _buildLight();
  static final dark = _buildDark();

  static ThemeData _buildLight() {
    final colors = ColorScheme.fromSeed(seedColor: brand);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'TT Fors',
      colorScheme: colors,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.white,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F4F7),
        hintStyle: TextStyle(color: colors.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F4F7),
        selectedColor: brand.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          color: colors.onSurface,
        ),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: colors.outline,
        indicatorColor: brand,
        indicator: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(8),
        ),
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'TT Fors'),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : colors.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brand : colors.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(fontFamily: 'TT Fors', color: colors.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          color: colors.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: colors.onSurfaceVariant,
        collapsedIconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        collapsedTextColor: colors.onSurface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(fontFamily: 'TT Fors', color: colors.onInverseSurface, fontSize: 12),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: brand,
        textColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brand : colors.surfaceContainerHighest),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brand : colors.outline),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F4F7),
          selectedBackgroundColor: brand,
          selectedForegroundColor: Colors.white,
          foregroundColor: colors.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: brand.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? brand : colors.onSurfaceVariant,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? brand : colors.onSurfaceVariant,
        )),
      ),
    );
  }

  static ThemeData _buildDark() {
    final colors = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: brandDark,
      onPrimary: const Color(0xFF35134D),
      surface: const Color(0xFF151219),
      surfaceContainerLow: const Color(0xFF201B26),
      surfaceContainer: const Color(0xFF261F2D),
      surfaceContainerHigh: const Color(0xFF302737),
      surfaceContainerHighest: const Color(0xFF3B3142),
      onSurface: const Color(0xFFF2EDF5),
      onSurfaceVariant: const Color(0xFFCEC4D5),
      outline: const Color(0xFF9A8FA8),
      outlineVariant: const Color(0xFF4E4358),
      secondaryContainer: const Color(0xFF3B3142),
      onSecondaryContainer: const Color(0xFFCEC4D5),
      error: const Color(0xFFCF6679),
      onError: const Color(0xFF601410),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'TT Fors',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surfaceContainerLow,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brandDark, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: brandDark.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          color: colors.onSurface,
        ),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF35134D),
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: brandDark,
        indicator: BoxDecoration(
          color: brandDark,
          borderRadius: BorderRadius.circular(8),
        ),
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'TT Fors'),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? const Color(0xFF35134D) : colors.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brandDark : colors.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(fontFamily: 'TT Fors', color: colors.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          color: colors.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brandDark),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandDark,
          foregroundColor: const Color(0xFF35134D),
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandDark,
          foregroundColor: const Color(0xFF35134D),
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandDark,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandDark,
          textStyle: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: colors.onSurfaceVariant,
        collapsedIconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        collapsedTextColor: colors.onSurface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(fontFamily: 'TT Fors', color: colors.onInverseSurface, fontSize: 12),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: brandDark,
        textColor: const Color(0xFF35134D),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brandDark : colors.surfaceContainerHighest),
        checkColor: WidgetStateProperty.all(const Color(0xFF35134D)),
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brandDark : colors.outline),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.surfaceContainerLow,
          selectedBackgroundColor: brandDark,
          selectedForegroundColor: const Color(0xFF35134D),
          foregroundColor: colors.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: brandDark.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? brandDark : colors.onSurfaceVariant,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? brandDark : colors.onSurfaceVariant,
        )),
      ),
    );
  }
}
