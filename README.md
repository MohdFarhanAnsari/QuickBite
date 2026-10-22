# QuickBite — Food Delivery & Ordering Mobile App

A modern, full-featured food delivery mobile application built with **Flutter**, featuring a polished user experience, reactive state management with **Riverpod**, type-safe declarative navigation with **GoRouter**, and persistent local storage.

---

## 📱 App Highlights

- **Modern Culinary Design System:** Material 3 theming featuring an appetizing coral-orange brand palette (`#FF6B35`), clean typography powered by **Plus Jakarta Sans**, and fluid micro-animations.
- **Feature-First Clean Architecture:** Maintainable directory organization dividing features into `domain`, `data`, and `presentation` layers.
- **Reactive State Management:** Centralized and testable state handled via **Riverpod** providers and notifiers.
- **Declarative Deep Linking:** Stateful bottom navigation tabs (`StatefulShellRoute.indexedStack`) paired with parameterized root routes via **GoRouter**.
- **Offline Persistence:** Persistent order history, cart handling, and user address management using **SharedPreferences**.
- **Comprehensive Automated Test Suite:** Unit tests, widget tests, and a 30-step end-to-end simulated customer journey test.
- **Custom Branding Automation:** Programmatic asset generator (`tool/generate_branding_assets.dart`) producing high-resolution app icons, adaptive foreground/background layers, and splash graphics.

---

## 📌 Implementation Disclosures (Demo / Portfolio Project)

To maintain complete transparency for reviewers and portfolio visitors:

> **Important Notices:**
> 1. **Restaurant & Menu Data:** All restaurant profiles, dishes, pricing, ratings, and dietary indicators are loaded from a deterministic, high-fidelity local dataset (`MockRestaurantData`). There is no live remote restaurant backend.
> 2. **Checkout & Payment Simulation:** The checkout interface supports address selection, delivery speed tiers, promo code calculation, and payment method selection (UPI, Credit/Debit Card, Cash on Delivery). This is a **client-side simulation** built to demonstrate UI state transitions, form validations, and price calculation logic. **No live payment gateway** (such as Stripe or Razorpay) is integrated, and no financial transactions are processed.
> 3. **Order Tracking Lifecycle:** The live tracking screen displays a step-by-step progress timeline (`Order Placed` ➔ `Preparing` ➔ `On the Way` ➔ `Delivered`). This is a **simulated status flow** showcasing UI states and lifecycle badges. It does not connect to live GPS vehicle tracking, driver telematics, or real-time socket connections.
> 4. **Backend Architecture:** The application operates in client-only demo mode with local storage persistence, designed to highlight frontend Flutter engineering, clean architecture, and UI craft.

---

## ✨ Features

### 1. Splash & Branded App Launch
- Native splash screen integration using `flutter_native_splash`.
- Branded in-app splash sequence with animated logo reveal and automatic route transition to the main interface.

### 2. Home & Restaurant Discovery
- **Location Selector:** Address header with bottom-sheet picker to toggle between home, work, and custom delivery locations.
- **Interactive Search:** Live search bar with category and cuisine filtering.
- **Promotional Banners:** Interactive marketing banners with discount codes (`QUICK50`).
- **Category Carousel:** Horizontal food category selector (Pizza, Burgers, Biryani, Asian, Rolls, Desserts).
- **Curated Restaurant Listings:** Restaurant cards displaying ratings, review counts, estimated delivery times, delivery fees, and distance tags.

### 3. Restaurant Menu & Details
- Dynamic header with restaurant imagery, cuisine tags, distance, and operating status.
- Menu categorized into curated sections with item descriptions, prices (₹ INR), dietary indicators (Veg/Non-Veg), and "Popular" badges.

### 4. Interactive Food Customization
- Dedicated item customizer screen with image hero header.
- **Single-select options:** Portion sizes (e.g., Regular 8", Large 12") and crust selections.
- **Multi-select add-ons:** Extra toppings, cheese bursts, dips, and sauces with per-option price modifiers.
- Dynamic subtotal updates reflecting active modifier selections in real time.
- Special cooking instructions text area.

### 5. Cart Management & Pricing Engine
- Global cart provider managing line items, selected customization groups, and quantities.
- Single-restaurant cart validation safeguards (prompting when switching restaurants).
- Dynamic pricing breakdown calculating subtotal, delivery fee tiers, promo discounts, and final total.
- Interactive quantity controls and item removal with undo feedback.

### 6. Checkout & Order Confirmation
- Delivery address review and bottom-sheet selection.
- Delivery speed options (Standard vs. Express delivery with dynamic fee recalculation).
- Promo code application with instant feedback.
- Payment method selector: UPI (GPay, PhonePe, Paytm), Credit/Debit Cards, and Cash on Delivery.
- Animated Order Success screen confirming placement and transitioning directly into live order tracking.

