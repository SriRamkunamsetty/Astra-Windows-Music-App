import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// A user-selectable tint, the same set macOS offers as "Accent color".
/// [light] and [dark] are Apple's system colour values for each appearance.
@immutable
class AccentPalette {
  const AccentPalette(this.id, this.name, this.light, this.dark);
  final String id, name;
  final Color light, dark;
  Color of(bool dark) => dark ? this.dark : light;
}

const accents = <AccentPalette>[
  AccentPalette('red', 'Red', Color(0xFFFA233B), Color(0xFFFF5A6E)),
  AccentPalette('pink', 'Pink', Color(0xFFFF2D55), Color(0xFFFF375F)),
  AccentPalette('orange', 'Orange', Color(0xFFFF9500), Color(0xFFFF9F0A)),
  AccentPalette('yellow', 'Yellow', Color(0xFFFFCC00), Color(0xFFFFD60A)),
  AccentPalette('green', 'Green', Color(0xFF34C759), Color(0xFF30D158)),
  AccentPalette('blue', 'Blue', Color(0xFF007AFF), Color(0xFF0A84FF)),
  AccentPalette('purple', 'Purple', Color(0xFFAF52DE), Color(0xFFBF5AF2)),
  AccentPalette('graphite', 'Graphite', Color(0xFF8E8E93), Color(0xFF98989D)),
];

AccentPalette accentById(String id) => accents.firstWhere((p) => p.id == id, orElse: () => accents.first);

/// The Liquid Glass transparency setting runs 0–100. 60 is the default.
const double kDefaultGlass = 60;

/// Corner radius for cover art. Apple scales it with the artwork.
double artRadius(double size) => (size * .075).clamp(5.0, 22.0);

/// iOS system colours, the text-style scale and the Liquid Glass parameters
/// for one appearance + accent + transparency combination.
@immutable
class AstraTokens {
  const AstraTokens({
    required this.dark,
    required this.accentId,
    required this.glass,
    required this.accent,
    required this.bg,
    required this.groupedBg,
    required this.cell,
    required this.fill,
    required this.fillStrong,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.separator,
    required this.glassFill,
    required this.glassBlur,
    required this.glassEdgeHi,
    required this.glassEdgeLo,
    required this.glassShadow,
    required this.reduceTransparency,
    required this.reduceMotion,
  });

  factory AstraTokens.resolve({
    required bool dark,
    required String accentId,
    required double glass,
    required bool reduceTransparency,
    required bool reduceMotion,
  }) {
    final g = (glass.clamp(0, 100)) / 100;
    final rt = reduceTransparency;
    // More transparency = a lighter fill over the blur.
    final lightFill = rt ? 1.0 : 0.82 - 0.50 * g;
    final darkFill = rt ? 1.0 : 0.78 - 0.46 * g;
    return AstraTokens(
      dark: dark,
      accentId: accentId,
      glass: glass,
      accent: accentById(accentId).of(dark),
      bg: dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      groupedBg: dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      cell: dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      fill: dark ? const Color(0x3D787880) : const Color(0x1F787880),
      fillStrong: dark ? const Color(0x5C787880) : const Color(0x33787880),
      label: dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      secondary: dark ? const Color(0x99EBEBF5) : const Color(0x993C3C43),
      tertiary: dark ? const Color(0x4DEBEBF5) : const Color(0x4D3C3C43),
      separator: dark ? const Color(0xA6545458) : const Color(0x4A3C3C43),
      glassFill: dark
          ? const Color(0xFF3A3A3C).withValues(alpha: darkFill)
          : const Color(0xFFFFFFFF).withValues(alpha: lightFill),
      glassBlur: rt ? 0 : 12,
      glassEdgeHi: CupertinoColors.white.withValues(alpha: dark ? .34 : .95),
      glassEdgeLo: CupertinoColors.white.withValues(alpha: dark ? .06 : .35),
      glassShadow: CupertinoColors.black.withValues(alpha: dark ? .5 : .14),
      reduceTransparency: rt,
      reduceMotion: reduceMotion,
    );
  }

