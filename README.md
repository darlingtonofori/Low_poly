# Lowpoly

Simple online 1v1 games (Tic-Tac-Toe live now, Chess/Ludo stubbed) — a lightweight Roblox-style hub.

## Structure

```
lowpoly/
  mobile/     Flutter app (this gets built into an APK by GitHub Actions)
  backend/    Node.js + Socket.IO server — deploy this to your VPS
  .github/workflows/build.yml   builds the APK on every push to main
```

## Important — first push will look different from later ones

This zip only has `lib/` and `pubspec.yaml`, not the full Flutter platform
folders (`android/`, `ios/`, etc.) — those are generated automatically by
the GitHub Actions workflow the first time it runs, since they're bulky
boilerplate you don't need to hand-edit. After the first successful build,
GitHub will have committed nothing extra to your repo (the android/ folder
is generated fresh in each CI run, not committed back) — build times stay
consistent. If you ever want it permanently in the repo instead (e.g. to
add a custom app icon or splash screen), say so and we'll commit it once
and drop that generation step.

## First run (Termux)

```bash
cd lowpoly
git add .
git commit -m "init lowpoly scaffold"
git push origin main
```

GitHub Actions will build the APK automatically. Go to the repo's
**Actions** tab → latest run → **Artifacts** → download `lowpoly-release-apk`.

## Backend — deploy on your VPS

```bash
cd backend
npm install
npm start
```

By default it listens on port 3000. Open that port in your VPS firewall
(you have a Firewall tool right there in your VPS panel).

Then in `mobile/lib/services/socket_service.dart`, change:

```dart
const String kServerUrl = 'http://YOUR_VPS_IP:3000';
```

to your actual VPS IP or domain. **Before real users touch this**, put
Nginx + Let's Encrypt in front of it and switch to `wss://` — plain
`ws://` over the open internet means anyone on the network path can read
game traffic.

## Google Sign-In (not wired yet)

The login screen has a "Continue as Guest" fallback so you can test
everything else first. To turn on real Google Sign-In:

1. Create a Firebase project at console.firebase.google.com
2. Add an Android app — package name must match `applicationId` in
   `mobile/android/app/build.gradle`
3. Download `google-services.json` into `mobile/android/app/`
4. Add the Google Services Gradle plugin (ask for this step when ready —
   it touches two gradle files and needs your SHA-1 fingerprint)

## Adding Chess or Ludo

Use `mobile/lib/screens/games/tic_tac_toe_screen.dart` and
`backend/games/ticTacToe.js` as the template:

- Backend: one file per game with `createMatch`, `applyMove`,
  `checkWinner`/game-over logic. Server stays authoritative — client only
  ever sends a move, never a board state.
- Frontend: one screen per game, same three socket events
  (`match:found`, `match:update`, `match:over`).
- Register the new game in `mobile/lib/models/game.dart` and
  `backend/server.js`'s `queues` object.

## Known gaps (v1, on purpose)

- No reconnect/forfeit handling if someone disconnects mid-match
- No persistent accounts/match history yet (no database wired in) —
  add Postgres or Firestore when you're ready for that
- No app icon signing config for release builds (Actions currently
  produces a debug-signed release APK, fine for testing, not for Play Store)
