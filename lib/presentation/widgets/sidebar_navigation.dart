import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/folder.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/theme_provider.dart';

enum MainViewTab {
  notes,
  dashboard,
  search,
  settings,
  trash,
}

class ActiveTabNotifier extends Notifier<MainViewTab> {
  @override
  MainViewTab build() => MainViewTab.notes;

  void setTab(MainViewTab tab) => state = tab;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, MainViewTab>(ActiveTabNotifier.new);

class SidebarNavigation extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const SidebarNavigation({
    super.key,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> {
  final Set<String> _expandedGroupIds = {};

  void _toggleGroupExpansion(String groupId) {
    setState(() {
      if (_expandedGroupIds.contains(groupId)) {
        _expandedGroupIds.remove(groupId);
      } else {
        _expandedGroupIds.add(groupId);
      }
    });
  }

  void _showNewBookGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_copy_rounded, size: 22),
            SizedBox(width: 8),
            Text('New Group of Books'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Work Projects, University, Personal',
            labelText: 'Group Name',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final group = await ref.read(foldersNotifierProvider.notifier).createBookGroup(name);
                setState(() => _expandedGroupIds.add(group.id));
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _showNewBookDialog(BuildContext context, {String? groupId, String? groupName}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 22),
            const SizedBox(width: 8),
            Text(groupId != null ? 'New Book in $groupName' : 'New Standalone Book'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Daily Journal, Architecture Notes, Ideas',
            labelText: 'Book Name',
            helperText: groupId != null ? 'Will be created inside "$groupName"' : 'Will be created in "Only Books"',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(foldersNotifierProvider.notifier).createBook(name, groupId: groupId);
                if (groupId != null) {
                  setState(() => _expandedGroupIds.add(groupId));
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create Book'),
          ),
        ],
      ),
    );
  }

