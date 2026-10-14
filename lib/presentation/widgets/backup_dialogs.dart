import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/backup_manifest.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/tags_provider.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});

class BackupDialogs {
  static Future<void> showCreateBackupDialog(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.backup_rounded, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Create Encrypted Backup'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your entire notes database, folders, tags, and attachments will be encrypted with AES-256 and packaged into a verified .letnote bundle.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Set Backup Password',
                  hintText: 'Enter a strong password',
                  prefixIcon: Icon(Icons.key_rounded, size: 20),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = passwordController.text.trim();
                if (pwd.length < 4) {
                  setState(() => error = 'Password must be at least 4 characters');
                  return;
                }

                try {
                  final repo = ref.read(backupRepositoryProvider);
                  final file = await repo.createEncryptedBackup(password: pwd);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Backup created at: ${file.path}'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => error = 'Backup failed: $e');
                }
              },
              child: const Text('Export Backup'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showRestoreBackupDialog(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['letnote', 'zip'],
    );

    if (picked.isEmpty || picked.first.path == null) return;
    final file = File(picked.first.path!);

    if (!context.mounted) return;

    final passwordController = TextEditingController();
    String? error;
    BackupManifest? previewManifest;
    bool isVerifying = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.settings_backup_restore_rounded, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text('Restore Backup'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${file.path.split(Platform.pathSeparator).last}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (previewManifest == null) ...[
                const Text(
                  'Enter the password used when creating this backup to verify and inspect contents.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Backup Password',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Integrity Verified', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• Notes: ${previewManifest!.noteCount}'),
                      Text('• Folders: ${previewManifest!.folderCount}'),
                      Text('• Tags: ${previewManifest!.tagCount}'),
                      Text('• Attachments: ${previewManifest!.attachmentCount}'),
                      const SizedBox(height: 6),
                      Text(
                        'Checksum: ${previewManifest!.checksum.substring(0, 12)}...',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            if (previewManifest == null)
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        final pwd = passwordController.text.trim();
                        if (pwd.isEmpty) {
                          setState(() => error = 'Please enter backup password');
                          return;
                        }
                        setState(() {
                          isVerifying = true;
                          error = null;
                        });

                        try {
                          final repo = ref.read(backupRepositoryProvider);
                          final manifest = await repo.inspectBackup(file, password: pwd);
                          setState(() {
                            previewManifest = manifest;
                            isVerifying = false;
                          });
                        } catch (e) {
                          setState(() {
                            error = '$e';
                            isVerifying = false;
                          });
                        }
                      },
                child: isVerifying
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify & Preview'),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    final repo = ref.read(backupRepositoryProvider);
                    await repo.restoreBackup(file, password: passwordController.text.trim());

                    ref.invalidate(notesNotifierProvider);
                    ref.invalidate(foldersNotifierProvider);
                    ref.invalidate(tagsNotifierProvider);

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup restored successfully!')),
                      );
                    }
                  } catch (e) {
                    setState(() => error = 'Restore failed: $e');
                  }
                },
                child: const Text('Confirm Restore'),
              ),
          ],
        ),
      ),
    );
  }
}
