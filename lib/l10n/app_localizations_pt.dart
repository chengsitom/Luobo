// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'Bom dia';

  @override
  String get goodAfternoon => 'Boa tarde';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String get forYou => 'Para você';

  @override
  String get quickPicks => 'Escolhas Rápidas';

  @override
  String get discoverMix => 'Mix de Descobertas';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Reproduzidos Recentemente';

  @override
  String get yourPlaylists => 'Suas Playlists';

  @override
  String get roaming => 'Roaming';

  @override
  String get roamingSubtitle => 'Shuffle the whole library';

  @override
  String get quickStart => 'Quick Start';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get sectionAlbums => 'Albums';

  @override
  String get sectionEPs => 'EPs';

  @override
  String get sectionSingles => 'Singles';

  @override
  String get madeForYou => 'Feito para você';

  @override
  String get dailyRecommendation => 'Today\'s Picks';

  @override
  String get continueListening => 'Continue Listening';

  @override
  String get commuteMix => 'Commute Mix';

  @override
  String get studyMix => 'Study Mix';

  @override
  String get sleepMix => 'Sleep Mix';

  @override
  String get favoritesMix => 'Favorites Mix';

  @override
  String get discover => 'Discover';

  @override
  String get aiPlaylist => 'AI Playlist';

  @override
  String get aiPlaylistSubtitle => 'Describe what you want to hear';

  @override
  String get generating => 'Generating…';

  @override
  String get addToCurrentQueue => 'Add to Queue';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String songCount(int count) {
    return '$count Songs';
  }

  @override
  String get dailySubtitle => 'Updated daily';

  @override
  String get commuteSubtitle => 'High energy';

  @override
  String get studySubtitle => 'Stay focused';

  @override
  String get sleepSubtitle => 'Wind down';

  @override
  String get favoritesSubtitle => 'Your favorites';

  @override
  String get discoverSubtitle => 'Fresh to you';

  @override
  String get dailySlogan1 => 'Start today with a great song';

  @override
  String get dailySlogan2 => 'Something new every day';

  @override
  String get dailySlogan3 => 'What do you feel like today?';

  @override
  String get commuteSlogan1 => 'Power up your commute';

  @override
  String get commuteSlogan2 => 'Fuel up before you go';

  @override
  String get commuteSlogan3 => 'Make the ride your own rhythm';

  @override
  String get studySlogan1 => 'A quiet world, just you and the music';

  @override
  String get studySlogan2 => 'Stay focused, notes in flow';

  @override
  String get studySlogan3 => 'Let focus have its soundtrack';

  @override
  String get sleepSlogan1 => 'Make tonight\'s dreams a little softer';

  @override
  String get sleepSlogan2 => 'Take it slow, sleep well';

  @override
  String get sleepSlogan3 => 'A slow song for the night';

  @override
  String get favoritesSlogan1 => 'The ones you saved are the ones you love';

  @override
  String get favoritesSlogan2 => 'Your most-played, all here';

  @override
  String get favoritesSlogan3 => 'Every song you loved counts';

  @override
  String get discoverSlogan1 => 'The next one might be your new favorite';

  @override
  String get discoverSlogan2 => 'Wander somewhere you haven\'t been';

  @override
  String get discoverSlogan3 => 'Switch it up, hear something fresh';

  @override
  String get topRated => 'Melhor Avaliados';

  @override
  String get noContentAvailable => 'Sem conteúdo disponível';

  @override
  String get tryRefreshing =>
      'Tente atualizar ou verifique a conexão do servidor';

  @override
  String get refresh => 'Atualizar';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs => 'Erro ao carregar músicas';

  @override
  String get noSongsInGenre => 'Nenhuma música neste gênero';

  @override
  String get errorLoadingAlbums => 'Erro ao carregar álbuns';

  @override
  String get noTopRatedAlbums => 'Nenhum álbum avaliado';

  @override
  String get login => 'Iniciar Sessão';

  @override
  String get serverUrl => 'URL do Servidor';

  @override
  String get username => 'Nome de usuário';

  @override
  String get password => 'Senha';

  @override
  String get selectCertificate => 'Selecione o certificado TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Falha ao selecionar certificado: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'O URL do servidor deve começar com http:// ou https://';

  @override
  String get failedToConnect => 'Falha ao conectar';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Buscar';

  @override
  String get settings => 'Configurações';

  @override
  String get albums => 'Álbuns';

  @override
  String get artists => 'Artistas';

  @override
  String get songs => 'Músicas';

  @override
  String get playlists => 'Playlists';

  @override
  String get genres => 'Gêneros';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoritos';

  @override
  String get nowPlaying => 'Tocando Agora';

  @override
  String get queue => 'Fila';

  @override
  String get lyrics => 'Letras';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausar';

  @override
  String get next => 'Próximo';

  @override
  String get previous => 'Anterior';

  @override
  String get shuffle => 'Aleatório';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatOne => 'Repetir Faixa';

  @override
  String get repeatOff => 'Não Repetir';

  @override
  String get addToPlaylist => 'Adicionar à Playlist';

  @override
  String get removeFromPlaylist => 'Remover da Playlist';

  @override
  String get addToFavorites => 'Adicionar aos Favoritos';

  @override
  String get removeFromFavorites => 'Remover dos Favoritos';

  @override
  String get download => 'Baixar';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Salvar';

  @override
  String get close => 'Fechar';

  @override
  String get general => 'Geral';

  @override
  String get appearance => 'Aparência';

  @override
  String get playback => 'Reprodução';

  @override
  String get storage => 'Armazenamento';

  @override
  String get about => 'Sobre';

  @override
  String get darkMode => 'Modo Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get version => 'Versão';

  @override
  String get githubRepository => 'Repositório no GitHub';

  @override
  String get reportIssue => 'Reportar Problema';

  @override
  String get unknownArtist => 'Artista Desconhecido';

  @override
  String get unknownAlbum => 'Álbum Desconhecido';

  @override
  String get playAll => 'Reproduzir Tudo';

  @override
  String get shuffleAll => 'Reproduzir em Aleatório';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Álbum';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByDuration => 'Duração';

  @override
  String get ascending => 'Crescente';

  @override
  String get descending => 'Decrescente';

  @override
  String get noLyricsAvailable => 'Sem letras disponíveis';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get searchHint => 'Buscar músicas, álbuns, artistas...';

  @override
  String get allSongs => 'Todas as músicas';

  @override
  String get allAlbums => 'Todos os Álbuns';

  @override
  String get allArtists => 'Todos os Artistas';

  @override
  String trackNumber(int number) {
    return 'Faixa $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count músicas',
      one: '1 música',
      zero: 'Sem músicas',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbuns',
      one: '1 álbum',
      zero: 'Sem álbuns',
    );
    return '$_temp0';
  }

  @override
  String get topArtistsTitle => 'Top artists';

  @override
  String playsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
      zero: 'No plays',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Encerrar Sessão';

  @override
  String get confirmLogout => 'Tem certeza que deseja encerrar a sessão?';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get offlineMode => 'Modo Offline';

  @override
  String get radio => 'Rádio';

  @override
  String get audiobooks => 'Audiobooks';

  @override
  String playedTo(String position) {
    return 'Played to $position';
  }

  @override
  String get finished => 'Finished';

  @override
  String chapterCount(int count) {
    return '$count Chapters';
  }

  @override
  String chapterX(int count) {
    return 'Chapter $count';
  }

  @override
  String get failedToLoadAudiobooks => 'Failed to load audiobooks';

  @override
  String get failedToLoadChapters => 'Failed to load chapters, please retry';

  @override
  String get exitAudiobookFirst => 'Please exit the audiobook first';

  @override
  String get jumpToChapter => 'Jump to chapter';

  @override
  String get searchChapters => 'Search chapters';

  @override
  String get noSearchResults => 'No matching chapters';

  @override
  String get changelog => 'Changelog';

  @override
  String get platform => 'Plataforma';

  @override
  String get server => 'Servidor';

  @override
  String get display => 'Personalização';

  @override
  String get playerInterface => 'Interface do Player';

  @override
  String get smartRecommendations => 'Recomendações Inteligentes';

  @override
  String get showVolumeSlider => 'Mostrar Controle de Volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Exibir controle de volume na tela Tocando Agora';

  @override
  String get showStarRatings => 'Mostrar Avaliações';

  @override
  String get showStarRatingsSubtitle => 'Avaliar músicas e ver avaliações';

  @override
  String get showMiniPlayerHeart => 'Show Heart Button';

  @override
  String get showMiniPlayerHeartSubtitle => 'Add to favorites from mini player';

  @override
  String get showMiniPlayerRepeat => 'Show Repeat Button';

  @override
  String get showMiniPlayerRepeatSubtitle =>
      'Toggle repeat mode from mini player';

  @override
  String get showMiniPlayerShuffle => 'Show Shuffle Button';

  @override
  String get showMiniPlayerShuffleSubtitle => 'Toggle shuffle from mini player';

  @override
  String get enableRecommendations => 'Habilitar Recomendações';

  @override
  String get enableRecommendationsSubtitle =>
      'Obter sugestões de músicas personalizadas';

  @override
  String get listeningData => 'Dados de Reprodução';

  @override
  String totalPlays(int count) {
    return 'Total de $count reproduções';
  }

  @override
  String get clearListeningHistory => 'Limpar Histórico de Reprodução';

  @override
  String get confirmClearHistory =>
      'Isso redefinirá todos os seus dados de reprodução e recomendações. Deseja continuar?';

  @override
  String get historyCleared => 'Histórico de reprodução limpo';

  @override
  String get discordStatus => 'Status do Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostrar música em reprodução no perfil do Discord';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get systemDefault => 'Padrão do Sistema';

  @override
  String get yourLibrary => 'Sua Biblioteca';

  @override
  String get filterAll => 'Tudo';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterAlbums => 'Álbuns';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get likedSongs => 'Músicas favoritas';

  @override
  String get localMusicLibrary => 'Local Music Library';

  @override
  String get mergeLocalLibrary => 'Merge with Server Library';

  @override
  String get mergeLocalLibrarySubtitle =>
      'Show local music alongside your server library';

  @override
  String get localMusicStats => 'Local Music Files';

  @override
  String get addMusicFolder => 'Add Music Folder';

  @override
  String get rescanLocalMusic => 'Rescan Local Music';

  @override
  String get localLibraryEmpty => 'Your library is empty';

  @override
  String get localLibraryEmptySubtitle =>
      'No local music files were found. Tap the button below to scan again.';

  @override
  String get libraryEmpty => 'Your library is empty';

  @override
  String get libraryEmptySubtitle => 'Add some songs to get started.';

  @override
  String get scanForMusic => 'Scan for Music';

  @override
  String get radioStations => 'Estações de rádio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Rádio Online';

  @override
  String get newPlaylist => 'Nova Playlist';

  @override
  String get playlistName => 'Nome da Playlist';

  @override
  String get create => 'Criar';

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Tem certeza de que deseja excluir a playlist \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" excluída';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Erro ao criar playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Erro ao excluir playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" criada';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchPlaceholder => 'Artistas, músicas e álbuns';

  @override
  String get tryDifferentSearch => 'Tente uma busca diferente';

  @override
  String get noSuggestions => 'Sem sugestões';

  @override
  String get browseCategories => 'Navegar categorias';

  @override
  String get liveSearchSection => 'Busca';

  @override
  String get liveSearch => 'Busca em tempo real';

  @override
  String get liveSearchSubtitle =>
      'Atualizar resultados enquanto digita em vez de mostrar um menu suspenso';

  @override
  String get categoryMadeForYou => 'Feito para você';

  @override
  String get categoryNewReleases => 'Novos lançamentos';

  @override
  String get categoryTopRated => 'Melhor Avaliados';

  @override
  String get categoryGenres => 'Gêneros';

  @override
  String get categoryFavorites => 'Favoritos';

  @override
  String get categoryRadio => 'Rádio';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get tabPlayback => 'Reprodução';

  @override
  String get tabStorage => 'Armazenamento';

  @override
  String get tabServer => 'Servidor';

  @override
  String get tabDisplay => 'Personalização';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Sobre';

  @override
  String get tabDiagnostics => 'Diagnostics';

  @override
  String get settingsGroupServer => 'Server & Account';

  @override
  String get settingsServerSettings => 'Server Settings';

  @override
  String get serverManagement => 'Server Management';

  @override
  String get noSavedProfiles => 'No saved server configurations yet';

  @override
  String get connectedSuccessfully => 'Connected successfully';

  @override
  String get settingsGroupPlayback => 'Playback & Quality';

  @override
  String get settingsPlaybackSettings => 'Playback Settings';

  @override
  String get settingsStreamingEntry => 'Streaming Quality';

  @override
  String get settingsGroupStorage => 'Download & Storage';

  @override
  String get settingsStorageEntry => 'Download & Storage';

  @override
  String get settingsGroupDisplay => 'Display & Appearance';

  @override
  String get settingsDisplayEntry => 'Player Interface';

  @override
  String get settingsGroupAbout => 'About Luobo';

  @override
  String get settingsGroupAi => 'AI';

  @override
  String get settingsAiEntry => 'AI Playlists & Knowledge';

  @override
  String get settingsGroupSupport => 'Support & Help';

  @override
  String get settingsMechanicsEntry => 'How It Works';

  @override
  String get mechanicsGroupRecommendation => 'Home Recommendations';

  @override
  String get mechanicsGroupListeningReport => 'Listening Report';

  @override
  String get mechanicsGroupStorage => 'Download & Storage';

  @override
  String get mechanicsGroupAi => 'AI';

  @override
  String get mechanicsGroupAudio => 'Audio';

  @override
  String get mechanicsGroupConnectivity => 'Connect & Cast';

  @override
  String get mechanicsGroupDiagnostics => 'Diagnostics & Privacy';

  @override
  String get mechanicsTechDetails => 'Technical Details';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsSearchHint => 'Search event type / content';

  @override
  String get diagnosticsNoLogs => 'No logs yet';

  @override
  String diagnosticsExported(Object path) {
    return 'Logs exported: $path';
  }

  @override
  String get diagnosticsExportFailed => 'Export failed, check storage space';

  @override
  String get diagnosticsCopied => 'Logs copied to clipboard (latest 2000)';

  @override
  String get diagnosticsClearTitle => 'Clear diagnostics logs';

  @override
  String get diagnosticsClearMessage =>
      'This will permanently delete all local diagnostics logs and metrics. Export first if needed.';

  @override
  String get diagnosticsClearAction => 'Clear';

  @override
  String get diagnosticsMetricFps => 'FPS';

  @override
  String get diagnosticsMetricJankRate => 'jank rate';

  @override
  String get diagnosticsMetricRequests => 'requests';

  @override
  String get diagnosticsMetricNetP90 => 'net p90';

  @override
  String get diagnosticsMetricErrorRate => 'error rate';

  @override
  String get diagnosticsAll => 'All';

  @override
  String get diagnosticsLevelDebug => 'debug';

  @override
  String get diagnosticsLevelInfo => 'info';

  @override
  String get diagnosticsLevelWarn => 'warn';

  @override
  String get diagnosticsLevelError => 'error';

  @override
  String get diagnosticsTooltipCopy => 'Copy to clipboard';

  @override
  String get diagnosticsTooltipExport => 'Export to file';

  @override
  String get diagnosticsTooltipClear => 'Clear';

  @override
  String renderError(Object err) {
    return 'Render error\n$err';
  }

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Modo Auto DJ';

  @override
  String get autoDjModeOff => 'Off';

  @override
  String get autoDjModeShuffleLibrary => 'Shuffle Library';

  @override
  String get autoDjModeSimilarSongs => 'Similar Songs';

  @override
  String get autoDjModeSameGenre => 'Same Genre';

  @override
  String get autoDjModeSameArtist => 'Same Artist';

  @override
  String get autoDjModeSmartMix => 'Smart Mix';

  @override
  String songsToAdd(int count) {
    return 'Músicas a adicionar: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZAÇÃO DE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modo';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Prevenir Clipping';

  @override
  String fallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALIDADE DE STREAMING';

  @override
  String get enableTranscoding => 'Ativar a transcodificação';

  @override
  String get qualityWifi => 'Qualidade em WiFi';

  @override
  String get qualityMobile => 'Qualidade em Dados Móveis';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle => 'Reduzir uso de dados com menor qualidade';

  @override
  String get modeOff => 'Desligado';

  @override
  String get modeTrack => 'Faixa';

  @override
  String get modeAlbum => 'Álbum';

  @override
  String get sectionServerConnection => 'CONEXÃO DO SERVIDOR';

  @override
  String get serverType => 'Tipo de Servidor';

  @override
  String get notConnected => 'Não conectado';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get sectionMusicFolders => 'PASTAS DE MÚSICA';

  @override
  String get musicFolders => 'Pastas de música';

  @override
  String get noMusicFolders => 'Nenhuma pasta de música encontrada';

  @override
  String get sectionSavedProfiles => 'SAVED PROFILES';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get switchServer => 'Switch Server';

  @override
  String get addProfile => 'Add Profile';

  @override
  String get shareQrCode => 'Share via QR Code';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get qrCodeTitle => 'Server QR Code';

  @override
  String get qrCodeSubtitle => 'Scan this code to add server configuration';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get savedToGallery => 'QR code saved to gallery';

  @override
  String get failedToSaveQr => 'Failed to save QR code';

  @override
  String get scanFromCamera => 'Camera';

  @override
  String get scanFromGallery => 'Gallery';

  @override
  String get invalidQrCode =>
      'Invalid QR code. Not a valid server configuration.';

  @override
  String get qrConfigImported => 'Server configuration imported successfully';

  @override
  String switchProfileConfirmation(String profile) {
    return 'Connect to \"$profile\"?';
  }

  @override
  String get sectionAccount => 'CONTA';

  @override
  String get logoutConfirmation =>
      'Tem certeza que deseja encerrar a sessão? Isso também limpará todos os dados em cache.';

  @override
  String get sectionCacheSettings => 'CONFIGURAÇÕES DE CACHE';

  @override
  String get imageCache => 'Cache de Imagem';

  @override
  String get musicCache => 'Cache de Música';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Salvar capas de álbuns localmente';

  @override
  String get saveSongMetadata => 'Salvar metadados da música localmente';

  @override
  String get saveBpmAnalysis => 'Salvar análise de BPM localmente';

  @override
  String get sectionCacheCleanup => 'LIMPEZA DE CACHE';

  @override
  String get clearAllCache => 'Limpar todo o cache';

  @override
  String get allCacheCleared => 'Todo o cache limpo';

  @override
  String get sectionOfflineDownloads => 'DOWNLOADS OFFLINE';

  @override
  String get downloadedSongs => 'Músicas Baixadas';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Baixando Biblioteca... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Baixar Toda a Biblioteca';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Isso baixará $count músicas para o seu dispositivo. Isso pode levar um tempo e usar espaço significativo de armazenamento.\n\nContinuar?';
  }

  @override
  String get keepScreenOnDuringDownload => 'Keep Screen On';

  @override
  String get keepScreenOnDuringDownloadSubtitle =>
      'Prevents download from failing when device locks';

  @override
  String get parallelDownloads => 'Parallel Downloads';

  @override
  String get parallelDownloadsSubtitle =>
      'Download multiple songs simultaneously';

  @override
  String get downloadSingular => 'download';

  @override
  String get downloadPlural => 'downloads';

  @override
  String get slowerButStable => 'Slower but more stable';

  @override
  String get fasterButMoreData => 'Faster but uses more data';

  @override
  String get libraryDownloadStarted => 'Download da biblioteca iniciado';

  @override
  String get deleteDownloads => 'Excluir Todos os Downloads';

  @override
  String get downloadsDeleted => 'Todos os downloads excluídos';

  @override
  String get noSongsAvailable =>
      'Nenhuma música disponível. Carregue sua biblioteca primeiro.';

  @override
  String get sectionBpmAnalysis => 'ANÁLISE BPM';

  @override
  String get cachedBpms => 'BPMs em Cache';

  @override
  String get cacheAllBpms => 'Cachear Todos os BPMs';

  @override
  String get clearBpmCache => 'Limpar Cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM limpo';

  @override
  String downloadedStats(int count, String size) {
    return '$count músicas • $size';
  }

  @override
  String get sectionInformation => 'INFORMAÇÕES';

  @override
  String get sectionDeveloper => 'DESENVOLVEDOR';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'Repositório no GitHub';

  @override
  String get playingFrom => 'REPRODUZINDO DE';

  @override
  String get live => 'AO VIVO';

  @override
  String get streamingLive => 'Transmissão Ao Vivo';

  @override
  String get stopRadio => 'Parar Rádio';

  @override
  String get removeFromLiked => 'Remover das Músicas Favoritas';

  @override
  String get addToLiked => 'Adicionar às Músicas Favoritas';

  @override
  String get playNext => 'Tocar em Seguida';

  @override
  String get addToQueue => 'Adicionar à Fila';

  @override
  String get goToAlbum => 'Ir para o Álbum';

  @override
  String get goToArtist => 'Ir para o Artista';

  @override
  String get rateSong => 'Avaliar Música';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Avaliar Música ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Avaliação removida';

  @override
  String rated(int rating, String stars) {
    return 'Avaliado com $rating $stars';
  }

  @override
  String get removeRating => 'Remover avaliação';

  @override
  String get downloaded => 'Baixado';

  @override
  String downloading(int percent) {
    return 'Baixando... $percent%';
  }

  @override
  String get removeDownload => 'Remover Download';

  @override
  String get removeDownloadConfirm =>
      'Remover esta música do armazenamento offline?';

  @override
  String get downloadRemoved => 'Download removido';

  @override
  String downloadedTitle(String title) {
    return '\"$title\" baixado';
  }

  @override
  String get downloadFailed => 'Falha no download';

  @override
  String downloadError(Object error) {
    return 'Erro no download: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Adicionado \"$title\" a $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Erro ao adicionar à playlist: $error';
  }

  @override
  String get noPlaylists => 'Sem playlists disponíveis';

  @override
  String get createNewPlaylist => 'Criar Nova Playlist';

  @override
  String artistNotFound(String name) {
    return 'O artista \"$name\" não foi encontrado';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Erro ao buscar artista: $error';
  }

  @override
  String get selectArtist => 'Selecionar Artista';

  @override
  String get removedFromFavorites => 'Removido dos favoritos';

  @override
  String get addedToFavorites => 'Adicionado aos favoritos';

  @override
  String get star => 'estrela';

  @override
  String get stars => 'estrelas';

  @override
  String get albumNotFound => 'Álbum não encontrado';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours H $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Mais Ouvidas';

  @override
  String get connected => 'Conectado';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'Nenhuma música em reprodução';

  @override
  String get internetRadioUppercase => 'RÁDIO ONLINE';

  @override
  String get playingNext => 'A seguir';

  @override
  String get createPlaylistTitle => 'Criar Playlist';

  @override
  String get playlistNameHint => 'Nome da Playlist';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist criada \"$name\" com esta música';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Erro ao carregar playlists: $error';
  }

  @override
  String get playlistNotFound => 'Playlist não foi encontrada';

  @override
  String get noSongsInPlaylist => 'Não há músicas nesta playlist';

  @override
  String get noFavoriteSongsYet => 'Nenhuma música favorita ainda';

  @override
  String get noFavoriteAlbumsYet => 'Nenhum álbum favorito ainda';

  @override
  String get listeningHistory => 'Histórico de Reprodução';

  @override
  String get noListeningHistory => 'Nenhum histórico de reprodução';

  @override
  String get songsWillAppearHere =>
      'As músicas que você reproduzir aparecerão aqui';

  @override
  String get sortByArtistAZ => 'Artista (A-Z)';

  @override
  String get sortByArtistZA => 'Artista (Z-A)';

  @override
  String get sortByAlbumAZ => 'Álbum (A-Z)';

  @override
  String get sortByAlbumZA => 'Álbum (Z-A)';

  @override
  String get recentlyAdded => 'Adicionado Recentemente';

  @override
  String get noSongsFound => 'Nenhuma música foi encontrada';

  @override
  String get noAlbumsFound => 'Nenhum álbum foi encontrado';

  @override
  String get noHomepageUrl => 'Nenhuma URL de página inicial disponível';

  @override
  String get playStation => 'Reproduzir estação';

  @override
  String get openHomepage => 'Abrir Página Inicial';

  @override
  String get copyStreamUrl => 'Copiar URL da Transmissão';

  @override
  String get failedToLoadRadioStations => 'Falha ao carregar estações de rádio';

  @override
  String get noRadioStations => 'Nenhuma estação de rádio';

  @override
  String get noRadioStationsHint =>
      'Adicione estações de rádio nas configurações do seu servidor Navidrome para vê-las aqui.';

  @override
  String get connectToServerSubtitle => 'Conecte-se ao seu servidor Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Por favor, insira o URL do servidor';

  @override
  String get invalidUrlFormat => 'O URL deve começar com http:// ou https://';

  @override
  String get pleaseEnterUsername => 'Por favor, insira o nome de usuário';

  @override
  String get pleaseEnterPassword => 'Por favor, insira a senha';

  @override
  String get legacyAuthentication => 'Autenticação Legada';

  @override
  String get legacyAuthSubtitle => 'Usado para antigos servidores Subsonic';

  @override
  String get allowSelfSignedCerts => 'Permitir Certificados Auto-Assinados';

  @override
  String get allowSelfSignedSubtitle =>
      'Para servidores com certificados TLS/SSL personalizados';

  @override
  String get advancedOptions => 'Opções Avançadas';

  @override
  String get customTlsCertificate => 'Certificado TLS/SSL personalizado';

  @override
  String get customCertificateSubtitle =>
      'Enviar certificado personalizado para servidores com CA não padrão';

  @override
  String get selectCertificateFile => 'Selecione o arquivo de certificado';

  @override
  String get clientCertificate => 'Certificado de Cliente (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticar este cliente usando um certificado (requer servidor com mTLS ativado)';

  @override
  String get selectClientCertificate => 'Selecione o certificado do cliente';

  @override
  String get clientCertPassword => 'Senha do certificado (opcional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Falha ao selecionar certificado do cliente: $error';
  }

  @override
  String get connect => 'Conectar';

  @override
  String get lanUrl => 'LAN URL (optional)';

  @override
  String get lanUrlHint => 'http://192.168.x.x:4533';

  @override
  String get serverUrlHint => 'https://your-server.com';

  @override
  String get usernameHint => 'e.g. admin';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get profileNameLabel => 'Profile Name (optional)';

  @override
  String get profileNameHint => 'e.g. Home, Work, VPN';

  @override
  String get or => 'OU';

  @override
  String get privacyFirst => 'Privacy First';

  @override
  String get privacySubtitle => 'Your data stays with you. Always.';

  @override
  String get noDataSelling => 'No Data Selling';

  @override
  String get noDataSellingDesc =>
      'We never sell, share, or transfer your personal data to third parties.';

  @override
  String get localFirstStorage => 'Local-First Storage';

  @override
  String get localFirstStorageDesc =>
      'Your music library and credentials stay on your device.';

  @override
  String get anonymousAnalytics => 'Anonymous Analytics';

  @override
  String get anonymousAnalyticsDesc =>
      'With your consent, we collect only anonymous crash reports and usage stats. No personal identifiers.';

  @override
  String get readFullPrivacyPolicy => 'Read Full Privacy Policy';

  @override
  String get viewCompleteDetails => 'View complete details on our website';

  @override
  String get agreeAndContinue => 'I Understand & Continue';

  @override
  String get declineAndExit => 'Decline & Exit';

  @override
  String get useLocalFiles => 'Usar Arquivos Locais';

  @override
  String get startingScan => 'Iniciando scan...';

  @override
  String get storagePermissionRequired =>
      'Permissão de armazenamento necessária para o scan dos arquivos locais';

  @override
  String get noMusicFilesFound =>
      'Nenhum arquivo de música foi encontrado no seu dispositivo';

  @override
  String get remove => 'Excluir';

  @override
  String failedToSetRating(Object error) {
    return 'Falha ao definir avaliação: $error';
  }

  @override
  String get home => 'Início';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Recolher';

  @override
  String get expand => 'Expandir';

  @override
  String get createPlaylist => 'Criar Playlist';

  @override
  String get likedSongsSidebar => 'Músicas favoritas';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count músicas';
  }

  @override
  String get failedToLoadLyrics => 'Falha ao carregar as letras';

  @override
  String get lyricsNotFoundSubtitle =>
      'Não foi possível encontrar as letras desta música';

  @override
  String get backToCurrent => 'Voltar para a atual';

  @override
  String get exitFullscreen => 'Sair da Tela Cheia';

  @override
  String get fullscreen => 'Tela cheia';

  @override
  String get noLyrics => 'Sem letras';

  @override
  String get internetRadioMiniPlayer => 'Rádio Online';

  @override
  String get liveBadge => 'AO VIVO';

  @override
  String get localFilesModeBanner => 'Modo Arquivos Locais';

  @override
  String get offlineModeBanner =>
      'Modo Offline – Reproduzindo apenas músicas baixadas';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get updateAvailableSubtitle =>
      'Uma nova versão do Luobo está disponível!';

  @override
  String updateCurrentVersion(String version) {
    return 'Atual: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Mais recente: v$version';
  }

  @override
  String get whatsNew => 'Novidades';

  @override
  String get downloadUpdate => 'Baixar';

  @override
  String get remindLater => 'Mais tarde';

  @override
  String get seeAll => 'Ver Todos';

  @override
  String get artistDataNotFound => 'Artista não foi encontrado';

  @override
  String get addedArtistToQueue => 'Adicionado artista à fila';

  @override
  String get addedArtistToQueueError => 'Falha ao adicionar artista à fila';

  @override
  String get casting => 'Transmitindo';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Transmitir / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Encerrar sessão';

  @override
  String get searchingDevices => 'Buscando dispositivos';

  @override
  String get castWifiHint =>
      'Certifique-se de que seu dispositivo Cast / DLNA esteja na mesma rede WiFi';

  @override
  String connectedToDevice(String name) {
    return 'Conectado a $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Falha ao conectar a $name';
  }

  @override
  String get removedFromLikedSongs => 'Removido das Músicas Favoritas';

  @override
  String get addedToLikedSongs => 'Adicionado às Músicas Favoritas';

  @override
  String get enableShuffle => 'Ativar aleatório';

  @override
  String get enableRepeat => 'Ativar repetição';

  @override
  String get closeLyrics => 'Fechar Letras';

  @override
  String errorStartingDownload(Object error) {
    return 'Erro ao iniciar download: $error';
  }

  @override
  String get errorLoadingGenres => 'Erro ao carregar gêneros';

  @override
  String get noGenresFound => 'Nenhum gênero foi encontrado';

  @override
  String get noAlbumsInGenre => 'Nenhum álbum neste gênero';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount músicas • $albumCount álbuns';
  }

  @override
  String get musicFoldersDialogTitle => 'Selecionar pastas de música';

  @override
  String get musicFoldersHint =>
      'Deixe todas ativadas para usar todas as pastas (padrão).';

  @override
  String get musicFoldersSaved => 'Seleção de pastas de música salva';

  @override
  String get artworkStyleSection => 'Estilo da Capa';

  @override
  String get artworkCornerRadius => 'Arredondamento dos Cantos';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Ajustar o nível de arredondamento dos cantos das capas de álbum';

  @override
  String get artworkCornerRadiusNone => 'Nenhum';

  @override
  String get artworkShape => 'Forma';

  @override
  String get artworkShapeRounded => 'Arredondado';

  @override
  String get artworkShapeCircle => 'Círculo';

  @override
  String get artworkShapeSquare => 'Quadrado';

  @override
  String get artworkShadow => 'Sombra';

  @override
  String get artworkShadowNone => 'Nenhum';

  @override
  String get artworkShadowSoft => 'Suave';

  @override
  String get artworkShadowMedium => 'Média';

  @override
  String get artworkShadowStrong => 'Forte';

  @override
  String get artworkShadowColor => 'Cor da Sombra';

  @override
  String get artworkShadowColorBlack => 'Preto';

  @override
  String get artworkShadowColorAccent => 'Destaque';

  @override
  String get artworkPreview => 'Prévia';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Sem Capa';

  @override
  String get serverUnreachableTitle => 'Não foi possível conectar ao servidor';

  @override
  String get serverUnreachableSubtitle =>
      'Verifique sua conexão ou as configurações do servidor.';

  @override
  String get openOfflineMode => 'Abrir no modo offline';

  @override
  String get appearanceSection => 'Aparência';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Cor de destaque';

  @override
  String get circularDesignLabel => 'Design circular';

  @override
  String get circularDesignSubtitle =>
      'Interface flutuante e arredondada com painéis translúcidos e efeito de desfoque de vidro no player e na barra de navegação.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get clearAppCache => 'Clear App Cache';

  @override
  String get appearanceGlassHint =>
      'Glass and card styling is defined by the design system and is not user-adjustable.';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get liveLabel => 'AO VIVO';

  @override
  String get discordStatusText => 'Texto de status do Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Segunda linha exibida na atividade do Discord';

  @override
  String get discordRpcStyleArtist => 'Nome do artista';

  @override
  String get discordRpcStyleSong => 'Título da música';

  @override
  String get discordRpcStyleApp => 'Nome do aplicativo (Luobo)';

  @override
  String get sectionVolumeNormalization =>
      'NORMALIZAÇÃO DE VOLUME (REPLAYGAIN)';

  @override
  String get sectionFadeInOut => 'FADE IN/OUT';

  @override
  String get fadeInOutEnable => 'Enable Fade In/Out';

  @override
  String get fadeInOutSubtitle => 'Smoothly fade audio when playing or pausing';

  @override
  String fadeDuration(int duration) {
    return 'Fade Duration: ${duration}ms';
  }

  @override
  String get replayGainModeOff => 'Desligado';

  @override
  String get replayGainModeTrack => 'Faixa';

  @override
  String get replayGainModeAlbum => 'Álbum';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Prevenir Clipping';

  @override
  String replayGainFallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Músicas a adicionar: $count';
  }

  @override
  String get transcodingEnable => 'Ativar a transcodificação';

  @override
  String get transcodingEnableSubtitle =>
      'Reduzir uso de dados com menor qualidade';

  @override
  String get smartTranscoding => 'Transcodificação Inteligente';

  @override
  String get smartTranscodingSubtitle =>
      'Ajusta automaticamente a qualidade com base na sua conexão (WiFi ou dados móveis)';

  @override
  String get smartTranscodingDetectedNetwork => 'Rede detectada: ';

  @override
  String get smartTranscodingHelpTitle => 'Smart Transcoding';

  @override
  String get smartTranscodingHelpBody =>
      'When on, the bitrate follows your network automatically:\n• Wi-Fi → Wi-Fi quality bitrate\n• Cellular → Mobile quality bitrate\nThe bitrate switches automatically when your network changes.';

  @override
  String get transcodingManualBitrate => 'Transcode Bitrate';

  @override
  String get transcodingManualBitrateSubtitle =>
      'Fixed bitrate used when smart transcoding is off';

  @override
  String get transcodingWifiQuality => 'Qualidade em WiFi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Usado automaticamente no WiFi';

  @override
  String get transcodingMobileQuality => 'Qualidade em Dados Móveis';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Usado automaticamente em dados móveis';

  @override
  String get transcodingFormat => 'Formato';

  @override
  String get transcodingFormatSubtitle => 'Codec de áudio usado para streaming';

  @override
  String get transcodingBitrateOriginal => 'Original (Sem transcodificação)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Cache de Imagem';

  @override
  String get imageCacheSubtitle => 'Salvar capas de álbuns localmente';

  @override
  String get musicCacheTitle => 'Cache de Música';

  @override
  String get musicCacheSubtitle => 'Salvar metadados da música localmente';

  @override
  String get bpmCacheTitle => 'Cache BPM';

  @override
  String get bpmCacheSubtitle => 'Salvar análise de BPM localmente';

  @override
  String get sectionAboutInformation => 'INFORMAÇÕES';

  @override
  String get sectionAboutDeveloper => 'DESENVOLVEDOR';

  @override
  String get sectionAboutLinks => 'LINKS';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutPlatform => 'Plataforma';

  @override
  String get aboutMadeBy => 'Feito por chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'Repositório no GitHub';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Reportar Problema';

  @override
  String get sectionAnalyticsPrivacy => 'Analytics & Privacy';

  @override
  String get deviceId => 'Device ID';

  @override
  String deviceIdAnonymous(String id) {
    return 'Anonymous ID: $id';
  }

  @override
  String get deviceIdDisabled =>
      'Enable analytics to see your anonymous device ID';

  @override
  String get aboutDeviceId => 'About Device ID';

  @override
  String get aboutDeviceIdSubtitle =>
      'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get normalSpeed => 'Normal (1×)';

  @override
  String get preservePitch => 'Preserve pitch';

  @override
  String get preservePitchSubtitle => 'Keep original pitch when changing speed';

  @override
  String get pitch => 'Pitch';

  @override
  String get pitchPreserved => 'pitch preserved';

  @override
  String speedTooltipWithPitch(String speed, String pitch) {
    return 'Speed $speed · pitch $pitch×';
  }

  @override
  String speedTooltipPitchPreserved(String speed) {
    return 'Speed $speed · pitch preserved';
  }

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get sleepTimerActive => 'Sleep timer active';

  @override
  String get fadeOut => 'Fade out';

  @override
  String fadeOutSubtitle(int seconds) {
    return 'Gradually lower volume in the last $seconds s';
  }

  @override
  String get finishCurrentSong => 'Finish current song';

  @override
  String get finishCurrentSongSubtitle => 'Stop after the current track ends';

  @override
  String sleepTimerMinutes(int count) {
    return '$count min';
  }

  @override
  String sleepTimerHours(int count) {
    return '$count hour';
  }

  @override
  String sleepTimerSetFor(String duration) {
    return 'Sleep timer set for $duration';
  }

  @override
  String get customDuration => 'Custom duration…';

  @override
  String get cancelTimer => 'Cancel timer';

  @override
  String get customSleepTimer => 'Custom Sleep Timer';

  @override
  String get set => 'Set';

  @override
  String get addToPlaylistTitle => 'Add to Playlist';

  @override
  String get yourPlaylistsLabel => 'Your Playlists';

  @override
  String get enableLrcLibFallback => 'Fetch lyrics from LRCLIB';

  @override
  String get lrcLibFallbackSubtitle =>
      'Automatically search LRCLIB for lyrics when your server does not provide them';

  @override
  String get themeSaved => 'Theme saved';

  @override
  String get themeUnsavedChanges => 'Unsaved changes';

  @override
  String get themeUnsavedChangesTitle => 'Unsaved Changes';

  @override
  String get themeUnsavedChangesBody =>
      'You have unsaved changes. Do you want to save before leaving?';

  @override
  String get discard => 'Discard';

  @override
  String get done => 'Done';

  @override
  String pickColor(String label) {
    return 'Pick $label';
  }

  @override
  String get titleStyle => 'Title Style';

  @override
  String get artistStyle => 'Artist Style';

  @override
  String get themeActive => 'ACTIVE';

  @override
  String get themeSafeMode => 'SAFE';

  @override
  String get themeCodeMode => 'CODE';

  @override
  String get themeAnimBadge => 'ANIM';

  @override
  String themeAuthor(String author) {
    return 'by $author';
  }

  @override
  String get gaplessPlayback => 'Gapless Playback';

  @override
  String get gaplessPlaybackSubtitle => 'Eliminate silence between songs';

  @override
  String get lyricsSection => 'LYRICS';

  @override
  String get neteaseLyrics => 'Netease Lyrics';

  @override
  String get neteaseLyricsSubtitle =>
      'Fetch lyrics from Netease Cloud Music when LRCLIB has no results (recommended for Chinese songs)';

  @override
  String get aiSmartPlaylist => 'AI Smart Playlist';

  @override
  String get apiKey => 'API Key';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get apiUrl => 'API URL';

  @override
  String get aiModel => 'Model';

  @override
  String get songKnowledgeBase => 'Song Knowledge Base';

  @override
  String knowledgeIndexed(int cached, int total) {
    return 'Indexed $cached / $total songs';
  }

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get generate => 'Generate';

  @override
  String get incrementalUpdate => 'Update';

  @override
  String knowledgeGenerated(int count) {
    return 'Knowledge base generated for $count songs';
  }

  @override
  String knowledgeGenerationFailed(String reason) {
    return 'Knowledge base generation failed: $reason';
  }

  @override
  String get apiUrlHint => 'https://api.deepseek.com';

  @override
  String get apiUrlDescription =>
      'Any OpenAI-compatible API URL works\ne.g. DeepSeek, OpenAI, Kimi, Tongyi Qianwen';

  @override
  String get modelName => 'Model Name';

  @override
  String get aiConnectionSettings => 'AI Connection';

  @override
  String get exportKnowledgeBase => 'Export Knowledge Base';

  @override
  String get exportKnowledgeBaseSubtitle =>
      'Export as a file to share with others on the same NAS library';

  @override
  String get export => 'Export';

  @override
  String exportedTo(String path) {
    return 'Exported to $path';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importKnowledgeBase => 'Import Knowledge Base';

  @override
  String get importKnowledgeBaseSubtitle =>
      'Import a knowledge base file shared by someone else';

  @override
  String get import => 'Import';

  @override
  String knowledgeImported(int count) {
    return 'Imported $count songs into knowledge base';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get howItWorks => 'How It Works';

  @override
  String get knowledgeBaseExplanation => 'How the Knowledge Base Works';

  @override
  String get playlistGenerationExplanation => 'How Playlist Generation Works';

  @override
  String get networkWifi => 'WiFi';

  @override
  String get networkMobile => 'Mobile';

  @override
  String get analyticsAndPrivacy => 'Analytics & Privacy';

  @override
  String get anonymousAnalyticsToggle => 'Anonymous Analytics';

  @override
  String get anonymousAnalyticsToggleSubtitle =>
      'Help improve Luobo with anonymous crash reports and usage stats';

  @override
  String anonymousIdLabel(String id) {
    return 'Anonymous ID: $id';
  }

  @override
  String get enableAnalyticsToSeeId =>
      'Enable analytics to see your anonymous device ID';

  @override
  String get copyDeviceId => 'Copy device ID';

  @override
  String get deviceIdCopied => 'Device ID copied to clipboard';

  @override
  String get aboutDeviceIdDescription =>
      'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.';

  @override
  String get support => 'Support';

  @override
  String get thanksForRating => 'Thanks for Rating!';

  @override
  String get alreadyRated => 'You\'ve already rated the app';

  @override
  String get rateMusly => 'Rate Luobo';

  @override
  String get shareFeedback => 'Share your feedback';

  @override
  String get howWouldYouRate => 'How would you rate your experience?';

  @override
  String get optionalFeedback => 'Optional feedback...';

  @override
  String get submit => 'Submit';

  @override
  String get thankYouFeedback => 'Thank you for your feedback!';

  @override
  String addedFolder(String path) {
    return 'Added folder: $path';
  }

  @override
  String get removeFolder => 'Remove Folder';

  @override
  String removeFolderConfirm(String path) {
    return 'Remove \"$path\" from scan paths?';
  }

  @override
  String get folderRemoved => 'Folder removed';

  @override
  String get loadingLibrary => 'Loading library...';

  @override
  String get libraryEmptyOrFailed =>
      'Library appears to be empty or failed to load. Make sure your server supports full library scanning.';

  @override
  String get addToLikedSongs => 'Add to Liked Songs';

  @override
  String get removeFromLikedSongs => 'Remove from Liked Songs';

  @override
  String rateSongWithRating(int rating) {
    String _temp0 = intl.Intl.pluralLogic(
      rating,
      locale: localeName,
      other: 'stars',
      one: 'star',
    );
    return 'Rate Song ($rating $_temp0)';
  }

  @override
  String songRated(int rating) {
    String _temp0 = intl.Intl.pluralLogic(
      rating,
      locale: localeName,
      other: 'stars',
      one: 'star',
    );
    return 'Rated $rating $_temp0';
  }

  @override
  String get songRemovedFromPlaylist => 'Song removed from playlist';

  @override
  String errorRemovingSong(Object error) {
    return 'Error removing song: $error';
  }

  @override
  String errorRemovingSongs(Object error) {
    return 'Error removing songs: $error';
  }

  @override
  String errorReorderingSong(Object error) {
    return 'Error reordering song: $error';
  }

  @override
  String get removeSongs => 'Remove songs';

  @override
  String removeSongsConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return 'Remove $count $_temp0 from this playlist?';
  }

  @override
  String songsRemovedFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return '$count $_temp0 removed from playlist';
  }

  @override
  String get reorderSongs => 'Reorder Songs';

  @override
  String get doneReordering => 'Done reordering';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get removeSelected => 'Remove selected';

  @override
  String get selectSongs => 'Select songs';

  @override
  String get downloadPlaylist => 'Download playlist';

  @override
  String removeSongFromPlaylistConfirm(String title) {
    return 'Remove \"$title\" from this playlist?';
  }

  @override
  String downloadedSongsFrom(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return 'Downloaded $count $_temp0 from $name';
  }

  @override
  String downloadingSongsInBackground(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return 'Downloading $count $_temp0 in background…';
  }

  @override
  String songsCountWithDuration(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return '$count $_temp0 • $duration';
  }

  @override
  String artistsCount(int count) {
    return '$count Artists';
  }

  @override
  String get createPlaylistToStart => 'Create a playlist to get started';

  @override
  String get enableSelfSignedCertsHint =>
      'Try enabling \"Allow Self-Signed Certificates\" below.';

  @override
  String get checkCredentialsHint =>
      'Check your username and password and try again.';

  @override
  String get verifyServerUrlHint =>
      'Verify the server URL path (e.g. /navidrome, /airsonic).';

  @override
  String get serverTimeoutHint =>
      'The server took too long to respond. Check your network.';

  @override
  String get copyError => 'Copy error';

  @override
  String get errorCopiedToClipboard => 'Error copied to clipboard';

  @override
  String get tapToEnableSelfSignedCerts =>
      'Tap to enable self-signed certificates';

  @override
  String get clickToEnableSelfSignedCerts =>
      'Click to enable self-signed certificates';

  @override
  String get failedToConnectToServer => 'Failed to connect to server';

  @override
  String get selectMusicFiles => 'Select your music files...';

  @override
  String get noFilesSelected =>
      'No files selected. Tap \"Use Local Files\" and pick your music files.';

  @override
  String get youtubeMusicDescription =>
      'YouTube Music streams music directly from YouTube. No account required — tap Connect to start.';

  @override
  String get savedProfiles => 'Saved Profiles';

  @override
  String get tapProfileToConnect =>
      'Tap a profile to connect • tap × to delete';

  @override
  String get myServers => 'My Servers';

  @override
  String get addServer => 'Add Server';

  @override
  String get editServer => 'Edit Server';

  @override
  String get selectServerType => 'Select Server Type';

  @override
  String get serverTypeAuto => 'Auto-detect (Recommended)';

  @override
  String get serverTypeAutoSubtitle => 'Subsonic / Jellyfin / 道理鱼';

  @override
  String get serverTypeSubsonic => 'Subsonic';

  @override
  String get serverTypeJellyfin => 'Emby / Jellyfin';

  @override
  String get serverTypeDaoliyu => '道理鱼';

  @override
  String get deleteProfileTitle => 'Delete Profile';

  @override
  String deleteProfileConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get formSectionConnection => 'Connection';

  @override
  String get formSectionAccount => 'Account';

  @override
  String get connecting => 'Conectando';

  @override
  String get newThemeDefaultName => 'New Theme';

  @override
  String get newThemeDefaultAuthor => 'Me';

  @override
  String get themeDeactivated => 'Theme deactivated (using default)';

  @override
  String get defaultThemeActivated => 'Default theme activated';

  @override
  String themeActivated(String name) {
    return '$name activated';
  }

  @override
  String themeCopyName(String name) {
    return '$name Copy';
  }

  @override
  String themeDuplicated(String name) {
    return 'Duplicated as \"$name\"';
  }

  @override
  String get exportThemeTitle => 'Export Theme';

  @override
  String themeExported(String path) {
    return 'Exported to $path';
  }

  @override
  String get themeImported => 'Theme imported';

  @override
  String get themeImportedSafeMode => 'Theme imported (Safe Mode)';

  @override
  String get themeImportedSuccess => 'Theme imported successfully';

  @override
  String get importFailedTitle => 'Import Failed';

  @override
  String get themeFileErrors => 'The theme file contains errors:';

  @override
  String get securityWarning => 'Security Warning';

  @override
  String get customCodeSecurityRisk =>
      'This theme contains custom Flutter code which may pose security risks.';

  @override
  String get themeDetailsLabel => 'Theme Details:';

  @override
  String get nameLabel => 'Name';

  @override
  String get authorLabel => 'Author';

  @override
  String get customWidgetsLabel => 'Custom Widgets:';

  @override
  String get dependenciesLabel => 'Dependencies:';

  @override
  String get safeModeButton => 'Safe Mode';

  @override
  String get enableCodeButton => 'Enable Code';

  @override
  String get deleteTheme => 'Delete Theme';

  @override
  String deleteThemeConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String themeDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get safeModeDisabled => 'Safe Mode disabled';

  @override
  String get safeModeEnabled => 'Safe Mode enabled';

  @override
  String get duplicateTheme => 'Duplicate Theme';

  @override
  String get newThemeNameHint => 'New theme name';

  @override
  String get duplicateButton => 'Duplicate';

  @override
  String get themeTabInfo => 'Info';

  @override
  String get themeTabBackground => 'Background';

  @override
  String get themeTabText => 'Text';

  @override
  String get themeTabArtwork => 'Artwork';

  @override
  String get themeTabProgress => 'Progress';

  @override
  String get themeTabControls => 'Controls';

  @override
  String get themeTabAnimations => 'Animations';

  @override
  String get themeNameLabel => 'Theme Name';

  @override
  String get backgroundTypeLabel => 'Background Type';

  @override
  String get color1Label => 'Color 1';

  @override
  String get color2Label => 'Color 2';

  @override
  String get opacityLabel => 'Opacity';

  @override
  String get blurSigmaLabel => 'Blur Sigma';

  @override
  String get colorLabel => 'Color';

  @override
  String get fontSizeLabel => 'Font Size';

  @override
  String get fontWeightLabel => 'Font Weight';

  @override
  String get shapeLabel => 'Shape';

  @override
  String get sizeFactorLabel => 'Size Factor';

  @override
  String get cornerRadiusLabel => 'Corner Radius';

  @override
  String get shadowLabel => 'Shadow';

  @override
  String get rotationAnimationLabel => 'Rotation Animation';

  @override
  String get activeColorLabel => 'Active Color';

  @override
  String get inactiveColorLabel => 'Inactive Color';

  @override
  String get heightLabel => 'Height';

  @override
  String get thumbVisibleLabel => 'Thumb Visible';

  @override
  String get buttonColorLabel => 'Button Color';

  @override
  String get playButtonColorLabel => 'Play Button Color';

  @override
  String get playButtonSizeLabel => 'Play Button Size';

  @override
  String get playButtonShapeLabel => 'Play Button Shape';

  @override
  String get coverRotationLabel => 'Cover Rotation';

  @override
  String get rotationSpeedLabel => 'Rotation Speed (s/turn)';

  @override
  String get pulseEffectLabel => 'Pulse Effect';

  @override
  String get fadeInLabel => 'Fade In';

  @override
  String get noFavoriteSongs => 'No favorite songs yet';

  @override
  String get listeningHistoryHint => 'Songs you play will appear here';

  @override
  String get searchInLibrary => 'Search in Library...';

  @override
  String get searchYourLibrary => 'Search your library';

  @override
  String get noPlaylistsFound => 'No playlists found';

  @override
  String get tableHeaderTitle => 'TITLE';

  @override
  String get tableHeaderAlbum => 'ALBUM';

  @override
  String get tableHeaderTime => 'TIME';

  @override
  String streamUrl(String url) {
    return 'Stream URL: $url';
  }

  @override
  String get newReleases => 'New Releases';

  @override
  String get noNewReleases => 'No new releases';

  @override
  String get downloadAlbum => 'Download album';

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get noSongsInQueue => 'No songs in queue';

  @override
  String get internetRadioLive => 'Internet Radio • LIVE';

  @override
  String get stop => 'Stop';

  @override
  String customWidgetLabel(String name) {
    return 'Custom Widget: $name';
  }

  @override
  String customWidgetError(String error) {
    return 'Custom widget error: $error';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String safeModeDisabledLabel(String name) {
    return 'Safe Mode: $name disabled';
  }

  @override
  String get compiling => 'Compiling...';

  @override
  String get exitApp => 'Exit App';

  @override
  String get noTranscoding => 'Original (not transcoded)';

  @override
  String get transcodeShortIdle => 'Direct';

  @override
  String get transcodeShortActive => 'Transcoding';

  @override
  String get transcodeShortDone => 'Transcoded';

  @override
  String get streamWillTranscode => 'Will transcode on current network';

  @override
  String streamWillTranscodeTo(String format, int bitrate, String network) {
    return 'Will transcode to $format ${bitrate}kbps on current network ($network)';
  }

  @override
  String transcodedTo(String format, int bitrate, String network) {
    return 'Transcoded to $format ${bitrate}kbps ($network)';
  }

  @override
  String transcodedToNoNetwork(String format, int bitrate) {
    return 'Transcoded to $format ${bitrate}kbps';
  }

  @override
  String transcodingInProgress(String format, int bitrate) {
    return 'Transcoding to $format ${bitrate}kbps';
  }

  @override
  String get edit => 'Editar';

  @override
  String get serverStatus => 'Server Status';

  @override
  String get rescanLibrary => 'Rescan Library';

  @override
  String get removeConnection => 'Remove Connection';

  @override
  String get connectedServers => 'Connected Servers';

  @override
  String get serversHint =>
      'Tap to switch the active server; scan or add from the top right.';

  @override
  String get libraryRefreshed => 'Library refreshed';

  @override
  String get serverDetail => 'Server Details';

  @override
  String get formLocalOnlyNote =>
      'This information is stored only on this device.';

  @override
  String get serverTypeGridHint =>
      'Pick a type, then fill in the address and account — the form is identical to \"Modify connection\".';

  @override
  String get otherWays => 'Other ways';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get useLocalFilesConfirmTitle => 'Switch to local music mode?';

  @override
  String get useLocalFilesConfirmBody =>
      'This disconnects the current server and uses music files stored on this device instead.';

  @override
  String get sortFieldTitle => 'Title';
}
