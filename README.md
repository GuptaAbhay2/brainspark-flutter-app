# 🧠 BrainSpark - Mobile App (Flutter)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Riverpod-State_Management-blue?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Hive-Local_Storage-orange?style=for-the-badge" alt="Hive" />
  <img src="https://img.shields.io/badge/Dio-Networking-red?style=for-the-badge" alt="Dio" />
  <img src="https://img.shields.io/badge/Backend-Django_REST-092E20?style=for-the-badge&logo=django&logoColor=white" alt="Django" />
</p>

<p align="center">
  <strong>Train • Compete • Win</strong><br />
  A feature-rich, cross-platform mobile app designed to boost cognitive skills through time-bound mini-games, daily puzzle challenges, streak tracking, and live global leaderboards.
</p>

---

## 🎮 Game Modes & Mini-Games

BrainSpark includes a variety of cognitive training games with progressive level selection and active game timers:

* ⚡ **Speed Math & Word Math:** Rapid arithmetic challenges and word-based math logic to test mental speed under time constraints.
* 🧩 **Logic Puzzles:** Complex problem-solving puzzles designed to improve reasoning skills.
* 🔢 **Number Tap:** High-focus visual scanning and numerical speed tapping games.
* 🃏 **Memory Match:** Card-matching and pattern memory retention games with increasing difficulty levels.
* 📅 **Today's Puzzle (Daily Challenge):** Fresh daily brain teasers to build consistent habits and reward bonus points.

---

## 🏆 Gamification & Engagement

* 🔥 **Streak Tracking:** Tracks active daily gameplay streaks to encourage consistency.
* 📊 **Leaderboard Ranks:** Compete globally with **Weekly** and **All-Time** user rankings.
* 🏅 **Profile Badges:** Earnable milestones and achievement badges displayed on the user profile.
* ⏱️ **Real-Time Game Timers:** Precision countdowns and score multipliers based on time taken.
* 🔄 **Score & Sync System:** Dual local (Hive) and remote REST API score synchronization via `ScoreService`.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev/) (Dart) |
| **State Management** | [Riverpod](https://riverpod.dev/) (`userProvider`) |
| **Networking** | [Dio](https://pub.dev/packages/dio) with custom error handling |
| **Local Cache** | [Hive](https://pub.dev/packages/hive) & `hive_flutter` |
| **Routing & Theme** | Custom MaterialApp Router & Dark/Light System Theme |
| **Backend API** | Django REST Framework *(Hosted on Railway)* |

---

## 📁 Project Structure

```text
lib/
├── providers/
│   └── user_provider.dart        # User state, Auth, Streaks, & Hive sync
├── screens/
│   ├── daily_challenge_screen.dart
│   ├── home_screen.dart
│   ├── leaderboard_screen.dart
│   ├── logic_puzzle_screen.dart
│   ├── login_screen.dart
│   ├── memory_game_screen.dart
│   ├── memory_levels_screen.dart
│   ├── memory_match_screen.dart
│   ├── number_tap_game_screen.dart
│   ├── number_tap_levels_screen.dart
│   ├── number_tap_screen.dart
│   ├── profile_screen.dart
│   ├── reaction_chain_screen.dart
│   ├── speed_math_game_screen.dart
│   ├── speed_math_levels_screen.dart
│   ├── speed_math_screen.dart
│   ├── splash_screen.dart
│   └── word_math_screen.dart
├── services/
│   ├── api_service.dart          # REST API endpoints & Dio HTTP client
│   └── score_service.dart        # Game scoring & streak logic
├── utils/
│   ├── router.dart               # Navigation routes
│   └── theme.dart                # App design tokens & styling
└── main.dart                     # Entry point & Hive initialization
```
---


## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0`)
* Android Studio / VS Code
* Physical Device or Emulator

### Setup Instructions

1. **Clone the repository:**
```bash
git clone [https://github.com/GuptaAbhay2/brainspark-flutter-app.git](https://github.com/GuptaAbhay2/brainspark-flutter-app.git)
cd brainspark-flutter-app

```


2. **Install dependencies:**
```bash
flutter pub get

```


3. **Verify API Endpoint:**
Check `lib/services/api_service.dart` to ensure backend endpoint is configured:
```dart
static const String baseUrl = '[https://brainspark-backend-production-22d9.up.railway.app/api](https://brainspark-backend-production-22d9.up.railway.app/api)';

```


4. **Run the App:**
```bash
flutter run

```



---

## 🔗 Related Repositories

* **Backend Repository:** [BrainSpark Django Backend](https://github.com/GuptaAbhay2/brainspark-backend)

---

## 📝 License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

```

```
