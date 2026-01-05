# dontAskUs Flutter App - Development Checklist

**Project:** dontAskUs Mobile App  
**Platform:** Flutter (iOS & Android)  
**Started:** December 18, 2025

---

## Phase 1: Project Foundation

### 1.1 Project Setup
- [x] Create Flutter project (`flutter create dont_ask_us`)
- [x] Configure `pubspec.yaml` with all dependencies
- [x] Set up folder structure (lib/models, providers, services, screens, widgets, utils)
- [x] Configure Android `minSdkVersion` to 23 (for secure storage)
- [x] Configure iOS deployment target
- [x] Add app icons and splash screen assets (flutter_launcher_icons, flutter_native_splash configured)

### 1.2 Core Dependencies (pubspec.yaml)
- [x] flutter_riverpod: ^2.4.0
- [x] http: ^1.1.0
- [x] web_socket_channel: ^2.4.0
- [x] flutter_secure_storage: ^9.0.0
- [x] fl_chart: ^0.65.0
- [x] shimmer: ^3.0.0
- [x] share_plus: ^7.2.0
- [x] qr_flutter: ^4.1.0
- [x] intl: ^0.18.0
- [x] connectivity_plus: ^5.0.0
- [x] shared_preferences: ^2.2.0

---

## Phase 2: Data Layer

### 2.1 Data Models
- [x] `lib/models/user.dart` - User model with fromJson/toJson
- [x] `lib/models/group.dart` - Group model with fromJson/toJson
- [x] `lib/models/group_member.dart` - GroupMember model
- [x] `lib/models/daily_question.dart` - DailyQuestion model
- [x] `lib/models/answer_response.dart` - AnswerResponse model
- [x] `lib/models/question_set.dart` - QuestionSet model
- [x] `lib/models/question_type.dart` - QuestionType enum with extension
- [x] `lib/models/models.dart` - Barrel export file

### 2.2 API & Services
- [x] `lib/services/api_config.dart` - Base URL and timeout config
- [x] `lib/services/api_client.dart` - HTTP client with GET/POST methods
- [x] `lib/services/api_exception.dart` - Custom exception handling
- [x] `lib/services/auth_service.dart` - Secure token storage
- [x] `lib/services/websocket_service.dart` - WebSocket for live votes
- [x] `lib/services/cache_service.dart` - Local caching with shared_preferences
- [x] `lib/services/services.dart` - Barrel export file

---

## Phase 3: State Management

### 3.1 Riverpod Providers
- [x] `lib/providers/api_provider.dart` - ApiClient provider
- [x] `lib/providers/auth_provider.dart` - CurrentUser state notifier
- [x] `lib/providers/group_provider.dart` - Group info & members providers
- [x] `lib/providers/question_provider.dart` - Today's question provider
- [x] `lib/providers/history_provider.dart` - Question history provider
- [x] `lib/providers/providers.dart` - Barrel export file

---

## Phase 4: Theme & UI Foundation

### 4.1 Theme Setup
- [x] `lib/utils/app_colors.dart` - Color palette definition
- [x] `lib/utils/app_theme.dart` - ThemeData configuration
- [x] `lib/utils/app_text_styles.dart` - Text style definitions
- [x] `lib/utils/constants.dart` - App-wide constants

### 4.2 Reusable Widgets
- [x] `lib/widgets/avatar_circle.dart` - Color-based avatar widget
- [x] `lib/widgets/streak_badge.dart` - Streak display with fire emoji
- [x] `lib/widgets/vote_option_card.dart` - Voting option with progress bar
- [x] `lib/widgets/loading_shimmer.dart` - Skeleton loading states
- [x] `lib/widgets/error_display.dart` - Error widget with retry button
- [x] `lib/widgets/question_card.dart` - Question display card
- [x] `lib/widgets/result_chart.dart` - Vote results bar chart
- [x] `lib/widgets/color_picker.dart` - Avatar color selection
- [x] `lib/widgets/invite_code_input.dart` - Formatted invite code input
- [x] `lib/widgets/widgets.dart` - Barrel export file

---

## Phase 5: Screens - Onboarding Flow

### 5.1 Splash Screen
- [x] `lib/screens/splash/splash_screen.dart` - App logo & loading
- [x] Implement token validation check
- [x] Auto-navigate based on auth state