### 7. Order History & Live Tracking
- **Order Tracking:** Multi-stage visual timeline displaying order status transitions (`Pending`, `Preparing`, `On the Way`, `Delivered`, `Cancelled`).
- **Order Details Screen:** Itemized order receipt breakdown, delivery address, delivery method, and payment summary.
- **Persistent Order History:** Placed orders persist across app restarts using local storage.

### 8. Profile & Account
- User profile overview with quick links to saved addresses, payment methods, notifications, and app preferences.

---

## 🏛️ Architecture & Tech Stack

```
quickbite/
├── lib/
│   ├── core/                        # Global & foundation layer
│   │   ├── constants/               # Colors, Spacing, Typography
│   │   ├── router/                  # GoRouter configuration & routes
│   │   ├── storage/                 # LocalStorageService (SharedPreferences)
│   │   └── theme/                   # Material 3 ThemeData & palette
│   ├── features/                    # Feature-First modules
│   │   ├── cart/                    # Cart domain, provider, and screens
│   │   ├── checkout/                # Checkout flow, order models, success screen
│   │   ├── home/                    # Home screen, categories, promo widgets
│   │   ├── orders/                  # Order repository, tracking, status badges
│   │   ├── profile/                 # Profile and account screens
│   │   ├── restaurants/             # Mock data, models, menu & food details
│   │   └── splash/                  # Branded splash screen
│   ├── shared/                      # Reusable cross-feature widgets
│   │   └── widgets/                 # AppNetworkImage, SectionHeader, MainShellScreen
│   └── main.dart                    # App entry point & dependency injection
├── test/
│   ├── unit/                        # Isolated unit tests for models & repos
│   ├── widget_test.dart             # Core widget verification
│   ├── day4_orders_widget_test.dart # Orders & tracking widget tests
│   └── e2e_complete_journey_test.dart # 30-step complete journey integration test
└── tool/
    └── generate_branding_assets.dart # Script generating app icon & splash assets
```

### Key Libraries & Dependencies

| Dependency | Purpose |
| :--- | :--- |
| **`flutter_riverpod`** (`^3.4.3`) | Reactive state management, dependency injection, and state providers |
| **`go_router`** (`^18.0.2`) | Declarative routing with `StatefulShellRoute` for bottom tabs & deep links |
| **`shared_preferences`** (`^2.5.6`) | Client-side persistent storage for orders and user state |
| **`google_fonts`** (`^9.0.0`) | Plus Jakarta Sans modern typography |
| **`cached_network_image`** (`^4.0.4`) | Efficient image caching with placeholder and fallback states |
| **`flutter_native_splash`** (`^2.4.8`) | Native Android splash screen configuration |
| **`flutter_launcher_icons`** (`^0.14.4`) | Automated app icon generation for Android |
| **`intl`** (`^0.20.3`) | Currency and date formatting |

---

## 🧪 Testing Suite

QuickBite maintains extensive automated test coverage across unit, widget, and integration levels:

```
test/
├── unit/
│   ├── cart_checkout_test.dart          # Cart price calculations & checkout validation
│   ├── domain_models_test.dart          # Serialization/deserialization of domain models
│   ├── food_image_audit_test.dart       # Validation of image URLs and fallback resilience
│   ├── local_persistence_test.dart      # SharedPreferences serialization & deserialization
│   ├── orders_test.dart                 # Order creation, updates, and status lifecycle
│   ├── restaurant_repository_test.dart  # Restaurant querying, category filtering, search
│   └── splash_screen_test.dart          # Splash screen timer and routing verification
├── widget_test.dart                     # UI layout, chips, cards, and navigation widgets
├── day4_orders_widget_test.dart         # Order cards, status badges, and tracking timeline
└── e2e_complete_journey_test.dart       # 30-step end-to-end customer journey simulation
```

### Running the Tests

To run the full test suite with all unit and widget tests:

```bash
flutter test
```

To run a specific test suite (e.g., the End-to-End customer journey):

```bash
flutter test test/e2e_complete_journey_test.dart
```

> **Note for CI/CD:** Tests use `GoogleFonts.config.allowRuntimeFetching = false` and mock network fallbacks to guarantee 100% offline, deterministic execution.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator running API 21+

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd quickbite
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **(Optional) Re-generate brand assets:**
   If you wish to re-render the programmatic icon and splash assets:
   ```bash
   flutter test tool/generate_branding_assets.dart
   ```

4. **Verify static analysis:**
   ```bash
   flutter analyze
   ```

5. **Run the test suite:**
   ```bash
   flutter test
   ```

6. **Launch the application:**
   ```bash
   flutter run
   ```

### Building the Debug APK

To produce a local debug APK for physical testing:

```bash
flutter build apk --debug
```

The compiled APK will be generated at:
```
build/app/outputs/flutter-apk/app-debug.apk
```
