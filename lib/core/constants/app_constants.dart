import 'package:flutter/material.dart';

/// Note types supported by LetNote as specified in PRD Section 7
enum NoteType {
  standard,
  checklist,
  todo,
  meeting,
  quick,
  idea,
  journal,
  study,
  project,
  code,
}

extension NoteTypeExtension on NoteType {
  String get name {
    switch (this) {
      case NoteType.standard:
        return 'Standard';
      case NoteType.checklist:
        return 'Checklist';
      case NoteType.todo:
        return 'To-Do';
      case NoteType.meeting:
        return 'Meeting';
      case NoteType.quick:
        return 'Quick Note';
      case NoteType.idea:
        return 'Idea';
      case NoteType.journal:
        return 'Journal';
      case NoteType.study:
        return 'Study';
      case NoteType.project:
        return 'Project';
      case NoteType.code:
        return 'Code';
    }
  }

  IconData get icon {
    switch (this) {
      case NoteType.standard:
        return Icons.article_outlined;
      case NoteType.checklist:
        return Icons.checklist_rounded;
      case NoteType.todo:
        return Icons.task_alt_rounded;
      case NoteType.meeting:
        return Icons.groups_rounded;
      case NoteType.quick:
        return Icons.bolt_rounded;
      case NoteType.idea:
        return Icons.lightbulb_outline_rounded;
      case NoteType.journal:
        return Icons.book_outlined;
      case NoteType.study:
        return Icons.school_outlined;
      case NoteType.project:
        return Icons.folder_special_outlined;
      case NoteType.code:
        return Icons.code_rounded;
    }
  }

  /// Default template body for each note type as defined in PRD Section 7
  String get defaultTemplate {
    switch (this) {
      case NoteType.standard:
        return '';
      case NoteType.checklist:
        return '[ ] First task\n[ ] Second task\n[ ] Third task';
      case NoteType.todo:
        return '### Due Date: [Select Date]\n\n- [ ] High priority action item\n- [ ] Follow up on notes';
      case NoteType.meeting:
        return '## Meeting Details\n**Date:** \n**Attendees:** \n\n## Agenda\n1. \n2. \n\n## Notes\n\n## Action Items\n- [ ] ';
      case NoteType.quick:
        return '';
      case NoteType.idea:
        return '## The Idea\n\n### Why It Matters\n\n### Next Steps\n- [ ] ';
      case NoteType.journal:
        return '## Today\'s Reflections\n**Date:** ${DateTime.now().toLocal().toString().split(' ')[0]}\n\n### Highlights\n\n### Challenges & Learnings\n\n### Gratitude';
      case NoteType.study:
        return '## Topic: \n\n### Key Concepts\n- \n\n### Detailed Notes\n\n### Summary & Review Questions\n- ';
      case NoteType.project:
        return '## Objective\n\n### Milestones & Tasks\n- [ ] Phase 1: \n- [ ] Phase 2: \n\n### Status\nIn Progress\n\n### General Notes';
      case NoteType.code:
        return '```dart\n// Language: Dart\nvoid main() {\n  // Code snippet here\n}\n```';
    }
  }

  static NoteType fromString(String? typeStr) {
    if (typeStr == null) return NoteType.standard;
    for (var type in NoteType.values) {
      if (type.name.toLowerCase() == typeStr.toLowerCase() ||
          type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase()) {
        return type;
      }
    }
    return NoteType.standard;
  }
}

class AppConstants {
  static const String appName = 'LetNote';
  static const String appTagline = 'Universal Offline-First Notes Management';
  static const String appVersion = '1.0.0';

  // Brand Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String logoTransparentPath = 'assets/images/logo_transparent.png';
  static const String logoIconPath = 'assets/images/logo_icon.png';
  static const String logoIconTransparentPath = 'assets/images/logo_icon_transparent.png';
  static const String appIconPath = 'assets/images/app_icon.png';

  // Limits and thresholds as per PRD Section 27 & 28
  static const int autoSaveDebounceMs = 1500;
  static const int searchDebounceMs = 150;
  static const int freeTierAttachmentLimitBytes = 25 * 1024 * 1024; // 25MB
  static const int freeTierTotalStorageLimitBytes = 500 * 1024 * 1024; // 500MB
  static const int trashRetentionDefaultDays = 30;
  static const int maxFolderNestingDepth = 10;
  static const int versionHistoryAutoSnapshotMinutes = 10;

  // Storage Keys
  static const String keyAppPinHash = 'letnote_app_pin_hash';
  static const String keyAppPinSalt = 'letnote_app_pin_salt';
  static const String keyBiometricsEnabled = 'letnote_biometrics_enabled';
  static const String keyAutoLockTimeout = 'letnote_autolock_timeout';
  static const String keySelectedThemeMode = 'letnote_theme_mode';
  static const String keySelectedAccentColor = 'letnote_accent_color';
  static const String keyTrashRetentionDays = 'letnote_trash_retention_days';
}