### 5.2 Onboarding/Join Group
- [x] `lib/screens/onboarding/onboarding_screen.dart` - Welcome screen
- [x] `lib/screens/onboarding/join_group_screen.dart` - Join via invite code
- [x] Invite code input with paste functionality
- [x] Group preview after code entry
- [x] Display name input with validation
- [x] Avatar color picker
- [x] Join button with loading state
- [x] Error handling (name taken, group not found)

### 5.3 Create Group
- [x] `lib/screens/onboarding/create_group_screen.dart` - Create new group
- [x] Group name input
- [x] Create button with loading
- [x] Show invite code after creation
- [x] Share invite code functionality
- [x] Store admin token securely

---

## Phase 6: Screens - Main App

### 6.1 Main Navigation Shell
- [x] `lib/screens/main/main_screen.dart` - Bottom navigation scaffold
- [x] Home tab
- [x] Members tab
- [x] History tab
- [x] Settings tab
- [x] Maintain scroll position between tabs

### 6.2 Home Screen (Today's Question)
- [x] `lib/screens/home/home_screen.dart` - Main home layout
- [x] `lib/screens/home/question_view.dart` - Question display
- [x] `lib/screens/home/voting_view.dart` - Vote options UI
- [x] `lib/screens/home/results_view.dart` - Results after voting
- [x] `lib/screens/home/no_question_view.dart` - Empty state
- [x] Pull-to-refresh functionality
- [x] Streak display
- [x] Handle all 5 question types:
  - [x] binary_vote (Yes/No)
  - [x] single_choice (Custom options)
  - [x] free_text (Text input)
  - [x] member_choice (Vote for member)
  - [x] duo_choice (Vote for pair)

### 6.3 Vote Submission Logic
- [x] Single choice submission
- [x] Multiple choice submission (allow_multiple)
- [x] Free text submission
- [x] Optimistic UI update
- [x] Success confirmation
- [x] Error handling

### 6.4 Members Screen
- [x] `lib/screens/members/members_screen.dart` - Members list
- [x] `lib/screens/members/member_card.dart` - Individual member card
- [x] Avatar with color
- [x] Display name
- [x] Streak badge
- [x] Sort by streak / name toggle

### 6.5 History Screen
- [x] `lib/screens/history/history_screen.dart` - Past questions list
- [x] `lib/screens/history/history_item.dart` - Single history entry
- [x] Date display
- [x] Question text
- [x] User's answer
- [x] Results summary
- [x] Pagination / infinite scroll

### 6.6 Settings Screen
- [x] `lib/screens/settings/settings_screen.dart` - Settings layout
- [x] Current group info section
- [x] Invite code display with copy/share
- [x] QR code for invite
- [x] Leave group option with confirmation
- [x] Switch groups (multi-group)
- [x] About / Help section
- [x] App version display

---

## Phase 7: Admin Features

### 7.1 Admin Question Creation
- [x] `lib/screens/admin/create_question_screen.dart` - Create question form
- [x] Question type selector dropdown
- [x] Question text input
- [x] Options input (for binary/single_choice)
- [x] Allow multiple toggle
- [x] Question set selector (optional)
- [x] Submit with X-Admin-Token
- [x] Success/error feedback

### 7.2 Question Sets Management
- [x] `lib/screens/admin/question_sets_screen.dart` - View/assign sets
- [x] List public question sets
- [x] Assign sets to group
- [x] View set templates

---

## Phase 8: Real-time Features

### 8.1 WebSocket Integration
- [x] Connect to vote WebSocket
- [x] Listen for vote_update messages
- [x] Update UI in real-time
- [x] Send votes via WebSocket
- [x] Handle disconnection/reconnection
- [x] Cleanup on dispose

### 8.2 Multi-Group Support
- [x] Store multiple session tokens
- [x] Group selector UI component
- [x] Switch between groups
- [x] Refresh data on group switch
- [x] Join additional groups flow

---

## Phase 9: Polish & UX

### 9.1 Loading States
- [x] Shimmer loading for question card
- [x] Shimmer loading for members list
- [x] Shimmer loading for history list
- [x] Button loading states
- [x] Pull-to-refresh indicators

### 9.2 Animations
- [x] Vote count update animation
- [x] Page transitions
- [x] Hero animations (where appropriate)
- [x] Haptic feedback on interactions
- [x] Success/error micro-animations