  final bool dark;
  final String accentId;
  final double glass;
  final Color accent;
  final Color bg, groupedBg, cell, fill, fillStrong;
  final Color label, secondary, tertiary, separator;
  final Color glassFill, glassEdgeHi, glassEdgeLo, glassShadow;
  final double glassBlur;
  final bool reduceTransparency, reduceMotion;

  Color get onAccent => const Color(0xFFFFFFFF);

  /// The same settings in the dark appearance (Now Playing is always dark).
  AstraTokens asDark() => dark
      ? this
      : AstraTokens.resolve(
          dark: true,
          accentId: accentId,
          glass: glass,
          reduceTransparency: reduceTransparency,
          reduceMotion: reduceMotion,
        );

  /// Background for a page that sits on the grouped (inset list) ground.
  Color get ground => groupedBg;

  Color accentTint(double alpha) => accent.withValues(alpha: alpha);

  // ---- Motion ------------------------------------------------------------
  /// Apple's sheet / navigation easing.
  static const Curve ease = Cubic(.32, .72, 0, 1);
  Duration get sheetDur => reduceMotion ? Duration.zero : const Duration(milliseconds: 460);
  Duration get fastDur => reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

  // ---- Type scale (iOS text styles) -----------------------------------------
  TextStyle get largeTitle => _s(34, FontWeight.w700, 41, .37);
  TextStyle get title1 => _s(28, FontWeight.w700, 34, .36);
  TextStyle get title2 => _s(22, FontWeight.w700, 28, .35);
  TextStyle get title3 => _s(20, FontWeight.w600, 25, .38);
  TextStyle get headline => _s(17, FontWeight.w600, 22, -.41);
  TextStyle get body => _s(17, FontWeight.w400, 22, -.41);
  TextStyle get callout => _s(16, FontWeight.w400, 21, -.32);
  TextStyle get subhead => _s(15, FontWeight.w400, 20, -.24);
  TextStyle get footnote => _s(13, FontWeight.w400, 18, -.08);
  TextStyle get caption1 => _s(12, FontWeight.w400, 16, 0);
  TextStyle get caption2 => _s(11, FontWeight.w400, 13, .07);

  /// The tab bar label: 10pt semibold.
  TextStyle get tabLabel => _s(10, FontWeight.w600, 12, .12);

  TextStyle _s(double size, FontWeight w, double lineHeight, double tracking) => TextStyle(
    fontFamily: _family(size),
    fontSize: size,
    fontWeight: w,
    height: lineHeight / size,
    letterSpacing: tracking,
    color: label,
    decoration: TextDecoration.none,
  );

  /// SF Pro on iOS (system font), Inter everywhere else.
  static String? _family(double size) {
    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      return size >= 20 ? '.SF Pro Display' : '.SF Pro Text';
    }
    return 'Inter';
  }

  CupertinoThemeData cupertinoTheme() => CupertinoThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    primaryColor: accent,
    scaffoldBackgroundColor: bg,
    barBackgroundColor: glassFill,
    textTheme: CupertinoTextThemeData(
      primaryColor: accent,
      textStyle: body,
      actionTextStyle: body.copyWith(color: accent),
      navTitleTextStyle: headline,
      navLargeTitleTextStyle: largeTitle,
    ),
  );
}

/// Hands the resolved tokens to every widget below it.
class AstraTheme extends InheritedWidget {
  const AstraTheme({super.key, required this.tokens, required super.child});
  final AstraTokens tokens;

  static AstraTokens of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AstraTheme>()!.tokens;

  @override
  bool updateShouldNotify(AstraTheme old) => !identical(tokens, old.tokens);
}

extension AstraContext on BuildContext {
  AstraTokens get tk => AstraTheme.of(this);
}
