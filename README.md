# Coupon Pro

A Flutter application for generating coupon with local SQLite storage.

## Features

- **Dashboard** — View totals of generated coupons, batches, and boxes with pull-to-refresh.
- **Generate Coupons** — Fill in operator name and location to trigger batch coupon generation:
  - Creates 1 batch → 5 boxes → 1,000 coupons per box (5,000 coupons total per run).
  - Each coupon gets a unique zero-padded serial number.
  - Winning serial numbers and prize amounts are randomly assigned per box.
- **Production Log Report** — Browse all batches with operator name, location, date/time, and expandable box/coupon details.

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter / Material Design |
| Local Database | SQLite via `sqflite` |
| Price Formatting | `intl` |
| Path Resolution | `path` |

## Database Schema

```
batches       — id, operator_name, location, total_coupons, created_at
  └── boxes   — id, batch_id, created_at
        └── coupons — id, serialnumber, box_id, amount, created_at
```

## Project Structure

```
lib/
├── main.dart
├── core/
│   └── database/
│       └── database_helper.dart   # SQLite singleton & queries
├── features/
│   ├── home/
│   │   └── pages/main_page.dart           # Dashboard
│   └── coupon/
│       └── pages/
│           ├── generate_coupons_form.dart  # Coupon generation form
│           └── production_log_report.dart  # Batch history report
└── shared/
    └── widgets/
        ├── title_bar.dart
        ├── input_field.dart
        ├── primary_button.dart
        └── error_alert.dart
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.5`
- Dart SDK `^3.11.5`
- Android / iOS emulator or physical device

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd coupons

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release
```

## Notes

- A maximum 2 batch limit is enforced at runtime — the app blocks generation once the limit is reached.
- All data is stored locally on-device; no network connection is required.
