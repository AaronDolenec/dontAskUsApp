# dontAskUs - Flutter Mobile App Development Briefing

**Project:** dontAskUs Mobile App  
**Platform:** Flutter (iOS & Android)  
**Backend:** FastAPI REST API  
**Last Updated:** December 18, 2025

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [App Purpose & User Flow](#2-app-purpose--user-flow)
3. [Core Features to Implement](#3-core-features-to-implement)
4. [Data Models](#4-data-models)
5. [Complete API Reference](#5-complete-api-reference)
6. [Authentication System](#6-authentication-system)
7. [UI/UX Requirements](#7-uiux-requirements)
8. [State Management Recommendations](#8-state-management-recommendations)
9. [Technical Implementation Notes](#9-technical-implementation-notes)
10. [Testing Considerations](#10-testing-considerations)

---

## 1. Project Overview

### What is dontAskUs?

dontAskUs is a **group-based daily question and voting platform**. Users join groups via invite
codes, answer a daily question, and vote on group members or choices. Think of it as a fun social
game where groups discover things about each other through daily prompts.

### Key Concepts

- **Groups**: Collections of users who participate together
- **Daily Questions**: One question per group per day
- **Voting**: Users vote/answer the daily question
- **Streaks**: Track consecutive days of participation
- **Question Sets**: Curated collections of question templates

### Backend Infrastructure

- **API Base URL (Development):** `http://localhost:8000`
- **API Base URL (Production):** Configure via environment
- **Authentication:** Session tokens (query parameter)
- **Real-time:** WebSocket for live vote updates

---

## 2. App Purpose & User Flow

### Primary User Journey

```
1. ONBOARDING
   ├── Welcome screen
   ├── Enter group invite code
   ├── Choose display name
   └── Pick avatar color

2. MAIN EXPERIENCE
   ├── View today's question
   ├── Submit answer/vote
   ├── See results (live updates)
   └── View streak progress

3. GROUP MANAGEMENT
   ├── View group members
   ├── Create new group (becomes admin)
   ├── Share invite code
   └── Switch between groups (if member of multiple)

4. HISTORY & STATS
   ├── View past questions/results
   ├── Personal answer history
   └── Streak achievements
```

### User Roles

| Role              | Capabilities                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------- |
| **Member**        | Join groups, answer questions, view results                                                 |
| **Group Creator** | All member abilities + create questions, manage question sets, create private question sets |

---

## 3. Core Features to Implement

### MVP Features (Phase 1)

1. **Join Group Flow**

   - Enter invite code
   - Set display name (unique within group)
   - Choose avatar color
   - Save session token securely

2. **Daily Question View**

   - Display today's question
   - Show question type (voting, multiple choice, free text)
   - Display options based on type
   - Show current vote counts (after voting)

3. **Answer Submission**

   - Submit vote/answer
   - Handle different question types
   - Show confirmation
   - Update streak count

4. **Results View**

   - Real-time vote counts via WebSocket
   - Visual representation (bar chart, pie chart)
   - Highlight winning option

5. **Group Members List**
   - Display all members
   - Show avatar colors
   - Display streaks

### Enhanced Features (Phase 2)

6. **Create Group**

   - Name the group
   - Receive admin token (store securely!)
   - Get invite code to share

7. **Group Admin: Create Questions**

   - Select question type
   - Write question text
   - For binary/single_choice: define options
   - Assign question set (optional)

8. **Question History**

   - Browse past daily questions
   - View historical results

9. **Multi-Group Support**

   - Switch between groups
   - Separate session tokens per group

10. **Push Notifications** (optional)
    - Daily reminder to answer
    - Results notification

---

## 4. Data Models

### Dart Model Classes

```dart
// ============= User Models =============

class User {
  final int id;
  final String oderId;
  final String displayName;
  final String colorAvatar; // Hex color like "#3B82F6"
  final String sessionToken; // Store securely!
  final DateTime createdAt;
  final int answerStreak;
  final int longestAnswerStreak;

  User({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.colorAvatar,
    required this.sessionToken,
    required this.createdAt,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['user_id'],
      displayName: json['display_name'],
      colorAvatar: json['color_avatar'],
      sessionToken: json['session_token'],
      createdAt: DateTime.parse(json['created_at']),
      answerStreak: json['answer_streak'] ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] ?? 0,
    );
  }
}

// ============= Group Models =============

class Group {
  final int id;
  final String groupId;
  final String name;
  final String inviteCode;
  final String? adminToken; // Only present if creator
  final DateTime createdAt;
  final int memberCount;

  Group({
    required this.id,
    required this.groupId,
    required this.name,
    required this.inviteCode,
    this.adminToken,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      groupId: json['group_id'],
      name: json['name'],
      inviteCode: json['invite_code'],
      adminToken: json['admin_token'],
      createdAt: DateTime.parse(json['created_at']),
      memberCount: json['member_count'] ?? 0,
    );
  }
}

class GroupMember {
  final String oderId;
  final String displayName;
  final String colorAvatar;
  final int answerStreak;
  final int longestAnswerStreak;

  GroupMember({
    required this.userId,
    required this.displayName,
    required this.colorAvatar,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'],
      displayName: json['display_name'],
      colorAvatar: json['color_avatar'],
      answerStreak: json['answer_streak'] ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] ?? 0,
    );
  }
}

// ============= Question Models =============

enum QuestionType {
  binaryVote,    // Yes/No
  singleChoice,  // Custom options
  freeText,      // Open-ended
  memberChoice,  // Vote for group member
  duoChoice,     // Vote for pair of members
}

extension QuestionTypeExtension on QuestionType {
  String get apiValue {
    switch (this) {
      case QuestionType.binaryVote: return 'binary_vote';
      case QuestionType.singleChoice: return 'single_choice';
      case QuestionType.freeText: return 'free_text';
      case QuestionType.memberChoice: return 'member_choice';
      case QuestionType.duoChoice: return 'duo_choice';
    }
  }

  static QuestionType fromString(String value) {
    switch (value) {
      case 'binary_vote': return QuestionType.binaryVote;
      case 'single_choice': return QuestionType.singleChoice;
      case 'free_text': return QuestionType.freeText;
      case 'member_choice': return QuestionType.memberChoice;
      case 'duo_choice': return QuestionType.duoChoice;
      default: return QuestionType.binaryVote;
    }
  }
}

class DailyQuestion {
  final int id;
  final String questionId;
  final String questionText;
  final QuestionType questionType;
  final List<String>? options; // Available choices
  final Map<String, int>? optionCounts; // Vote counts per option
  final DateTime questionDate;
  final bool isActive;
  final int totalVotes;
  final bool allowMultiple;
  final dynamic userVote; // String or List<String> or null
  final String? userTextAnswer;
  final int userStreak;
  final int longestStreak;

  DailyQuestion({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.optionCounts,
    required this.questionDate,
    required this.isActive,
    this.totalVotes = 0,
    this.allowMultiple = false,
    this.userVote,
    this.userTextAnswer,
    this.userStreak = 0,
    this.longestStreak = 0,
  });

  bool get hasUserVoted => userVote != null || userTextAnswer != null;

  factory DailyQuestion.fromJson(Map<String, dynamic> json) {
    return DailyQuestion(
      id: json['id'],
      questionId: json['question_id'],
      questionText: json['question_text'],
      questionType: QuestionTypeExtension.fromString(json['question_type']),
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      optionCounts: json['option_counts'] != null
          ? Map<String, int>.from(json['option_counts'])
          : null,
      questionDate: DateTime.parse(json['question_date']),
      isActive: json['is_active'] ?? true,
      totalVotes: json['total_votes'] ?? 0,
      allowMultiple: json['allow_multiple'] ?? false,
      userVote: json['user_vote'],
      userTextAnswer: json['user_text_answer'],
      userStreak: json['user_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }
}

// ============= Vote/Answer Models =============

class AnswerResponse {
  final String message;
  final String questionId;
  final List<String>? options;
  final Map<String, int>? optionCounts;
  final int totalVotes;
  final dynamic userAnswer;
  final int currentStreak;
  final int longestStreak;

  AnswerResponse({
    required this.message,
    required this.questionId,
    this.options,
    this.optionCounts,
    required this.totalVotes,
    this.userAnswer,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      message: json['message'],
      questionId: json['question_id'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      optionCounts: json['option_counts'] != null
          ? Map<String, int>.from(json['option_counts'])
          : null,
      totalVotes: json['total_votes'] ?? 0,
      userAnswer: json['user_answer'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }
}

// ============= Question Set Models =============

class QuestionSet {
  final String setId;
  final String name;
  final String? description;
  final bool isPublic;
  final int? templateCount;
  final DateTime createdAt;

  QuestionSet({
    required this.setId,
    required this.name,
    this.description,
    required this.isPublic,
    this.templateCount,
    required this.createdAt,
  });

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      setId: json['set_id'],
      name: json['name'],
      description: json['description'],
      isPublic: json['is_public'] ?? true,
      templateCount: json['template_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

---

## 5. Complete API Reference

### Base Configuration

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000'; // Change for production
  static const Duration timeout = Duration(seconds: 30);
}
```

### User Endpoints

#### Join Group

```
POST /api/users/join
Content-Type: application/json

Request:
{
  "display_name": "Alice",           // 1-50 chars, unique in group
  "group_invite_code": "ABC123",     // 6-8 uppercase alphanumeric
  "color_avatar": "#3B82F6"          // Optional, hex color
}

Response 200:
{
  "id": 10,
  "user_id": "uuid-here",
  "display_name": "Alice",
  "color_avatar": "#3B82F6",
  "session_token": "SAVE_THIS_SECURELY",
  "created_at": "2025-12-17T10:00:00Z",
  "answer_streak": 0,
  "longest_answer_streak": 0
}

Errors:
- 400: Invalid invite code or color format
- 404: Group not found
- 409: Display name already taken in group
```

#### Validate Session

```
GET /api/users/validate-session/{session_token}

Response 200:
{
  "valid": true,
  "user_id": "uuid",
  "display_name": "Alice",
  "group_id": "group-uuid",
  "answer_streak": 2,
  "longest_answer_streak": 5
}

Response 200 (invalid):
{
  "valid": false
}
```

### Group Endpoints

#### Create Group

```
POST /api/groups
Content-Type: application/json

Request:
{
  "name": "My Awesome Group"   // 1-100 chars
}

Response 200:
{
  "id": 1,
  "group_id": "uuid",
  "name": "My Awesome Group",
  "invite_code": "ABC123",
  "admin_token": "SAVE_THIS_SECURELY",  // Only returned on creation!
  "creator_id": null,
  "created_at": "2025-12-17T10:00:00Z",
  "member_count": 0
}
```

#### Get Group by Invite Code (Public)

```
GET /api/groups/{invite_code}

Response 200:
{
  "id": 1,
  "group_id": "uuid",
  "name": "My Awesome Group",
  "invite_code": "ABC123",
  "created_at": "2025-12-17T10:00:00Z",
  "member_count": 5
}

Errors:
- 404: Group not found
```

#### Get Group Info

```
GET /api/groups/{group_id}/info

Response 200:
{
  "id": 1,
  "group_id": "uuid",
  "name": "My Awesome Group",
  "invite_code": "ABC123",
  "member_count": 5,
  "created_at": "2025-12-17T10:00:00Z"
}
```

#### List Group Members

```
GET /api/groups/{group_id}/members

Response 200:
{
  "members": [
    {
      "user_id": "uuid",
      "display_name": "Alice",
      "color_avatar": "#3B82F6",
      "answer_streak": 2,
      "longest_answer_streak": 5
    }
  ]
}
```

### Daily Question Endpoints

#### Get Today's Question

```
GET /api/groups/{group_id}/questions/today?session_token={token}

Response 200:
{
  "id": 1,
  "question_id": "uuid",
  "question_text": "Who is the funniest?",
  "question_type": "member_choice",
  "options": ["Alice", "Bob", "Charlie"],
  "option_counts": {
    "Alice": 3,
    "Bob": 1,
    "Charlie": 2
  },
  "question_date": "2025-12-17T00:00:00Z",
  "is_active": true,
  "total_votes": 6,
  "allow_multiple": false,
  "user_vote": "Alice",         // null if not voted, string or array
  "user_text_answer": null,      // For free_text type
  "user_streak": 3,
  "longest_streak": 5
}

Errors:
- 401: Invalid session token
- 404: No question for today
```

#### Submit Answer/Vote

```
POST /api/groups/{group_id}/questions/{question_id}/answer?session_token={token}
Content-Type: application/json

Request (single choice):
{
  "answer": "Alice"
}

Request (multi-select when allow_multiple=true):
{
  "answer": ["Alice", "Bob"]
}

Request (free text):
{
  "text_answer": "My detailed response here"
}

Response 200:
{
  "message": "Vote recorded",
  "question_id": "uuid",
  "options": ["Alice", "Bob", "Charlie"],
  "option_counts": {
    "Alice": 4,
    "Bob": 1,
    "Charlie": 2
  },
  "total_votes": 7,
  "user_answer": "Alice",
  "current_streak": 4,
  "longest_streak": 5
}

Errors:
- 400: Invalid answer, already voted, or answer not in options
- 401: Invalid session token
- 404: Question not found
```

#### Create Daily Question (Admin)

```
POST /api/groups/{group_id}/questions
X-Admin-Token: {admin_token}
Content-Type: application/json

Request:
{
  "question_text": "Who is the funniest?",
  "question_type": "member_choice",    // See QuestionType enum
  "option_a": null,                     // For binary/single_choice
  "option_b": null,                     // For binary/single_choice
  "allow_multiple": false,              // Allow multi-select
  "question_set_id": null               // Optional set ID
}

Response 200:
{
  "id": 1,
  "question_id": "uuid",
  "question_text": "Who is the funniest?",
  "question_type": "member_choice",
  "options": ["Alice", "Bob", "Charlie"],
  "question_date": "2025-12-17T00:00:00Z",
  "is_active": true,
  "allow_multiple": false
}

Errors:
- 400: Question already exists for today, or <2 members for member/duo types
- 401: Invalid admin token
```

### Question Set Endpoints

#### List Public Question Sets

```
GET /api/question-sets

Response 200:
{
  "sets": [
    {
      "id": 1,
      "set_id": "uuid",
      "name": "Icebreakers",
      "is_public": true,
      "template_count": 10
    }
  ]
}
```

#### Get Question Set Details

```
GET /api/question-sets/{set_id}

Response 200:
{
  "id": 1,
  "set_id": "uuid",
  "name": "Icebreakers",
  "is_public": true,
  "templates": [
    {
      "id": 1,
      "template_id": "uuid",
      "question_text": "What's your superpower?",
      "question_type": "free_text"
    }
  ]
}
```

#### Assign Sets to Group (Admin)

```
POST /api/groups/{group_id}/question-sets
X-Admin-Token: {admin_token}
Content-Type: application/json

Request:
{
  "question_set_ids": ["set-uuid-1", "set-uuid-2"],
  "replace": false   // true = replace all, false = add
}

Response 200:
{
  "group_id": "uuid",
  "question_sets": [
    {
      "set_id": "uuid",
      "name": "Icebreakers",
      "template_count": 10
    }
  ]
}
```

#### List Group Question Sets

```
GET /api/groups/{group_id}/question-sets

Response 200:
{
  "group_id": "uuid",
  "question_sets": [
    {
      "set_id": "uuid",
      "name": "Icebreakers",
      "is_public": true,
      "template_count": 10
    }
  ]
}
```

### WebSocket - Live Vote Updates

```
Connection: WS /ws/groups/{group_id}/questions/{question_id}

Send (vote):
{
  "type": "vote",
  "session_token": "token",
  "answer": "Alice"
}

Receive (vote update):
{
  "type": "vote_update",
  "option_counts": {
    "Alice": 4,
    "Bob": 2
  },
  "total_votes": 6
}
```

---

## 6. Authentication System

### Session Token Management

```dart
// Store session token securely using flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'session_token';
  static const _groupIdKey = 'current_group_id';

  // For multi-group support, store tokens per group
  static Future<void> saveSession(String groupId, String token) async {
    await _storage.write(key: '${_tokenKey}_$groupId', value: token);
    await _storage.write(key: _groupIdKey, value: groupId);
  }

  static Future<String?> getToken(String groupId) async {
    return await _storage.read(key: '${_tokenKey}_$groupId');
  }

  static Future<String?> getCurrentGroupId() async {
    return await _storage.read(key: _groupIdKey);
  }

  static Future<void> clearSession(String groupId) async {
    await _storage.delete(key: '${_tokenKey}_$groupId');
  }
}
```

### API Client with Auth

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<http.Response> get(
    String endpoint, {
    String? sessionToken,
    String? adminToken,
  }) async {
    String url = '$baseUrl$endpoint';

    // Add session token as query param
    if (sessionToken != null) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}session_token=$sessionToken';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add admin token as header
    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    return await http.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? sessionToken,
    String? adminToken,
  }) async {
    String url = '$baseUrl$endpoint';

    if (sessionToken != null) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}session_token=$sessionToken';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }
}
```

### Token Storage Strategy

| Token Type    | Storage                | Lifetime              | Notes                                 |
| ------------- | ---------------------- | --------------------- | ------------------------------------- |
| Session Token | flutter_secure_storage | 7 days (configurable) | Per-group, auto-refresh not available |
| Admin Token   | flutter_secure_storage | Never expires         | Only for group creators               |

---

## 7. UI/UX Requirements

### Color Scheme

```dart
class AppColors {
  // Primary brand colors
  static const primary = Color(0xFF3B82F6);      // Blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const secondary = Color(0xFF10B981);    // Green

  // Backgrounds
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1F2937);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Voting colors (for results visualization)
  static const voteColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];
}
```

### Screen Flow Diagram

```
┌─────────────────┐
│   Splash Screen │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Has Valid Token?│──No─▶│  Onboarding     │
└────────┬────────┘     │  (Join Group)   │
         │Yes           └────────┬────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│              Home Screen                │
│  ┌───────────────────────────────────┐  │
│  │     Today's Question Card         │  │
│  │  "Who is the funniest?"           │  │
│  │  [Alice] [Bob] [Charlie]          │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     Your Streak: 🔥 5 days        │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Bottom Nav:    │
│  • Home         │
│  • Members      │
│  • History      │
│  • Settings     │
└─────────────────┘
```

### Key Screens

1. **Splash Screen**

   - App logo
   - Check token validity
   - Auto-navigate

2. **Onboarding / Join Group**

   - Invite code input (with paste button)
   - Preview group name/member count
   - Display name input
   - Color picker for avatar
   - "Join Group" button

3. **Home (Today's Question)**

   - Question card with text
   - Options to vote on
   - Results visualization (after voting)
   - Streak display
   - Pull-to-refresh

4. **Members List**

   - Avatar circles with colors
   - Display names
   - Streak badges
   - Sort by streak/name

5. **Question History**

   - Scrollable list of past questions
   - Date, question text, your answer
   - Winner/results summary

6. **Settings**
   - Current group info
   - Leave group option
   - Switch groups (if multi-group)
   - About / Help

### Component Patterns

```dart
// Avatar Circle Component
class AvatarCircle extends StatelessWidget {
  final String colorHex;
  final String? initials;
  final double size;

  const AvatarCircle({
    required this.colorHex,
    this.initials,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
      child: initials != null
          ? Center(
              child: Text(
                initials!,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : null,
    );
  }
}

// Vote Option Card
class VoteOptionCard extends StatelessWidget {
  final String option;
  final int? voteCount;
  final int? totalVotes;
  final bool isSelected;
  final bool showResults;
  final VoidCallback onTap;

  // ... implementation
}

// Streak Badge
class StreakBadge extends StatelessWidget {
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: streak > 0 ? Colors.orange.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(streak > 0 ? '🔥' : '💤'),
          SizedBox(width: 4),
          Text(
            '$streak day${streak != 1 ? 's' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: streak > 0 ? Colors.orange.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. State Management Recommendations

### Recommended: Riverpod

```dart
// providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:8000');
});

// Current User Provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<User?>>((ref) {
  return CurrentUserNotifier(ref);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  CurrentUserNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Load from secure storage
  }

  Future<void> joinGroup(String inviteCode, String displayName, String? color) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/api/users/join', {
        'display_name': displayName,
        'group_invite_code': inviteCode,
        'color_avatar': color,
      });

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        await AuthService.saveSession(user.userId, user.sessionToken);
        state = AsyncValue.data(user);
      } else {
        throw Exception('Failed to join group');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Today's Question Provider
final todaysQuestionProvider = FutureProvider<DailyQuestion?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final api = ref.read(apiClientProvider);
  final groupId = await AuthService.getCurrentGroupId();
  final token = await AuthService.getToken(groupId!);

  final response = await api.get(
    '/api/groups/$groupId/questions/today',
    sessionToken: token,
  );

  if (response.statusCode == 200) {
    return DailyQuestion.fromJson(jsonDecode(response.body));
  }
  return null;
});

// Group Members Provider
final groupMembersProvider = FutureProvider<List<GroupMember>>((ref) async {
  final groupId = await AuthService.getCurrentGroupId();
  if (groupId == null) return [];

  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/groups/$groupId/members');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['members'] as List)
        .map((m) => GroupMember.fromJson(m))
        .toList();
  }
  return [];
});
```

### Alternative: Provider + ChangeNotifier

```dart
class QuestionProvider extends ChangeNotifier {
  DailyQuestion? _question;
  bool _loading = false;
  String? _error;

  DailyQuestion? get question => _question;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchTodaysQuestion(String groupId, String token) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // API call
      _question = await _api.getTodaysQuestion(groupId, token);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> submitAnswer(String answer) async {
    // Submit and update local state
  }
}
```

---

## 9. Technical Implementation Notes

### Package Recommendations

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0

  # HTTP & WebSocket
  http: ^1.1.0
  web_socket_channel: ^2.4.0

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # UI Components
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0 # Loading skeletons
  fl_chart: ^0.65.0 # Charts for results

  # Utilities
  intl: ^0.18.0 # Date formatting
  share_plus: ^7.2.0 # Share invite code
  url_launcher: ^6.2.0
  qr_flutter: ^4.1.0 # QR code for invite

  # Optional - Push Notifications
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Error Handling

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return ApiException(
        statusCode: response.statusCode,
        message: body['detail'] ?? 'Unknown error',
        details: body,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        message: 'Request failed with status ${response.statusCode}',
      );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// Usage
Future<User> joinGroup(...) async {
  final response = await api.post('/api/users/join', body);

  if (response.statusCode != 200) {
    throw ApiException.fromResponse(response);
  }

  return User.fromJson(jsonDecode(response.body));
}
```

### WebSocket Integration

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class VoteWebSocket {
  WebSocketChannel? _channel;
  final String baseUrl;

  VoteWebSocket({required this.baseUrl});

  void connect(String groupId, String questionId, Function(Map<String, int>) onVoteUpdate) {
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/groups/$groupId/questions/$questionId'),
    );

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'vote_update') {
        onVoteUpdate(Map<String, int>.from(data['option_counts']));
      }
    });
  }

  void sendVote(String sessionToken, String answer) {
    _channel?.sink.add(jsonEncode({
      'type': 'vote',
      'session_token': sessionToken,
      'answer': answer,
    }));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
```

### Offline Handling

```dart
// Check connectivity before API calls
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}

// Cache last question locally
import 'package:shared_preferences/shared_preferences.dart';

class QuestionCache {
  static const _key = 'cached_question';

  static Future<void> save(DailyQuestion question) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(question.toJson()));
  }

  static Future<DailyQuestion?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      return DailyQuestion.fromJson(jsonDecode(data));
    }
    return null;
  }
}
```

---

## 10. Testing Considerations

### API Mocking

```dart
// test/mocks/api_client_mock.dart
class MockApiClient extends Mock implements ApiClient {}

// test/providers/question_provider_test.dart
void main() {
  group('QuestionProvider', () {
    late MockApiClient mockApi;

    setUp(() {
      mockApi = MockApiClient();
    });

    test('fetches today\'s question successfully', () async {
      when(mockApi.get(any, sessionToken: anyNamed('sessionToken')))
          .thenAnswer((_) async => http.Response(
            jsonEncode({
              'id': 1,
              'question_id': 'test-uuid',
              'question_text': 'Test question?',
              'question_type': 'member_choice',
              'options': ['Alice', 'Bob'],
              'option_counts': {'Alice': 1, 'Bob': 0},
              'question_date': '2025-12-17T00:00:00Z',
              'is_active': true,
              'total_votes': 1,
              'allow_multiple': false,
            }),
            200,
          ));

      // Test implementation
    });
  });
}
```

### Widget Testing

```dart
void main() {
  testWidgets('VoteOptionCard shows vote count after voting', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VoteOptionCard(
          option: 'Alice',
          voteCount: 5,
          totalVotes: 10,
          isSelected: true,
          showResults: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('5 votes'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });
}
```

---

## Quick Reference: Error Codes

| Code | Meaning      | Action                              |
| ---- | ------------ | ----------------------------------- |
| 200  | Success      | Process response                    |
| 400  | Bad Request  | Show validation error               |
| 401  | Unauthorized | Redirect to login/join              |
| 403  | Forbidden    | Show access denied                  |
| 404  | Not Found    | Show "not found" message            |
| 409  | Conflict     | Handle duplicate (e.g., name taken) |
| 429  | Rate Limited | Show "slow down" message            |
| 500  | Server Error | Show generic error, retry           |

---

## Development Checklist

### Phase 1: MVP

- [ ] Project setup with recommended packages
- [ ] API client with error handling
- [ ] Secure token storage
- [ ] Join group flow
- [ ] Today's question display
- [ ] Vote submission
- [ ] Results view
- [ ] Basic navigation

### Phase 2: Enhanced

- [ ] Create group flow
- [ ] Admin: create questions
- [ ] Question history
- [ ] Multi-group support
- [ ] WebSocket live updates
- [ ] Pull-to-refresh
- [ ] Share invite code

### Phase 3: Polish

- [ ] Push notifications
- [ ] Offline caching
- [ ] Animations
- [ ] Dark mode
- [ ] Accessibility
- [ ] Analytics

---

**End of Flutter App Briefing**

_This document contains everything needed to build the dontAskUs mobile app. The API is already
deployed and functional. Good luck!_
