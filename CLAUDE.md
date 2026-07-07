# CLAUDE.md

Guidance for working in this repository. **Paper Block** is a Flutter mobile puzzle game.

## Startup flow

`main()` → `MaterialApp(home: SplashScreen)` → after exactly 2s → `MainMenuScreen`.
The splash ([lib/screens/splash_screen.dart](lib/screens/splash_screen.dart)) is a
**custom widget** (not `flutter_native_splash`) so it controls the fixed 2-second timing,
precaches `assets/logo.png` during the wait to avoid transition jank, and fades into the
menu. The logo lives at `assets/logo.png` (registered in `pubspec.yaml`). It navigates to
Home on every launch (no first-launch branch).

## Game concept & core mechanic

The player is given an outlined target shape (a set of highlighted grid cells) plus a
tray of colored polyomino pieces. The goal is to drag every piece from the tray onto
the board so that the pieces **exactly tile the target shape** — no gaps, no overlaps,
and nothing outside the outline.

- A piece can only be dropped where **all** of its cells land on empty target cells
  (`GameState.canPlace`). Invalid drops are rejected; a live "ghost" preview shows
  validity while dragging.
- Pieces are **not rotatable or flippable** — each piece is placed in its authored
  orientation. Solvability therefore depends on the level author, not runtime rotation.
- A level is complete when every target cell is covered
  (`GameState.isComplete`). Completion shows a celebration overlay and unlocks the
  next level.
- Progress (unlocked count + last played level) persists via `shared_preferences`.

## Folder structure & where key logic lives

```
lib/
├── main.dart                     # App entry: ad init, portrait lock, MaterialApp → MainMenuScreen
├── data/
│   └── levels.dart               # ★ All 60 levels defined here (level data)
├── models/
│   ├── level.dart                # Level model + Level.fromGrid() ASCII parser
│   ├── piece.dart                # Piece / PieceCell models (relative cell offsets)
│   └── game_state.dart           # ★ State management (ChangeNotifier): placement + validation
├── painters/
│   ├── board_painter.dart        # CustomPainter for the board, target outline, ghost
│   └── piece_painter.dart        # CustomPainter for individual pieces
├── screens/
│   ├── splash_screen.dart        # White splash, centered logo, 2s → main menu
│   ├── main_menu_screen.dart     # Title, Play, Continue
│   ├── level_select_screen.dart  # Level grid with lock/unlock state
│   └── game_screen.dart          # ★ Gameplay screen: header (hint/reset), board, tray, banner
├── services/
│   └── sound_service.dart        # Persisted sound on/off + asset-free click/haptic feedback
└── widgets/
    ├── banner_ad_placeholder.dart # ★ Reserved adaptive-banner region (placeholder, no SDK)
    ├── game_board_widget.dart    # Board + drag-drop hit testing (pixel → grid col/row)
    ├── hint_button.dart          # ★ Top-right Hint button (placeholder "coming soon")
    └── piece_tray_widget.dart    # Draggable tray of remaining pieces
```

- **Level data:** `lib/data/levels.dart`
- **State management:** `provider` is a dependency but the app primarily uses a plain
  `ChangeNotifier` (`GameState`) held in `game_screen.dart` state and consumed via
  `ListenableBuilder`. `AdService` is also a `ChangeNotifier` singleton.
- **Validation:** `GameState.canPlace` / `isComplete` in `lib/models/game_state.dart`.

## How levels are defined/stored (data format)

There are **60 levels** with a difficulty ramp — board size and piece count grow from
~12 cells / 4 pieces (level 4) to ~56 cells / 13 pieces (level 60). Levels **1–3** are
hand-authored intros; levels **4–60** are machine-generated (see below) but land in the
same file in the same format.

Levels are **hardcoded in Dart** (compiled in, not loaded from JSON/assets) in the
`allLevels` list in [lib/data/levels.dart](lib/data/levels.dart). Each level is built
with `Level.fromGrid`:

```dart
Level.fromGrid(
  id: 1,
  name: 'First Step',
  rows: const [           // ASCII grid — '#' = target cell, '.' = empty
    '........',
    '..##....',
    '..###...',
    '....#...',
    '........',
  ],
  pieces: [               // pieces the player must place
    _p('1a', _coral, _coralD, [(0, 0), (1, 0), (0, 1)]),  // (col,row) offsets
    _p('1b', _blue,  _blueD,  [(0, 0), (1, 0), (1, 1)]),
  ],
),
```

- The `rows` strings are parsed by `Level.fromGrid` into `targetCells` — a list of
  `(col, row)` tuples for every `#`. Board dimensions come from the grid size.
- A **piece** is a set of relative `(dx, dy)` cell offsets, an id, and a color pair
  (`color` / `darkColor` for shading). Colors are shared constants (`_coral`, `_blue`, …)
  defined at the top of the file. `_p(...)` is a local helper wrapping the `Piece` ctor.
