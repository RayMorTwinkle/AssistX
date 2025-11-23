import 'package:flutter/material.dart';

/// 应用主题和设计令牌
class AppTheme {
  /// 响应式断点
  static const double breakpoint = 800;

  /// 颜色方案
  static const ColorScheme colorScheme = ColorScheme(
    primary: Color(0xFF4F46E5),
    primaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF10B981),
    secondaryContainer: Color(0xFFD1FAE5),
    surface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFF9FAFB), // 替代background
    error: Color(0xFFEF4444),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    onError: Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  /// 深色模式颜色方案
  static const ColorScheme darkColorScheme = ColorScheme(
    primary: Color(0xFF818CF8),
    primaryContainer: Color(0xFF312E81),
    secondary: Color(0xFF34D399),
    secondaryContainer: Color(0xFF065F46),
    surface: Color(0xFF111827),
    surfaceContainerHighest: Color(0xFF030712), // 替代background
    error: Color(0xFFF87171),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFFF3F4F6),
    onError: Color(0xFFFFFFFF),
    brightness: Brightness.dark,
  );

  /// 尺寸和间距
  static const EdgeInsets paddingXS = EdgeInsets.all(4);
  static const EdgeInsets paddingS = EdgeInsets.all(8);
  static const EdgeInsets paddingM = EdgeInsets.all(16);
  static const EdgeInsets paddingL = EdgeInsets.all(24);
  static const EdgeInsets paddingXL = EdgeInsets.all(32);

  /// 圆角
  static const double radiusS = 4;
  static const double radiusM = 8;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  /// 文本样式
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    )
  );

  /// 动画时长
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// 创建主题
  static ThemeData createTheme({bool isDarkMode = false}) {
    final scheme = isDarkMode ? darkColorScheme : colorScheme;

    return ThemeData(
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: scheme.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: paddingM,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: paddingM,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        contentPadding: paddingM,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: paddingS,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusL),
            topRight: Radius.circular(radiusL),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    );
  }

  /// 判断是否为大屏幕
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpoint;
  }

  /// 获取响应式容器宽度
  static double getResponsiveWidth(BuildContext context, {
    double? maxWidth,
    double? fraction,
  }) {
    final width = MediaQuery.of(context).size.width;
    final containerWidth = width >= breakpoint
        ? maxWidth ?? breakpoint
        : width;
    
    return fraction != null ? containerWidth * fraction : containerWidth;
  }
}