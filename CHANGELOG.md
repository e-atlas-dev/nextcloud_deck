# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Known issues
- Moving cards between stacks is temporarily disabled.

---

## [1.0.0] - Initial release

### Added
- Full Kanban board with horizontal scroll and drag-to-reorder within a stack
- Offline-first: all boards, stacks and cards cached in Hive CE
- Nextcloud Login Flow v2 via in-app WebView
- Offline sync queue: edits queued and replayed on reconnect (FIFO, 5-retry limit)
- Conflict detection: lastModified comparison; side-by-side resolution UI
- Sync logs: timestamped record of every sync, queue drain, and conflict resolution
- Filters: assignee, due date, overdue; sort by order, due date, alphabetical
- Global search across all boards
- Create, edit, delete boards, stacks and cards; archive/unarchive boards
- Soft-deleted board filtering via deletedAt field
- Due date picker with overdue and due-today indicators
- Markdown rendering in card descriptions
- Dark mode following system setting
- Onboarding: animated 3-page intro on first launch
- Fully localised (English); all strings in lib/l10n/app_en.arb
- Offline banner with pending operation count
- Settings: manual sync, conflict resolution preference, cache clear, sync logs
