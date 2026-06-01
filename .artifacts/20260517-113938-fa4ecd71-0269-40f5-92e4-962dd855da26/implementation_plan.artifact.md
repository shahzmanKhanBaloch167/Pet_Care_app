# Material 3 UI Standardization Plan

Standardize the application UI to follow Material 3 design patterns across all screens while maintaining the existing color palette (Deep Blue, Purple, Lavender, Gold) and gradients.

## Proposed Changes

### [Core] Centralized UI Constants
Create a central place for colors and gradients to ensure consistency and easier maintenance.

#### [NEW] [app_ui.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/core/constants/app_ui.dart)
- Define `AppColors` (primaryDark, primaryPurple, accentPurple, accentYellow).
- Define `AppGradients` (mainGradient, accentGradient).
- Define `AppStyles` (M3-compliant border radii, paddings).

---

### [Widgets] Standardized Components
Update shared widgets to M3 patterns.

#### [bottom_navigation_bar.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/widgets/bottom_navigation_bar.dart)
- Update indicator pill to M3 style.
- Use `AppColors` and `AppGradients`.

---

### [Screens] Feature UI Updates
Each screen will be updated to use M3 components and centralized constants.

#### [home_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/home_screen.dart)
- Standardize `QuickActionCard` to M3 card style.
- Update `SliverAppBar` to M3 Large/Medium style.
- Use `AppColors` and `AppGradients`.

#### [pets_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/pets_screen.dart)
- Update `SearchBar` to M3 style.
- Standardize `PetCard` with M3 elevation and corners.
- Update stats section.

#### [pet_profile_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/pet_profile_screen.dart)
- Update `_StatCard` and action cards to M3 style.
- Use `AppGradients` for the header.

#### [add_pet_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/add_pet_screen.dart)
- Update `TextFormField` to M3 filled style with primary colors.
- Update `ElevatedButton` to M3 `FilledButton` style.
- Use `AppColors`.

#### [add_reminder_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/add_reminder_screen.dart)
- Update selection cards and input decorations.
- Ensure consistent M3 typography.

#### [diet_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/diet_screen.dart)
- Update `_buildFeedingScheduleSection` and other list sections to M3 card styles.
- Update water tracking progress bar.

#### [health_records_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/health_records_screen.dart)
- Update `TabBar` and `FloatingActionButton` to M3 styles.
- Standardize `_MedicalRecordCard` and `_VaccineCard`.

#### [reminders_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/reminders_screen.dart)
- Update `TabBar` and `AppBar`.
- Update `FloatingActionButton` to M3 style.

#### [emergency_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/emergency_screen.dart)
- Update cards to M3 style.
- Standardize sections.

#### [splash_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/splash_screen.dart)
- Use centralized constants.

#### [onboarding_screen.dart](file:///C:/Users/FasihKhan/FlutterProjects/flutter_pet_care_app/lib/presentation/screens/onboarding_screen.dart)
- Update page indicators and buttons.

## Verification Plan

### Manual Verification
- I will use `render_compose_preview` (if applicable for some layouts, though it's Flutter) or simply audit the code changes for compliance with the plan.
- I will verify that `useMaterial3: true` is enabled in `main.dart`.
- I will check each screen to ensure `AppColors` and `AppGradients` are used consistently.
