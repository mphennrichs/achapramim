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
  String get navMyWatches => 'Meus Alertas';

  @override
  String get navNewWatch => 'Novo Alerta';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navLogout => 'Sair';

  @override
  String get navUserDashboard => 'Painel do Usuário';

  @override
  String get watchListTitle => 'Meus Alertas';

  @override
  String get watchListEmpty => 'Nenhum Alerta cadastrado ainda.';

  @override
  String get watchListCreateFirst => 'Criar o primeiro Alerta';

  @override
  String watchListLoadError(String error) {
    return 'Falha ao carregar Alertas: $error';
  }

  @override
  String watchTolerance(String percent) {
    return 'Tolerância $percent%';
  }

  @override
  String get watchEditTooltip => 'Editar Alerta';

  @override
  String get watchDeleteTooltip => 'Excluir Alerta';

  @override
  String get watchDeleteConfirmTitle => 'Excluir Alerta?';

  @override
  String get watchDeleteConfirmMessage =>
      'Esta ação não pode ser desfeita. Todas as Offers e o histórico de Scans deste Alerta serão perdidos.';

  @override
  String get watchDeleteConfirmCancel => 'Cancelar';

  @override
  String get watchDeleteConfirmConfirm => 'Excluir';

  @override
  String watchDeleteError(String error) {
    return 'Falha ao excluir Alerta: $error';
  }

  @override
  String get newWatchTitle => 'Novo Alerta';

  @override
  String get newWatchFromLinkTitle => 'Criar a partir de Link';

  @override
  String get newWatchFromLinkDescription =>
      'Cole a URL de um anúncio para gerar uma Proposta de Preenchimento — sempre editável, nunca cria o Alerta sozinha.';

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
  String get newWatchIdentification => 'Identificação do Alerta';

  @override
  String get newWatchAiSuggested => 'Sugerido por IA';

  @override
  String get newWatchNameLabel => 'Nome do Alerta';

  @override
  String get newWatchRegionTitle => 'Região da Busca';

  @override
  String get newWatchCityLabel => 'Cidade';

  @override
  String get newWatchStateLabel => 'Estado (UF)';

  @override
  String get newWatchActiveMarketplaces => 'Marketplaces';

  @override
  String get marketplaceOlx => 'OLX';

  @override
  String get marketplaceFacebook => 'Facebook Marketplace';

  @override
  String get newWatchKeywords => 'Palavras-Chave';

  @override
  String get newWatchBlockedWords => 'Palavras Bloqueadas';

  @override
  String get newWatchAddWordHint => 'Adicionar...';

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
    return 'Falha ao salvar Alerta: $details';
  }

  @override
  String get newWatchSubmit => 'Ativar Monitoramento';

  @override
  String get editWatchTitle => 'Editar Alerta';

  @override
  String get editWatchSubmit => 'Salvar Alterações';

  @override
  String get watchDetailFallbackTitle => 'Alerta';

  @override
  String watchDetailLoadError(String error) {
    return 'Falha ao carregar Alerta: $error';
  }

  @override
  String get watchDetailTabOffers => 'Ofertas';

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
  String get watchDetailSortLabel => 'Ordenar por';

  @override
  String get watchDetailSortRecommended => 'Recomendados';

  @override
  String get watchDetailSortPriceAsc => 'Menor preço';

  @override
  String get watchDetailSortPriceDesc => 'Maior preço';

  @override
  String get watchDetailSortNewest => 'Mais recentes';

  @override
  String get watchDetailOfferUnavailable => 'Indisponível';

  @override
  String get watchDetailOpenListing => 'Abrir anúncio';

  @override
  String get watchDetailOpenListingError =>
      'Não foi possível abrir o anúncio. O link pode estar inválido.';

  @override
  String get watchDetailMonitorOffer => 'Monitorar esta oferta';

  @override
  String get watchDetailUnmonitorOffer => 'Parar de monitorar esta oferta';

  @override
  String watchDetailMonitorError(String error) {
    return 'Não foi possível atualizar o monitoramento: $error';
  }

  @override
  String get watchDetailPriceHistoryTooltip => 'Histórico de preço';

  @override
  String get watchDetailPriceHistoryTitle => 'Histórico de preço';

  @override
  String watchDetailPriceHistoryLoadError(String error) {
    return 'Falha ao carregar histórico de preço: $error';
  }

  @override
  String get watchDetailPriceHistoryEmpty =>
      'Ainda não há histórico de preço para esta oferta.';

  @override
  String get watchDetailPriceHistoryClose => 'Fechar';

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
  String get scanStatusSuccess => 'Sucesso';

  @override
  String get scanStatusPartial => 'Parcial';

  @override
  String get scanStatusFailed => 'Falhou';

  @override
  String get scanStatusPending => 'Pendente';

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
  String get profileThemeTitle => 'Tema';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Escuro';

  @override
  String get profileThemeSystem => 'Sistema';

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

  @override
  String get navAdminUsers => 'Usuários';

  @override
  String get navAdminAllWatches => 'Todos os Alertas';

  @override
  String get navAdminSettings => 'Configurações';

  @override
  String get adminUsersTitle => 'Usuários';

  @override
  String adminUsersLoadError(String error) {
    return 'Falha ao carregar usuários: $error';
  }

  @override
  String get adminUsersCreate => 'Novo usuário';

  @override
  String get adminUsersNameLabel => 'Nome';

  @override
  String get adminUsersEmailLabel => 'E-mail';

  @override
  String get adminUsersPasswordLabel => 'Senha inicial';

  @override
  String get adminUsersUsernameLabel => 'Username (opcional)';

  @override
  String get adminUsersUsernameHint =>
      'Deixe em branco para o usuário definir no Primeiro Acesso';

  @override
  String get adminUsersUsernameInvalid =>
      '3-30 caracteres: minúsculas, números ou _';

  @override
  String get adminUsersUsernameTaken => 'Username já em uso';

  @override
  String get adminUsersUsernameAvailable => 'Disponível';

  @override
  String get adminUsersUsernameChecking => 'Verificando...';

  @override
  String get adminUsersRoleLabel => 'Role';

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleUser => 'Usuário';

  @override
  String get adminUsersCreateSubmit => 'Cadastrar';

  @override
  String adminUsersCreateError(String details) {
    return 'Falha ao cadastrar usuário: $details';
  }

  @override
  String get adminUsersActive => 'Ativo';

  @override
  String get adminUsersInactive => 'Inativo';

  @override
  String get adminUsersUsernamePending => 'Username pendente';

  @override
  String get adminUsersUpdateError =>
      'Falha ao atualizar usuário. Tente novamente.';

  @override
  String get adminUsersCancel => 'Cancelar';

  @override
  String get adminUsersEditUsername => 'Editar username';

  @override
  String get adminUsersSetUsername => 'Definir username';

  @override
  String adminUsersUsernameDialogTitle(String name) {
    return 'Username de $name';
  }

  @override
  String get adminUsersUsernameSave => 'Salvar';

  @override
  String adminUsersUsernameSaveError(String details) {
    return 'Falha ao salvar username: $details';
  }

  @override
  String get adminWatchesTitle => 'Todos os Alertas';

  @override
  String adminWatchesLoadError(String error) {
    return 'Falha ao carregar Alertas: $error';
  }

  @override
  String get adminWatchesEmpty => 'Nenhum Alerta cadastrado no sistema ainda.';

  @override
  String adminWatchesOwnerLabel(String name, String email) {
    return 'Dono: $name ($email)';
  }

  @override
  String get adminSettingsTitle => 'Configurações';

  @override
  String adminSettingsLoadError(String error) {
    return 'Falha ao carregar configurações: $error';
  }

  @override
  String get adminSettingsScanTitle => 'Intervalo de Scan';

  @override
  String get adminSettingsScanDescription =>
      'Intervalo mínimo e máximo (em minutos) entre execuções de Scan de cada Alerta. O agendamento real de cada Alerta é sorteado dentro dessa faixa.';

  @override
  String get adminSettingsMinIntervalLabel => 'Intervalo mínimo (minutos)';

  @override
  String get adminSettingsMaxIntervalLabel => 'Intervalo máximo (minutos)';

  @override
  String get adminSettingsRegionTitle => 'Região Padrão de Busca';

  @override
  String get adminSettingsRegionDescription =>
      'Usada por um Alerta quando ele não define cidade/estado próprios.';

  @override
  String get adminSettingsDefaultCityLabel => 'Cidade padrão';

  @override
  String get adminSettingsDefaultStateLabel => 'Estado (UF)';

  @override
  String get adminSettingsBlockedWordsTitle => 'Palavras Bloqueadas Padrão';

  @override
  String get adminSettingsBlockedWordsDescription =>
      'Copiadas para todo Alerta novo na criação. Editar aqui não afeta Alertas já criados.';

  @override
  String get adminSettingsValidationError =>
      'Verifique o intervalo (máximo ≥ mínimo) e preencha cidade e estado padrão.';

  @override
  String get adminSettingsSaveError =>
      'Falha ao salvar configurações. Tente novamente.';

  @override
  String get adminSettingsSaveSuccess => 'Configurações salvas com sucesso.';

  @override
  String get adminSettingsSave => 'Salvar';

  @override
  String get adminSettingsApifyUsageTitle =>
      'Custo do Facebook Marketplace (Apify)';

  @override
  String get adminSettingsApifyUsageDescription =>
      'Últimas execuções e custo acumulado no ciclo atual, consultado ao vivo na conta Apify usada pelo scraper do Facebook Marketplace.';

  @override
  String adminSettingsApifyUsageTotal(String total) {
    return 'Total no período: US\$ $total';
  }

  @override
  String get adminSettingsApifyUsageEmpty =>
      'Nenhuma execução registrada ainda.';

  @override
  String adminSettingsApifyUsageError(String error) {
    return 'Falha ao carregar custo do Apify: $error';
  }

  @override
  String get apifyRunStatusReady => 'Pronto';

  @override
  String get apifyRunStatusRunning => 'Em execução';

  @override
  String get apifyRunStatusSucceeded => 'Concluído';

  @override
  String get apifyRunStatusFailed => 'Falhou';

  @override
  String get apifyRunStatusAborting => 'Cancelando';

  @override
  String get apifyRunStatusAborted => 'Cancelado';

  @override
  String get apifyRunStatusTimingOut => 'Expirando';

  @override
  String get apifyRunStatusTimedOut => 'Expirou';
}
