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
| [`lib/models/investment_card_model.dart`](file:///C:/InvestmentTracker/lib/models/investment_card_model.dart) | Data model for `InvestmentCardModel` and `Transaction` (buy, sell, dividend) with date-wise sorting, cost basis, and quantity calculation. | When adding new card attributes or transaction types. |
| [`lib/services/yahoo_finance_service.dart`](file:///C:/InvestmentTracker/lib/services/yahoo_finance_service.dart) | Service for querying Yahoo Finance search/autocomplete API exclusively for stock search. | When altering stock search endpoints or headers. |
| [`lib/screens/investments/investments_screen.dart`](file:///C:/InvestmentTracker/lib/screens/investments/investments_screen.dart) | Main investments mobile UI: list of investment cards and date-wise transaction ledger. | When modifying the investment card UI or transaction modal. |
| [`lib/screens/investments/create_card_flow_screen.dart`](file:///C:/InvestmentTracker/lib/screens/investments/create_card_flow_screen.dart) | Multi-step full-screen flow for creating a card: Step 1 (Stock select + duplicate prevention), Step 2 (Tags), Step 3 (Initial Buy transaction). | When adjusting the card creation steps. |
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
