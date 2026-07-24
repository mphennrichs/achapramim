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
  /// **'Meus Alertas'**
  String get navMyWatches;

  /// No description provided for @navNewWatch.
  ///
  /// In pt, this message translates to:
  /// **'Novo Alerta'**
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
  /// **'Meus Alertas'**
  String get watchListTitle;

  /// No description provided for @watchListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Alerta cadastrado ainda.'**
  String get watchListEmpty;

  /// No description provided for @watchListCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar o primeiro Alerta'**
  String get watchListCreateFirst;

  /// No description provided for @watchListLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Alertas: {error}'**
  String watchListLoadError(String error);

  /// No description provided for @watchTolerance.
  ///
  /// In pt, this message translates to:
  /// **'Tolerância {percent}%'**
  String watchTolerance(String percent);

  /// No description provided for @watchEditTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar Alerta'**
  String get watchEditTooltip;

  /// No description provided for @watchDeleteTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Alerta'**
  String get watchDeleteTooltip;

  /// No description provided for @watchDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Alerta?'**
  String get watchDeleteConfirmTitle;

  /// No description provided for @watchDeleteConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita. Todas as Offers e o histórico de Scans deste Alerta serão perdidos.'**
  String get watchDeleteConfirmMessage;

  /// No description provided for @watchDeleteConfirmCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get watchDeleteConfirmCancel;

  /// No description provided for @watchDeleteConfirmConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get watchDeleteConfirmConfirm;

  /// No description provided for @watchDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao excluir Alerta: {error}'**
  String watchDeleteError(String error);

  /// No description provided for @newWatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Alerta'**
  String get newWatchTitle;

  /// No description provided for @newWatchFromLinkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar a partir de Link'**
  String get newWatchFromLinkTitle;

  /// No description provided for @newWatchFromLinkDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cole a URL de um anúncio para gerar uma Proposta de Preenchimento — sempre editável, nunca cria o Alerta sozinha.'**
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
  /// **'Identificação do Alerta'**
  String get newWatchIdentification;

  /// No description provided for @newWatchAiSuggested.
  ///
  /// In pt, this message translates to:
  /// **'Sugerido por IA'**
  String get newWatchAiSuggested;

  /// No description provided for @newWatchNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Alerta'**
  String get newWatchNameLabel;

  /// No description provided for @newWatchRegionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Região da Busca'**
  String get newWatchRegionTitle;

  /// No description provided for @newWatchCityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get newWatchCityLabel;

  /// No description provided for @newWatchStateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado (UF)'**
  String get newWatchStateLabel;

  /// No description provided for @newWatchActiveMarketplaces.
  ///
  /// In pt, this message translates to:
  /// **'Marketplaces'**
  String get newWatchActiveMarketplaces;

  /// No description provided for @marketplaceOlx.
  ///
  /// In pt, this message translates to:
  /// **'OLX'**
  String get marketplaceOlx;

  /// No description provided for @marketplaceFacebook.
  ///
  /// In pt, this message translates to:
  /// **'Facebook Marketplace'**
  String get marketplaceFacebook;

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
  /// **'Falha ao salvar Alerta: {details}'**
  String newWatchSaveError(String details);

  /// No description provided for @newWatchSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Ativar Monitoramento'**
  String get newWatchSubmit;

  /// No description provided for @editWatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Alerta'**
  String get editWatchTitle;

  /// No description provided for @editWatchSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get editWatchSubmit;

  /// No description provided for @watchDetailFallbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get watchDetailFallbackTitle;

  /// No description provided for @watchDetailLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Alerta: {error}'**
  String watchDetailLoadError(String error);

  /// No description provided for @watchDetailTabOffers.
  ///
  /// In pt, this message translates to:
  /// **'Ofertas'**
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

  /// No description provided for @watchDetailSortLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get watchDetailSortLabel;

  /// No description provided for @watchDetailSortRecommended.
  ///
  /// In pt, this message translates to:
  /// **'Recomendados'**
  String get watchDetailSortRecommended;

  /// No description provided for @watchDetailSortPriceAsc.
  ///
  /// In pt, this message translates to:
  /// **'Menor preço'**
  String get watchDetailSortPriceAsc;

  /// No description provided for @watchDetailSortPriceDesc.
  ///
  /// In pt, this message translates to:
  /// **'Maior preço'**
  String get watchDetailSortPriceDesc;

  /// No description provided for @watchDetailSortNewest.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get watchDetailSortNewest;

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

  /// No description provided for @watchDetailOpenListingError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o anúncio. O link pode estar inválido.'**
  String get watchDetailOpenListingError;

  /// No description provided for @watchDetailMonitorOffer.
  ///
  /// In pt, this message translates to:
  /// **'Monitorar esta oferta'**
  String get watchDetailMonitorOffer;

  /// No description provided for @watchDetailUnmonitorOffer.
  ///
  /// In pt, this message translates to:
  /// **'Parar de monitorar esta oferta'**
  String get watchDetailUnmonitorOffer;

  /// No description provided for @watchDetailMonitorError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o monitoramento: {error}'**
  String watchDetailMonitorError(String error);

  /// No description provided for @watchDetailPriceHistoryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preço'**
  String get watchDetailPriceHistoryTooltip;

  /// No description provided for @watchDetailPriceHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preço'**
  String get watchDetailPriceHistoryTitle;

  /// No description provided for @watchDetailPriceHistoryLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar histórico de preço: {error}'**
  String watchDetailPriceHistoryLoadError(String error);

  /// No description provided for @watchDetailPriceHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há histórico de preço para esta oferta.'**
  String get watchDetailPriceHistoryEmpty;

  /// No description provided for @watchDetailPriceHistoryClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get watchDetailPriceHistoryClose;

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

  /// No description provided for @watchDetailScanNewAndSeen.
  ///
  /// In pt, this message translates to:
  /// **'{newCount} novos, {seenCount} já vistos'**
  String watchDetailScanNewAndSeen(int newCount, int seenCount);

  /// No description provided for @notificationsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsTooltip;

  /// No description provided for @notificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação ainda.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar notificações: {error}'**
  String notificationsLoadError(String error);

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In pt, this message translates to:
  /// **'Marcar todas como lidas'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get notificationsClose;

  /// No description provided for @notificationsPriceDropTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preço baixou: {watchName}'**
  String notificationsPriceDropTitle(String watchName);

  /// No description provided for @notificationsPriceDropBody.
  ///
  /// In pt, this message translates to:
  /// **'{offerTitle} agora por {price}'**
  String notificationsPriceDropBody(String offerTitle, String price);

  /// No description provided for @watchDetailOffersFound.
  ///
  /// In pt, this message translates to:
  /// **'{count} ofertas'**
  String watchDetailOffersFound(int count);

  /// No description provided for @scanStatusSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get scanStatusSuccess;

  /// No description provided for @scanStatusPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get scanStatusPartial;

  /// No description provided for @scanStatusFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get scanStatusFailed;

  /// No description provided for @scanStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get scanStatusPending;

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

  /// No description provided for @profileThemeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get profileThemeTitle;

  /// No description provided for @profileThemeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get profileThemeDark;

  /// No description provided for @profileThemeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get profileThemeSystem;

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

  /// No description provided for @navAdminUsers.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get navAdminUsers;

  /// No description provided for @navAdminAllWatches.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Alertas'**
  String get navAdminAllWatches;

  /// No description provided for @navAdminSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get navAdminSettings;

  /// No description provided for @adminUsersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get adminUsersTitle;

  /// No description provided for @adminUsersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar usuários: {error}'**
  String adminUsersLoadError(String error);

  /// No description provided for @adminUsersCreate.
  ///
  /// In pt, this message translates to:
  /// **'Novo usuário'**
  String get adminUsersCreate;

  /// No description provided for @adminUsersNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get adminUsersNameLabel;

  /// No description provided for @adminUsersEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get adminUsersEmailLabel;

  /// No description provided for @adminUsersPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha inicial'**
  String get adminUsersPasswordLabel;

  /// No description provided for @adminUsersUsernameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Username (opcional)'**
  String get adminUsersUsernameLabel;

  /// No description provided for @adminUsersUsernameHint.
  ///
  /// In pt, this message translates to:
  /// **'Deixe em branco para o usuário definir no Primeiro Acesso'**
  String get adminUsersUsernameHint;

  /// No description provided for @adminUsersUsernameInvalid.
  ///
  /// In pt, this message translates to:
  /// **'3-30 caracteres: minúsculas, números ou _'**
  String get adminUsersUsernameInvalid;

  /// No description provided for @adminUsersUsernameTaken.
  ///
  /// In pt, this message translates to:
  /// **'Username já em uso'**
  String get adminUsersUsernameTaken;

  /// No description provided for @adminUsersUsernameAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get adminUsersUsernameAvailable;

  /// No description provided for @adminUsersUsernameChecking.
  ///
  /// In pt, this message translates to:
  /// **'Verificando...'**
  String get adminUsersUsernameChecking;

  /// No description provided for @adminUsersRoleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Role'**
  String get adminUsersRoleLabel;

  /// No description provided for @adminUsersRoleAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Admin'**
  String get adminUsersRoleAdmin;

  /// No description provided for @adminUsersRoleUser.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get adminUsersRoleUser;

  /// No description provided for @adminUsersCreateSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get adminUsersCreateSubmit;

  /// No description provided for @adminUsersCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao cadastrar usuário: {details}'**
  String adminUsersCreateError(String details);

  /// No description provided for @adminUsersActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get adminUsersActive;

  /// No description provided for @adminUsersInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get adminUsersInactive;

  /// No description provided for @adminUsersUsernamePending.
  ///
  /// In pt, this message translates to:
  /// **'Username pendente'**
  String get adminUsersUsernamePending;

  /// No description provided for @adminUsersUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao atualizar usuário. Tente novamente.'**
  String get adminUsersUpdateError;

  /// No description provided for @adminUsersCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get adminUsersCancel;

  /// No description provided for @adminUsersEditUsername.
  ///
  /// In pt, this message translates to:
  /// **'Editar username'**
  String get adminUsersEditUsername;

  /// No description provided for @adminUsersSetUsername.
  ///
  /// In pt, this message translates to:
  /// **'Definir username'**
  String get adminUsersSetUsername;

  /// No description provided for @adminUsersUsernameDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Username de {name}'**
  String adminUsersUsernameDialogTitle(String name);

  /// No description provided for @adminUsersUsernameSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get adminUsersUsernameSave;

  /// No description provided for @adminUsersUsernameSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar username: {details}'**
  String adminUsersUsernameSaveError(String details);

  /// No description provided for @adminWatchesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Alertas'**
  String get adminWatchesTitle;

  /// No description provided for @adminWatchesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar Alertas: {error}'**
  String adminWatchesLoadError(String error);

  /// No description provided for @adminWatchesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Alerta cadastrado no sistema ainda.'**
  String get adminWatchesEmpty;

  /// No description provided for @adminWatchesOwnerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dono: {name} ({email})'**
  String adminWatchesOwnerLabel(String name, String email);

  /// No description provided for @adminSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get adminSettingsTitle;

  /// No description provided for @adminSettingsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar configurações: {error}'**
  String adminSettingsLoadError(String error);

  /// No description provided for @adminSettingsScanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo de Scan'**
  String get adminSettingsScanTitle;

  /// No description provided for @adminSettingsScanDescription.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo mínimo e máximo (em minutos) entre execuções de Scan de cada Alerta. O agendamento real de cada Alerta é sorteado dentro dessa faixa.'**
  String get adminSettingsScanDescription;

  /// No description provided for @adminSettingsMinIntervalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo mínimo (minutos)'**
  String get adminSettingsMinIntervalLabel;

  /// No description provided for @adminSettingsMaxIntervalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo máximo (minutos)'**
  String get adminSettingsMaxIntervalLabel;

  /// No description provided for @adminSettingsRegionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Região Padrão de Busca'**
  String get adminSettingsRegionTitle;

  /// No description provided for @adminSettingsRegionDescription.
  ///
  /// In pt, this message translates to:
  /// **'Usada por um Alerta quando ele não define cidade/estado próprios.'**
  String get adminSettingsRegionDescription;

  /// No description provided for @adminSettingsDefaultCityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cidade padrão'**
  String get adminSettingsDefaultCityLabel;

  /// No description provided for @adminSettingsDefaultStateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado (UF)'**
  String get adminSettingsDefaultStateLabel;

  /// No description provided for @adminSettingsBlockedWordsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Palavras Bloqueadas Padrão'**
  String get adminSettingsBlockedWordsTitle;

  /// No description provided for @adminSettingsBlockedWordsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Copiadas para todo Alerta novo na criação. Editar aqui não afeta Alertas já criados.'**
  String get adminSettingsBlockedWordsDescription;

  /// No description provided for @adminSettingsValidationError.
  ///
  /// In pt, this message translates to:
  /// **'Verifique o intervalo (máximo ≥ mínimo) e preencha cidade e estado padrão.'**
  String get adminSettingsValidationError;

  /// No description provided for @adminSettingsSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar configurações. Tente novamente.'**
  String get adminSettingsSaveError;

  /// No description provided for @adminSettingsSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Configurações salvas com sucesso.'**
  String get adminSettingsSaveSuccess;

  /// No description provided for @adminSettingsSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get adminSettingsSave;

  /// No description provided for @adminSettingsApifyUsageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Custo do Facebook Marketplace (Apify)'**
  String get adminSettingsApifyUsageTitle;

  /// No description provided for @adminSettingsApifyUsageDescription.
  ///
  /// In pt, this message translates to:
  /// **'Últimas execuções e custo acumulado no ciclo atual, consultado ao vivo na conta Apify usada pelo scraper do Facebook Marketplace.'**
  String get adminSettingsApifyUsageDescription;

  /// No description provided for @adminSettingsApifyUsageTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total no período: US\$ {total}'**
  String adminSettingsApifyUsageTotal(String total);

  /// No description provided for @adminSettingsApifyUsageEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma execução registrada ainda.'**
  String get adminSettingsApifyUsageEmpty;

  /// No description provided for @adminSettingsApifyUsageError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar custo do Apify: {error}'**
  String adminSettingsApifyUsageError(String error);

  /// No description provided for @apifyRunStatusReady.
  ///
  /// In pt, this message translates to:
  /// **'Pronto'**
  String get apifyRunStatusReady;

  /// No description provided for @apifyRunStatusRunning.
  ///
  /// In pt, this message translates to:
  /// **'Em execução'**
  String get apifyRunStatusRunning;

  /// No description provided for @apifyRunStatusSucceeded.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get apifyRunStatusSucceeded;

  /// No description provided for @apifyRunStatusFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get apifyRunStatusFailed;

  /// No description provided for @apifyRunStatusAborting.
  ///
  /// In pt, this message translates to:
  /// **'Cancelando'**
  String get apifyRunStatusAborting;

  /// No description provided for @apifyRunStatusAborted.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get apifyRunStatusAborted;

  /// No description provided for @apifyRunStatusTimingOut.
  ///
  /// In pt, this message translates to:
  /// **'Expirando'**
  String get apifyRunStatusTimingOut;

  /// No description provided for @apifyRunStatusTimedOut.
  ///
  /// In pt, this message translates to:
  /// **'Expirou'**
  String get apifyRunStatusTimedOut;
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
