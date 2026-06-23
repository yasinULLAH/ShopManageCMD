# Changelog

> **Coverage**: This changelog covers all changes from the initial commit up to **2026-06-23**.
>
> **Next entry**: When adding new changes, append a new `## [Unreleased]` or version section below the last entry dated **2026-06-23**.

---

## [1.0.0] - 2026-06-23

Initial release of Shop Manager — a complete terminal-based retail and wholesale business management system built with Python and SQLite.

### Features

- **Initial system architecture** — Full implementation of shop management system with 50+ database tables covering products, customers, suppliers, sales, purchases, inventory, and accounting ([a832f73])
- **Console auto-maximization** — Window auto-fullscreen on launch with optimized 90x50 terminal dimensions for scrollbar-free display ([2af0db0])
- **Usage-based menu layout** — Two-column main menu with 38+ options ordered by real-world usage frequency ([2af0db0])
- **Default user roles** — Four pre-configured user roles: Admin (full access), Manager (operations), Cashier (POS/sales), Viewer (read-only) ([068f63a])
- **Role-based access control** — Complete RBAC with frontend menu filtering and backend method guards across all modules ([b34bc42])
- **Clear sample data utility** — Option to wipe all transactional data while preserving default users, settings, and configuration ([b38c826])
- **Automated backup rotation** — Configurable `max_backups` setting with automatic cleanup of oldest backups ([d78bbe2])

### Refactoring

- **Object-oriented architecture** — Restructured flat procedural code into maintainable OOP classes: Database, AuthManager, MasterManager, PartyManager, TradeManager, ReportManager ([a3d10ba])

### Documentation

- **Bilingual README** — Complete English and Urdu documentation covering all 38+ modules, database structure, and system behaviors ([a8cdcb8])
- **README enhancements** — Added GitHub and technology badges, console features section, role permission matrix ([527209f])
- **README cleanup** — Refined project title and improved login table formatting ([79f52e6])
- **Comprehensive user guide** — 1146-line userguide.md with step-by-step instructions, keyboard shortcuts, and real-world examples ([7990326])
- **Clear sample data docs** — Added utility documentation to both README and user guide ([21bd11d])
- **Backup settings docs** — Documented `max_backups` configuration and backup rotation feature ([141b95e])
- **Screenshots and demo video** — Added visual documentation with 20+ screenshots and demonstration video ([f4e6035])
- **Screenshot reorganization** — Renamed screenshots to standardized numbered format and embedded throughout documentation ([e0334b5])

### Chores

- **Database seeding** — Added sample data for development and testing ([f2e5b7c], [695ccef])
- **File rename** — Renamed main executable from `ShopApp (1).cmd` to `ShopApp.cmd` ([23ec112])
- **Database checkpoints** — Incremental database snapshots throughout development ([d5cb14c], [c72e9cc])
- **Remove obsolete backup** — Cleaned up `ShopApp.cmd.bak` ([24c1278])
- **Demo database backup** — Added clean database snapshot for distribution ([406f4e0])
- **Gitignore setup** — Added `.gitignore` and removed stale entries ([dff15ce], [74ecd7f])

---

[a832f73]: https://github.com/yasinULLAH/ShopManageCMD/commit/a832f73
[f2e5b7c]: https://github.com/yasinULLAH/ShopManageCMD/commit/f2e5b7c
[a3d10ba]: https://github.com/yasinULLAH/ShopManageCMD/commit/a3d10ba
[23ec112]: https://github.com/yasinULLAH/ShopManageCMD/commit/23ec112
[d5cb14c]: https://github.com/yasinULLAH/ShopManageCMD/commit/d5cb14c
[a8cdcb8]: https://github.com/yasinULLAH/ShopManageCMD/commit/a8cdcb8
[695ccef]: https://github.com/yasinULLAH/ShopManageCMD/commit/695ccef
[24c1278]: https://github.com/yasinULLAH/ShopManageCMD/commit/24c1278
[2af0db0]: https://github.com/yasinULLAH/ShopManageCMD/commit/2af0db0
[527209f]: https://github.com/yasinULLAH/ShopManageCMD/commit/527209f
[79f52e6]: https://github.com/yasinULLAH/ShopManageCMD/commit/79f52e6
[7990326]: https://github.com/yasinULLAH/ShopManageCMD/commit/7990326
[068f63a]: https://github.com/yasinULLAH/ShopManageCMD/commit/068f63a
[c72e9cc]: https://github.com/yasinULLAH/ShopManageCMD/commit/c72e9cc
[b38c826]: https://github.com/yasinULLAH/ShopManageCMD/commit/b38c826
[21bd11d]: https://github.com/yasinULLAH/ShopManageCMD/commit/21bd11d
[b34bc42]: https://github.com/yasinULLAH/ShopManageCMD/commit/b34bc42
[d78bbe2]: https://github.com/yasinULLAH/ShopManageCMD/commit/d78bbe2
[141b95e]: https://github.com/yasinULLAH/ShopManageCMD/commit/141b95e
[406f4e0]: https://github.com/yasinULLAH/ShopManageCMD/commit/406f4e0
[f4e6035]: https://github.com/yasinULLAH/ShopManageCMD/commit/f4e6035
[e0334b5]: https://github.com/yasinULLAH/ShopManageCMD/commit/e0334b5
[dff15ce]: https://github.com/yasinULLAH/ShopManageCMD/commit/dff15ce
[74ecd7f]: https://github.com/yasinULLAH/ShopManageCMD/commit/74ecd7f
