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
  String get newWatchKeywords => 'Keywords';

  @override
  String get newWatchBlockedWords => 'Blocked Words';

  @override
  String get newWatchAddWordHint => 'Add...';

  @override
  String get newWatchActiveMarketplaces => 'Active Marketplaces';

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
  String get marketplaceOlx => 'OLX Brasil';

  @override
  String get marketplaceMercadoLivre => 'Mercado Livre';

  @override
  String get marketplaceFacebook => 'FB Marketplace';

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
}
