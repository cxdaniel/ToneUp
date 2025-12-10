# ToneUp App - AI Coding Agent Instructions

## Project Overview
ToneUp is a Chinese language learning app built with Flutter + Supabase + RevenueCat. The app follows a freemium model with Pro subscriptions available on iOS/Android (Web shows read-only subscription status).

## Core Tech Stack:**
- Flutter 3.35.2 (Dart 3.9.0, Material Design 3)
- Supabase (authentication, database, real-time subscriptions)
- RevenueCat (iOS/Android in-app purchase management)
- Provider pattern for state management
- go_router for navigation
- JiebaSegmenter for Chinese word segmentation

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

## Key Development Workflows

### Testing Subscriptions (iOS)
1. **Local Testing**: Use `ios/ToneUp Chinese learning.storekit` configuration
   - Configured with 7-day free trial for both products
   - Enable StoreKit Configuration in Xcode Scheme settings
   - Check: Edit Scheme → Run → Options → StoreKit Configuration

2. **Sandbox Testing**:
   - Use sandbox Apple ID from App Store Connect
   - RevenueCat automatically uses test key when `kDebugMode == true`
   - Monitor logs: `flutter logs | grep -i revenue`

3. **Production Testing**:
   - TestFlight builds use production API key
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
- `lib/main.dart`: App initialization (Supabase, JiebaSegmenter, providers)
- `lib/routes.dart`: Route constants (use `AppRoutes.ROUTE_NAME`)

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
```

## AI Agent Workflow Recommendations
1. **Before editing subscription code**: Review `revenue_cat_service.dart` and `subscription_provider.dart`
2. **Before adding Pro features**: Check `PremiumFeatureGate` usage patterns
3. **Before UI changes**: Verify Material 3 theme usage and custom extensions
4. **When debugging**: Search for emoji-prefixed logs (✅ success, ❌ error, ⚠️ warning, 🔔 event)
5. **For platform features**: Always ask "Does this need Web vs Mobile differentiation?"
