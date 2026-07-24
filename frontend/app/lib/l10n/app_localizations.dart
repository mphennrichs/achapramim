import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Achapramim'**
  String get appTitle;

  /// No description provided for @loginEmailOrUsernameLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou username'**
  String get loginEmailOrUsernameLabel;

  /// No description provided for @loginEmailOrUsernameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o e-mail ou username'**
  String get loginEmailOrUsernameRequired;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a senha'**
  String get loginPasswordRequired;

  /// No description provided for @loginSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginSubmit;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail/username ou senha inválidos.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar. Tente novamente.'**
  String get loginGenericError;

  /// No description provided for @setUsernameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu username'**
  String get setUsernameTitle;

  /// No description provided for @setUsernameDescription.
  ///
  /// In pt, this message translates to:
  /// **'Identificador único e permanente — não poderá ser alterado depois. Você poderá usá-lo para entrar, junto com seu e-mail.'**
  String get setUsernameDescription;

  /// No description provided for @setUsernameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Username'**
  String get setUsernameLabel;

  /// No description provided for @setUsernameHelper.
  ///
  /// In pt, this message translates to:
  /// **'Minúsculas, números e underscore. 3 a 30 caracteres.'**
  String get setUsernameHelper;

  /// No description provided for @setUsernameValidationError.
  ///
  /// In pt, this message translates to:
  /// **'Use 3 a 30 letras minúsculas, números ou _'**
  String get setUsernameValidationError;

  /// No description provided for @setUsernameConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get setUsernameConfirm;

  /// No description provided for @setUsernameTaken.
  ///
  /// In pt, this message translates to:
  /// **'Este username já está em uso. Escolha outro.'**
  String get setUsernameTaken;

  /// No description provided for @setUsernameGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente.'**
  String get setUsernameGenericError;

  /// No description provided for @navMyWatches.
  ///
  /// In pt, this message translates to:
  /// **'Meus Watches'**
  String get navMyWatches;

  /// No description provided for @navNewWatch.
  ///
  /// In pt, this message translates to:
  /// **'Nova Consulta'**
  String get navNewWatch;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get navLogout;

  /// No description provided for @navUserDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Painel do Usuário'**
  String get navUserDashboard;

  /// No description provided for @watchListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus Watches'**
  String get watchListTitle;

  /// No description provided for @watchListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Watch cadastrado ainda.'**
  String get watchListEmpty;

  /// No description provided for @watchListCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar o primeiro Watch'**
  String get watchListCreateFirst;

  /// No description provided for @watchListLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Watches: {error}'**
  String watchListLoadError(String error);

  /// No description provided for @watchTolerance.
  ///
  /// In pt, this message translates to:
  /// **'Tolerância {percent}%'**
  String watchTolerance(String percent);

  /// No description provided for @newWatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Consulta'**
  String get newWatchTitle;

  /// No description provided for @newWatchFromLinkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar a partir de Link'**
  String get newWatchFromLinkTitle;

  /// No description provided for @newWatchFromLinkDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cole a URL de um anúncio para gerar uma Proposta de Preenchimento — sempre editável, nunca cria o Watch sozinha.'**
  String get newWatchFromLinkDescription;

  /// No description provided for @newWatchLinkHint.
  ///
  /// In pt, this message translates to:
  /// **'https://www.olx.com.br/...'**
  String get newWatchLinkHint;

  /// No description provided for @newWatchAnalyze.
  ///
  /// In pt, this message translates to:
  /// **'Analisar'**
  String get newWatchAnalyze;

  /// No description provided for @newWatchPartialFailure.
  ///
  /// In pt, this message translates to:
  /// **'A análise foi parcial — revise os campos preenchidos e complete o restante manualmente.'**
  String get newWatchPartialFailure;

  /// No description provided for @newWatchLinkAnalysisError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível analisar o link agora. Preencha manualmente.'**
  String get newWatchLinkAnalysisError;

  /// No description provided for @newWatchIdentification.
  ///
  /// In pt, this message translates to:
  /// **'Identificação do Watch'**
  String get newWatchIdentification;

  /// No description provided for @newWatchAiSuggested.
  ///
  /// In pt, this message translates to:
  /// **'Sugerido por IA'**
  String get newWatchAiSuggested;

  /// No description provided for @newWatchNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Watch'**
  String get newWatchNameLabel;

  /// No description provided for @newWatchKeywords.
  ///
  /// In pt, this message translates to:
  /// **'Palavras-Chave'**
  String get newWatchKeywords;

  /// No description provided for @newWatchBlockedWords.
  ///
  /// In pt, this message translates to:
  /// **'Palavras Bloqueadas'**
  String get newWatchBlockedWords;

  /// No description provided for @newWatchAddWordHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar...'**
  String get newWatchAddWordHint;

  /// No description provided for @newWatchActiveMarketplaces.
  ///
  /// In pt, this message translates to:
  /// **'Marketplaces Ativos'**
  String get newWatchActiveMarketplaces;

  /// No description provided for @newWatchFinanceAndLimits.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro e Limites'**
  String get newWatchFinanceAndLimits;

  /// No description provided for @newWatchTargetPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço-Alvo (BRL)'**
  String get newWatchTargetPriceLabel;

  /// No description provided for @newWatchToleranceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tolerância (%)'**
  String get newWatchToleranceLabel;

  /// No description provided for @newWatchDropThresholdLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gatilho de Queda (%)'**
  String get newWatchDropThresholdLabel;

  /// No description provided for @newWatchMaxOffersLabel.
  ///
  /// In pt, this message translates to:
  /// **'Máximo de Ofertas'**
  String get newWatchMaxOffersLabel;

  /// No description provided for @newWatchValidationError.
  ///
  /// In pt, this message translates to:
  /// **'Preencha nome, preço-alvo e ao menos um marketplace.'**
  String get newWatchValidationError;

  /// No description provided for @newWatchSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar Watch: {details}'**
  String newWatchSaveError(String details);

  /// No description provided for @newWatchSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Ativar Monitoramento'**
  String get newWatchSubmit;

  /// No description provided for @marketplaceOlx.
  ///
  /// In pt, this message translates to:
  /// **'OLX Brasil'**
  String get marketplaceOlx;

  /// No description provided for @marketplaceMercadoLivre.
  ///
  /// In pt, this message translates to:
  /// **'Mercado Livre'**
  String get marketplaceMercadoLivre;

  /// No description provided for @marketplaceFacebook.
  ///
  /// In pt, this message translates to:
  /// **'FB Marketplace'**
  String get marketplaceFacebook;

  /// No description provided for @watchDetailFallbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Watch'**
  String get watchDetailFallbackTitle;

  /// No description provided for @watchDetailLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Watch: {error}'**
  String watchDetailLoadError(String error);

  /// No description provided for @watchDetailTabOffers.
  ///
  /// In pt, this message translates to:
  /// **'Offers'**
  String get watchDetailTabOffers;

  /// No description provided for @watchDetailTabScans.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Scans'**
  String get watchDetailTabScans;

  /// No description provided for @watchDetailTarget.
  ///
  /// In pt, this message translates to:
  /// **'Alvo: {price}'**
  String watchDetailTarget(String price);

  /// No description provided for @watchDetailTolerance.
  ///
  /// In pt, this message translates to:
  /// **'Tolerância: {percent}%'**
  String watchDetailTolerance(String percent);

  /// No description provided for @watchDetailDropThreshold.
  ///
  /// In pt, this message translates to:
  /// **'Gatilho de queda: {percent}%'**
  String watchDetailDropThreshold(String percent);

  /// No description provided for @watchDetailMaxOffers.
  ///
  /// In pt, this message translates to:
  /// **'Máx. ofertas: {count}'**
  String watchDetailMaxOffers(int count);

  /// No description provided for @watchDetailActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get watchDetailActive;

  /// No description provided for @watchDetailInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get watchDetailInactive;

  /// No description provided for @watchDetailOffersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Offers: {error}'**
  String watchDetailOffersLoadError(String error);

  /// No description provided for @watchDetailNoOffers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma Offer encontrada ainda.'**
  String get watchDetailNoOffers;

  /// No description provided for @watchDetailOfferUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get watchDetailOfferUnavailable;

  /// No description provided for @watchDetailOpenListing.
  ///
  /// In pt, this message translates to:
  /// **'Abrir anúncio'**
  String get watchDetailOpenListing;

  /// No description provided for @watchDetailScansLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Scans: {error}'**
  String watchDetailScansLoadError(String error);

  /// No description provided for @watchDetailNoScans.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Scan executado ainda.'**
  String get watchDetailNoScans;

  /// No description provided for @watchDetailScanFailures.
  ///
  /// In pt, this message translates to:
  /// **'Falhas: {marketplaces}'**
  String watchDetailScanFailures(String marketplaces);

  /// No description provided for @watchDetailOffersFound.
  ///
  /// In pt, this message translates to:
  /// **'{count} ofertas'**
  String watchDetailOffersFound(int count);

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar perfil: {error}'**
  String profileLoadError(String error);

  /// No description provided for @profileEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get profileEmailLabel;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Username'**
  String get profileUsernameLabel;

  /// No description provided for @profileUsernameNotSet.
  ///
  /// In pt, this message translates to:
  /// **'Não definido'**
  String get profileUsernameNotSet;

  /// No description provided for @profileNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profileNameLabel;

  /// No description provided for @profileChangePasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar senha'**
  String get profileChangePasswordTitle;

  /// No description provided for @profileCurrentPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get profileCurrentPasswordLabel;

  /// No description provided for @profileNewPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get profileNewPasswordLabel;

  /// No description provided for @profileConfirmNewPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova senha'**
  String get profileConfirmNewPasswordLabel;

  /// No description provided for @profilePasswordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get profilePasswordMismatch;

  /// No description provided for @profilePasswordTooShort.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter ao menos 6 caracteres'**
  String get profilePasswordTooShort;

  /// No description provided for @profileCurrentPasswordWrong.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual incorreta.'**
  String get profileCurrentPasswordWrong;

  /// No description provided for @profilePasswordChangeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível trocar a senha. Tente novamente.'**
  String get profilePasswordChangeError;

  /// No description provided for @profilePasswordChangeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso.'**
  String get profilePasswordChangeSuccess;

  /// No description provided for @profileSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get profileSaveChanges;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
