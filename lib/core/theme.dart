import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFFEF9F3); // Krem hangat
  static const Color primary = Color(0xFFEA580C);    // Oranye
  static const Color accent = Color(0xFFFACC15);     // Kuning cerah
  static const Color surface = Color(0xFFFFFFFF);    // Surface/Card
  static const Color border = Color(0xFF18181B);     // Border hitam #18181B
  static const Color ink = Color(0xFF18181B);
  static const Color textMuted = Color(0xFF71717A);  // Abu-abu teks
  static const Color green = Color(0xFF16A34A);      // Status buka / ready
  static const Color greenLight = Color(0xFFDCFCE7); // Background status ready
  static const Color red = Color(0xFFDC2626);        // Status tutup
}

// Aliases for convenience & compatibility
const Color cream = AppColors.background;
const Color orange = AppColors.primary;
const Color yellow = AppColors.accent;
const Color ink = AppColors.border;

final ThemeData neoTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: AppColors.border,
    error: AppColors.red,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.border,
  ),
  textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.border,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: GoogleFonts.plusJakartaSans(
      color: AppColors.border,
      fontSize: 20,
      fontWeight: FontWeight.w900,
    ),
  ),
);

class NeoBrutalistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final double borderRadius;
  final Offset shadowOffset;
  final double borderWidth;

  const NeoBrutalistCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = AppColors.surface,
    this.onTap,
    this.borderRadius = 12.0,
    this.shadowOffset = const Offset(3, 3),
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.border, width: borderWidth),
      boxShadow: shadowOffset == Offset.zero
          ? null
          : [
              BoxShadow(
                color: AppColors.border,
                offset: shadowOffset,
                blurRadius: 0,
              ),
            ],
    );

    if (onTap != null) {
      return Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

class NeoBrutalistBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const NeoBrutalistBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.fontSize = 9.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    this.borderRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor ?? AppColors.border,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class NeoBrutalistButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final double borderRadius;

  const NeoBrutalistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.textColor,
    this.icon,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.isFullWidth = true,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ??
        (color == AppColors.accent ? AppColors.border : Colors.white);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize + 4, color: effectiveTextColor),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    final buttonWidget = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