  void _showMoveBookDialog(BuildContext context, Folder book, List<Folder> allGroups) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move "${book.name}"'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select target destination:'),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.book_outlined),
                title: const Text('Only Books (Standalone)'),
                subtitle: const Text('No group'),
                selected: book.parentFolderId == null,
                onTap: () async {
                  await ref.read(foldersNotifierProvider.notifier).moveBookToGroup(book.id, null);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              const Divider(),
              if (allGroups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No book groups created yet.', style: TextStyle(color: Colors.grey)),
                )
              else
                ...allGroups.map((g) => ListTile(
                      leading: const Icon(Icons.folder_copy_rounded),
                      title: Text(g.name),
                      selected: book.parentFolderId == g.id,
                      onTap: () async {
                        await ref.read(foldersNotifierProvider.notifier).moveBookToGroup(book.id, g.id);
                        setState(() => _expandedGroupIds.add(g.id));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Folder item, String itemType) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename $itemType'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: '$itemType Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(foldersNotifierProvider.notifier).renameFolder(item.id, newName);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Folder item, String itemType, {bool isGroup = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $itemType?'),
        content: Text(
          isGroup
              ? 'Are you sure you want to delete the group "${item.name}"? Books inside this group will be moved to "Only Books" and their notes will be preserved.'
              : 'Are you sure you want to delete the book "${item.name}"? Notes inside it will become uncategorized.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(foldersNotifierProvider.notifier).deleteFolder(item.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNewTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Work, Research, Personal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(tagsNotifierProvider.notifier).addTag(name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(noteFilterProvider);
    final activeTab = ref.watch(activeTabProvider);
    final foldersAsync = ref.watch(foldersNotifierProvider);
    final tagsAsync = ref.watch(tagsNotifierProvider);
    final isCollapsed = widget.isCollapsed;

    return Container(
      width: isCollapsed ? 64 : 260,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Header / Branding (responsive and overflow safe)
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
            alignment: Alignment.centerLeft,
            child: isCollapsed
                ? Center(
                    child: InkWell(
                      onTap: widget.onToggleCollapse,
                      borderRadius: BorderRadius.circular(10),
                      child: Tooltip(
                        message: 'Expand Sidebar (${AppConstants.appName})',
                        child: Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            AppConstants.logoIconTransparentPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            AppConstants.logoIconTransparentPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Offline-First Notes',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: widget.onToggleCollapse,
                        tooltip: 'Collapse Sidebar',
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),

          // Navigation Tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: activeTab == MainViewTab.dashboard,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.dashboard);
                  },
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Search Notes',
                  isSelected: activeTab == MainViewTab.search,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.search);
                  },
                ),
                const SizedBox(height: 12),

                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'SMART VIEWS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                _NavItem(
                  icon: Icons.notes_rounded,
                  label: 'All Notes',
                  isSelected: activeTab == MainViewTab.notes &&
                      filterState.smartFilter == SmartFilter.all &&
                      filterState.folderId == null &&
                      filterState.bookGroupId == null &&
                      filterState.tagId == null,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                    ref.read(noteFilterProvider.notifier).setFilter(
                          const NoteFilterState(smartFilter: SmartFilter.all),
                        );
                  },
                ),
                _NavItem(
                  icon: Icons.push_pin_outlined,
                  activeIcon: Icons.push_pin_rounded,
                  label: 'Pinned',
                  isSelected: activeTab == MainViewTab.notes && filterState.smartFilter == SmartFilter.pinned,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                    ref.read(noteFilterProvider.notifier).setFilter(
                          const NoteFilterState(smartFilter: SmartFilter.pinned),
                        );
                  },
                ),
                _NavItem(
                  icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Favorites',
                  isSelected: activeTab == MainViewTab.notes && filterState.smartFilter == SmartFilter.favorites,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                    ref.read(noteFilterProvider.notifier).setFilter(
                          const NoteFilterState(smartFilter: SmartFilter.favorites),
                        );
                  },
                ),
                _NavItem(
                  icon: Icons.archive_outlined,
                  activeIcon: Icons.archive_rounded,
                  label: 'Archive',
                  isSelected: activeTab == MainViewTab.notes && filterState.smartFilter == SmartFilter.archived,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                    ref.read(noteFilterProvider.notifier).setFilter(
                          const NoteFilterState(smartFilter: SmartFilter.archived),
                        );
                  },
                ),
                _NavItem(
                  icon: Icons.delete_outline_rounded,
                  activeIcon: Icons.delete_rounded,
                  label: 'Trash',
                  isSelected: activeTab == MainViewTab.trash,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref.read(activeTabProvider.notifier).setTab(MainViewTab.trash);
                  },
                ),

                const SizedBox(height: 16),

                // BOOK GROUPS & ONLY BOOKS SECTIONS
                foldersAsync.when(
                  data: (folders) {
                    // Identify groups: either explicitly marked isGroup or has children
                    final groups = folders.where((f) => f.isGroup || (f.parentFolderId == null && folders.any((c) => c.parentFolderId == f.id))).toList();
                    final groupIds = groups.map((g) => g.id).toSet();
                    // Identify standalone books (not a group, and parent is null)
                    final standaloneBooks = folders.where((f) => !groupIds.contains(f.id) && f.parentFolderId == null).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: GROUP OF BOOKS
                        if (!isCollapsed) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.folder_copy_outlined, size: 14, color: theme.hintColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'GROUP OF BOOKS',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.hintColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Add Book Group',
                                  onPressed: () => _showNewBookGroupDialog(context),
                                ),
                              ],
                            ),
                          ),
                          if (groups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'No book groups yet',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            )
                          else
                            ...groups.map((group) {
                              final childBooks = folders.where((f) => f.parentFolderId == group.id).toList();
                              final isExpanded = _expandedGroupIds.contains(group.id);
                              final isGroupSelected = activeTab == MainViewTab.notes && filterState.bookGroupId == group.id;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Group Header Item
                                  _NavItem(
                                    icon: isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                                    label: group.name,
                                    isSelected: isGroupSelected,
                                    isCollapsed: isCollapsed,
                                    onTap: () {
                                      ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                                      ref.read(noteFilterProvider.notifier).setFilter(
                                            NoteFilterState(bookGroupId: group.id),
                                          );
                                      if (!isExpanded) {
                                        _toggleGroupExpansion(group.id);
                                      }
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Child count badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.dividerColor.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${childBooks.length}',
                                            style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                            size: 18,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _toggleGroupExpansion(group.id),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, size: 16),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'add_book',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.add_rounded, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Add Book to Group'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'rename',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_rounded, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Rename Group'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Delete Group', style: TextStyle(color: Colors.redAccent)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (val) {
                                            if (val == 'add_book') {
                                              _showNewBookDialog(context, groupId: group.id, groupName: group.name);
                                            } else if (val == 'rename') {
                                              _showRenameDialog(context, group, 'Group');
                                            } else if (val == 'delete') {
                                              _showDeleteDialog(context, group, 'Group', isGroup: true);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Child Books inside group (when expanded)
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16.0),
                                      child: Column(
                                        children: [
                                          if (childBooks.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'No books inside',
                                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => _showNewBookDialog(context, groupId: group.id, groupName: group.name),
                                                    child: const Text('+ Add', style: TextStyle(fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            ...childBooks.map((book) {
                                              final isBookSelected = activeTab == MainViewTab.notes && filterState.folderId == book.id;
                                              return _NavItem(
                                                icon: Icons.menu_book_rounded,
                                                label: book.name,
                                                isSelected: isBookSelected,
                                                isCollapsed: isCollapsed,
                                                onTap: () {
                                                  ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                                                  ref.read(noteFilterProvider.notifier).setFilter(
                                                        NoteFilterState(folderId: book.id),
                                                      );
                                                },
                                                trailing: PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_horiz_rounded, size: 16),
                                                  itemBuilder: (ctx) => [
                                                    const PopupMenuItem(
                                                      value: 'move',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.drive_file_move_outlined, size: 16),
                                                          SizedBox(width: 8),
                                                          Text('Move Book...'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'rename',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit_rounded, size: 16),
                                                          SizedBox(width: 8),
                                                          Text('Rename Book'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                                          SizedBox(width: 8),
                                                          Text('Delete Book', style: TextStyle(color: Colors.redAccent)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onSelected: (val) {
                                                    if (val == 'move') {
                                                      _showMoveBookDialog(context, book, groups);
                                                    } else if (val == 'rename') {
                                                      _showRenameDialog(context, book, 'Book');
                                                    } else if (val == 'delete') {
                                                      _showDeleteDialog(context, book, 'Book');
                                                    }
                                                  },
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }),

                          const SizedBox(height: 16),

                          // SECTION 2: ONLY BOOKS (STANDALONE BOOKS)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 14, color: theme.hintColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ONLY BOOKS',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.hintColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Add Standalone Book',
                                  onPressed: () => _showNewBookDialog(context, groupId: null),
                                ),
                              ],
                            ),
                          ),
                          if (standaloneBooks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'No standalone books yet',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            )
                          else
                            ...standaloneBooks.map((book) {
                              final isSelected = activeTab == MainViewTab.notes && filterState.folderId == book.id;
                              return _NavItem(
                                icon: Icons.menu_book_rounded,
                                label: book.name,
                                isSelected: isSelected,
                                isCollapsed: isCollapsed,
                                onTap: () {
                                  ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                                  ref.read(noteFilterProvider.notifier).setFilter(
                                        NoteFilterState(folderId: book.id),
                                      );
                                },
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz_rounded, size: 16),
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'move',
                                      child: Row(
                                        children: [
                                          Icon(Icons.drive_file_move_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Move to Group...'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, size: 16),
                                          SizedBox(width: 8),
                                          Text('Rename Book'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                          SizedBox(width: 8),
                                          Text('Delete Book', style: TextStyle(color: Colors.redAccent)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'move') {
                                      _showMoveBookDialog(context, book, groups);
                                    } else if (val == 'rename') {
                                      _showRenameDialog(context, book, 'Book');
                                    } else if (val == 'delete') {
                                      _showDeleteDialog(context, book, 'Book');
                                    }
                                  },
                                ),
                              );
                            }),
                        ] else ...[
                          // Collapsed state navigation items
                          _NavItem(
                            icon: Icons.folder_copy_outlined,
                            label: 'Book Groups',
                            isSelected: filterState.bookGroupId != null,
                            isCollapsed: true,
                            onTap: widget.onToggleCollapse,
                          ),
                          _NavItem(
                            icon: Icons.menu_book_rounded,
                            label: 'Books',
                            isSelected: filterState.folderId != null,
                            isCollapsed: true,
                            onTap: widget.onToggleCollapse,
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Tags Section
                if (!isCollapsed) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TAGS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Add Tag',
                          onPressed: () => _showNewTagDialog(context),
                        ),
                      ],
                    ),
                  ),
                  tagsAsync.when(
                    data: (tags) {
                      if (tags.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text(
                            'No tags yet',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                        );
                      }
                      return Column(
                        children: tags.map((tag) {
                          final isSelected = activeTab == MainViewTab.notes && filterState.tagId == tag.id;
                          return _NavItem(
                            icon: Icons.tag_rounded,
                            label: tag.name,
                            isSelected: isSelected,
                            isCollapsed: isCollapsed,
                            onTap: () {
                              ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                              ref.read(noteFilterProvider.notifier).setFilter(
                                    NoteFilterState(tagId: tag.id),
                                  );
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom Bar (Settings & Theme toggle)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isSelected: activeTab == MainViewTab.settings,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      ref.read(activeTabProvider.notifier).setTab(MainViewTab.settings);
                    },
                  ),
                ),
                if (!isCollapsed)
                  IconButton(
                    icon: Icon(
                      theme.brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    tooltip: 'Toggle Theme',
                    onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCollapsed) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              color: isSelected ? theme.primaryColor : theme.iconTheme.color,
              size: 20,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(
            isSelected ? (activeIcon ?? icon) : icon,
            color: isSelected ? theme.primaryColor : theme.iconTheme.color?.withValues(alpha: 0.8),
            size: 20,
          ),
          title: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? theme.primaryColor : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
