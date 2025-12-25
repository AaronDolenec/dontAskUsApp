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
- [ ] Configure iOS deployment target
- [ ] Add app icons and splash screen assets

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
- [ ] `lib/utils/app_text_styles.dart` - Text style definitions
- [x] `lib/utils/constants.dart` - App-wide constants

### 4.2 Reusable Widgets
- [x] `lib/widgets/avatar_circle.dart` - Color-based avatar widget
- [x] `lib/widgets/streak_badge.dart` - Streak display with fire emoji
- [x] `lib/widgets/vote_option_card.dart` - Voting option with progress bar
- [x] `lib/widgets/loading_shimmer.dart` - Skeleton loading states
- [x] `lib/widgets/error_display.dart` - Error widget with retry button
- [x] `lib/widgets/question_card.dart` - Question display card
- [ ] `lib/widgets/result_chart.dart` - Vote results bar chart
- [x] `lib/widgets/color_picker.dart` - Avatar color selection
- [ ] `lib/widgets/invite_code_input.dart` - Formatted invite code input
- [x] `lib/widgets/widgets.dart` - Barrel export file

---

## Phase 5: Screens - Onboarding Flow

### 5.1 Splash Screen
- [x] `lib/screens/splash/splash_screen.dart` - App logo & loading
- [x] Implement token validation check
- [x] Auto-navigate based on auth state

### 5.2 Onboarding/Join Group
- [ ] `lib/screens/onboarding/onboarding_screen.dart` - Welcome screen
- [x] `lib/screens/onboarding/join_group_screen.dart` - Join via invite code
- [x] Invite code input with paste functionality
- [ ] Group preview after code entry
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
- [ ] Maintain scroll position between tabs

### 6.2 Home Screen (Today's Question)
- [x] `lib/screens/home/home_screen.dart` - Main home layout
- [ ] `lib/screens/home/question_view.dart` - Question display
- [ ] `lib/screens/home/voting_view.dart` - Vote options UI
- [ ] `lib/screens/home/results_view.dart` - Results after voting
- [ ] `lib/screens/home/no_question_view.dart` - Empty state
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
- [ ] Multiple choice submission (allow_multiple)
- [x] Free text submission
- [ ] Optimistic UI update
- [ ] Success confirmation
- [x] Error handling

### 6.4 Members Screen
- [x] `lib/screens/members/members_screen.dart` - Members list
- [ ] `lib/screens/members/member_card.dart` - Individual member card
- [x] Avatar with color
- [x] Display name
- [x] Streak badge
- [ ] Sort by streak / name toggle

### 6.5 History Screen
- [x] `lib/screens/history/history_screen.dart` - Past questions list
- [ ] `lib/screens/history/history_item.dart` - Single history entry
- [x] Date display
- [x] Question text
- [x] User's answer
- [x] Results summary
- [ ] Pagination / infinite scroll

### 6.6 Settings Screen
- [x] `lib/screens/settings/settings_screen.dart` - Settings layout
- [x] Current group info section
- [x] Invite code display with copy/share
- [x] QR code for invite
- [x] Leave group option with confirmation
- [ ] Switch groups (multi-group)
- [ ] About / Help section
- [x] App version display

---

## Phase 7: Admin Features

### 7.1 Admin Question Creation
- [ ] `lib/screens/admin/create_question_screen.dart` - Create question form
- [ ] Question type selector dropdown
- [ ] Question text input
- [ ] Options input (for binary/single_choice)
- [ ] Allow multiple toggle
- [ ] Question set selector (optional)
- [ ] Submit with X-Admin-Token
- [ ] Success/error feedback

### 7.2 Question Sets Management
- [ ] `lib/screens/admin/question_sets_screen.dart` - View/assign sets
- [ ] List public question sets
- [ ] Assign sets to group
- [ ] View set templates

---

## Phase 8: Real-time Features

### 8.1 WebSocket Integration
- [ ] Connect to vote WebSocket
- [ ] Listen for vote_update messages
- [ ] Update UI in real-time
- [ ] Send votes via WebSocket
- [ ] Handle disconnection/reconnection
- [ ] Cleanup on dispose

