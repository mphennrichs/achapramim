// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Achapramim';

  @override
  String get loginEmailOrUsernameLabel => 'Email or username';

  @override
  String get loginEmailOrUsernameRequired => 'Enter your email or username';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalidCredentials => 'Invalid email/username or password.';

  @override
  String get loginGenericError => 'Could not connect. Please try again.';

  @override
  String get setUsernameTitle => 'Choose your username';

  @override
  String get setUsernameDescription =>
      'Unique and permanent identifier — cannot be changed later. You\'ll be able to use it to sign in, along with your email.';

  @override
  String get setUsernameLabel => 'Username';

  @override
  String get setUsernameHelper =>
      'Lowercase letters, numbers and underscore. 3 to 30 characters.';

  @override
  String get setUsernameValidationError =>
      'Use 3 to 30 lowercase letters, numbers or _';

  @override
  String get setUsernameConfirm => 'Confirm';

  @override
  String get setUsernameTaken =>
      'This username is already taken. Choose another one.';

  @override
  String get setUsernameGenericError => 'Could not save. Please try again.';

  @override
  String get navMyWatches => 'My Watches';

  @override
  String get navNewWatch => 'New Search';

  @override
  String get navProfile => 'Profile';

  @override
  String get navLogout => 'Logout';

  @override
  String get navUserDashboard => 'User Dashboard';

  @override
  String get watchListTitle => 'My Watches';

  @override
  String get watchListEmpty => 'No Watch created yet.';

  @override
  String get watchListCreateFirst => 'Create your first Watch';

  @override
  String watchListLoadError(String error) {
    return 'Failed to load Watches: $error';
  }

  @override
  String watchTolerance(String percent) {
    return 'Tolerance $percent%';
  }

  @override
  String get newWatchTitle => 'New Search';

  @override
  String get newWatchFromLinkTitle => 'Create from Link';

  @override
  String get newWatchFromLinkDescription =>
      'Paste a listing URL to generate a Prefill Proposal — always editable, never creates the Watch on its own.';

  @override
  String get newWatchLinkHint => 'https://www.olx.com.br/...';

  @override
  String get newWatchAnalyze => 'Analyze';

  @override
  String get newWatchPartialFailure =>
      'The analysis was partial — review the filled fields and complete the rest manually.';

  @override
  String get newWatchLinkAnalysisError =>
      'Could not analyze the link right now. Please fill in manually.';

  @override
  String get newWatchIdentification => 'Watch Identification';

  @override
  String get newWatchAiSuggested => 'AI suggested';

  @override
  String get newWatchNameLabel => 'Watch name';

  @override
  String get newWatchRegionTitle => 'Search Region';

  @override
  String get newWatchCityLabel => 'City';

  @override
  String get newWatchStateLabel => 'State';

  @override
  String get newWatchActiveMarketplaces => 'Marketplaces';

  @override
  String get marketplaceOlx => 'OLX';

  @override
  String get marketplaceFacebook => 'Facebook Marketplace';

  @override
  String get newWatchKeywords => 'Keywords';

  @override
  String get newWatchBlockedWords => 'Blocked Words';

  @override
  String get newWatchAddWordHint => 'Add...';

  @override
  String get newWatchFinanceAndLimits => 'Finance and Limits';

  @override
  String get newWatchTargetPriceLabel => 'Target Price (BRL)';

  @override
  String get newWatchToleranceLabel => 'Tolerance (%)';

  @override
  String get newWatchDropThresholdLabel => 'Drop Trigger (%)';

  @override
  String get newWatchMaxOffersLabel => 'Max Offers';

  @override
  String get newWatchValidationError =>
      'Fill in the name, target price and at least one marketplace.';

  @override
  String newWatchSaveError(String details) {
    return 'Failed to save Watch: $details';
  }

  @override
  String get newWatchSubmit => 'Activate Monitoring';

  @override
  String get watchDetailFallbackTitle => 'Watch';

  @override
  String watchDetailLoadError(String error) {
    return 'Failed to load Watch: $error';
  }

  @override
  String get watchDetailTabOffers => 'Offers';

  @override
  String get watchDetailTabScans => 'Scan History';

  @override
  String watchDetailTarget(String price) {
    return 'Target: $price';
  }

  @override
  String watchDetailTolerance(String percent) {
    return 'Tolerance: $percent%';
  }

  @override
  String watchDetailDropThreshold(String percent) {
    return 'Drop trigger: $percent%';
  }

  @override
  String watchDetailMaxOffers(int count) {
    return 'Max. offers: $count';
  }

  @override
  String get watchDetailActive => 'Active';

  @override
  String get watchDetailInactive => 'Inactive';

  @override
  String watchDetailOffersLoadError(String error) {
    return 'Failed to load Offers: $error';
  }

  @override
  String get watchDetailNoOffers => 'No Offer found yet.';

  @override
  String get watchDetailOfferUnavailable => 'Unavailable';

  @override
  String get watchDetailOpenListing => 'Open listing';

  @override
  String watchDetailScansLoadError(String error) {
    return 'Failed to load Scans: $error';
  }

  @override
  String get watchDetailNoScans => 'No Scan run yet.';

  @override
  String watchDetailScanFailures(String marketplaces) {
    return 'Failures: $marketplaces';
  }

  @override
  String watchDetailOffersFound(int count) {
    return '$count offers';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String profileLoadError(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileUsernameNotSet => 'Not set';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileThemeTitle => 'Theme';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileChangePasswordTitle => 'Change password';

  @override
  String get profileCurrentPasswordLabel => 'Current password';

  @override
  String get profileNewPasswordLabel => 'New password';

  @override
  String get profileConfirmNewPasswordLabel => 'Confirm new password';

  @override
  String get profilePasswordMismatch => 'Passwords don\'t match';

  @override
  String get profilePasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get profileCurrentPasswordWrong => 'Current password is incorrect.';

  @override
  String get profilePasswordChangeError =>
      'Could not change password. Please try again.';

  @override
  String get profilePasswordChangeSuccess => 'Password changed successfully.';

  @override
  String get profileSaveChanges => 'Save';

  @override
  String get navAdminUsers => 'Users';

  @override
  String get navAdminAllWatches => 'All Watches';

  @override
  String get navAdminSettings => 'Settings';

  @override
  String get adminUsersTitle => 'Users';

  @override
  String adminUsersLoadError(String error) {
    return 'Failed to load users: $error';
  }

  @override
  String get adminUsersCreate => 'New user';

  @override
  String get adminUsersNameLabel => 'Name';

  @override
  String get adminUsersEmailLabel => 'Email';

  @override
  String get adminUsersPasswordLabel => 'Initial password';

  @override
  String get adminUsersUsernameLabel => 'Username (optional)';

  @override
  String get adminUsersUsernameHint =>
      'Leave blank for the user to set it on First Access';

  @override
  String get adminUsersUsernameInvalid =>
      '3-30 characters: lowercase letters, numbers or _';

  @override
  String get adminUsersUsernameTaken => 'Username already taken';

  @override
  String get adminUsersUsernameAvailable => 'Available';

  @override
  String get adminUsersUsernameChecking => 'Checking...';

  @override
  String get adminUsersRoleLabel => 'Role';

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleUser => 'User';

  @override
  String get adminUsersCreateSubmit => 'Create';

  @override
  String adminUsersCreateError(String details) {
    return 'Failed to create user: $details';
  }

  @override
  String get adminUsersActive => 'Active';

  @override
  String get adminUsersInactive => 'Inactive';

  @override
  String get adminUsersUsernamePending => 'Username pending';

  @override
  String get adminUsersUpdateError =>
      'Failed to update user. Please try again.';

  @override
  String get adminUsersCancel => 'Cancel';

  @override
  String get adminUsersEditUsername => 'Edit username';

  @override
  String get adminUsersSetUsername => 'Set username';

  @override
  String adminUsersUsernameDialogTitle(String name) {
    return '$name\'s username';
  }

  @override
  String get adminUsersUsernameSave => 'Save';

  @override
  String adminUsersUsernameSaveError(String details) {
    return 'Failed to save username: $details';
  }

  @override
  String get adminWatchesTitle => 'All Watches';

  @override
  String adminWatchesLoadError(String error) {
    return 'Failed to load Watches: $error';
  }

  @override
  String get adminWatchesEmpty => 'No Watch created in the system yet.';

  @override
  String adminWatchesOwnerLabel(String name, String email) {
    return 'Owner: $name ($email)';
  }

  @override
  String get adminSettingsTitle => 'Settings';

  @override
  String adminSettingsLoadError(String error) {
    return 'Failed to load settings: $error';
  }

  @override
  String get adminSettingsScanTitle => 'Scan Interval';

  @override
  String get adminSettingsScanDescription =>
      'Minimum and maximum interval (in minutes) between Scan runs for each Watch. Each Watch\'s actual schedule is randomized within this range.';

  @override
  String get adminSettingsMinIntervalLabel => 'Minimum interval (minutes)';

  @override
  String get adminSettingsMaxIntervalLabel => 'Maximum interval (minutes)';

  @override
  String get adminSettingsRegionTitle => 'Default Search Region';

  @override
  String get adminSettingsRegionDescription =>
      'Used by a Watch when it doesn\'t define its own city/state.';

  @override
  String get adminSettingsDefaultCityLabel => 'Default city';

  @override
  String get adminSettingsDefaultStateLabel => 'State';

  @override
  String get adminSettingsBlockedWordsTitle => 'Default Blocked Words';

  @override
  String get adminSettingsBlockedWordsDescription =>
      'Copied to every new Watch on creation. Editing here does not affect existing Watches.';

  @override
  String get adminSettingsValidationError =>
      'Check the interval (max >= min) and fill in the default city and state.';

  @override
  String get adminSettingsSaveError =>
      'Failed to save settings. Please try again.';

  @override
  String get adminSettingsSaveSuccess => 'Settings saved successfully.';

  @override
  String get adminSettingsSave => 'Save';
}