### 9.3 Error Handling UI
- [x] 400 - Validation error display
- [x] 401 - Session expired, redirect to login
- [x] 404 - Not found message
- [x] 409 - Conflict (name taken) handling
- [x] 429 - Rate limit warning
- [x] 500 - Server error with retry
- [x] Offline indicator
- [x] Retry mechanisms

### 9.4 Offline Support
- [x] Connectivity checking
- [x] Cache today's question
- [x] Show cached data when offline
- [x] Queue actions for when online
- [x] Sync indicator

---

## Phase 10: Share & Social

### 10.1 Share Features
- [x] Share invite code as text
- [x] Generate QR code for invite
- [x] QR scanner for joining (optional)
- [x] Deep link handling (optional)

---

## Phase 11: Notifications (Optional)

### 11.1 Push Notifications Setup
- [ ] Configure Firebase project
- [ ] Add firebase_messaging dependency
- [ ] Add flutter_local_notifications
- [ ] iOS APNs configuration
- [ ] Android FCM configuration

### 11.2 Notification Types
- [ ] Daily reminder to answer
- [ ] Results available notification
- [ ] New member joined (optional)
- [ ] Notification preferences screen

---

## Phase 12: Testing

### 12.1 Unit Tests
- [x] Model fromJson/toJson tests
- [x] ApiClient tests with mocks
- [x] AuthService tests
- [x] Provider logic tests

### 12.2 Widget Tests
- [x] AvatarCircle widget test
- [x] StreakBadge widget test
- [x] VoteOptionCard widget test
- [x] QuestionCard widget test
- [x] ColorPicker widget test

### 12.3 Integration Tests
- [x] Join group flow test
- [x] Voting flow test
- [x] Navigation test
- [x] Error handling test

---

## Phase 13: Final Polish

### 13.1 Accessibility
- [x] Semantic labels for screen readers (accessibility.dart)
- [x] Sufficient color contrast (ContrastUtils)
- [x] Touch target sizes (48x48 minimum) - TouchTargetPadding widget
- [x] Dynamic text scaling support (main.dart builder)

### 13.2 Dark Mode
- [x] Dark theme color palette
- [x] Theme switching logic
- [x] System theme detection
- [x] Persist theme preference

### 13.3 Localization Structure
- [x] Set up flutter_localizations
- [x] Create ARB files structure (app_en.arb, app_de.arb)
- [x] Extract hardcoded strings (170+ translations)
- [x] Add German translations

### 13.4 Performance
- [x] Image optimization (ImageOptimization utils)
- [x] Lazy loading for lists (LazyLoader, chunked iteration)
- [x] Memory leak checks (ExpiringCache, Debouncer/Throttler)
- [x] Build size optimization (performance.dart utilities)

### 13.5 Release Preparation
- [x] Update app name and bundle ID (com.dontaskus.app)
- [x] Configure release signing (Android) - key.properties, proguard-rules.pro
- [x] Configure release signing (iOS) - ExportOptions.plist
- [x] App store metadata (store_metadata/app_store_metadata.md)
- [x] Screenshots setup (Fastlane configuration)
- [x] Privacy policy URL (store_metadata/privacy_policy.md)

---

## Progress Summary

| Phase | Description | Progress |
|-------|-------------|----------|
| 1 | Project Foundation | 17/17 ✅ |
| 2 | Data Layer | 15/15 ✅ |
| 3 | State Management | 6/6 ✅ |
| 4 | Theme & UI Foundation | 14/14 ✅ |
| 5 | Screens - Onboarding | 14/14 ✅ |
| 6 | Screens - Main App | 30/30 ✅ |
| 7 | Admin Features | 12/12 ✅ |
| 8 | Real-time Features | 11/11 ✅ |
| 9 | Polish & UX | 22/22 ✅ |
| 10 | Share & Social | 4/4 ✅ |
| 11 | Notifications | 0/7 (Optional) |
| 12 | Testing | 12/12 ✅ |
| 13 | Final Polish | 17/17 ✅ |

**Total Tasks:** 163  
**Completed:** 163 (excluding optional notifications)  
**Status:** ✅ COMPLETE - Ready for Release!

---

## Notes

- Backend API is already deployed and functional
- Prioritize MVP features (Phases 1-6) first
- WebSocket and notifications can be added incrementally
- Test on both iOS and Android simulators throughout development
