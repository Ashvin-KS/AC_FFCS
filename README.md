# ♟️ Offline Chess - 1v1 Local Multiplayer

A fully-featured offline chess game for Android with complete chess rules, ELO rating system, game timers, and player statistics.

![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-green)
![Version](https://img.shields.io/badge/Version-2.0.0-blue)

## 📱 Features

### Complete Chess Rules
- ✅ All standard piece movements (King, Queen, Rook, Bishop, Knight, Pawn)
- ✅ **Special Moves**: Castling (kingside & queenside), En Passant, Pawn Promotion
- ✅ **Check Detection**: Visual warning when king is in check
- ✅ **Checkmate & Stalemate**: Automatic game end detection
- ✅ **Draw Detection**: Threefold repetition, 50-move rule, insufficient material

### ELO Rating System
- 📊 Proper ELO calculation with K-factor
- 📈 Rating changes displayed after each game
- 🏆 Rating categories: Beginner → Grandmaster
- 📉 Track rating history and progress

### Player Statistics
- 👤 Player profiles with detailed stats
- 📊 Win/Loss/Draw record
- 📈 Win rate percentage
- 🔥 Current and best win streaks
- 🏆 Leaderboards sorted by ELO and win rate

### Game Timers
- ⏱️ Multiple time controls:
  - **Bullet**: 1+1, 2+1
  - **Blitz**: 3 min, 5+3
  - **Rapid**: 10+5, 15+10
  - **Classical**: 30 min
  - **Unlimited**: No time limit
- ⚡ Time increments per move
- 🚨 Low time warning (under 30 seconds)

### Game Features
- 📝 Move history in algebraic notation
- 🎯 Legal move highlighting
- 📍 Last move indication
- 📐 Board coordinates (a-h, 1-8)
- 🏳️ Resign and draw offer options
- 💾 Automatic game saving

### User Interface
- 🌙 Dark theme optimized for gameplay
- 📱 Portrait mode design
- 🎨 Clean, modern UI
- ⚡ Smooth animations

---

## 📥 Installation

### Method 1: Direct APK Installation (Recommended)

1. **Download the APK**
   - Locate the file: `build/app/outputs/flutter-apk/app-release.apk`
   - Transfer it to your Android device

2. **Enable Unknown Sources**
   - Go to **Settings** → **Security**
   - Enable **"Install from unknown sources"** or **"Allow from this source"**
   - This varies by Android version

3. **Install the APK**
   - Open the APK file on your device
   - Tap **"Install"**
   - Wait for installation to complete

4. **Launch the App**
   - Tap **"Open"** or find "Offline Chess" in your app drawer

### Method 2: Build from Source

#### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.11+)
- [Android Studio](https://developer.android.com/studio) (optional)
- Android SDK (installed via Android Studio or command line)

#### Steps

```bash
# 1. Clone or navigate to the project
cd ac_ffcs

# 2. Install dependencies
flutter pub get

# 3. Build the APK
flutter build apk --release

# 4. The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

#### Debug Build (for testing)
```bash
flutter run
```

---

## 🎮 How to Play

### Starting a Game
1. Enter player names for White and Black
2. Select a time control
3. Configure game settings (legal moves, coordinates)
4. Tap **"Start Game"**

### During the Game
- **Tap a piece** to select it
- **Green dots** show legal moves
- **Green border** shows capture squares
- **Tap a highlighted square** to move
- **Yellow highlight** shows the last move

### Game Controls
- 🏳️ **Flag icon**: Resign the game
- 🤝 **Handshake icon**: Offer a draw

### Pawn Promotion
When a pawn reaches the opposite end of the board, a dialog appears to select the promotion piece:
- Queen (Q)
- Rook (R)
- Bishop (B)
- Knight (N)

---

## 📊 Understanding ELO Ratings

### Rating Categories
| Rating | Category |
|--------|----------|
| < 1000 | Beginner |
| 1000-1199 | Novice |
| 1200-1399 | Intermediate |
| 1400-1599 | Advanced |
| 1600-1799 | Expert |
| 1800-1999 | Candidate Master |
| 2000-2199 | Master |
| 2200-2399 | Senior Master |
| 2400+ | Grandmaster |

### How ELO Works
- Win against a higher-rated opponent = more points gained
- Loss against a lower-rated opponent = more points lost
- Draws favor the lower-rated player
- K-factor: 32 (standard for most players)

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── chess_piece.dart      # Chess piece definitions
│   ├── chess_move.dart       # Move representation
│   ├── player_stats.dart     # Player statistics & ELO
│   └── game_history.dart     # Game records & time controls
├── screens/
│   ├── home_screen.dart      # Main menu
│   ├── game_screen.dart      # Chess board & gameplay
│   ├── game_over_screen.dart # Results & ELO changes
│   ├── stats_screen.dart     # Leaderboards & history
│   ├── settings_screen.dart  # App settings
│   └── promotion_dialog.dart  # Pawn promotion UI
└── services/
    ├── chess_engine.dart     # Complete chess logic
    └── storage_service.dart  # Local data persistence
```

---

## 🔧 Technical Details

### Dependencies
- `flutter` - UI framework
- `path_provider` - Local file storage
- `shared_preferences` - Key-value storage

### Chess Engine Features
- Bitboard-inspired position representation
- Legal move generation with pin detection
- FEN-like position hashing for repetition detection
- Efficient check detection algorithm

### Data Storage
- Player statistics stored locally as JSON
- Game history (last 100 games)
- Settings persistence across sessions

---

## 🎯 Future Enhancements

- [ ] AI opponent with difficulty levels
- [ ] Online multiplayer
- [ ] PGN import/export
- [ ] Game analysis mode
- [ ] Custom themes and board styles
- [ ] Sound effects
- [ ] Multiple language support

---

## 📄 License

This project is open source and available under the MIT License.

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

---

## 📞 Support

If you encounter any issues or have questions, please open an issue on the project repository.

---

**Enjoy playing chess! ♟️**