### 8.2 Multi-Group Support
- [ ] Store multiple session tokens
- [ ] Group selector UI component
- [ ] Switch between groups
- [ ] Refresh data on group switch
- [ ] Join additional groups flow

---

## Phase 9: Polish & UX

### 9.1 Loading States
- [ ] Shimmer loading for question card
- [ ] Shimmer loading for members list
- [ ] Shimmer loading for history list
- [ ] Button loading states
- [ ] Pull-to-refresh indicators

### 9.2 Animations
- [ ] Vote count update animation
- [ ] Page transitions
- [ ] Hero animations (where appropriate)
- [ ] Haptic feedback on interactions
- [ ] Success/error micro-animations

### 9.3 Error Handling UI
- [ ] 400 - Validation error display
- [ ] 401 - Session expired, redirect to login
- [ ] 404 - Not found message
- [ ] 409 - Conflict (name taken) handling
- [ ] 429 - Rate limit warning
- [ ] 500 - Server error with retry
- [ ] Offline indicator
- [ ] Retry mechanisms

### 9.4 Offline Support
- [ ] Connectivity checking
- [ ] Cache today's question
- [ ] Show cached data when offline
- [ ] Queue actions for when online
- [ ] Sync indicator

---

## Phase 10: Share & Social

### 10.1 Share Features
- [ ] Share invite code as text
- [ ] Generate QR code for invite
- [ ] QR scanner for joining (optional)
- [ ] Deep link handling (optional)

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
- [ ] Model fromJson/toJson tests
- [ ] ApiClient tests with mocks
- [ ] AuthService tests
- [ ] Provider logic tests

### 12.2 Widget Tests
- [ ] AvatarCircle widget test
- [ ] StreakBadge widget test
- [ ] VoteOptionCard widget test
- [ ] QuestionCard widget test
- [ ] ColorPicker widget test

### 12.3 Integration Tests
- [ ] Join group flow test
- [ ] Voting flow test
- [ ] Navigation test
- [ ] Error handling test

---

## Phase 13: Final Polish

### 13.1 Accessibility
- [ ] Semantic labels for screen readers
- [ ] Sufficient color contrast
- [ ] Touch target sizes (48x48 minimum)
- [ ] Dynamic text scaling support

### 13.2 Dark Mode
- [ ] Dark theme color palette
- [ ] Theme switching logic
- [ ] System theme detection
- [ ] Persist theme preference

### 13.3 Localization Structure
- [ ] Set up flutter_localizations
- [ ] Create ARB files structure
- [ ] Extract hardcoded strings
- [ ] Add German translations (optional)

### 13.4 Performance
- [ ] Image optimization
- [ ] Lazy loading for lists
- [ ] Memory leak checks
- [ ] Build size optimization

### 13.5 Release Preparation
- [ ] Update app name and bundle ID
- [ ] Configure release signing (Android)
- [ ] Configure release signing (iOS)
- [ ] App store metadata
- [ ] Screenshots for stores
- [ ] Privacy policy URL

---

## Progress Summary

| Phase | Description | Progress |
|-------|-------------|----------|
| 1 | Project Foundation | 15/17 |
| 2 | Data Layer | 15/15 |
| 3 | State Management | 6/6 |
| 4 | Theme & UI Foundation | 11/14 |
| 5 | Screens - Onboarding | 12/14 |
| 6 | Screens - Main App | 22/26 |
| 7 | Admin Features | 0/9 |
| 8 | Real-time Features | 0/11 |
| 9 | Polish & UX | 0/22 |
| 10 | Share & Social | 0/4 |
| 11 | Notifications | 0/7 |
| 12 | Testing | 0/12 |
| 13 | Final Polish | 0/17 |

**Total Tasks:** 163  
**Completed:** 81  
**Remaining:** 82

---

## Notes

- Backend API is already deployed and functional
- Prioritize MVP features (Phases 1-6) first
- WebSocket and notifications can be added incrementally
- Test on both iOS and Android simulators throughout development
