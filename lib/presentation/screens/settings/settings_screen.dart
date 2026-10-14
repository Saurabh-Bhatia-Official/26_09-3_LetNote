import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/database_helper.dart';
import '../../providers/theme_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/tags_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/backup_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final securityState = ref.watch(securityProvider);
    final securityNotifier = ref.read(securityProvider.notifier);
    final aiState = ref.watch(aiAssistantProvider);
    final aiNotifier = ref.read(aiAssistantProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // APPEARANCE SECTION
          _buildSectionHeader(theme, 'APPEARANCE & THEME'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium_rounded),
                  title: const Text('Theme Mode'),
                  subtitle: Text(
                    themeState.themeMode == ThemeMode.dark
                        ? 'Dark Mode (Obsidian)'
                        : themeState.themeMode == ThemeMode.light
                            ? 'Light Mode'
                            : 'System Default',
                  ),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
                    ],
                    selected: {themeState.themeMode},
                    onSelectionChanged: (set) => themeNotifier.setThemeMode(set.first),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Accent Color Preset'),
                  subtitle: Text(themeState.accentColor.label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AppAccentColor.values.map((c) {
                      final isSelected = themeState.accentColor == c;
                      return GestureDetector(
                        onTap: () => themeNotifier.setAccentColor(c),
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SECURITY & ENCRYPTION SECTION
          _buildSectionHeader(theme, 'SECURITY & PRIVACY (AES-256)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    securityState.hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: securityState.hasPin ? theme.primaryColor : null,
                  ),
                  title: const Text('App & Note Lock PIN'),
                  subtitle: Text(
                    securityState.hasPin
                        ? 'PIN is active. Locked notes are encrypted at rest with AES-256-GCM.'
                        : 'No PIN configured. Set a PIN to enable note encryption.',
                  ),
                  trailing: securityState.hasPin
                      ? OutlinedButton(
                          onPressed: () async {
                            final pin = await PinDialog.show(
                              context,
                              mode: PinDialogMode.verify,
                              title: 'Remove PIN',
                              subtitle: 'Enter your PIN to remove security protection',
                            );
                            if (pin != null) {
                              final valid = await securityNotifier.verifyPin(pin);
                              if (valid) {
                                await securityNotifier.removePin();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PIN removed.')),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incorrect PIN.')),
                                );
                              }
                            }
                          },
                          child: const Text('Remove PIN'),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final pin = await PinDialog.show(
                              context,
                              mode: PinDialogMode.create,
                              title: 'Create PIN',
                              subtitle: 'Create a 4-6 digit PIN to protect sensitive notes',
                            );
                            if (pin != null) {
                              await securityNotifier.setPin(pin);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PIN configured successfully!')),
                                );
                              }
                            }
                          },
                          child: const Text('Set PIN'),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Auto-Lock Inactivity Timeout'),
                  subtitle: Text('${securityState.autoLockTimeoutMinutes} minutes'),
                  trailing: DropdownButton<int>(
                    value: securityState.autoLockTimeoutMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 minute')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        securityNotifier.setAutoLockTimeoutMinutes(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // BACKUP & RESTORE SECTION
          _buildSectionHeader(theme, 'BACKUP & RESTORE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.blueAccent),
                  title: const Text('Create Encrypted Backup'),
                  subtitle: const Text('Package full database and attachments into a password-protected .letnote bundle'),
                  trailing: ElevatedButton.icon(
                    onPressed: () => BackupDialogs.showCreateBackupDialog(context, ref),
                    icon: const Icon(Icons.file_download_rounded, size: 16),
                    label: const Text('Backup'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore_rounded, color: Colors.orangeAccent),
                  title: const Text('Restore Backup'),
                  subtitle: const Text('Inspect manifest checksum and restore notes from a backup archive'),
                  trailing: OutlinedButton.icon(
                    onPressed: () => BackupDialogs.showRestoreBackupDialog(context, ref),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Restore'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI ASSISTANT SECTION
          _buildSectionHeader(theme, 'OPTIONAL AI MODULE (DECOUPLED)'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome_outlined, color: Colors.purpleAccent),
                  title: const Text('Enable AI Features'),
                  subtitle: const Text('Enables smart summarization, action-item extraction, and title suggestions'),
                  value: aiState.isConsentGiven,
                  onChanged: (val) => aiNotifier.setConsent(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DATA MANAGEMENT (DANGER ZONE)
          _buildSectionHeader(theme, 'DATA MANAGEMENT', color: Colors.redAccent),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 26),
                  ),
                  title: const Text(
                    'Delete All Data',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: const Text(
                    'Permanently wipe all notes, books, tags, checklists, versions, and local attachments from this device.',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showDeleteAllDataDialog(context, ref, securityState),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text('Delete All Data'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT LETNOTE
          _buildSectionHeader(theme, 'ABOUT LETNOTE'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.04)
                        : theme.primaryColor.withValues(alpha: 0.04),
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.16),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppConstants.logoIconTransparentPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.appTagline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App Version'),
                  subtitle: const Text('${AppConstants.appName} v${AppConstants.appVersion} • Clean Architecture'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: const Text('Storage Engine'),
                  subtitle: const Text('Local SQLite via sqflite_common_ffi with FTS5 virtual tables'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Security Standard'),
                  subtitle: const Text('AES-256-CBC/GCM with PBKDF2/Argon2 salt key derivation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: color ?? theme.hintColor,
        ),
      ),
    );
  }

  Future<void> _showDeleteAllDataDialog(
    BuildContext context,
    WidgetRef ref,
    SecurityState securityState,
  ) async {
    // 1. If an App PIN is configured, verify PIN first
    if (securityState.hasPin) {
      final pin = await PinDialog.show(
        context,
        mode: PinDialogMode.verify,
        title: 'Verify App PIN',
        subtitle: 'Enter your PIN to authorize wiping all data',
      );
      if (pin == null) return;
      final verified = await ref.read(securityProvider.notifier).verifyPin(pin);
      if (!verified) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect PIN. Data deletion cancelled.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    // 2. Double-confirmation dialog
    final confirmController = TextEditingController();
    bool alsoResetSettings = false;
    bool isDeleting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDeleteKeywordTyped = confirmController.text.trim().toUpperCase() == 'DELETE';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Text('Delete All Data?', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This action is PERMANENT and CANNOT be undone. All your offline-first notes, books, tags, checklists, version snapshots, and attachments will be erased from local storage.',
                                style: TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The following will be completely wiped:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      const Text('• All active, pinned, and archived notes', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const Text('• All trash notes and version histories', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const Text('• All book groups, books, and tag metadata', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const Text('• All local attachment files and search index', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Also reset App PIN & security lock', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('Clears your app PIN and security configuration', style: TextStyle(fontSize: 11)),
                        value: alsoResetSettings,
                        onChanged: isDeleting
                            ? null
                            : (val) {
                                setDialogState(() {
                                  alsoResetSettings = val ?? false;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'To confirm, please type DELETE below:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmController,
                        enabled: !isDeleting,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'DELETE',
                          hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      if (isDeleting) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                              ),
                              SizedBox(width: 12),
                              Text('Wiping database & local storage...', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white70,
                  ),
                  onPressed: (!isDeleteKeywordTyped || isDeleting)
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            // 1. Wipe database & disk attachments
                            await DatabaseHelper.instance.deleteAllData(resetSettings: alsoResetSettings);

                            // 2. Reset PIN if requested
                            if (alsoResetSettings) {
                              await ref.read(securityProvider.notifier).removePin();
                            }

                            // 3. Invalidate and reload all Riverpod providers
                            ref.invalidate(notesNotifierProvider);
                            ref.invalidate(foldersNotifierProvider);
                            ref.invalidate(tagsNotifierProvider);
                            ref.read(activeNoteIdProvider.notifier).select(null);
                            ref.invalidate(dashboardDataProvider);

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text('All data has been permanently deleted.'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete data: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Permanently Delete Everything'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
