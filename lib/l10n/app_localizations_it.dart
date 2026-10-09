// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'Buon giorno';

  @override
  String get goodAfternoon => 'Buona sera';

  @override
  String get goodEvening => 'Buon pomeriggio';

  @override
  String get forYou => 'Per Te';

  @override
  String get quickPicks => 'Scelte Rapide';

  @override
  String get discoverMix => 'Mix Scoperta';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Riprodotte Recentemente';

  @override
  String get yourPlaylists => 'Le Tue Playlist';

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
  String get madeForYou => 'Fatte Per Te';

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
  String get topRated => 'Più Votata';

  @override
  String get noContentAvailable => 'Nessun contenuto disponibile';

  @override
  String get tryRefreshing =>
      'Prova ad aggiornare o controlla la connessione al server';

  @override
  String get refresh => 'Aggiorna';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs => 'Errore durante il caricamento delle canzoni';

  @override
  String get noSongsInGenre => 'Nessun brano in questo genere';

  @override
  String get errorLoadingAlbums => 'Errore durante il caricamento album';

  @override
  String get noTopRatedAlbums => 'Nessun album classificato';

  @override
  String get login => 'Accedi';

  @override
  String get serverUrl => 'URL Del Server';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get selectCertificate => 'Seleziona Certificato TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Impossibile selezionare il certificato: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'L\'URL del server deve iniziare con http:// o https://';

  @override
  String get failedToConnect => 'Connessione fallita';

  @override
  String get library => 'Libreria';

  @override
  String get search => 'Cerca';

  @override
  String get settings => 'Impostazioni';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artisti';

  @override
  String get songs => 'Brani';

  @override
  String get playlists => 'Playlist';

  @override
  String get genres => 'Generi';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Preferiti';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get queue => 'Coda';

  @override
  String get lyrics => 'Testi';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Successivo';

  @override
  String get previous => 'Precedente';

  @override
  String get shuffle => 'Riproduzione casuale';

  @override
  String get repeat => 'Ripeti';

  @override
  String get repeatOne => 'Ripeti una volta';

  @override
  String get repeatOff => 'Ripetizione disattivata';

  @override
  String get addToPlaylist => 'Aggiungi alla Playlist';

  @override
  String get removeFromPlaylist => 'Rimuovi dalla Playlist';

  @override
  String get addToFavorites => 'Aggiungi ai Preferiti';

  @override
  String get removeFromFavorites => 'Rimuovi dai Preferiti';

  @override
  String get download => 'Scarica';

  @override
  String get delete => 'Cancella';

  @override
  String get cancel => 'Annulla';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Salva';

  @override
  String get close => 'Chiudi';

  @override
  String get general => 'Generale';

  @override
  String get appearance => 'Aspetto';

  @override
  String get playback => 'Riproduzione';

  @override
  String get storage => 'Spazio di archiviazione';

  @override
  String get about => 'Informazioni';

  @override
  String get darkMode => 'Tema Scuro';

  @override
  String get language => 'Lingua';

  @override
  String get version => 'Versione';

  @override
  String get githubRepository => 'Repository GitHub';

  @override
  String get reportIssue => 'Segnala un problema';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get shuffleAll => 'Riproduzione casuale per tutti i brani';

  @override
  String get sortBy => 'Ordina Per';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByDuration => 'Durata';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Discendente';

  @override
  String get noLyricsAvailable => 'Nessun testo disponibile per questo brano';

  @override
  String get loading => 'Caricamento in corso...';

  @override
  String get error => 'Errore';

  @override
  String get retry => 'Riprova';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get searchHint => 'Cerca brani, album, artisti...';

  @override
  String get allSongs => 'Tutti i Brani';

  @override
  String get allAlbums => 'Tutti Gli Album';

  @override
  String get allArtists => 'Tutti Gli Artisti';

  @override
  String trackNumber(int number) {
    return 'Traccia $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canzoni',
      one: '1 canzone',
      zero: 'Nessuna canzone',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
      zero: 'Nessun album',
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
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Sei sicuro di volerti disconnettere?';

  @override
  String get yes => 'Si';

  @override
  String get no => 'No';

  @override
  String get offlineMode => 'Modalità offline';

  @override
  String get radio => 'Radio';

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
  String get changelog => 'Registro delle modifiche';

  @override
  String get platform => 'Piattaforma';

  @override
  String get server => 'Server';

  @override
  String get display => 'Schermo';

  @override
  String get playerInterface => 'Interfaccia Lettore';

  @override
  String get smartRecommendations => 'Raccomandazioni intelligenti';

  @override
  String get showVolumeSlider => 'Mostra Cursore Del Volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Visualizza il controllo del volume nella schermata Ora in riproduzione';

  @override
  String get showStarRatings => 'Mostra Valutazioni Stella';

  @override
  String get showStarRatingsSubtitle => 'Vota brani e visualizza valutazioni';

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
  String get enableRecommendations => 'Attiva Raccomandazioni';

  @override
  String get enableRecommendationsSubtitle =>
      'Ottieni suggerimenti musicali personalizzati';

  @override
  String get listeningData => 'Dati Di Ascolto';

  @override
  String totalPlays(int count) {
    return '$count Riproduzioni Totali';
  }

  @override
  String get clearListeningHistory => 'Cancella Cronologia Ascolti';

  @override
  String get confirmClearHistory =>
      'Questo resetterà tutti i tuoi dati di ascolto e i tuoi consigli. Sei sicuro?';

  @override
  String get historyCleared => 'Cronologia di ascolto cancellata';

  @override
  String get discordStatus => 'Stato Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostra il brano in riproduzione sul profilo Discord';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get systemDefault => 'Predefinita di Sistema';

  @override
  String get yourLibrary => 'La Tua Libreria';

  @override
  String get filterAll => 'Tutto';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Playlist';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterArtists => 'Artisti';

  @override
  String get likedSongs => 'Brani preferiti';

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
  String get radioStations => 'Stazioni radio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Radio Internet';

  @override
  String get newPlaylist => 'Nuova Playlist';

  @override
  String get playlistName => 'Nome Playlist';

  @override
  String get create => 'Crea';

  @override
  String get deletePlaylist => 'Elimina Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Sei sicuro di voler eliminare la playlist \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" eliminata';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Errore nella creazione della playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Errore nell\'eliminare la playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" creata';
  }

  @override
  String get searchTitle => 'Cerca';

  @override
  String get searchPlaceholder => 'Artisti, Canzoni, Album';

  @override
  String get tryDifferentSearch => 'Prova un’altra ricerca';

  @override
  String get noSuggestions => 'Nessun suggerimento';

  @override
  String get browseCategories => 'Esplora le categorie';

  @override
  String get liveSearchSection => 'Ricerca';

  @override
  String get liveSearch => 'Ricerca Live';

  @override
  String get liveSearchSubtitle =>
      'Aggiorna i risultati mentre digiti invece di mostrare un menu a tendina';

  @override
  String get categoryMadeForYou => 'Fatte Per Te';

  @override
  String get categoryNewReleases => 'Nuovi Rilasci';

  @override
  String get categoryTopRated => 'I più votati';

  @override
  String get categoryGenres => 'Generi';

  @override
  String get categoryFavorites => 'Preferiti';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get tabPlayback => 'Riproduzione';

  @override
  String get tabStorage => 'Spazio di archiviazione';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Schermo';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Informazioni';

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
  String get autoDjMode => 'Modalità DJ Automatica';

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
    return 'Brani da aggiungere: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZZAZIONE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modalità';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Previeni Il Clipping';

  @override
  String fallbackGain(String value) {
    return 'Guadagno Fallback: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALITÀ DI STREAMING';

  @override
  String get enableTranscoding => 'Abilita La Transcodifica';

  @override
  String get qualityWifi => 'Qualità WiFi';

  @override
  String get qualityMobile => 'Qualità Mobile';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle =>
      'Riduce l\'utilizzo dei dati con qualità inferiore';

  @override
  String get modeOff => 'Off';

  @override
  String get modeTrack => 'Traccia';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'CONNESSIONE DEL SERVER';

  @override
  String get serverType => 'Tipo di server';

  @override
  String get notConnected => 'Non connesso';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get sectionMusicFolders => 'CARTELLE MUSICA';

  @override
  String get musicFolders => 'Cartelle Musica';

  @override
  String get noMusicFolders => 'Nessuna cartella musicale trovata';

  @override
  String get sectionSavedProfiles => 'PROFILI SALVATI';

  @override
  String get switchProfile => 'Cambia Profilo';

  @override
  String get switchServer => 'Cambia Server';

  @override
  String get addProfile => 'Aggiungi Profilo';

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
    return 'Connetti a \"$profile\"?';
  }

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get logoutConfirmation =>
      'Sei sicuro di voler uscire? Questo cancellerà tutti i dati memorizzati nella cache.';

  @override
  String get sectionCacheSettings => 'IMPOSTAZIONI CACHE';

  @override
  String get imageCache => 'Cache delle immagini';

  @override
  String get musicCache => 'Cache Della Musica';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Salva localmente le copertine degli album';

  @override
  String get saveSongMetadata => 'Salva i metadati del brano localmente';

  @override
  String get saveBpmAnalysis => 'Salva analisi BPM localmente';

  @override
  String get sectionCacheCleanup => 'PULIZIA DELLA CACHE';

  @override
  String get clearAllCache => 'Svuota tutta la cache';

  @override
  String get allCacheCleared => 'Tutta la cache cancellata';

  @override
  String get sectionOfflineDownloads => 'DOWNLOAD OFFLINE';

  @override
  String get downloadedSongs => 'Brani Scaricati';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Scaricamento Della Libreria... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Scarica Tutta La Libreria';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Questo scaricherà  $count brani sul tuo dispositivo. Questo potrebbe richiedere un po\' di tempo e utilizzare uno spazio di archiviazione significativo.\n\nContinuare?';
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
  String get libraryDownloadStarted => 'Download della libreria avviato';

  @override
  String get deleteDownloads => 'Elimina tutti i download';

  @override
  String get downloadsDeleted => 'Tutti i download eliminati';

  @override
  String get noSongsAvailable =>
      'Nessun brano disponibile. Carica prima la tua libreria.';

  @override
  String get sectionBpmAnalysis => 'ANALISI BPM';

  @override
  String get cachedBpms => 'Cached BPMs';

  @override
  String get cacheAllBpms => 'Cache Tutti I Bpm';

  @override
  String get clearBpmCache => 'Cancella Cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM cancellata';

  @override
  String downloadedStats(int count, String size) {
    return '$count canzoni • $size';
  }

  @override
  String get sectionInformation => 'INFORMAZIONI';

  @override
  String get sectionDeveloper => 'SVILUPPATORE';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'Repository GitHub';

  @override
  String get playingFrom => 'IN RIPRODUZIONE DA';

  @override
  String get live => 'IN DIRETTA';

  @override
  String get streamingLive => 'Streaming In Diretta';

  @override
  String get stopRadio => 'Ferma La Radio';

  @override
  String get removeFromLiked => 'Rimuovi dai brani aggiunti ai preferiti';

  @override
  String get addToLiked => 'Aggiungi alle canzoni preferite';

  @override
  String get playNext => 'Riproduci Successivo';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get goToAlbum => 'Vai all\'album';

  @override
  String get goToArtist => 'Vai all\'artista';

  @override
  String get rateSong => 'Vota Brano';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Valuta Canzone ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Valutazione rimossa';

  @override
  String rated(int rating, String stars) {
    return 'Votato $rating $stars';
  }

  @override
  String get removeRating => 'Rimuovi Voto';

  @override
  String get downloaded => 'Scaricato';

  @override
  String downloading(int percent) {
    return 'Scaricamento... $percent%';
  }

  @override
  String get removeDownload => 'Rimuovi download';

  @override
  String get removeDownloadConfirm =>
      'Rimuovere questa canzone dalla memoria offline?';

  @override
  String get downloadRemoved => 'Download rimosso';

  @override
  String downloadedTitle(String title) {
    return 'Scaricato \"$title\"';
  }

  @override
  String get downloadFailed => 'Download fallito';

  @override
  String downloadError(Object error) {
    return 'Errore di download: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Aggiunto \"$title\" alla $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Errore nell\'aggiungere alla playlist: $error';
  }

  @override
  String get noPlaylists => 'Nessuna playlist disponibile';

  @override
  String get createNewPlaylist => 'Crea Nuova Playlist';

  @override
  String artistNotFound(String name) {
    return 'Artista \"$name\" non trovato';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Errore cercando l\'artista: $error';
  }

  @override
  String get selectArtist => 'Seleziona artista';

  @override
  String get removedFromFavorites => 'Rimosso dai preferiti';

  @override
  String get addedToFavorites => 'Aggiunto ai preferiti';

  @override
  String get star => 'stella';

  @override
  String get stars => 'stelle';

  @override
  String get albumNotFound => 'Album non trovato';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Canzoni più ascoltate';

  @override
  String get connected => 'Collegato';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'Nessuna brano in riproduzione';

  @override
  String get internetRadioUppercase => 'RADIO INTERNET';

  @override
  String get playingNext => 'Riproduzione Successiva';

  @override
  String get createPlaylistTitle => 'Crea playlist';

  @override
  String get playlistNameHint => 'Nome playlist';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist creata \"$name\" con questa canzone';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Errore nel caricare le playlist: $error';
  }

  @override
  String get playlistNotFound => 'Playlist non trovata';

  @override
  String get noSongsInPlaylist => 'Nessun brano in questa playlist';

  @override
  String get noFavoriteSongsYet => 'Ancora nessuna canzone preferita';

  @override
  String get noFavoriteAlbumsYet => 'Ancora nessun album preferito';

  @override
  String get listeningHistory => 'Cronologia Ascolti';

  @override
  String get noListeningHistory => 'Nessuna Cronologia Di Ascolto';

  @override
  String get songsWillAppearHere => 'Le canzoni che riproduci appariranno qui';

  @override
  String get sortByArtistAZ => 'Artista (A-Z)';

  @override
  String get sortByArtistZA => 'Artista (Z-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (Z-A)';

  @override
  String get recentlyAdded => 'Aggiunto di Recente';

  @override
  String get noSongsFound => 'Nessuna canzone trovata';

  @override
  String get noAlbumsFound => 'Nessun album trovato';

  @override
  String get noHomepageUrl => 'Nessun URL di homepage disponibile';

  @override
  String get playStation => 'Play Station';

  @override
  String get openHomepage => 'Apri Homepage';

  @override
  String get copyStreamUrl => 'Copia URL streaming';

  @override
  String get failedToLoadRadioStations =>
      'Impossibile caricare le stazioni radio';

  @override
  String get noRadioStations => 'Nessuna Stazione Radio';

  @override
  String get noRadioStationsHint =>
      'Aggiungi stazioni radio nelle impostazioni del tuo server Navidrome per vederle qui.';

  @override
  String get connectToServerSubtitle => 'Connettiti al tuo server Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Inserisci l\'URL del server';

  @override
  String get invalidUrlFormat => 'L\'URL deve iniziare con http:// o https://';

  @override
  String get pleaseEnterUsername => 'Inserisci il nome utente';

  @override
  String get pleaseEnterPassword => 'Inserisci la password';

  @override
  String get legacyAuthentication => 'Autenticazione Legacy';

  @override
  String get legacyAuthSubtitle => 'Usa per vecchi server Subsonic';

  @override
  String get allowSelfSignedCerts => 'Consenti Certificati Auto-Firmati';

  @override
  String get allowSelfSignedSubtitle =>
      'Per server con certificati TLS/SSL personalizzati';

  @override
  String get advancedOptions => 'Opzioni Avanzate';

  @override
  String get customTlsCertificate => 'Certificato TLS/Ssl Personalizzato';

  @override
  String get customCertificateSubtitle =>
      'Carica un certificato personalizzato per server con CA non standard';

  @override
  String get selectCertificateFile => 'Seleziona il file del certificato';

  @override
  String get clientCertificate => 'Certificato Client (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticare questo client utilizzando un certificato (richiede un server abilitato per mTLS)';

  @override
  String get selectClientCertificate => 'Seleziona Certificato Client';

  @override
  String get clientCertPassword => 'Password del certificato (opzionale)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Impossibile selezionare il certificato: $error';
  }

  @override
  String get connect => 'Connetti';

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
  String get or => 'O';

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
  String get useLocalFiles => 'Usa File Locali';

  @override
  String get startingScan => 'Avvio scansione...';

  @override
  String get storagePermissionRequired =>
      'È richiesta l\'autorizzazione di archiviazione per eseguire la scansione dei file locali';

  @override
  String get noMusicFilesFound =>
      'Nessun file musicale trovato sul tuo dispositivo';

  @override
  String get remove => 'Rimuovi';

  @override
  String failedToSetRating(Object error) {
    return 'Impossibile impostare la valutazione: $error';
  }

  @override
  String get home => 'Home';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Comprimi';

  @override
  String get expand => 'Espandi';

  @override
  String get createPlaylist => 'Crea playlist';

  @override
  String get likedSongsSidebar => 'Brani piaciuti';

  @override
  String playlistSongsCount(int count) {
    return '';
  }

  @override
  String get failedToLoadLyrics => 'Impossibile caricare i testi';

  @override
  String get lyricsNotFoundSubtitle =>
      'Impossibile trovare il testo di questa canzone';

  @override
  String get backToCurrent => 'Torna al corrente';

  @override
  String get exitFullscreen => 'Esci da schermo intero';

  @override
  String get fullscreen => 'Schermo Intero';

  @override
  String get noLyrics => 'Nessun testo';

  @override
  String get internetRadioMiniPlayer => 'Radio Internet';

  @override
  String get liveBadge => 'IN DIRETTA';

  @override
  String get localFilesModeBanner => 'Modalità File Locali';

  @override
  String get offlineModeBanner =>
      'Modalità offline – Solo riproduzione di musica scaricata';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get updateAvailableSubtitle =>
      'Una nuova versione di Luobo è disponibile!';

  @override
  String updateCurrentVersion(String version) {
    return 'Attuale: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Ultima: v$version';
  }

  @override
  String get whatsNew => 'Cosa c\'è di nuovo';

  @override
  String get downloadUpdate => 'Scarica';

  @override
  String get remindLater => 'Dopo';

  @override
  String get seeAll => 'Vedi tutti';

  @override
  String get artistDataNotFound => 'Artista non trovato';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'In trasmissione';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get searchingDevices => 'Ricerca di dispositivi in corso';

  @override
  String get castWifiHint =>
      'Assicurati che il tuo dispositivo Cast / DLNA\nsia sulla stessa rete Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Connesso a $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Impossibile connettersi a $name';
  }

  @override
  String get removedFromLikedSongs => 'Rimosso da brani che ti piacciono';

  @override
  String get addedToLikedSongs => 'Aggiunto a brani che ti piacciono';

  @override
  String get enableShuffle => 'Attiva la riproduzione casuale';

  @override
  String get enableRepeat => 'Abilita ripetizione';

  @override
  String get closeLyrics => 'Chiudi Testi';

  @override
  String errorStartingDownload(Object error) {
    return 'Errore nell\'avvio del download: $error';
  }

  @override
  String get errorLoadingGenres => 'Errore nel caricamento dei generi';

  @override
  String get noGenresFound => 'Nessun genere trovato';

  @override
  String get noAlbumsInGenre => 'Nessun album in questo genere';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount canzoni • $albumCount album';
  }

  @override
  String get musicFoldersDialogTitle => 'Seleziona Cartelle Musicali';

  @override
  String get musicFoldersHint =>
      'Lascia tutto abilitato per usare tutte le cartelle (predefinito).';

  @override
  String get musicFoldersSaved => 'Selezione di cartelle musicali salvata';

  @override
  String get artworkStyleSection => 'Stile Grafica';

  @override
  String get artworkCornerRadius => 'Raggio Angoli';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Regola come appaiono gli angoli delle copertine degli album';

  @override
  String get artworkCornerRadiusNone => 'Nessuno';

  @override
  String get artworkShape => 'Forma';

  @override
  String get artworkShapeRounded => 'Arrotondato';

  @override
  String get artworkShapeCircle => 'Cerchio';

  @override
  String get artworkShapeSquare => 'Quadrato';

  @override
  String get artworkShadow => 'Ombra';

  @override
  String get artworkShadowNone => 'Nessuno';

  @override
  String get artworkShadowSoft => 'Soft';

  @override
  String get artworkShadowMedium => 'Medio';

  @override
  String get artworkShadowStrong => 'Strong';

  @override
  String get artworkShadowColor => 'Colore ombreggiatura';

  @override
  String get artworkShadowColorBlack => 'Nero';

  @override
  String get artworkShadowColorAccent => 'Accento';

  @override
  String get artworkPreview => 'Anteprima';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Nessuna copertina';

  @override
  String get serverUnreachableTitle => 'Impossibile raggiungere il server';

  @override
  String get serverUnreachableSubtitle =>
      'Controllare la connessione o le impostazioni del server.';

  @override
  String get openOfflineMode => 'Apri in modalità offline';

  @override
  String get appearanceSection => 'Aspetto';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Tema colore';

  @override
  String get circularDesignLabel => 'Design Circolare';

  @override
  String get circularDesignSubtitle =>
      'UI galleggiante e arrotondata con pannelli traslucidi ed effetto sfocatura di vetro sul lettore e sulla barra di navigazione.';

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
  String get themeModeLight => 'Chiaro';

  @override
  String get themeModeDark => 'Scuro';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Stato di Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Seconda riga mostrata nell\'attività di Discord';

  @override
  String get discordRpcStyleArtist => 'Nome artista';

  @override
  String get discordRpcStyleSong => 'Titolo del brano';

  @override
  String get discordRpcStyleApp => 'Nome app (Luobo)';

  @override
  String get sectionVolumeNormalization =>
      'NORMALIZZAZIONE VOLUME (REPLAYGAIN)';

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
  String get replayGainModeOff => 'Off';

  @override
  String get replayGainModeTrack => 'Traccia';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Previeni Il Clipping';

  @override
  String replayGainFallbackGain(String value) {
    return 'Guadagno Fallback: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Brani da aggiungere: $count';
  }

  @override
  String get transcodingEnable => 'Abilita La Transcodifica';

  @override
  String get transcodingEnableSubtitle =>
      'Riduce l\'utilizzo dei dati con qualità inferiore';

  @override
  String get smartTranscoding => 'Trascodifica Intelligente';

  @override
  String get smartTranscodingSubtitle =>
      'Regola automaticamente la qualità in base alla tua connessione (WiFi vs dati mobili)';

  @override
  String get smartTranscodingDetectedNetwork => 'Rete rilevata: ';

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
  String get transcodingWifiQuality => 'Qualità WiFi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Usato automaticamente su WiFi';

  @override
  String get transcodingMobileQuality => 'Qualità Mobile';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Utilizzato automaticamente su dati cellulari';

  @override
  String get transcodingFormat => 'Formato';

  @override
  String get transcodingFormatSubtitle =>
      'Codec audio utilizzato per lo streaming';

  @override
  String get transcodingBitrateOriginal => 'Originale (Nessuna Transcodifica)';

  @override
  String get transcodingFormatOriginal => 'Originale';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Cache immagini';

  @override
  String get imageCacheSubtitle => 'Salva localmente le copertine degli album';

  @override
  String get musicCacheTitle => 'Cache Della Musica';

  @override
  String get musicCacheSubtitle => 'Salva i metadati del brano localmente';

  @override
  String get bpmCacheTitle => 'Cache BPM';

  @override
  String get bpmCacheSubtitle => 'Salva analisi BPM localmente';

  @override
  String get sectionAboutInformation => 'INFORMAZIONI';

  @override
  String get sectionAboutDeveloper => 'SVILUPPATORE';

  @override
  String get sectionAboutLinks => 'LINKS';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutPlatform => 'Piattaforma';

  @override
  String get aboutMadeBy => 'Realizzato da chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'Repository GitHub';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Segnala un problema';

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
  String get connecting => 'In connessione';

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
  String get edit => 'Modifica';

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
