import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/emotion_entry.dart';
import '../services/emotion_store.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'record_sheet.dart';
import 'stats_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.store});

  final EmotionStore store;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  EmotionStore get store => widget.store;

  Future<void> _openRecord({
    EntryType type = EntryType.moment,
    DateTime? date,
    EmotionEntry? entry,
  }) async {
    final result = await showRecordSheet(
      context,
      store: store,
      initialType: entry?.type ?? type,
      initialDate: date,
      entry: entry,
    );
    if (!mounted || result == null) return;
    if (result == RecordSheetAction.deleted) {
      showWarmSnackBar(context, '这条记录已删除', icon: Icons.delete_outline_rounded);
      return;
    }
    HapticFeedback.lightImpact();
    showWarmSnackBar(
      context,
      entry == null ? '心情已收好，谢谢你说出来' : '记录已更新',
      icon: Icons.favorite_rounded,
    );
  }

  void _openDaily() {
    final today = store.now;
    final existing = store.dailyEntryOn(today);
    _openRecord(type: EntryType.daily, date: today, entry: existing);
  }

  void _openForDate(DateTime date) {
    final existing = store.dailyEntryOn(date);
    _openRecord(type: EntryType.daily, date: startOfDay(date), entry: existing);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileScreen(store: store),
      ),
    );
  }

  void _setIndex(int index) {
    if (_index == index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _AmbientBackground()),
            IndexedStack(
              index: _index,
              children: [
                HomeScreen(
                  store: store,
                  onQuickRecord: () => _openRecord(),
                  onDailySummary: _openDaily,
                  onOpenTrends: () => _setIndex(1),
                  onOpenHistory: () => _setIndex(2),
                  onOpenProfile: _openProfile,
                  onEditEntry: (entry) => _openRecord(entry: entry),
                  onRecordForDate: _openForDate,
                ),
                StatsScreen(
                  store: store,
                  onRecord: () => _openRecord(),
                  onOpenHistory: () => _setIndex(2),
                ),
                HistoryScreen(
                  store: store,
                  onEditEntry: (entry) => _openRecord(entry: entry),
                  onRecordForDate: _openForDate,
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: _WarmNavigationBar(index: _index, onChanged: _setIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.apricot.withValues(alpha: 0.23),
                    AppColors.apricot.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -150,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.rose.withValues(alpha: 0.08),
                    AppColors.rose.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmNavigationBar extends StatelessWidget {
  const _WarmNavigationBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E4A35).withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: '首页',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: '趋势',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories_rounded,
            label: '时光',
            selected: index == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 21,
                  color: selected ? AppColors.primaryDeep : AppColors.muted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppColors.primaryDeep : AppColors.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
