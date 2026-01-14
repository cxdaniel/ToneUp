# ToneUp App - AI Coding Agent Instructions

## Project Overview
ToneUp is a Chinese language learning app built with Flutter + Supabase + RevenueCat. The app follows a freemium model with Pro subscriptions available on iOS/Android (Web shows read-only subscription status).

## Core Tech Stack
- **Flutter**: 3.35.2 (Dart 3.9.0, Material Design 3)
- **Backend**: Supabase (auth, PostgreSQL, real-time)
- **Subscriptions**: RevenueCat (iOS/Android IAP only - not Web)
- **State Management**: Provider pattern (`ChangeNotifier`)
- **Routing**: go_router 16.2.1 with `AppRouter` class
- **Chinese Processing**: JiebaSegmenter, pinyin library
- **Audio**: just_audio, flutter_tts (火山引擎 VolcTTS via `volc_api.dart`)

### Third-Party Authentication
- **Apple Sign In**: Native experience using `sign_in_with_apple` package (iOS 13+, macOS 10.15+)
  - Full native UI integration, no browser required
  - iOS native environment doesn't require nonce parameter
  - Login: `signInWithIdToken(provider: apple, idToken)`
  - Account Linking: `linkIdentityWithIdToken(provider: apple, idToken)`
  
- **Google Sign In**: Native experience using `google_sign_in` 7.x
  - Uses `authenticate()` method (7.x API)
  - **Critical Supabase Configuration**: "Skip nonce checks" MUST be enabled in Google provider
    - Reason: google_sign_in SDK auto-generates nonce in idToken, original value inaccessible
    - Location: Supabase Dashboard → Authentication → Providers → Google
  - Platform-specific initialization:
    - iOS/Android: Requires `serverClientId` for idToken generation
    - Web: Must set `serverClientId: null` (not supported on web platform)
  - Token retrieval:
    - idToken: `googleUser.authentication.idToken`
    - accessToken: `googleUser.authorizationClient.authorizationForScopes()`
  - Login: `signInWithIdToken(provider: google, idToken, accessToken)`
  - Account Linking: `linkIdentityWithIdToken(provider: google, idToken, accessToken)`
  - Full native UI on mobile, OAuth fallback on web

- **Account Linking Strategy**:
  - Mobile (iOS/Android): Use `linkIdentityWithIdToken` for native experience
  - Web: Use `linkIdentity` with OAuth browser flow
  - Implementation: `NativeAuthService` for mobile, `OAuthService` for web
  
- **Documentation**: See `docs/THIRD_PARTY_AUTH.md` for detailed implementation guide

## Architecture Patterns

### Provider + Service Architecture
- **Providers** (`lib/providers/`): State management layer (ChangeNotifier-based)
  - `SubscriptionProvider`: Subscription state, purchase flow, platform-aware loading
  - `ProfileProvider`: User profile data, settings sync
  - `PlanProvider`: Weekly learning plans, progress tracking
  - All providers auto-listen to Supabase auth changes via `onAuthStateChange`
  
- **Services** (`lib/services/`): Business logic layer
  - `RevenueCatService`: Singleton pattern, platform-specific initialization (mobile-only)
  - `DataService`: Supabase CRUD operations wrapper
  - `NativeAuthService`: Native Apple/Google authentication (mobile-only)
  - `OAuthService`: OAuth browser-based authentication (web fallback)
  - Services should be stateless; state lives in Providers

### Platform-Specific Design
**Critical Pattern**: Always check platform before using RevenueCat or native purchase APIs.
```dart
// DO: Platform-aware initialization
if (kIsWeb) {
  debugPrint('⚠️ Web端跳过 RevenueCat 初始化');
  return;
}
// Then proceed with mobile logic
```

**Platform Detection Utilities** (`lib/services/config.dart`):
- `PlatformUtils.isMobile` - iOS or Android
- `PlatformUtils.isWeb` - Web platform
- `PlatformUtils.supportsInAppPurchase()` - Whether RevenueCat should be used

**UI Rendering Strategy**:
- Mobile: Show full subscription purchase flow with RevenueCat offerings
- Web: Show subscription status (synced from Supabase) + download prompt for app stores
- Use conditional rendering in UI: `if (!PlatformUtils.isWeb) { /* show purchase buttons */ }`

### Subscription Flow Architecture
1. **Mobile Purchase Flow**:
   - User clicks "Upgrade" → `PaywallPage` displays `Offerings` from RevenueCat
   - Purchase via `SubscriptionProvider.purchase()` → RevenueCat SDK handles App Store/Play Store
   - RevenueCat webhook → Supabase `subscriptions` table updated
   - `SubscriptionProvider` polls Supabase to reflect new status

