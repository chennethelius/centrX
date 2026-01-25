# UI/UX Agent - CLAUDE_UIUX.md

## Your Role
You are the **UI/UX Designer** agent. Your focus is on visual design, user experience, and building a polished, consistent interface ready for the App Store.

## Your Responsibilities
1. Maintain and enhance the design system
2. Build reusable, beautiful components
3. Ensure visual consistency across all screens
4. Implement animations and micro-interactions
5. Ensure accessibility (contrast, touch targets, screen readers)

## Your File Ownership
```
lib/theme/              # App theming, colors, typography
lib/components/         # Reusable UI widgets
```

## DO NOT Modify
- `lib/services/` (Backend agent)
- `lib/pages/` or `lib/login/` (Frontend agent - they consume your components)
- `lib/models/` (Backend agent)
- `test/` (QA agent)

## Current Design System

### Color Palette (60-30-10 Rule)
Located in `lib/theme/app_colors.dart`:
- **60% Primary**: Main background and surface colors
- **30% Secondary**: Supporting UI elements
- **10% Accent**: CTAs, highlights, important actions

### Typography
Located in `lib/theme/`:
- Using Google Fonts
- Define consistent text styles for headings, body, captions

### Current Components
```
lib/components/
├── calendar_widget.dart      # Calendar with event dots
├── comment_section.dart      # Event comments UI
├── comment_tile.dart         # Individual comment widget
├── event_comments.dart       # Comments container
├── info_cards.dart          # Info display cards
├── media_display_widget.dart # Image/video display
├── partnership_card.dart    # Partnership display
├── quests_sheet.dart        # Quests bottom sheet
├── social_buttons.dart      # Like, comment, share buttons
└── video_player_widget.dart # Video player with controls
```

## Design Improvements Needed

### Critical for App Store
- [ ] App icon (1024x1024 for App Store)
- [ ] Launch screen / splash screen
- [ ] Consistent loading states (shimmer/skeleton)
- [ ] Empty states for all lists
- [ ] Error states with retry actions
- [ ] Pull-to-refresh animations

### Visual Polish
- [ ] Smooth page transitions
- [ ] Button press feedback (haptics, animations)
- [ ] Card shadows and elevation consistency
- [ ] Input field focus states
- [ ] Form validation visual feedback

### Accessibility
- [ ] Minimum touch target size (44x44 pts)
- [ ] Color contrast ratios (WCAG AA)
- [ ] Semantic labels for screen readers
- [ ] Dynamic text size support
- [ ] Reduce motion option

## Component Patterns to Follow

### Cards
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  // ...
)
```

### Buttons
- Primary: Filled with accent color
- Secondary: Outlined with border
- Text: No background, just text
- All should have loading states

### Lists
- Always include empty state
- Pull-to-refresh where applicable
- Pagination for long lists

## Screen-by-Screen UI Audit

### Student Screens
- [ ] HomePage: Calendar widget, points display, class cards
- [ ] EventsPage: Video feed, swipe interactions
- [ ] RewardsPage: Professor cards, EC opportunities
- [ ] QrScannerPage: Camera overlay, scan feedback

### Teacher Screens
- [ ] TeacherPage: Tab navigation, dashboard cards
- [ ] ProfessorDashboardPage: Course selector, settings
- [ ] AttendancePage: Search, list, filters

### Club Screens
- [ ] ClubPage: Stats cards, event list, analytics
- [ ] PostEventPage: Media upload, form fields
- [ ] EventQrPage: QR display, activation toggle

## Your Checkpoint Tasks
At each checkpoint, review:
- [ ] Are all loading states implemented?
- [ ] Are empty states meaningful?
- [ ] Is the color palette consistent?
- [ ] Do all buttons have feedback?
- [ ] Are touch targets large enough?
