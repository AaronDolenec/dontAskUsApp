# dontAskUs Mobile App - Documentation TODO

**Project:** dontAskUs Flutter Mobile App  
**Purpose:** Create comprehensive documentation for the mobile application  
**Note:** API Documentation is already available in `COMPLETE_API_DOCUMENTATION.md` - do not duplicate

---

## Table of Contents

1. [Overview Documentation](#1-overview-documentation)
2. [Architecture Documentation](#2-architecture-documentation)
3. [Models Documentation](#3-models-documentation)
4. [Services Documentation](#4-services-documentation)
5. [State Management Documentation](#5-state-management-documentation)
6. [Screens & UI Documentation](#6-screens--ui-documentation)
7. [Widgets Documentation](#7-widgets-documentation)
8. [Utilities Documentation](#8-utilities-documentation)
9. [Configuration & Setup Documentation](#9-configuration--setup-documentation)
10. [Testing Documentation](#10-testing-documentation)
11. [Deployment Documentation](#11-deployment-documentation)

---

## 1. Overview Documentation

### 1.1 README.md Update
- [ ] Rewrite `README.md` with proper project description
- [ ] Add app screenshots/GIFs
- [ ] Add installation instructions
- [ ] Add build commands (iOS/Android/Web)
- [ ] Add development setup guide
- [ ] Add environment configuration section
- [ ] Add contributing guidelines
- [ ] Add license information

### 1.2 App Overview Document
- [ ] Create `docs/APP_OVERVIEW.md`
- [ ] Document app purpose and target audience
- [ ] Document user roles (Member vs Admin)
- [ ] Document key concepts (Groups, Daily Questions, Streaks, Voting)
- [ ] Document 5 question types with use cases:
  - Binary Vote (Yes/No)
  - Single Choice
  - Free Text
  - Member Choice (vote for group member)
  - Duo Choice (vote for pair)
- [ ] Document user journey flowcharts

---

## 2. Architecture Documentation

### 2.1 Project Structure
- [ ] Create `docs/ARCHITECTURE.md`
- [ ] Document folder structure with explanations:
  ```
  lib/
  ├── main.dart           # App entry point
  ├── l10n/               # Localization files
  ├── models/             # Data models
  ├── providers/          # Riverpod state management
  ├── screens/            # App screens
  ├── services/           # API & business logic
  ├── utils/              # Utilities & helpers
  └── widgets/            # Reusable UI components
  ```
- [ ] Document state management pattern (Riverpod)
- [ ] Document data flow diagram
- [ ] Document dependency injection approach

### 2.2 Navigation Architecture
- [ ] Document routing structure
- [ ] Document screen navigation flow:
  - Splash → Onboarding/Main
  - Join Group flow
  - Create Group flow
  - Main app navigation (tabs)
- [ ] Document deep linking support (if applicable)

### 2.3 Platform Support
- [ ] Document supported platforms (iOS, Android, Web)
- [ ] Document platform-specific implementations:
  - Secure storage (FlutterSecureStorage vs SharedPreferences for web)
  - System UI overlays
  - Orientation handling

---

## 3. Models Documentation

### 3.1 Data Models Reference
- [ ] Create `docs/MODELS.md`
- [ ] Document each model with fields and usage:

| Model | File | Description |
|-------|------|-------------|
| User | `user.dart` | User profile with streaks |
| Group | `group.dart` | Group info with admin status |
| GroupMember | `group_member.dart` | Group member profile |
| DailyQuestion | `daily_question.dart` | Daily question with votes |
| AnswerResponse | `answer_response.dart` | Vote submission response |
| QuestionSet | `question_set.dart` | Question set templates |
| QuestionType | `question_type.dart` | Question type enum |
| SessionValidation | `session_validation.dart` | Session validation result |

- [ ] Document JSON serialization/deserialization patterns
- [ ] Document model relationships diagram
- [ ] Document `copyWith` pattern usage
- [ ] Document computed properties (e.g., `hasUserVoted`, `winningOption`)

---

## 4. Services Documentation

### 4.1 Services Reference
- [ ] Create `docs/SERVICES.md`
- [ ] Document each service:

| Service | File | Purpose |
|---------|------|---------|
| ApiClient | `api_client.dart` | HTTP client for API calls |
| ApiConfig | `api_config.dart` | Environment-based API configuration |
| ApiException | `api_exception.dart` | Custom exception handling |
| AuthService | `auth_service.dart` | Secure token storage |
| WebSocketService | `websocket_service.dart` | Real-time vote updates |
| CacheService | `cache_service.dart` | Local data caching |
| ShareService | `share_service.dart` | Share functionality |

### 4.2 API Client Documentation
- [ ] Document GET/POST/PUT/DELETE methods
- [ ] Document authentication (session_token, X-Admin-Token)
- [ ] Document error handling patterns
- [ ] Document timeout configuration

### 4.3 WebSocket Documentation
- [ ] Document WebSocket connection lifecycle
- [ ] Document message types (`vote_update`)
- [ ] Document reconnection strategy (5 max attempts, exponential backoff)
- [ ] Document vote sending via WebSocket

### 4.4 Auth Service Documentation
- [ ] Document token storage patterns
- [ ] Document multi-group session management
- [ ] Document platform-specific storage backends
- [ ] Document admin token handling

### 4.5 Cache Service Documentation
- [ ] Document cache keys and structure
- [ ] Document cache expiration policies:
  - Questions: 1 hour
  - Members: 30 minutes
  - Group info: 24 hours
- [ ] Document offline support strategy

---

## 5. State Management Documentation

### 5.1 Providers Reference
- [ ] Create `docs/STATE_MANAGEMENT.md`
- [ ] Document Riverpod providers:

| Provider | File | Type | Purpose |
|----------|------|------|---------|
| apiClientProvider | `api_provider.dart` | Provider | ApiClient instance |
| authProvider | `auth_provider.dart` | StateNotifier | Auth state & user |
| groupInfoProvider | `group_provider.dart` | FutureProvider | Current group info |
| groupMembersProvider | `group_provider.dart` | FutureProvider | Group members list |
| questionProvider | `question_provider.dart` | StateNotifier | Daily question state |
| historyProvider | `history_provider.dart` | FutureProvider | Question history |
| websocketProvider | `websocket_provider.dart` | Provider | WebSocket service |
| connectivityProvider | `connectivity_provider.dart` | StreamProvider | Network status |
| themeProvider | `theme_provider.dart` | StateNotifier | Theme mode |
| multiGroupProvider | `multi_group_provider.dart` | StateNotifier | Multi-group state |

### 5.2 Auth Flow Documentation
- [ ] Document authentication flow:
  1. Check stored session
  2. Validate session with API
  3. Set auth state
- [ ] Document join group flow
- [ ] Document create group flow
- [ ] Document logout/leave group flow

### 5.3 Question State Documentation
- [ ] Document question fetching logic
- [ ] Document vote submission flow
- [ ] Document real-time update handling
- [ ] Document caching strategy

---

## 6. Screens & UI Documentation

### 6.1 Screen Reference
- [ ] Create `docs/SCREENS.md`
- [ ] Document all screens with screenshots:

#### Onboarding Flow
| Screen | File | Purpose |
|--------|------|---------|
| SplashScreen | `splash/splash_screen.dart` | App launch & session check |
| OnboardingScreen | `onboarding/onboarding_screen.dart` | Welcome & intro |
| JoinGroupScreen | `onboarding/join_group_screen.dart` | Join via invite code |
| CreateGroupScreen | `onboarding/create_group_screen.dart` | Create new group |

#### Main App
| Screen | File | Purpose |
|--------|------|---------|
| MainScreen | `main/main_screen.dart` | Bottom navigation shell |
| HomeScreen | `home/home_screen.dart` | Today's question |
| MembersScreen | `members/members_screen.dart` | Group members list |
| HistoryScreen | `history/history_screen.dart` | Past questions |
| SettingsScreen | `settings/settings_screen.dart` | App settings |
| HelpScreen | `settings/help_screen.dart` | Help & FAQ |
| SessionInfoScreen | `settings/session_info_screen.dart` | Debug info |

#### Admin Screens
| Screen | File | Purpose |
|--------|------|---------|
| CreateQuestionScreen | `admin/create_question_screen.dart` | Create new questions |
| QuestionSetsScreen | `admin/question_sets_screen.dart` | Manage question sets |

### 6.2 Home Screen Components
- [ ] Document question display logic
- [ ] Document 5 voting UI variants:
  - Binary voting (Yes/No buttons)
  - Single choice (radio options)
  - Multiple choice (checkboxes)
  - Free text (text input)
  - Member choice (member cards)
  - Duo choice (pair selection)
- [ ] Document results visualization
- [ ] Document streak display

### 6.3 Settings Screen Features
- [ ] Document group info display
- [ ] Document invite code sharing (text, QR)
- [ ] Document multi-group switching
- [ ] Document theme switching
- [ ] Document leave group flow

---

## 7. Widgets Documentation

### 7.1 Widgets Reference
- [ ] Create `docs/WIDGETS.md`
- [ ] Document reusable widgets:

| Widget | File | Purpose |
|--------|------|---------|
| AvatarCircle | `avatar_circle.dart` | Color-based user avatar |
| StreakBadge | `streak_badge.dart` | Streak display with fire emoji |
| VoteOptionCard | `vote_option_card.dart` | Voting option with progress |
| LoadingShimmer | `loading_shimmer.dart` | Skeleton loading states |
| ErrorDisplay | `error_display.dart` | Error with retry button |
| QuestionCard | `question_card.dart` | Question display card |
| ResultChart | `result_chart.dart` | Vote results bar chart |
| ColorPicker | `color_picker.dart` | Avatar color selection |
| InviteCodeInput | `invite_code_input.dart` | Formatted code input |
| ConnectionStatusIndicator | `connection_status_indicator.dart` | Network status |

### 7.2 Widget Usage Examples
- [ ] Document widget props and usage examples
- [ ] Document theming/styling customization
- [ ] Document accessibility features

---

## 8. Utilities Documentation

### 8.1 Utilities Reference
- [ ] Create `docs/UTILITIES.md`
- [ ] Document utility files:

| Utility | File | Purpose |
|---------|------|---------|
| AppColors | `app_colors.dart` | Color palette & helpers |
| AppTheme | `app_theme.dart` | Light/dark theme data |
| AppTextStyles | `app_text_styles.dart` | Text style definitions |
| AppConstants | `constants.dart` | App-wide constants |
| Animations | `animations.dart` | Animation utilities |
| PageRoutes | `page_routes.dart` | Route transitions |
| Accessibility | `accessibility.dart` | A11y utilities |
| Performance | `performance.dart` | Performance utilities |

### 8.2 Theme Customization
- [ ] Document color palette (primary, secondary, status colors)
- [ ] Document dark mode colors
- [ ] Document avatar colors (12 preset colors)
- [ ] Document vote result colors (8 preset colors)

### 8.3 Constants Reference
- [ ] Document validation constants
- [ ] Document animation durations
- [ ] Document cache durations
- [ ] Document UI constants (spacing, radius, sizes)

---

## 9. Configuration & Setup Documentation

### 9.1 Environment Setup
- [ ] Create `docs/SETUP.md`
- [ ] Document `.env` file configuration:
  ```
  USE_PRODUCTION=development|production
  PRODUCTION_API_URL=https://api.example.com
  DEV_SERVER_HOST=192.168.1.100
  DEV_SERVER_PORT=8000
  API_TIMEOUT=30
  ```
- [ ] Document environment switching
- [ ] Document platform-specific setup (Android minSdk, iOS deployment target)

### 9.2 Dependencies Documentation
- [ ] Document all dependencies from `pubspec.yaml`:
  - flutter_riverpod - State management
  - http - HTTP client
  - web_socket_channel - WebSocket support
  - flutter_secure_storage - Secure storage
  - fl_chart - Charts
  - shimmer - Loading states
  - share_plus - Sharing
  - qr_flutter - QR code generation
  - connectivity_plus - Network status
  - shared_preferences - Simple storage
  - flutter_dotenv - Environment config
- [ ] Document version requirements

### 9.3 Build Configuration
- [ ] Document Android build configuration:
  - `android/app/build.gradle`
  - Signing configuration
  - ProGuard rules
- [ ] Document iOS build configuration:
  - `ios/Runner/Info.plist`
  - Export options
- [ ] Document Fastlane setup (iOS/Android)

---

## 10. Testing Documentation

### 10.1 Testing Guide
- [ ] Create `docs/TESTING.md`
- [ ] Document testing setup
- [ ] Document test file structure:
  ```
  test/                    # Unit & widget tests
  integration_test/        # Integration tests
  ```

### 10.2 Unit Tests
- [ ] Document model tests
- [ ] Document service tests (with mocking)
- [ ] Document provider tests

### 10.3 Widget Tests
- [ ] Document widget testing patterns
- [ ] Document test utilities

### 10.4 Integration Tests
- [ ] Document integration test flows:
  - Join group flow
  - Voting flow
  - Navigation tests
  - Error handling tests
- [ ] Document running integration tests

---

## 11. Deployment Documentation

### 11.1 Release Guide
- [ ] Create `docs/DEPLOYMENT.md`
- [ ] Document Android release process:
  - Keystore setup
  - `key.properties` configuration
  - Building release APK/AAB
  - Play Store submission
- [ ] Document iOS release process:
  - Certificate setup
  - Provisioning profiles
  - Building IPA
  - App Store submission

### 11.2 App Store Metadata
- [ ] Document metadata in `store_metadata/`
- [ ] Document screenshot requirements
- [ ] Document privacy policy

### 11.3 CI/CD (Optional)
- [ ] Document Fastlane workflows
- [ ] Document GitHub Actions setup (if applicable)

---

## 12. Localization Documentation

### 12.1 Localization Guide
- [ ] Create `docs/LOCALIZATION.md`
- [ ] Document ARB file structure
- [ ] Document supported locales (en, de)
- [ ] Document adding new languages
- [ ] Document 170+ translation keys
- [ ] Document pluralization patterns

---

## Progress Tracking

| Section | Tasks | Completed |
|---------|-------|-----------|
| 1. Overview | 8 | 0 |
| 2. Architecture | 10 | 0 |
| 3. Models | 5 | 0 |
| 4. Services | 11 | 0 |
| 5. State Management | 7 | 0 |
| 6. Screens & UI | 10 | 0 |
| 7. Widgets | 3 | 0 |
| 8. Utilities | 5 | 0 |
| 9. Configuration | 7 | 0 |
| 10. Testing | 6 | 0 |
| 11. Deployment | 5 | 0 |
| 12. Localization | 6 | 0 |
| **TOTAL** | **83** | **0** |

---

## Documentation File Structure

When complete, the documentation should follow this structure:

```
docs/
├── APP_OVERVIEW.md
├── ARCHITECTURE.md
├── MODELS.md
├── SERVICES.md
├── STATE_MANAGEMENT.md
├── SCREENS.md
├── WIDGETS.md
├── UTILITIES.md
├── SETUP.md
├── TESTING.md
├── DEPLOYMENT.md
├── LOCALIZATION.md
└── images/
    ├── architecture-diagram.png
    ├── data-flow.png
    ├── screenshots/
    │   ├── onboarding.png
    │   ├── home-screen.png
    │   ├── voting.png
    │   ├── results.png
    │   ├── members.png
    │   ├── history.png
    │   └── settings.png
    └── user-flow.png
```

---

## Notes

- **Existing Documentation:** `FlutterAppBriefing.MD` contains development briefing and can be referenced but should not replace official documentation
- **API Documentation:** Already exists in `COMPLETE_API_DOCUMENTATION.md` - reference it, don't duplicate
- **Development TODO:** `TODO.md` is a development checklist (completed), keep separate from user documentation
- **Store Metadata:** `store_metadata/` contains app store descriptions - can be used as reference for app overview
