# Project Architecture & File Map

> **Purpose**: Consult this map before inspecting files to minimize token consumption. Each file's purpose, scope, and responsibility is explicitly documented below.

---

## 1. Directory Tree & Roles

```text
InvestmentTracker/
├── AGENTS.md               <- Master agent instructions, guidelines, and cleanup rules
├── ARCHITECTURE.md         <- File registry and module responsibility map (this file)
├── pubspec.yaml            <- Flutter dependencies, SDK versions, fonts, and assets
├── analysis_options.yaml   <- Linter rules and static analysis configuration
├── lib/
│   └── main.dart           <- App entrypoint, theme, bottom navigation, and top-level tab routes
└── test/
    └── widget_test.dart    <- Smoke tests for top-level navigation and screen rendering
```

---

## 2. File Index & Responsibilities

| File Path | Description & Contents | When to Touch |
|---|---|---|
| [`lib/main.dart`](file:///C:/InvestmentTracker/lib/main.dart) | Contains `InvestmentTrackerApp`, `MainMobileScreen` (Bottom `NavigationBar` controller), and placeholder routes. | Only when adjusting root theme, main navigation tabs, or switching root routes. |
| [`lib/models/stock_holding.dart`](file:///C:/InvestmentTracker/lib/models/stock_holding.dart) | Data model for a stock holding with computed properties (gain/loss, value, percentage). | When adding new stock attributes or metrics. |
| [`lib/screens/investments/investments_screen.dart`](file:///C:/InvestmentTracker/lib/screens/investments/investments_screen.dart) | Main investments mobile UI: portfolio card, holdings list, swipe-to-delete, and add stock bottom sheet. | When modifying the stock investment screen UX. |
| [`AGENTS.md`](file:///C:/InvestmentTracker/AGENTS.md) | Agent rules, dead code deletion mandate, design standards. | When updating workspace rules or core constraints. |
| [`ARCHITECTURE.md`](file:///C:/InvestmentTracker/ARCHITECTURE.md) | Map of all files, their contents, and token-saving index. | **Update whenever a new file/module is added, moved, or deleted.** |
| [`COMMITS.md`](file:///C:/InvestmentTracker/COMMITS.md) | Log of every git commit ID, timestamp, and summary. | **Update with every git commit.** |
| [`pubspec.yaml`](file:///C:/InvestmentTracker/pubspec.yaml) | Package dependencies (e.g., charts, icons, state management, storage). | When adding new Flutter plugins/packages or assets. |
| [`test/widget_test.dart`](file:///C:/InvestmentTracker/test/widget_test.dart) | Top-level widget smoke test. | When root widgets or initial screen text change. |

---

## 3. Planned Module Architecture (To be created as needed)

When implementing the upcoming features, organize them strictly into:

```text
lib/
├── models/         # Data models (e.g., InvestmentAsset, PortfolioSummary, Transaction)
├── services/       # Local database, market price APIs, calculation services
├── state/          # State management (ChangeNotifier, Provider, Riverpod, or Bloc)
├── screens/
│   ├── investments/  # Investments listing, asset detail, add/edit asset modal
│   └── analytics/    # Portfolio allocation charts, performance curves, profit/loss breakdown
└── widgets/        # Shared mobile UI components (MetricCard, AssetTile, etc.)
```

> **Reminder:** Always update this file whenever new files or directories are created.
