import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/text_utils.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/sidebar_navigation.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.invalidate(dashboardDataProvider),
          ),
        ],
      ),
      body: dataAsync.when(
        data: (data) => _buildDashboardBody(context, ref, theme, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DashboardData data,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner & Quick Action
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.colorScheme.secondary.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppConstants.logoIconTransparentPath,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to ${AppConstants.appName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'True offline-first workspace. ${data.totalNotes} notes captured locally with instant retrieval.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(notesNotifierProvider.notifier).createNewNote();
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.black87),
                  label: const Text('Quick Note', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Overview KPI cards
          Row(
            children: [
              _buildKpiCard(
                theme,
                'Total Notes',
                data.totalNotes.toString(),
                Icons.description_outlined,
                Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                theme,
                'Pinned',
                data.pinnedCount.toString(),
                Icons.push_pin_outlined,
                Colors.amberAccent,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                theme,
                'Favorites',
                data.favoritesCount.toString(),
                Icons.star_outline_rounded,
                Colors.redAccent,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                theme,
                'Open Tasks',
                data.openChecklistsCount.toString(),
                Icons.checklist_rounded,
                Colors.tealAccent,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Quick Create By Note Type (Section 7 PRD)
          Text(
            'CREATE BY NOTE TYPE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: NoteType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final type = NoteType.values[i];
                return InkWell(
                  onTap: () async {
                    await ref.read(notesNotifierProvider.notifier).createNewNote(noteType: type);
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(type.icon, color: theme.primaryColor, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          type.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Recent Notes
          Text(
            'RECENT NOTES',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          if (data.recentNotes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: const Center(child: Text('No notes created yet. Click "Quick Note" above!')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final note = data.recentNotes[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(note.noteType.icon, color: theme.primaryColor, size: 18),
                    ),
                    title: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled Note',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      TextUtils.stripMarkdown(note.bodyDelta),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      DateFormatter.formatRelative(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                    ),
                    onTap: () {
                      ref.read(activeNoteIdProvider.notifier).select(note.id);
                      ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
