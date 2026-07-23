// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Achapramim';

  @override
  String get loginEmailOrUsernameLabel => 'E-mail ou username';

  @override
  String get loginEmailOrUsernameRequired => 'Informe o e-mail ou username';

  @override
  String get loginPasswordLabel => 'Senha';

  @override
  String get loginPasswordRequired => 'Informe a senha';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginInvalidCredentials => 'E-mail/username ou senha inválidos.';

  @override
  String get loginGenericError => 'Não foi possível conectar. Tente novamente.';

  @override
  String get setUsernameTitle => 'Escolha seu username';

  @override
  String get setUsernameDescription =>
      'Identificador único e permanente — não poderá ser alterado depois. Você poderá usá-lo para entrar, junto com seu e-mail.';

  @override
  String get setUsernameLabel => 'Username';

  @override
  String get setUsernameHelper =>
      'Minúsculas, números e underscore. 3 a 30 caracteres.';

  @override
  String get setUsernameValidationError =>
      'Use 3 a 30 letras minúsculas, números ou _';

  @override
  String get setUsernameConfirm => 'Confirmar';

  @override
  String get setUsernameTaken => 'Este username já está em uso. Escolha outro.';

  @override
  String get setUsernameGenericError =>
      'Não foi possível salvar. Tente novamente.';

  @override
  String get navMyWatches => 'Meus Watches';

  @override
  String get navNewWatch => 'Nova Consulta';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navLogout => 'Logout';

  @override
  String get navUserDashboard => 'Painel do Usuário';

  @override
  String get watchListTitle => 'Meus Watches';

  @override
  String get watchListEmpty => 'Nenhum Watch cadastrado ainda.';

  @override
  String get watchListCreateFirst => 'Criar o primeiro Watch';

  @override
  String watchListLoadError(String error) {
    return 'Falha ao carregar Watches: $error';
  }

  @override
  String watchTolerance(String percent) {
    return 'Tolerância $percent%';
  }

  @override
  String get newWatchTitle => 'Nova Consulta';

  @override
  String get newWatchFromLinkTitle => 'Criar a partir de Link';

  @override
  String get newWatchFromLinkDescription =>
      'Cole a URL de um anúncio para gerar uma Proposta de Preenchimento — sempre editável, nunca cria o Watch sozinha.';

  @override
  String get newWatchLinkHint => 'https://www.olx.com.br/...';

  @override
  String get newWatchAnalyze => 'Analisar';

  @override
  String get newWatchPartialFailure =>
      'A análise foi parcial — revise os campos preenchidos e complete o restante manualmente.';

  @override
  String get newWatchLinkAnalysisError =>
      'Não foi possível analisar o link agora. Preencha manualmente.';

  @override
  String get newWatchIdentification => 'Identificação do Watch';

  @override
  String get newWatchAiSuggested => 'Sugerido por IA';

  @override
  String get newWatchNameLabel => 'Nome do Watch';

  @override
  String get newWatchKeywords => 'Palavras-Chave';

  @override
  String get newWatchBlockedWords => 'Palavras Bloqueadas';

  @override
  String get newWatchAddWordHint => 'Adicionar...';

  @override
  String get newWatchActiveMarketplaces => 'Marketplaces Ativos';

  @override
  String get newWatchFinanceAndLimits => 'Financeiro e Limites';

  @override
  String get newWatchTargetPriceLabel => 'Preço-Alvo (BRL)';

  @override
  String get newWatchToleranceLabel => 'Tolerância (%)';

  @override
  String get newWatchDropThresholdLabel => 'Gatilho de Queda (%)';

  @override
  String get newWatchMaxOffersLabel => 'Máximo de Ofertas';

  @override
  String get newWatchValidationError =>
      'Preencha nome, preço-alvo e ao menos um marketplace.';

  @override
  String newWatchSaveError(String details) {
    return 'Falha ao salvar Watch: $details';
  }

  @override
  String get newWatchSubmit => 'Ativar Monitoramento';

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
    return 'Falha ao carregar Watch: $error';
  }

  @override
  String get watchDetailTabOffers => 'Offers';

  @override
  String get watchDetailTabScans => 'Histórico de Scans';

  @override
  String watchDetailTarget(String price) {
    return 'Alvo: $price';
  }

  @override
  String watchDetailTolerance(String percent) {
    return 'Tolerância: $percent%';
  }

  @override
  String watchDetailDropThreshold(String percent) {
    return 'Gatilho de queda: $percent%';
  }

  @override
  String watchDetailMaxOffers(int count) {
    return 'Máx. ofertas: $count';
  }

  @override
  String get watchDetailActive => 'Ativo';

  @override
  String get watchDetailInactive => 'Inativo';

  @override
  String watchDetailOffersLoadError(String error) {
    return 'Falha ao carregar Offers: $error';
  }

  @override
  String get watchDetailNoOffers => 'Nenhuma Offer encontrada ainda.';

  @override
  String get watchDetailOfferUnavailable => 'Indisponível';

  @override
  String get watchDetailOpenListing => 'Abrir anúncio';

  @override
  String watchDetailScansLoadError(String error) {
    return 'Falha ao carregar Scans: $error';
  }

  @override
  String get watchDetailNoScans => 'Nenhum Scan executado ainda.';

  @override
  String watchDetailScanFailures(String marketplaces) {
    return 'Falhas: $marketplaces';
  }

  @override
  String watchDetailOffersFound(int count) {
    return '$count ofertas';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String profileLoadError(String error) {
    return 'Falha ao carregar perfil: $error';
  }

  @override
  String get profileEmailLabel => 'E-mail';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileUsernameNotSet => 'Não definido';

  @override
  String get profileNameLabel => 'Nome';

  @override
  String get profileChangePasswordTitle => 'Trocar senha';

  @override
  String get profileCurrentPasswordLabel => 'Senha atual';

  @override
  String get profileNewPasswordLabel => 'Nova senha';

  @override
  String get profileConfirmNewPasswordLabel => 'Confirmar nova senha';

  @override
  String get profilePasswordMismatch => 'As senhas não coincidem';

  @override
  String get profilePasswordTooShort =>
      'A senha deve ter ao menos 6 caracteres';

  @override
  String get profileCurrentPasswordWrong => 'Senha atual incorreta.';

  @override
  String get profilePasswordChangeError =>
      'Não foi possível trocar a senha. Tente novamente.';

  @override
  String get profilePasswordChangeSuccess => 'Senha alterada com sucesso.';

  @override
  String get profileSaveChanges => 'Salvar';
}