2. **Web Flow**:
   - No purchase UI, only displays subscription status from Supabase
   - Show "Download App" buttons linking to App Store/Google Play

3. **Data Sync**:
   - RevenueCat is source of truth for mobile purchases
   - Supabase `subscriptions` table is source of truth for app logic
   - `RevenueCatService.syncSubscriptionToSupabase()` keeps them in sync

## Configuration Management

### API Keys & Environment (`lib/services/config.dart`)
- **RevenueCat Keys**: Uses `kDebugMode` to auto-switch between test/production keys
  - Test Key (sandbox): `test_shpnmmJxpcaomwUSHhOLGIfqrAy`
  - Production iOS Key: `appl_PfoovuEVLvjtBrZlHZMBaHdnpqW`
  - Android Production Key: `YOUR_ANDROID_API_KEY` (placeholder - needs configuration)
- **Product IDs**: Must match App Store Connect configuration
  - Monthly: `toneup_monthly_sub`
  - Annual: `toneup_annually_sub`
- **Entitlement ID**: `pro_features` (RevenueCat entitlement name)

### Supabase Configuration
- URL: `https://kixonwnuivnjqlraydmz.supabase.co`
- Key: In `SupabaseConfig` (current implementation has anon key hardcoded - consider moving to env vars)

## Theme System (Material Design 3)

### Theme Configuration (`lib/theme_data.dart`)
- Uses Material 3 with custom color extensions for app-specific states
- **Custom Theme Extension**: `AppThemeExtensions`
  - `statePass` / `statePassContainer`: Correct answer feedback colors
  - `stateFail` / `stateFailContainer`: Wrong answer feedback colors
  - `exp` / `expContainer`: Experience points display colors
- **Usage Pattern**: Access via `Theme.of(context).extension<AppThemeExtensions>()`
- Light and dark themes both defined with proper Material 3 contrast

### Theming Best Practices
- Always use `Theme.of(context).colorScheme.*` for standard colors
- Use custom extensions for domain-specific colors (quiz feedback, XP)
- Never hardcode color values directly in widgets

## Critical Build & Run Commands

### Development
```bash
flutter pub get                           # Install dependencies
flutter run -d "iPhone 15 Pro"            # iOS simulator
flutter run -d chrome --web-port=8080     # Web (localhost:8080 for OAuth)
flutter run -d emulator-5554              # Android emulator
```

### Building
```bash
flutter build ios --release               # iOS production build
flutter build web --release --wasm        # Web with WASM (deployed to Netlify)
cd ios && pod install                     # Update iOS CocoaPods (after pubspec changes)
```

### Debugging
```bash
flutter logs | grep -i revenue            # Monitor RevenueCat logs
flutter analyze                           # Lint check
flutter test --coverage                   # Run tests with coverage
```

### CI/CD Scripts
- `ci_scripts/ci_post_clone.sh`: Runs `pod install` after clone
- `ci_scripts/ci_pre_xcodebuild.sh`: Runs `flutter build ios --release --no-codesign`

## Key Development Workflows

### Testing Subscriptions (iOS)
1. **Local Testing**: Use `ios/ToneUp Chinese learning.storekit` configuration
   - Configured with 7-day free trial for both products
   - Enable StoreKit Configuration in Xcode Scheme settings
   - Check: Edit Scheme → Run → Options → StoreKit Configuration

2. **Sandbox Testing**:
   - Use sandbox Apple ID from App Store Connect
   - RevenueCat automatically uses test key when `kDebugMode == true`
  **Tables use snake_case**: `user_weekly_plan`, `user_practice`, `subscriptions`, `profiles`, `user_materials`
- **Models use PascalCase**: `UserWeeklyPlanModel`, `UserPracticeModel`, `SubscriptionModel`, `ProfileModel`
- All models in `lib/models/` with `fromJson`/`toJson` serialization
- RLS (Row Level Security) enabled for user-specific data
- **15-dimension ability indicators**: Each learning material tagged with indicators like `charsRecognition`, `wordRecognition`, `listening`, `speaking` (see `lib/models/indicators_model.dart`)
- **HSK Level System**: Content categorized by HSK 1-6 (150 chars → 5000+ chars)
   - Subscription purchases are real (but can be refunded)
   - Verify webhook delivery to Supabase in RevenueCat dashboard

