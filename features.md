# LetNote - Complete Feature Specification & Capabilities

**LetNote** is a modern, high-performance, universal offline-first notes and knowledge management workspace built with Flutter, Riverpod, and SQLite. It combines local-first privacy, AES-256 encryption, lightning-fast full-text search, and a responsive adaptive interface designed for desktop, mobile, and web.

---

## 1. Core Architecture & Philosophy

- **True Offline-First**: All data, metadata, search indexes, versions, and attachments reside strictly on the user's local device without mandatory network connectivity.
- **Clean Architecture Pattern**:
  - **Domain Layer**: Pure business entities (`Note`, `Folder`, `Tag`, `ChecklistItem`, `NoteVersion`, `BackupManifest`) and repository contracts.
  - **Data Layer**: SQLite data sources via `sqflite` (mobile) and `sqflite_common_ffi` (Windows, macOS, Linux), data models, repository implementations, and encryption services.
  - **Presentation Layer**: Riverpod state management with asynchronous notifiers, decoupled providers, and reactive UI.
- **SQLite Engine with WAL Mode**: Uses write-ahead logging (WAL) and foreign keys for atomicity, durability, and high concurrency.
- **Privacy by Design**: Sensitive user data never leaves the device without explicit user-initiated encrypted export.

---

## 2. Note Types & Specialized Templates

LetNote supports 10 distinct note types, each tailored with dedicated icons and structured templates:

| Note Type | Icon | Default Template & Use Case |
| :--- | :--- | :--- |
| **Standard** | `Icons.article_outlined` | Freeform writing, clean slate for thoughts and essays. |
| **Checklist** | `Icons.checklist_rounded` | Pre-populated interactive checklist tasks with toggles. |
| **To-Do** | `Icons.task_alt_rounded` | Task lists with due dates, priorities, and action items. |
| **Meeting** | `Icons.groups_rounded` | Date, Attendees, Agenda, Meeting Notes, and Action Items. |
| **Quick Note** | `Icons.bolt_rounded` | Immediate scratchpad for thoughts, memos, and quick captures. |
| **Idea** | `Icons.lightbulb_outline_rounded` | Structured sections: "The Idea", "Why It Matters", and "Next Steps". |
| **Journal** | `Icons.book_outlined` | Daily reflections, timestamps, highlights, challenges, and gratitude. |
| **Study** | `Icons.school_outlined` | Academic notes with Topic, Key Concepts, Notes, and Review Questions. |
| **Project** | `Icons.folder_special_outlined` | Project objectives, milestone phases, status tracking, and notes. |
| **Code** | `Icons.code_rounded` | Code snippet editor with language formatting and monospaced blocks. |

---

## 3. Hierarchical Knowledge Organization

- **Two-Tier Nested Organization**:
  - **Book Groups**: Top-level collections (e.g., *Work Projects*, *University*, *Personal*).
  - **Books (Folders)**: Dedicated notebooks that can either live inside a Book Group or stand alone in "Only Books".
  - **Nesting Depth**: Supports up to 10 nesting levels.
- **Tagging System**:
  - Many-to-many tag relationships with note junction tables (`note_tags`).
  - Customizable hex color badges per tag.
  - One-click tag creation, filtering, and deletion.
- **Smart Views & Filter States**:
  - **All Notes**: Unified reverse-chronological list of active notes.
  - **Pinned Notes**: Critical notes anchored to the top of lists.
  - **Favorites**: Starred notes for instant one-click access.
  - **Archived Notes**: Completed or reference notes kept out of active workflows.
  - **Trash**: Soft-deleted notes with 30-day default retention and single-click empty trash functionality.
  - **Contextual Filtering**: Filter by specific Book Group, Book, Tag, or Note Type.

---

## 4. Interactive Editor & Markdown Engine

- **Interactive Markdown Formatting Toolbar**:
  - Typography: **Bold**, *Italic*, ~~Strikethrough~~, Inline Code, Code Blocks.
  - Headers: **H1**, **H2**, **H3** hierarchy.
  - Lists: Bulleted lists, Numbered lists, and Interactive Checklists (`- [ ]`).
  - Layout: Quotes, Horizontal dividers, and Markdown links.
- **Dual Mode (Edit & Live Preview)**:
  - Instant toggle between editor and rich rendered Markdown preview via `flutter_markdown`.
- **Interactive Checklists in Editor**:
  - Interactive checkboxes in checklists can be toggled directly from the UI without manual text editing.
- **Auto-Save Engine**:
  - Debounced auto-save (1,500ms delay) guarantees no data loss while typing.
- **Real-Time Writing Statistics**:
  - Live Word Count (`TextUtils.countWords`).
  - Live Character Count (`TextUtils.countCharacters`).
  - Estimated Reading Time metric.

---

## 5. High-Speed Search & Retrieval

- **SQLite FTS5 Full-Text Search Engine**:
  - Dedicated virtual table `notes_fts` indexed using the `unicode61` tokenizer.
  - Sub-150ms query execution across 10,000+ notes.
  - Indexes note title, markdown body (stripped of markdown syntax), and tag names.
