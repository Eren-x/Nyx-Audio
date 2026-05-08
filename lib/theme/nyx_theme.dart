import 'package:flutter/material.dart';

class NyxColors {
  // Backgrounds
  static const bg = Color(0xFF08070F);
  static const surface = Color(0xFF0F0F1A);
  static const surfaceAlt = Color(0xFF0D0D18);
  static const border = Color(0xFF1E1230);
  static const borderBright = Color(0xFF2A1A4A);

  // Purple palette
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryText = Color(0xFFC4A8FF);
  static const primaryDim = Color(0xFF1A0F35);
  static const primaryDimmer = Color(0xFF120C30);

  // Text
  static const textPrimary = Color(0xFFE8D8FF);
  static const textSecondary = Color(0xFF7A6A9A);
  static const textMuted = Color(0xFF5A4A7A);
  static const textGhost = Color(0xFF3A2A5A);

  // Status
  static const success = Color(0xFF4ADE80);
  static const successBg = Color(0xFF0F2A1A);
  static const error = Color(0xFFFF6B6B);
  static const errorBg = Color(0xFF2A0F0F);
  static const warning = Color(0xFFFBBF24);
}

class NyxTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NyxColors.bg,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: NyxColors.primary,
          onPrimary: Colors.white,
          secondary: NyxColors.primaryLight,
          onSecondary: Colors.white,
          surface: NyxColors.surface,
          onSurface: NyxColors.textPrimary,
          error: NyxColors.error,
          outline: NyxColors.border,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: NyxColors.textPrimary,
            letterSpacing: 0.5,
          ),
          displayMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: NyxColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: NyxColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: NyxColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: NyxColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: NyxColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: NyxColors.textMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: NyxColors.textMuted,
            letterSpacing: 0.12,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: NyxColors.border,
          thickness: 0.5,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: NyxColors.surfaceAlt,
          selectedIconTheme: const IconThemeData(color: NyxColors.primaryText),
          unselectedIconTheme:
              const IconThemeData(color: NyxColors.textSecondary),
          selectedLabelTextStyle: const TextStyle(
            color: NyxColors.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: NyxColors.textSecondary,
            fontSize: 12,
          ),
          indicatorColor: NyxColors.primaryDim,
          elevation: 0,
          minWidth: 170,
          minExtendedWidth: 170,
          groupAlignment: -1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: NyxColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: NyxColors.borderBright, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: NyxColors.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: NyxColors.primary, width: 1),
          ),
          hintStyle: const TextStyle(color: NyxColors.textGhost, fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NyxColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: NyxColors.primaryText,
            side: const BorderSide(color: NyxColors.borderBright, width: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: CardThemeData(
          color: NyxColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: NyxColors.border, width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          selectedTileColor: NyxColors.primaryDim,
          iconColor: NyxColors.textSecondary,
          textColor: NyxColors.textPrimary,
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: NyxColors.surface,
          contentTextStyle: const TextStyle(color: NyxColors.textPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: NyxColors.borderBright, width: 0.5)),
          behavior: SnackBarBehavior.floating,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(NyxColors.borderBright),
          trackColor: WidgetStateProperty.all(Colors.transparent),
        ),
      );
}

// Reusable style helpers
class NyxText {
  static const heading = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: NyxColors.textPrimary,
  );

  static const subheading = TextStyle(
    fontSize: 11,
    color: NyxColors.textMuted,
    letterSpacing: 0.1,
  );

  static const sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: NyxColors.textMuted,
    letterSpacing: 0.12,
  );

  static const trackTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: NyxColors.primaryText,
  );

  static const trackArtist = TextStyle(
    fontSize: 11,
    color: NyxColors.textMuted,
  );
}

// Reusable pill/badge widget
class NyxPill extends StatelessWidget {
  final String label;
  final NyxPillStyle style;

  const NyxPill(this.label, {super.key, this.style = NyxPillStyle.purple});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (style) {
      case NyxPillStyle.green:
        bg = NyxColors.successBg;
        fg = NyxColors.success;
        border = const Color(0xFF1A4A2A);
      case NyxPillStyle.gray:
        bg = const Color(0xFF15151F);
        fg = NyxColors.textMuted;
        border = NyxColors.border;
      case NyxPillStyle.purple:
        bg = NyxColors.primaryDim;
        fg = NyxColors.primaryText;
        border = NyxColors.borderBright;
      case NyxPillStyle.red:
        bg = NyxColors.errorBg;
        fg = NyxColors.error;
        border = const Color(0xFF4A1A1A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

enum NyxPillStyle { green, gray, purple, red }