### Debugging Subscription Issues
- Check RevenueCat initialization logs: Look for `✅ RevenueCat 初始化成功`
- Verify offerings load: `await _revenueCat.getOfferings()` should not be empty
- Check Supabase sync: Query `subscriptions` table for user's entry
- Common errors:
  - **Configuration error (23)**: StoreKit Configuration not enabled
  - **Empty offerings**: Products not set up in App Store Connect or StoreKit file
  - **Purchase failing**: Financial information incomplete in App Store Connect

### Adding New Features
1. **Gated Features** (Pro-only): Use `PremiumFeatureGate` widget wrapper
   ```dart
   PremiumFeatureGate(
     featureName: 'Advanced Analytics',
     child: YourProFeatureWidget(),
   )
   ```
2. **Free Features**: No special handling needed
3. **Platform-Specific Features**: Always wrap mobile-only code with `if (!PlatformUtils.isWeb)`

### Database Schema Conventions (Supabase)
- Tables use snake_case: `user_weekly_plan`, `user_practice`, `subscriptions`
- Models use PascalCase: `UserWeeklyPlanModel`, `UserPracticeModel`, `SubscriptionModel`
- All models in `lib/models/` with `fromJson`/`toJson` serialization
- RLS (Row Level Security) should be enabled for user-specific data

## Critical File Locations

### Entry Points
- `lib/main.dart`: App initialization (Supabase, JiebaSegmenter, providers via `MultiProvider`)
- `lib/router_config.dart`: Route config and constants (use `AppRouter.ROUTE_NAME`)
  - Auth redirects in `_handleRedirect()` - distinguishes login vs linking flows
  - Shell routing via `StatefulShellBranch` for bottom navigation

### Subscription System
- `lib/services/revenue_cat_service.dart`: RevenueCat SDK wrapper (299 lines)
- `lib/providers/subscription_provider.dart`: Subscription state management (331 lines)
- `lib/pages/paywall.dart`: Subscription purchase UI
- `lib/pages/profile_page.dart`: Subscription status display (platform-specific rendering)
- `lib/components/premium_feature_gate.dart`: Pro feature access control

### Core Models
- `lib/models/subscription_model.dart`: Subscription data structure
- `lib/models/profile_model.dart`: User profile data
- `lib/models/user_weekly_plan_model.dart`: Learning plan structure

## Common Pitfalls & Solutions

### ❌ Don't
- **Never** call RevenueCat APIs on Web platform (will crash)
- **Never** hardcode API keys directly in code without environment checks
- **Never** use `setState` in Provider classes (use `notifyListeners()`)
- **Never** forget to check `_disposed` flag before calling `notifyListeners()`
- **Never** initialize RevenueCat synchronously in `main()` (use async/await)

### ✅ Do
- **Always** check `kIsWeb` before using RevenueCat or platform-specific packages
- **Always** use `debugPrint()` for logging (respects debug/release mode)
- **Always** handle errors in subscription flow with user-friendly messages
- **Always** sync subscription state to Supabase after RevenueCat purchase
- **Always** use absolute imports: `package:toneup_app/...` (not relative paths)

## Navigation Patterns
- Uses `go_router` with named routes in `AppRoutes` class
- Navigation: `context.push(AppRoutes.PAYWALL)` or `context.go(AppRoutes.HOME)`
- Shell routing via `MainShell` widget for bottom tab navigation
- Auth redirects handled in router configuration (see `main.dart` router setup)

## State Management Conventions
- **Provider Pattern**: All app-wide state via `MultiProvider` in `main.dart`
- **Provider Lifecycle**: 
  - Initialize in constructor or `initialize()` method
  - Set up auth listeners in constructor
  - Always implement `dispose()` with `_disposed` flag
  - Cancel stream subscriptions in `dispose()`
- **Accessing State**: Use `Consumer<T>` widget for reactive UI updates
- **Modifying State**: Call methods on provider, which then call `notifyListeners()`

## Testing Strategy
- Unit tests: Test provider logic and service methods
- Widget tests: Test UI components with mocked providers
- Integration tests: Test full subscription flow with test RevenueCat key
- Use `flutter test --coverage` to ensure critical paths are tested

## Deployment Checklist
**iOS Release:**
- [ ] Switch `useTestKey = false` in `RevenueCatConfig` (or keep `kDebugMode` logic)
- [ ] Verify production API key is set
- [ ] App Store Connect products configured with correct free trial duration
- [ ] RevenueCat webhook URL added to App Store Connect
- [ ] Financial information completed in App Store Connect

**Android Release (TODO):**
- [ ] Configure Android subscription products in Play Console
- [ ] Add production Android API key to `RevenueCatConfig`
- [ ] Test with Google Play sandbox accounts

**Web Deployment:**
- [ ] Ensure no RevenueCat code is called (platform checks in place)
- [ ] Verify Supabase subscription status displays correctly
- [ ] Test download links to App Store/Google Play

