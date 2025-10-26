import 'package:flutter/material.dart';

// Material 3 标准 Light 主题
final lightTheme = ThemeData.light(useMaterial3: true);
final ThemeData appThemeData = lightTheme.copyWith(
  extensions: [
    const AppThemeExtensions(
      statePass: Color(0xFF4A6B38),
      statePassContainer: Color(0xFFD1E3C8),
      statePassOnPrimary: Color(0xFFB8ED9B),
      stateFail: Color(0xFF7D5260),
      stateFailContainer: Color(0xFFFFD9E4),
      stateFailOnPrimary: Color(0xFFFFD9E4),
      exp: Color(0xFFF3B531),
      expContainer: Color(0xFFFBDC82),
      onExpContainer: Color(0xFFBF7308),
    ),
  ],
);

// Material 3 标准 Dark 主题
final darkTheme = ThemeData.dark(useMaterial3: true);
final ThemeData appDarkThemeData = darkTheme.copyWith(
  extensions: [
    const AppThemeExtensions(
      statePass: Color(0xFFD2F6BE),
      statePassContainer: Color(0xFF508635),
      statePassOnPrimary: Color(0xFF508036),
      stateFail: Color(0xFFF180A1),
      stateFailContainer: Color(0xFF6E3447),
      stateFailOnPrimary: Color(0xFFC7587C),
      exp: Color(0xFFBC8819),
      expContainer: Color(0xFF584614),
      onExpContainer: Color(0xFFDFBD8D),
    ),
  ],
);

class AppThemeExtensions extends ThemeExtension<AppThemeExtensions> {
  final Color? statePass;
  final Color? statePassContainer;
  final Color? statePassOnPrimary;
  final Color? stateFail;
  final Color? stateFailContainer;
  final Color? stateFailOnPrimary;
  final Color? exp;
  final Color? expContainer;
  final Color? onExpContainer;

  const AppThemeExtensions({
    this.statePass,
    this.statePassContainer,
    this.statePassOnPrimary,
    this.stateFail,
    this.stateFailContainer,
    this.stateFailOnPrimary,
    this.exp,
    this.expContainer,
    this.onExpContainer,
  });

  @override
  ThemeExtension<AppThemeExtensions> copyWith({
    Color? statePass,
    Color? statePassContainer,
    Color? statePassOnPrimary,
    Color? stateFail,
    Color? stateFailContainer,
    Color? stateFailOnPrimary,
    Color? exp,
    Color? expContainer,
    Color? onExpContainer,
  }) {
    return AppThemeExtensions(
      statePass: statePass ?? this.statePass,
      statePassContainer: statePassContainer ?? this.statePassContainer,
      statePassOnPrimary: statePassOnPrimary ?? this.statePassOnPrimary,
      stateFail: stateFail ?? this.stateFail,
      stateFailContainer: stateFailContainer ?? this.stateFailContainer,
      stateFailOnPrimary: stateFailOnPrimary ?? this.stateFailOnPrimary,
      exp: exp ?? this.exp,
      expContainer: expContainer ?? this.expContainer,
      onExpContainer: onExpContainer ?? this.onExpContainer,
    );
  }

  @override
  ThemeExtension<AppThemeExtensions> lerp(
    covariant AppThemeExtensions? other,
    double t,
  ) {
    if (other is! AppThemeExtensions) return this;
    return AppThemeExtensions(
      statePass: Color.lerp(statePass, other.statePass, t)!,
      statePassContainer: Color.lerp(
        statePassContainer,
        other.statePassContainer,
        t,
      )!,
      statePassOnPrimary: Color.lerp(
        statePassOnPrimary,
        other.statePassOnPrimary,
        t,
      )!,
      stateFail: Color.lerp(stateFail, other.stateFail, t)!,
      stateFailContainer: Color.lerp(
        stateFailContainer,
        other.stateFailContainer,
        t,
      )!,
      stateFailOnPrimary: Color.lerp(
        stateFailOnPrimary,
        other.stateFailOnPrimary,
        t,
      )!,
      exp: Color.lerp(exp, other.exp, t)!,
      expContainer: Color.lerp(expContainer, other.expContainer, t)!,
      onExpContainer: Color.lerp(onExpContainer, other.onExpContainer, t)!,
    );
  }
}
