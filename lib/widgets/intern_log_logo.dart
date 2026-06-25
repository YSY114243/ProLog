import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared branded logo widget for InternLog.
///
/// Used consistently across the AppBar, Sidebar, Landing page, and Auth screen.
///
/// [light] — when true, renders text and icon in white (for gradient/dark backgrounds).
/// [size]  — controls overall scale: small ≈ sidebar, medium ≈ nav bar, large ≈ hero.
class InternLogLogo extends StatelessWidget {
  final bool light;
  final LogoSize _size;

  const InternLogLogo({
    super.key,
    this.light = false,
    LogoSize size = LogoSize.medium,
  }) : _size = size;

  const InternLogLogo.small({super.key, this.light = false}) : _size = LogoSize.small;
  const InternLogLogo.medium({super.key, this.light = false}) : _size = LogoSize.medium;
  const InternLogLogo.large({super.key, this.light = false}) : _size = LogoSize.large;

  @override
  Widget build(BuildContext context) {
    final primary   = light ? Colors.white : Theme.of(context).colorScheme.primary;
    final textColor = light ? Colors.white : Theme.of(context).colorScheme.onSurface;

    final double iconBoxSize;
    final double fontSize;
    final double subSize;
    final double spacing;
    final double borderRadius;

    switch (_size) {
      case LogoSize.small:
        iconBoxSize = 32; fontSize = 15;
        subSize = 9;  spacing = 8;  borderRadius = 8;
        break;
      case LogoSize.medium:
        iconBoxSize = 38; fontSize = 19;
        subSize = 10; spacing = 10; borderRadius = 10;
        break;
      case LogoSize.large:
        iconBoxSize = 52; fontSize = 26;
        subSize = 12; spacing = 13; borderRadius = 14;
        break;
    }


    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon badge
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              if (!light)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: iconBoxSize,
              height: iconBoxSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: spacing),

        // Word-mark
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Intern',
                    style: GoogleFonts.montserrat(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Log',
                    style: GoogleFonts.montserrat(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_size != LogoSize.small)
              Text(
                'Engineering Internship Tracker',
                style: GoogleFonts.inter(
                  fontSize: subSize,
                  fontWeight: FontWeight.w500,
                  color: light
                      ? Colors.white.withValues(alpha: 0.65)
                      : Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                  letterSpacing: 0.1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum LogoSize { small, medium, large }