## Example Code Patterns

### Accessing Subscription Status in UI
```dart
Consumer<SubscriptionProvider>(
  builder: (context, subscription, _) {
    if (subscription.isPro) {
      return ProFeatureWidget();
    }
    return UpgradePromptWidget();
  },
)
```

### Making a Feature Pro-Only
```dart
PremiumFeatureGate(
  featureName: 'Unlimited Practice',
  child: PracticeSection(),
)
```

### Platform-Specific Rendering
```dart
if (PlatformUtils.isWeb) {
  return DownloadAppPrompt();
} else {
  return SubscriptionPurchaseUI();
}
```

### Loading Data with Error Handling
```dart
Future<void> loadData() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  
  try {
    final data = await _service.fetchData();
    _data = data;
  } catch (e) {
    _errorMessage = '加载失败: $e';
    debugPrint('❌ Error: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```Important Project-Specific Patterns

### Auth Flow Nuances (Critical!)
- **Login vs Linking Detection** (`lib/main.dart:_authStateChangeHandler()`):
  - Checks current route to determine if `signedIn` event is from login or account linking
  - Login: Redirects to `HOME` and initializes all providers
  - Linking: Stays on current page, only refreshes `ProfileProvider`
  - Custom scheme deep links have `path == "/"` - check full URI string
- **OAuth State Caching** (`lib/main.dart:_cacheOAuthUserInfo()`):
  - Stores OAuth user metadata temporarily during auth flow
  - Used to create profile if doesn't exist in Supabase

### Logging Convention
Search emoji-prefixed logs for debugging:
- `✅` Success events (e.g., `✅ RevenueCat 初始化成功`)
- `❌` Errors (e.g., `❌ RevenueCat 初始化失败`)
- `⚠️` Warnings (e.g., `⚠️ Web 端跳过 RevenueCat 初始化`)
- `🔔` Auth events (e.g., `🔔 @main 收到 auth event: signedIn`)

### Initialization Order (main.dart)
```dart
WidgetsFlutterBinding.ensureInitialized();
usePathUrlStrategy();                  // Remove # from Web URLs
await Supabase.initialize(...);
await JiebaSegmenter.init();           // Load Chinese segmentation dict
await NativeAuthService().initialize(); // Platform-specific auth setup
runApp(MyApp());
```

### Services Architecture
- **DataService** (`lib/services/data_service.dart`): CRUD wrapper for Supabase, used by providers
- **NativeAuthService**: Mobile-only, handles Apple/Google native sign-in
- **OAuthService**: Web fallback for browser-based OAuth
- **RevenueCatService**: Singleton, mobile-only (check `kIsWeb` before calling)
- **NavigationService**: Global navigator key for context-less navigation

### Providers Lifecycle Pattern
All providers follow this pattern:
```dart
class MyProvider extends ChangeNotifier {
  bool _disposed = false;
  StreamSubscription? _authSub;
  
  MyProvider() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(...);
  }
  
  void onUserSign(bool isSignedIn) {
    if (isSignedIn) {
      loadData();
    } else {
      clearData();
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    super.dispose();
  }
  
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
```

## Documentation References
- **Full Architecture**: `docs/PROJECT_OVERVIEW.md` (900+ lines covering HSK system, 15 indicators, data models)
- **Third-Party Auth**: `docs/THIRD_PARTY_AUTH.md` (Google/Apple native + OAuth strategies)
- **Testing Guide**: `docs/TESTING_GUIDE.md` (Platform-specific test commands)
- **Web Deployment**: `docs/WEB_DEPLOYMENT.md` (Netlify WASM build process)
- **Data Models**: `docs/DATA_MODELS.md` (Complete schema reference)

## AI Agent Workflow Recommendations
1. **Before editing subscription code**: Review `revenue_cat_service.dart` and `subscription_provider.dart`
2. **Before adding Pro features**: Check `PremiumFeatureGate` usage in `lib/components/`
3. **Before UI changes**: Verify Material 3 theme usage and custom `AppThemeExtensions`
4. **When debugging auth**: Search for `🔔 @main 收到 auth event` to trace flow
5. **For platform features**: Always ask "Does this need Web vs Mobile differentiation?" Check `kIsWeb` first
6. **Before modifying routes**: Check `router_config.dart` auth redirect logic to avoid breaking login/linking flows
4. **When debugging**: Search for emoji-prefixed logs (✅ success, ❌ error, ⚠️ warning, 🔔 event)
5. **For platform features**: Always ask "Does this need Web vs Mobile differentiation?"
