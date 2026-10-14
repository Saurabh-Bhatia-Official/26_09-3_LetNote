import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/notes_provider.dart';
import '../widgets/sidebar_navigation.dart';
import 'dashboard/dashboard_screen.dart';
import 'notes_list/notes_list_view.dart';
import 'editor/note_editor_screen.dart';
import 'search/search_screen.dart';
import 'trash/trash_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTab = ref.watch(activeTabProvider);
    final activeNote = ref.watch(activeNoteProvider);
    final width = MediaQuery.of(context).size.width;

    // Desktop/Wide screen 3-pane layout
    if (width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            // 1. Sidebar Navigation
            SidebarNavigation(
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),

            // 2. Center Content Area / Notes List
            if (activeTab == MainViewTab.notes) ...[
              const SizedBox(
                width: 330,
                child: NotesListView(),
              ),
              const VerticalDivider(width: 1),
              // 3. Right Editor pane
              Expanded(
                child: activeNote != null
                    ? NoteEditorScreen(note: activeNote)
                    : _buildNoActiveNotePlaceholder(theme),
              ),
            ] else if (activeTab == MainViewTab.dashboard) ...[
              const Expanded(child: DashboardScreen()),
            ] else if (activeTab == MainViewTab.search) ...[
              const Expanded(child: SearchScreen()),
            ] else if (activeTab == MainViewTab.trash) ...[
              const Expanded(child: TrashScreen()),
            ] else if (activeTab == MainViewTab.settings) ...[
              const Expanded(child: SettingsScreen()),
            ],
          ],
        ),
      );
    }

    // Tablet 2-pane layout
    if (width >= 600) {
      return Scaffold(
        body: Row(
          children: [
            SidebarNavigation(
              isCollapsed: true,
              onToggleCollapse: () {},
            ),
            Expanded(
              child: _buildCurrentTabScreen(activeTab, activeNote, theme),
            ),
          ],
        ),
      );
    }

    // Mobile layout with Bottom Navigation Bar
    return Scaffold(
      body: _buildMobileTabScreen(activeTab, activeNote, theme),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabToIndex(activeTab),
        onDestinationSelected: (idx) {
          ref.read(activeTabProvider.notifier).setTab(_indexToTab(idx));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabScreen(MainViewTab tab, dynamic activeNote, ThemeData theme) {
    switch (tab) {
      case MainViewTab.dashboard:
        return const DashboardScreen();
      case MainViewTab.search:
        return const SearchScreen();
      case MainViewTab.trash:
        return const TrashScreen();
      case MainViewTab.settings:
        return const SettingsScreen();
      case MainViewTab.notes:
        if (activeNote != null) {
          return Row(
            children: [
              const SizedBox(width: 300, child: NotesListView()),
              const VerticalDivider(width: 1),
              Expanded(child: NoteEditorScreen(note: activeNote)),
            ],
          );
        }
        return const NotesListView();
    }
  }

  Widget _buildMobileTabScreen(MainViewTab tab, dynamic activeNote, ThemeData theme) {
    switch (tab) {
      case MainViewTab.dashboard:
        return const DashboardScreen();
      case MainViewTab.search:
        return const SearchScreen();
      case MainViewTab.trash:
        return const TrashScreen();
      case MainViewTab.settings:
        return const SettingsScreen();
      case MainViewTab.notes:
        if (activeNote != null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              ref.read(activeNoteIdProvider.notifier).select(null);
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => ref.read(activeNoteIdProvider.notifier).select(null),
                ),
              ),
              body: NoteEditorScreen(note: activeNote),
            ),
          );
        }
        return const NotesListView();
    }
  }

  int _tabToIndex(MainViewTab tab) {
    switch (tab) {
      case MainViewTab.notes:
      case MainViewTab.trash:
        return 0;
      case MainViewTab.dashboard:
        return 1;
      case MainViewTab.search:
        return 2;
      case MainViewTab.settings:
        return 3;
    }
  }

  MainViewTab _indexToTab(int idx) {
    switch (idx) {
      case 0:
        return MainViewTab.notes;
      case 1:
        return MainViewTab.dashboard;
      case 2:
        return MainViewTab.search;
      case 3:
        return MainViewTab.settings;
      default:
        return MainViewTab.notes;
    }
  }

  Widget _buildNoActiveNotePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : theme.primaryColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: Image.asset(
              AppConstants.logoIconTransparentPath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a note to view or edit',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Or create a new note using the "+ New" button.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