- Piece ids follow the convention `<levelId><letter>` (e.g. `12c`).

### How solvability is guaranteed

The game itself only validates **individual placements** (`canPlace`: cells must be
inside the target and unoccupied) and **overall completion** (`isComplete`: all target
cells covered) — it never searches for a solution. Because pieces cannot be
rotated/flipped, a level is solvable iff its pieces exactly tile the target in their
authored orientations. Two things enforce that:

1. **Generation by construction** — levels 4–60 come from
   [tool/gen_levels.py](tool/gen_levels.py), which carves a target shape and *partitions*
   it into polyominoes. The partition IS a valid no-rotation solution, so solvability is
   structural. Re-run with `python3 tool/gen_levels.py` to regenerate/extend (it
   overwrites `lib/data/levels.dart`; tweak the ramp/`NAMES`/size distribution there).
   The script also runs its own exact-cover solver before emitting each level.
2. **A repo test** — [test/levels_solvable_test.dart](test/levels_solvable_test.dart)
   independently backtrack-solves **every** level under the real game rules (fixed
   orientation, `canPlace` semantics) and asserts piece-cell count == target-cell count.
   This runs in `flutter test`, so any hand-edit that breaks a level fails CI.

When hand-authoring or editing a level, run `flutter test` — if it's unwinnable the
solvability test will fail (rather than shipping a dead level that only surfaces at
runtime).

## Known placeholders → what to make them real

**No AdMob SDK is integrated** — the `google_mobile_ads` dependency was intentionally
removed. Ads are represented by two isolated placeholder widgets so real AdMob code can be
dropped in later without touching gameplay logic. There are no native AdMob app IDs in the
Android/iOS manifests.

### 1. Banner — `lib/widgets/banner_ad_placeholder.dart`

`BannerAdPlaceholder` reserves the bottom region for an **Anchored Adaptive Banner** (full
device width; height = `heightFor(context)` ≈ 15% of screen height, clamped to the SDK's
50–90 dp band). It draws a bordered `[Banner Ad Placeholder]` box of exactly that height so
the layout won't shift when a real banner loads. It renders **nothing on web** (`kIsWeb`) —
ads are disabled there.

To go live: keep the widget's spot in `game_screen`'s column and swap the body of `build`
for an `AdWidget(ad: bannerAd)` sized via `AdSize.getAnchoredAdaptiveBannerAdSize(...)`.

### 2. Hint button — `lib/widgets/hint_button.dart`

`HintButton` sits top-right in the game header and currently shows a "Hints are coming
soon!" dialog — a **placeholder**, no rewarded-ad SDK. To make real: replace `_onPressed`
with the rewarded-ad flow (show ad → on reward, reveal a hint, e.g. a backtracking solver
highlighting a valid placement). Placement/styling stay unchanged.

Both widgets are self-contained — `game_screen` just embeds `const BannerAdPlaceholder()`
and `const HintButton()`; no gameplay code references any ad SDK.

## App identity

- Display name: **Paper Blocks** (`android:label`, iOS `CFBundleDisplayName`)
- Bundle/application ID: **`com.xufagroup.paperblock`**
  - Android `namespace` + `applicationId` in `android/app/build.gradle.kts`; Kotlin
    package `com.xufagroup.paperblock` at
    `android/app/src/main/kotlin/com/xufagroup/paperblock/MainActivity.kt`
  - iOS `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`
    (RunnerTests target is `com.xufagroup.paperblock.RunnerTests`)
- The internal Dart package name (`pubspec.yaml` `name: paper_block_game`, used in Dart
  imports like `package:paper_block_game/...`) is **unchanged** — it is not the app
  bundle ID and renaming it would break imports/tests.
- **Launcher (home-screen) icon** is generated by `flutter_launcher_icons` from
  `assets/icon/app_icon.png` (config block in `pubspec.yaml`). It writes the Android
  mipmaps + adaptive icon (white background, foreground inset 16%), the iOS `AppIcon`
  set, and the web icons/manifest. Regenerate after changing the source with
  `dart run flutter_launcher_icons`. This is **separate** from the in-app splash logo
  at `assets/logo.png`.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on connected device/emulator (debug)
flutter run -d <device_id>      # target a specific device (flutter devices to list)

flutter analyze                 # static analysis / lints (analysis_options.yaml)
flutter test                    # run tests (test/widget_test.dart)

flutter build apk               # Android APK
flutter build appbundle         # Android App Bundle (Play Store)
flutter build ios               # iOS (requires Xcode / macOS)
```

- SDK: Dart `^3.11.0`, Flutter with Material 3. Portrait-only.
- Key deps: `provider`, `shared_preferences`, `cupertino_icons`. (No ads SDK — see
  placeholders below.)
- The existing widget test just asserts the menu renders (`PLAY` button present); there
  are no gameplay/level tests yet.
