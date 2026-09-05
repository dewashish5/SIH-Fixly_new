# Implementation Plan: Home Screen Map Hero & Nested Scroll Refactor

## 1. Architectural Pivot: `NestedScrollView`
Replace the current `CustomScrollView` in `CustomerHomePage` with a `NestedScrollView`. This allows the header (map and categories) to collapse, while the body (services list) scrolls independently once the header is pinned.

## 2. Pinned Map Header (`SliverAppBar`)
- **Component**: `SliverAppBar`
- **Behavior**: `pinned: true`, `expandedHeight: 350` (approximate).
- **Foreground (Title)**: Greeting, Name, Address (with tap-to-open location picker), and Notification bell.
- **Background (`FlexibleSpaceBar`)**:
  - Full-width `FixlyMapView` (`claimGestures: false`).
  - **Blur Gradient overlay**: Instead of a dark solid gradient, use a `BackdropFilter` with `ImageFilter.blur` combined with a top-down fading gradient. This ensures the text/status bar is visible without making the map look dark.

## 3. Pinned Categories Card (`SliverPersistentHeader`)
- **Component**: `SliverPersistentHeader` (pinned below the `SliverAppBar`).
- **Styling**: Container with a white background and `borderRadius: BorderRadius.vertical(top: Radius.circular(24))`. This creates the "card covering the map" effect as the user scrolls.
- **Content**: The Categories horizontal list.
- **Behavior**: As the user scrolls up, this card slides up to cover the map and pins itself right below the collapsed App Bar (which shows the greeting/address).

## 4. Lazy-Loaded Services Body (`ListView.builder`)
- **Component**: `ListView.builder` inside the `NestedScrollView`'s `body`.
- **Behavior**: Vertical scrollable list of "Popular Services".
- **Features**: 
  - Add shimmer loading effect for initial load.
  - Implement basic pagination/lazy-loading structure.

## 5. Pull-to-Refresh Support
- Wrap `NestedScrollView` in a `RefreshIndicator`.
- Ensure the background color behind the scrollview matches the blur/gradient theme so when the user pulls down, it looks seamless.