- **Privacy-Aware Search Isolation**:
  - Locked (encrypted) notes and trashed notes are strictly excluded from the plaintext FTS virtual table until authenticated.
- **Recent Searches**:
  - Tracks search history with single-tap replay and query clear.

---

## 6. Version History & Point-in-Time Restore

- **Automated Snapshotting**:
  - Snapshots created every 10 minutes of active editing or upon major modifications.
- **Version Inspection Dialog** (`VersionHistoryDialog`):
  - View timestamps, title snapshots, and body changes across all versions of any note.
- **Single-Click Rollback**:
  - Restore any historic version snapshot back to the active editor with automatic state synchronization.

---

## 7. Security, Privacy & Local Encryption

- **Cryptographic Engine** (`EncryptionService`):
  - **Algorithm**: AES-256 (CBC/GCM modes with PKCS7 padding).
  - **Key Derivation**: PBKDF2/Argon2 key derivation with cryptographically secure random salts.
  - **Integrity Verification**: SHA-256 checksums to detect file tampering.
- **Application Security Lock**:
  - User-configurable numeric App PIN.
  - Biometrics authentication support (Face / Fingerprint) where available.
  - Auto-lock inactivity timeout (1 min, 5 min, 15 min, 30 min).
- **Per-Note Encryption & Lock**:
  - Lock individual sensitive notes with AES-256 encryption.
  - Body payload is encrypted and replaced with ciphertext on disk; plaintext is only retained in memory when unlocked by PIN.

---

## 8. Encrypted Backup & Data Portability

- **`.letnote` Encrypted Archive Bundle**:
  - Complete packaging of all notes, folders, tags, versions, and attachments into a password-protected, encrypted zip archive.
  - Embedded JSON manifest with SHA-256 integrity checksums.
- **Safe Restoration Workflow**:
  - Pre-restore validation: decrypts and validates manifest and checksum before making changes.
  - Atomic database restoration inside a transaction.
- **Individual Note Exports**:
  - Export to **Markdown** (`.md`)
  - Export to **Plain Text** (`.txt`)
  - Export to **JSON** (`.json`) with full metadata

---

## 9. Decoupled AI Assistant (Optional & Consent-Driven)

- **Decoupled Architecture**: Completely optional module with zero data transmission unless explicitly opted in.
- **Consent-Gated Activation**: Requires explicit toggle in Settings (`AiAssistantNotifier`).
- **AI Capabilities**:
  - **Smart Summarization**: Generates concise summaries of long-form notes.
  - **Action-Item Extraction**: Identifies and formats actionable tasks from unstructured notes.
  - **Title Suggestion**: Auto-suggests context-aware titles based on note content.

---

## 10. Dashboard & Analytics

- **Branded Welcome Hero Banner**:
  - Highlights workspace metrics and features the official LetNote brand emblem.
  - Quick Note shortcut for instant capture.
- **Live KPI Overview Cards**:
  - Total Active Notes count.
  - Pinned Notes count.
  - Favorites count.
  - Open Checklist Tasks count.
- **Recent Notes Stream**:
  - Full-width, real-time list of recently updated notes with instant editor navigation.

---

## 11. Data Management (Danger Zone)

- **Delete All Data Button**:
  - Dedicated administrative function located in Settings under "DATA MANAGEMENT".
  - Performs an atomic database transaction wiping all notes, books, tags, checklists, version snapshots, attachments, and FTS tables.
  - Automatically cleans up local attachment folders on disk.
- **Multi-Stage Safety Protections**:
  - **PIN Challenge**: If an App PIN is configured, prompts for the PIN before displaying deletion options.
  - **Safety Phrase Confirmation**: Requires typing **`DELETE`** to activate the final button.
  - **Optional Credential Reset**: Checkbox allows resetting the App PIN and security credentials in the same operation.
  - **Live State Invalidation**: Instantly updates all active views, providers, and dashboard metrics.

---

## 12. Design System & Responsive Layout

- **Theme Modes**:
  - **Dark Mode (Obsidian)**: Deep neutral palette with high-contrast typography and subtle borders.
  - **Light Mode**: Clean paper aesthetic with soft elevation and crisp borders.
  - **Custom Accent Colors**: Ocean Blue, Forest Green, Sunset Orange, Royal Purple, Rose Pink, Crimson Red, Charcoal Amber.
- **Responsive Multi-Pane Layout**:
  - **Desktop (Width ≥ 900px)**: 3-pane layout (Collapsible Sidebar Navigation, Notes List, Full Block Editor).
  - **Tablet (600px ≤ Width < 900px)**: 2-pane layout (Compact Sidebar + Dynamic Content/Editor).
  - **Mobile (Width < 600px)**: Bottom Navigation Bar with full-screen editor transitions and system pop handling.
- **Branding Assets Suite**:
  - Official custom LetNote logo (notebook + pen emblem with custom typography).
  - Multi-resolution launcher icons for Android, iOS, macOS, Windows (`.ico`), and Web (`favicon`, maskable icons).
