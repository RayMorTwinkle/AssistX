import 'package:flutter/material.dart';
import 'package:assistx/shared/themes/app_theme.dart';
import 'package:assistx/shared/widgets/responsive_layout.dart';
import 'package:assistx/features/home/widgets/recording_controls.dart';
import 'package:assistx/features/home/widgets/real_time_text_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssistX'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ResponsiveLayout(
        mobileLayout: _buildMobileLayout(context),
        tabletLayout: _buildTabletLayout(context),
        centered: false,
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: const RealTimeTextView(),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: const RecordingControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          // 侧边栏（200px宽度）
          Container(
            width: 200,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebarItem(context, '主页', Icons.home, true),
                _buildSidebarItem(context, '历史记录', Icons.history, false),
                _buildSidebarItem(context, '设置', Icons.settings, false),
                const Spacer(),
                _buildSidebarItem(context, '关于', Icons.info_outline, false),
              ],
            ),
          ),
          // 主内容区域
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: const RealTimeTextView(),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: const RecordingControls(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, bool isSelected) {
    return Container(
      padding: AppTheme.paddingM,
      decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : Colors.transparent,
            border: isSelected
                ? const Border(
                    left: BorderSide(
                      color: Colors.transparent,
                      width: 3,
                    ),
                  )
                : Border.all(width: 0),
          ),
          child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(153)
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}