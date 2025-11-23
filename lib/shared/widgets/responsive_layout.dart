import 'package:flutter/material.dart';
import 'package:assistx/shared/themes/app_theme.dart';

/// 响应式布局组件
class ResponsiveLayout extends StatelessWidget {
  /// 小屏幕布局（<800px）
  final Widget mobileLayout;

  /// 大屏幕布局（>=800px）
  final Widget tabletLayout;

  /// 是否居中显示内容
  final bool centered;

  /// 最大内容宽度
  final double? maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    this.centered = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = AppTheme.isLargeScreen(context);
        final currentLayout = isLargeScreen ? tabletLayout : mobileLayout;

        if (centered) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.getResponsiveWidth(context, maxWidth: maxWidth),
              ),
              child: currentLayout,
            ),
          );
        }

        return currentLayout;
      },
    );
  }
}

/// 响应式网格容器
class ResponsiveGrid extends StatelessWidget {
  /// 子组件列表
  final List<Widget> children;

  /// 小屏幕列数
  final int mobileColumns;

  /// 大屏幕列数
  final int tabletColumns;

  /// 子组件之间的间距
  final double spacing;

  /// 是否居中显示
  final bool centered;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.spacing = 16,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);
    final columns = isLargeScreen ? tabletColumns : mobileColumns;

    final gridLayout = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

    if (centered) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.getResponsiveWidth(context),
          ),
          child: gridLayout,
        ),
      );
    }

    return gridLayout;
  }
}

/// 响应式行布局
class ResponsiveRow extends StatelessWidget {
  /// 小屏幕布局（垂直排列）
  final Widget mobileLayout;

  /// 大屏幕布局（水平排列）
  final Widget tabletLayout;

  /// 对齐方式
  final CrossAxisAlignment crossAxisAlignment;

  /// 主轴对齐方式
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);
    
    return isLargeScreen ? tabletLayout : mobileLayout;
  }
}

/// 响应式卡片组件
class ResponsiveCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 卡片边缘内边距
  final EdgeInsets padding;

  /// 是否显示阴影
  final bool shadow;

  /// 边框圆角
  final double borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding = AppTheme.paddingM,
    this.shadow = true,
    this.borderRadius = AppTheme.radiusM,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: shadow ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 响应式文本组件
class ResponsiveText extends StatelessWidget {
  /// 文本内容
  final String text;

  /// 小屏幕文本样式
  final TextStyle mobileStyle;

  /// 大屏幕文本样式
  final TextStyle tabletStyle;

  /// 文本对齐方式
  final TextAlign textAlign;

  /// 最大行数
  final int? maxLines;

  /// 溢出处理
  final TextOverflow overflow;

  const ResponsiveText({
    super.key,
    required this.text,
    required this.mobileStyle,
    required this.tabletStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);
    
    return Text(
      text,
      style: isLargeScreen ? tabletStyle : mobileStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 响应式边距组件
class ResponsivePadding extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 小屏幕内边距
  final EdgeInsets mobilePadding;

  /// 大屏幕内边距
  final EdgeInsets tabletPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    required this.mobilePadding,
    required this.tabletPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);
    
    return Padding(
      padding: isLargeScreen ? tabletPadding : mobilePadding,
      child: child,
    );
  }
}