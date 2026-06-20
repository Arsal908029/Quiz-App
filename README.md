# Quiz Master

A comprehensive Flutter-based quiz application that allows users to take quizzes on various categories, track their progress, compete on leaderboards, and enjoy daily challenges. Built with a clean architecture and powered by Supabase for backend services.

## Features

### User Authentication
- **Sign Up & Sign In**: Secure user registration and login using Supabase authentication
- **Profile Management**: Update user information, avatar, and view personal statistics

### Quiz System
- **Category-Based Quizzes**: Browse and select from various quiz categories
- **Timed Quizzes**: 10-minute timer for each quiz session with time warnings
- **Scoring System**: Real-time score tracking with instant feedback
- **Question Navigation**: Skip questions or navigate through the quiz
- **Results Screen**: Detailed quiz results with score breakdown and performance analysis

### Daily Challenges
- **Daily Quiz Challenge**: Special daily quizzes to keep users engaged
- **Streak Tracking**: Maintain daily participation streaks

### Leaderboard
- **Global Rankings**: Compete with other users on the leaderboard
- **Score-Based Ranking**: Rankings based on total scores and quiz completion

### User Experience
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Animations & Effects**: Smooth animations, Lottie animations, confetti celebrations
- **Responsive Design**: Optimized for mobile devices
- **Loading States**: Shimmer effects and progress indicators

### Data Management
- **Supabase Integration**: Real-time database for user data, quizzes, and scores
- **Offline Support**: Local data persistence for better user experience
- **State Management**: Provider pattern for efficient state handling

## Architecture

The app follows a clean architecture pattern with three main layers:

### Presentation Layer (`lib/presentation/`)
- **Screens**: UI screens for different features (auth, home, quiz, etc.)
- **Widgets**: Reusable UI components
- **Navigation**: Go Router for declarative routing

### Data Layer (`lib/data/`)
- **Models**: Data models for users, questions, categories, etc.
- **Services**: Supabase service for API calls and data management
- **Repositories**: Data access abstractions

### Core Layer (`lib/core/`)
- **Constants**: App-wide constants and configuration
- **Theme**: App theming and styling
- **Utils**: Utility functions and helpers

## Dependencies

- **Flutter SDK**: ^3.10.3
- **Supabase Flutter**: ^2.0.0 - Backend as a service
- **Go Router**: ^12.0.0 - Declarative routing
- **Provider**: ^6.0.5 - State management
- **Google Fonts**: ^5.1.0 - Custom typography
- **Lottie**: ^2.7.0 - Vector animations
- **Animations**: ^2.0.7 - Flutter animations
- **Percent Indicator**: ^4.2.3 - Progress indicators
- **Confetti**: ^0.7.0 - Celebration effects
- **Shimmer**: ^3.0.0 - Loading animations
- **UUID**: ^4.2.0 - Unique identifier generation

## Installation

1. **Prerequisites**:
   - Flutter SDK installed (version 3.10.3 or higher)
   - Dart SDK
   - Android Studio or VS Code with Flutter extensions
   - Supabase account and project set up

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd quiz_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Configure Supabase**:
   - Create a Supabase project
   - Update `lib/core/constants/app_constants.dart` with your Supabase URL and anon key
   - Set up the following database tables:
     - `users` (id, email, name, avatar_url, total_score, total_quizzes, created_at)
     - `categories` (id, name, description, image_url)
     - `questions` (id, category_id, question_text, options, correct_answer, explanation)
     - `quiz_sessions` (id, user_id, category_id, score, total_questions, completed_at)

5. **Run the app**:
   ```bash
   flutter run
   ```

## Usage

1. **Launch the App**: Start the app on your device or emulator
2. **Sign Up/Sign In**: Create an account or log in with existing credentials
3. **Explore Categories**: Browse available quiz categories from the home screen
4. **Take a Quiz**: Select a category and start answering questions within the time limit
5. **View Results**: Check your score and detailed performance after completing a quiz
6. **Check Leaderboard**: See how you rank against other users
7. **Update Profile**: Manage your profile information and view statistics
8. **Daily Challenges**: Participate in daily quiz challenges to maintain streaks

## Development

### Project Structure
```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── auth/
    ├── categories/
    ├── home/
    ├── leaderboard/
    ├── profile/
    └── quiz/
```

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Flutter
- Powered by Supabase
- Icons and animations from various open-source libraries
