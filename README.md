# esp_home

A new Flutter project.

## Structure

Home screen UI and logic are split under `lib/home/` for easier maintenance.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Startup / loading behavior

- App initialization is completed on `SplashScreen`.
- After initialization, the app navigates directly to `HomePage` (no intermediate circular loading route).
- On background (`inactive`/`paused`), non-essential work is paused:
  - Firebase realtime subscription is stopped on mobile/web.
  - Desktop polling timer is stopped.
- On resume, listeners/polling are restarted.

## Android home screen widgets

The app now includes Android widgets that follow the app theme:

1. **Single relay widgets**
   - `1x1` and `1x2` variants.
   - Configure relay key + label when adding.
   - Primary tap = relay toggle (same as in-app tap).
   - `ALT` tap = sensor-control toggle (long-press equivalent).

2. **All buttons widget (large)**
   - Shows up to four relay actions (+ `ALT` actions),
   - Includes `ALL ON`, `ALL OFF`, `SET TIME`, `OPEN APP`.

3. **Set time widget**
   - Opens app directly into the timeout flow.

### How to add widgets

1. Long-press home screen → **Widgets**.
2. Search for **ESP Home**.
3. Add one of:
   - Single Action 1x1
   - Single Action 1x2
   - All Buttons
   - Set Time
4. For Single Action widgets, enter relay key (e.g. `relay1`) and optional label.

### Platform limitations

- Android does not support custom app-defined long-press handlers on widgets (long press is reserved by launcher for move/resize).
- To preserve behavior parity, widgets expose a secondary **ALT** tap target that maps to the app’s long-press action (sensor toggle).
