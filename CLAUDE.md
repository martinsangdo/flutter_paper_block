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
│   ├── board_painter.dart        # CustomPainter for the board, target outline, ghost, hint
│   └── piece_painter.dart        # CustomPainter for individual pieces
├── screens/
│   ├── splash_screen.dart        # White splash, centered logo, 2s → main menu
│   ├── main_menu_screen.dart     # Title, Play, Continue
│   ├── level_select_screen.dart  # Level grid with lock/unlock state
│   └── game_screen.dart          # ★ Gameplay screen: header (hint/reset), board, tray, banner
├── services/
│   ├── sound_service.dart        # Persisted sound on/off + asset-free click/haptic feedback
│   ├── ad_config.dart            # ★ AdMob unit IDs (Google test IDs; swap before release)
│   └── ad_service.dart           # ★ AdMob SDK init + rewarded-ad load/show (ChangeNotifier)
└── widgets/
    ├── banner_ad_widget.dart     # ★ Anchored adaptive AdMob banner (bottom of game_screen)
    ├── game_board_widget.dart    # Board + drag-drop hit testing (pixel → grid col/row)
    ├── hint_button.dart          # ★ Top-right Hint button: rewarded ad (once/level) → full-solution reveal
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

## Ads (AdMob via `google_mobile_ads`)

AdMob is **integrated** (`google_mobile_ads` dependency). The SDK is initialized fire-and-
forget in `main()` (`AdService.instance.initialize()`) so it never delays the first frame.
Ads are **disabled on web / desktop** (`AdConfig.adsSupported`, gated on `kIsWeb` + platform).

**⚠️ Test IDs — swap before release.** Every ad identifier currently uses Google's official
*sample/test* IDs (safe to ship in dev; they never earn revenue and never risk a policy
strike). Before release, replace **all three** places:
1. Ad **unit** IDs in [lib/services/ad_config.dart](lib/services/ad_config.dart) (banner + rewarded, per platform).
2. Android **app** ID: `com.google.android.gms.ads.APPLICATION_ID` meta-data in
   [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).
3. iOS **app** ID: `GADApplicationIdentifier` in [ios/Runner/Info.plist](ios/Runner/Info.plist).

`google_mobile_ads 9.0.0` requires Android **minSdk 24** — already Flutter's default
(`flutter.minSdkVersion`), so no Gradle change was needed.

### 1. Banner — `lib/widgets/banner_ad_widget.dart`

`BannerAdWidget` loads an **Anchored Adaptive Banner** at the bottom of `game_screen`'s
column. It reserves a fixed-height box (`reservedHeight` ≈ 15% of screen height, clamped
50–90 dp) while the ad loads or if it fails, so the gameplay layout never shifts, then
swaps in the real `AdWidget` once loaded. Size comes from
`AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(Orientation.portrait, width)`.
Self-contained: `game_screen` just embeds `const BannerAdWidget()`.

### 2. Rewarded hint — `lib/widgets/hint_button.dart` + `lib/services/ad_service.dart`

Tapping the top-right `HintButton` reveals the **completed board**: a backtracking
exact-cover solver (`GameState.solveHint`) computes a placement for *every* remaining
piece, and `BoardPainter` draws the full solution as a preview overlay (each piece in
its own color with a golden hint border). The overlay is cleared when the player places
a piece or on reset; re-tap Hint to recompute it for the new state.

The rewarded ad is charged **once per level**: the first Hint tap plays a **rewarded ad**
(`AdService.showRewarded`) and, on reward, calls `GameState.markHintUnlocked()`, so every
later Hint tap that level reveals instantly with no ad. `AdService` preloads the next
rewarded ad after each show. The `hintUnlocked` flag lives on `GameState` (per level
instance) and survives `reset()`.

Graceful degradation, in priority order:
- If the current board is **no longer solvable** (a legal-but-wrong placement is blocking),
  `solveHint` returns null and the button shows an "undo/reset" dialog — **no ad is shown**.
- If **no rewarded ad is ready** (offline / not yet loaded), the hint is granted anyway (and
  marked unlocked) so gameplay is never blocked by ad availability.

`GameState.solveHint` mirrors `canPlace` semantics exactly (fixed orientation, cells inside
the target and unoccupied) and returns the full solution (`List<(Piece, int, int)>?`);
[test/hint_solver_test.dart](test/hint_solver_test.dart) asserts that placing that solution
completes every level.

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
- Key deps: `provider`, `shared_preferences`, `audioplayers`, `cupertino_icons`,
  `google_mobile_ads` (see Ads section above).
