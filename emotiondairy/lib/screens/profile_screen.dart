import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../services/emotion_store.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});

  final EmotionStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: '返回',
                            onPressed: () => Navigator.of(context).pop(),
                            size: 40,
                          ),
                          const Spacer(),
                          Text(
                            '我的小屋',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _ProfileHero(store: store),
                      const SizedBox(height: 16),
                      _StatsRow(store: store),
                      const SizedBox(height: 22),
                      _SectionLabel(title: '数据与隐私'),
                      const SizedBox(height: 10),
                      SoftCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.content_copy_rounded,
                              iconColor: AppColors.sage,
                              background: AppColors.sageSoft,
                              title: '复制我的日记',
                              subtitle: '把全部记录复制为 JSON，方便自己备份',
                              onTap: () => _copyEntries(context),
                            ),
                            _ActionTile(
                              icon: Icons.delete_outline_rounded,
                              iconColor: AppColors.warning,
                              background: const Color(0xFFF9E4DF),
                              title: '清空全部记录',
                              subtitle: '本机上的所有心情都会被删除',
                              showDivider: false,
                              onTap: () => _clearAll(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(title: '关于快乐度'),
                      const SizedBox(height: 10),
                      const _FormulaCard(),
                      const SizedBox(height: 22),
                      _SectionLabel(title: '关于暖迹'),
                      const SizedBox(height: 10),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppLogo(size: 36),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '暖迹',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'v1.0.0',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '暖迹不是一个要求你“每天开心”的应用。它更想做一个安静的角落：让你看见情绪的来路，也记得在低处给自己一点照顾。',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 12, height: 1.8),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: AppColors.sage,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '所有记录仅保存在本机，不上传、不分析、不分享。',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              size: 20,
                              color: AppColors.peach,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '愿你有记录心情的耐心，也有放过自己的温柔。',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(letterSpacing: 0.4, height: 1.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyEntries(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportAsJson()));
    if (!context.mounted) return;
    showWarmSnackBar(context, '日记已复制到剪贴板', icon: Icons.content_copy_rounded);
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有记录？'),
        content: const Text('这会永久删除这台设备上的全部心情记录，无法恢复。建议先复制一份备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('先留着'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await store.clearAllData();
    if (!context.mounted) return;
    showWarmSnackBar(context, '记录已清空，随时可以重新开始', icon: Icons.refresh_rounded);
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.store});

  final EmotionStore store;

  @override
  Widget build(BuildContext context) {
    final first = store.firstRecordedDate;
    final joined = first == null
        ? '还没有开始记录'
        : '从 ${fullDateLabel(first)} 开始，记录生活';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0D9C8)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 29,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '情绪旅人',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      joined,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  store.currentStreak == 0
                      ? '今天也可以从这里开始'
                      : '已经连续记录 ${store.currentStreak} 天',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.inkSoft),
                ),
                const Spacer(),
                Text(
                  store.totalEntries == 0 ? '等待第一条记录' : '真实记录',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.store});

  final EmotionStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: '记录天数',
            value: '${store.recordedDayCount}',
            unit: '天',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            label: '心情片段',
            value: '${store.totalEntries}',
            unit: '条',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            label: '连续记录',
            value: '${store.currentStreak}',
            unit: '天',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  unit,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontSize: 9.5, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 63, right: 15),
            child: Divider(),
          ),
      ],
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDF6ED), Color(0xFFFFFCF8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.functions_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                '快乐度 = 50 + 平均情绪 × 10 − 波动 × 3',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '平均分代表情绪底色，标准差代表起伏。稳定的好心情得分更高，剧烈的波动会适度扣分。结果限制在 0–100，它不是心理诊断，只是一面温柔的小镜子。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.7, fontSize: 10.5),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: const [
              TagPill(label: '均值'),
              TagPill(label: '方差'),
              TagPill(label: '标准差'),
              TagPill(label: '每日聚合'),
            ],
          ),
        ],
      ),
    );
  }
}
