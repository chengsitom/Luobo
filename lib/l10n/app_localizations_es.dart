// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get forYou => 'Para Ti';

  @override
  String get quickPicks => 'Selecciones Rápidas';

  @override
  String get discoverMix => 'Descubrir Mix';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Reproducido Recientemente';

  @override
  String get yourPlaylists => 'Tus Listas';

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
  String get madeForYou => 'Hecho Para Ti';

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
  String get topRated => 'Mejor Valorado';

  @override
  String get noContentAvailable => 'No hay contenido disponible';

  @override
  String get tryRefreshing =>
      'Intenta recargar o verifica la conexión del servidor';

  @override
  String get refresh => 'Actualizar';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs => 'Error al cargar las pistas';

  @override
  String get noSongsInGenre => 'No hay canciones en este género';

  @override
  String get errorLoadingAlbums => 'Error al cargar álbumes';

  @override
  String get noTopRatedAlbums => 'Sin álbumes mejor valorados';

  @override
  String get login => 'Inicio de sesión';

  @override
  String get serverUrl => 'URL de servidor';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get selectCertificate => 'Seleccione certificado TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'No se pudo seleccionar el certificado: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'La URL del servidor debe comenzar con http:// o https://';

  @override
  String get failedToConnect => 'Error al conectar';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Búsqueda';

  @override
  String get settings => 'Preferencias';

  @override
  String get albums => 'Álbumes';

  @override
  String get artists => 'Artistas';

  @override
  String get songs => 'Canciones';

  @override
  String get playlists => 'Listas';

  @override
  String get genres => 'Géneros';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoritos';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get queue => 'Cola';

  @override
  String get lyrics => 'Letras';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatOne => 'Repetir Una';

  @override
  String get repeatOff => 'Repetición Desactivada';

  @override
  String get addToPlaylist => 'Añadir a lista';

  @override
  String get removeFromPlaylist => 'Eliminar de la Lista';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get removeFromFavorites => 'Eliminar de favoritos';

  @override
  String get download => 'Descargar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get general => 'General';

  @override
  String get appearance => 'Apariencia';

  @override
  String get playback => 'Reproducción';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get about => 'Acerca de';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get version => 'Versión';

  @override
  String get githubRepository => 'Repositorio de GitHub';

  @override
  String get reportIssue => 'Reportar problema';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get unknownAlbum => 'Álbum Desconocido';

  @override
  String get playAll => 'Reproducir todo';

  @override
  String get shuffleAll => 'Mezclar todo';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Álbum';

  @override
  String get sortByDate => 'Fecha';

  @override
  String get sortByDuration => 'Duración';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get noLyricsAvailable => 'No hay letra disponible';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get searchHint => 'Buscar canciones, álbumes, artistas...';

  @override
  String get allSongs => 'Todas las Canciones';

  @override
  String get allAlbums => 'Todos los Álbumes';

  @override
  String get allArtists => 'Todos los Artistas';

  @override
  String trackNumber(int number) {
    return 'Pista $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'No hay canciones',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
      zero: 'No hay álbumes',
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
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => '¿Está seguro de que quiere cerrar sesión?';

  @override
  String get yes => 'Si';

  @override
  String get no => 'No';

  @override
  String get offlineMode => 'Modo Sin Conexión';

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
  String get changelog => 'Historial de actualizaciones';

  @override
  String get platform => 'Plataforma';

  @override
  String get server => 'Servidor';

  @override
  String get display => 'Pantalla';

  @override
  String get playerInterface => 'Interfaz del reproductor';

  @override
  String get smartRecommendations => 'Recomendaciones Inteligentes';

  @override
  String get showVolumeSlider => 'Mostrar barra de volumen';

  @override
  String get showVolumeSliderSubtitle =>
      'Mostrar control de volumen en la pantalla de reproducción';

  @override
  String get showStarRatings => 'Mostrar valoraciones de estrellas';

  @override
  String get showStarRatingsSubtitle => 'Valorar canciones y ver valoraciones';

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
  String get enableRecommendations => 'Habilitar Recomendaciones';

  @override
  String get enableRecommendationsSubtitle =>
      'Obtener sugerencias musicales personalizadas';

  @override
  String get listeningData => 'Datos de Reproducción';

  @override
  String totalPlays(int count) {
    return '$count reproducciones totales';
  }

  @override
  String get clearListeningHistory => 'Borrar Historial de Reproducción';

  @override
  String get confirmClearHistory =>
      'Esto restablecerá todos sus datos de reproducción y recomendaciones. ¿Está seguro?';

  @override
  String get historyCleared => 'Historial de Reproducción borrado';

  @override
  String get discordStatus => 'Estado de Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostrar reproducción de la canción en el perfil de Discord';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get systemDefault => 'Valores por defecto del sistema';

  @override
  String get yourLibrary => 'Tu Biblioteca';

  @override
  String get filterAll => 'Todo';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Listas';

  @override
  String get filterAlbums => 'Álbumes';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get likedSongs => 'Canciones que te gustan';

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
  String get radioStations => 'Emisoras de radio';

  @override
  String get playlist => 'Lista';

  @override
  String get internetRadio => 'Radio de Internet';

  @override
  String get newPlaylist => 'Nueva Lista';

  @override
  String get playlistName => 'Nombre de la Lista';

  @override
  String get create => 'Crear';

  @override
  String get deletePlaylist => 'Eliminar Lista';

  @override
  String deletePlaylistConfirmation(String name) {
    return '¿Está seguro de que desea eliminar la lista \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Lista \"$name\" eliminada';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Error al crear la lista: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Error al eliminar la lista: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Lista \"$name\" creada';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchPlaceholder => 'Artistas, Canciones, Álbumes';

  @override
  String get tryDifferentSearch => 'Intenta una búsqueda diferente';

  @override
  String get noSuggestions => 'Sin sugerencias';

  @override
  String get browseCategories => 'Explorar Categorías';

  @override
  String get liveSearchSection => 'Búsqueda';

  @override
  String get liveSearch => 'Búsqueda en tiempo real';

  @override
  String get liveSearchSubtitle =>
      'Actualizar los resultados mientras escribes en lugar de mostrar un desplegable';

  @override
  String get categoryMadeForYou => 'Hecho para ti';

  @override
  String get categoryNewReleases => 'Estrenos';

  @override
  String get categoryTopRated => 'Mejor valorado';

  @override
  String get categoryGenres => 'Géneros';

  @override
  String get categoryFavorites => 'Favoritos';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Preferencias';

  @override
  String get tabPlayback => 'Reproducción';

  @override
  String get tabStorage => 'Almacenamiento';

  @override
  String get tabServer => 'Servidor';

  @override
  String get tabDisplay => 'Pantalla';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Acerca de';

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
    return 'Canciones a añadir: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZACIÓN DE VOLUMEN (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modo';

  @override
  String preamp(String value) {
    return 'Preamplificador: $value dB';
  }

  @override
  String get preventClipping => 'Evitar recorte';

  @override
  String fallbackGain(String value) {
    return 'Ganancia de reserva: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'CALIDAD DE TRANSMISIÓN';

  @override
  String get enableTranscoding => 'Habilitar Transcodificación';

  @override
  String get qualityWifi => 'Calidad WiFi';

  @override
  String get qualityMobile => 'Calidad Móvil';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle => 'Reducir el uso de datos con menor calidad';

  @override
  String get modeOff => 'Desactivado';

  @override
  String get modeTrack => 'Pista';

  @override
  String get modeAlbum => 'Álbum';

  @override
  String get sectionServerConnection => 'CONEXÓN DEL SERVIDOR';

  @override
  String get serverType => 'Tipo de Servidor';

  @override
  String get notConnected => 'No conectado';

  @override
  String get unknown => 'Desconocido';

  @override
  String get sectionMusicFolders => 'CARPETAS DE MÚSICA';

  @override
  String get musicFolders => 'Carpeta de Música';

  @override
  String get noMusicFolders => 'No se encontraron carpetas de música';

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
  String get sectionAccount => 'CUENTA';

  @override
  String get logoutConfirmation =>
      '¿Seguro que quieres cerrar sesión? También se eliminarán todos los datos en caché.';

  @override
  String get sectionCacheSettings => 'AJUSTES DE CACHÉ';

  @override
  String get imageCache => 'Caché de Imágenes';

  @override
  String get musicCache => 'Caché de Música';

  @override
  String get bpmCache => 'Caché de BPM';

  @override
  String get saveAlbumCovers => 'Guardar carátulas de álbumes localmente';

  @override
  String get saveSongMetadata => 'Guardar metadatos de la canción localmente';

  @override
  String get saveBpmAnalysis => 'Guardar el análisis de BPM localmente';

  @override
  String get sectionCacheCleanup => 'LIMPIEZA DE CACHÉ';

  @override
  String get clearAllCache => 'Borrar toda la caché';

  @override
  String get allCacheCleared => 'Toda la caché borrada';

  @override
  String get sectionOfflineDownloads => 'DESCARGAS SIN CONEXIÓN';

  @override
  String get downloadedSongs => 'Canciones Descargadas';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Descargando Biblioteca... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Descargar toda la Biblioteca';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Esto descargará $count canciones en tu dispositivo. Esto puede tardar un rato y usar un espacio de almacenamiento significativo.\n\n¿Continuar?';
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
  String get libraryDownloadStarted => 'Descarga de la Biblioteca iniciada';

  @override
  String get deleteDownloads => 'Eliminar Todas las Descargas';

  @override
  String get downloadsDeleted => 'Todas las descargas eliminadas';

  @override
  String get noSongsAvailable =>
      'No hay canciones disponibles. Por favor, cargue su biblioteca primero.';

  @override
  String get sectionBpmAnalysis => 'ANÁLISIS BPM';

  @override
  String get cachedBpms => 'BPM en caché';

  @override
  String get cacheAllBpms => 'Guardar todos los BPM en caché';

  @override
  String get clearBpmCache => 'Limpiar caché de BPM';

  @override
  String get bpmCacheCleared => 'Caché de BPM limpiada';

  @override
  String downloadedStats(int count, String size) {
    return '$count canciones · $size';
  }

  @override
  String get sectionInformation => 'INFORMACIÓN';

  @override
  String get sectionDeveloper => 'DESARROLLADOR';

  @override
  String get sectionLinks => 'ENLACES';

  @override
  String get githubRepo => 'Repositorio de GitHub';

  @override
  String get playingFrom => 'REPRODUCIENDO DESDE';

  @override
  String get live => 'EN DIRECTO';

  @override
  String get streamingLive => 'Transmisión en directo';

  @override
  String get stopRadio => 'Parar Radio';

  @override
  String get removeFromLiked => 'Eliminar de Canciones que te gustan';

  @override
  String get addToLiked => 'Añadir a Canciones que te gustan';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Añadir a la Cola';

  @override
  String get goToAlbum => 'Ir al Álbum';

  @override
  String get goToArtist => 'Ir al artista';

  @override
  String get rateSong => 'Puntuar canción';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Puntuar Canción ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Valoración eliminada';

  @override
  String rated(int rating, String stars) {
    return 'Valorado con $rating $stars';
  }

  @override
  String get removeRating => 'Eliminar Puntuación';

  @override
  String get downloaded => 'Descargado';

  @override
  String downloading(int percent) {
    return 'Descargando... $percent%';
  }

  @override
  String get removeDownload => 'Eliminar la descarga';

  @override
  String get removeDownloadConfirm =>
      '¿Eliminar esta canción del almacenamiento sin conexión?';

  @override
  String get downloadRemoved => 'Descarga eliminada';

  @override
  String downloadedTitle(String title) {
    return 'Descargado \"$title\"';
  }

  @override
  String get downloadFailed => 'Descarga fallida';

  @override
  String downloadError(Object error) {
    return 'Error de descarga: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Añadido \"$title\" a $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Error al añadir a la lista: $error';
  }

  @override
  String get noPlaylists => 'No hay listas disponibles';

  @override
  String get createNewPlaylist => 'Crear Nueva Lista';

  @override
  String artistNotFound(String name) {
    return 'Artista \"$name\" no encontrado';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Error al buscar el artista: $error';
  }

  @override
  String get selectArtist => 'Seleccionar artista';

  @override
  String get removedFromFavorites => 'Eliminado de favoritos';

  @override
  String get addedToFavorites => 'Añadido a favoritos';

  @override
  String get star => 'estrella';

  @override
  String get stars => 'estrellas';

  @override
  String get albumNotFound => 'Álbum no encontrado.';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours H $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Canciones Destacadas';

  @override
  String get connected => 'Conectado';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'No se está reproduciendo ninguna canción';

  @override
  String get internetRadioUppercase => 'RADIO DE INTERNET';

  @override
  String get playingNext => 'Reproducir siguiente';

  @override
  String get createPlaylistTitle => 'Crear Lista';

  @override
  String get playlistNameHint => 'Nombre de la Lista';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Lista creada \"$name\" con esta canción';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Error al cargar lista: $error';
  }

  @override
  String get playlistNotFound => 'Lista no encontrada';

  @override
  String get noSongsInPlaylist => 'No hay canciones en esta lista';

  @override
  String get noFavoriteSongsYet => 'Aún no hay canciones favoritas';

  @override
  String get noFavoriteAlbumsYet => 'Aún no hay álbumes favoritos';

  @override
  String get listeningHistory => 'Historial de Reproducción';

  @override
  String get noListeningHistory => 'Sin Historial de Reproducción';

  @override
  String get songsWillAppearHere =>
      'Las canciones que reproduzcas aparecerán aquí';

  @override
  String get sortByArtistAZ => 'Artista (A-Z)';

  @override
  String get sortByArtistZA => 'Artista (Z-A)';

  @override
  String get sortByAlbumAZ => 'Álbum (A-Z)';

  @override
  String get sortByAlbumZA => 'Álbum (Z-A)';

  @override
  String get recentlyAdded => 'Añadido recientemente';

  @override
  String get noSongsFound => 'No se han encontrado canciones';

  @override
  String get noAlbumsFound => 'No se encontraron álbumes';

  @override
  String get noHomepageUrl => 'No hay URL de página de inicio disponible';

  @override
  String get playStation => 'Reproducir la Emisora';

  @override
  String get openHomepage => 'Abrir página de Inicio';

  @override
  String get copyStreamUrl => 'Copiar URL de la Transmisión';

  @override
  String get failedToLoadRadioStations =>
      'Error al cargar las emisoras de radio';

  @override
  String get noRadioStations => 'Sin Emisoras de Radio';

  @override
  String get noRadioStationsHint =>
      'Añade emisoras de radio en la configuración de tu servidor Navidrome para verlas aquí.';

  @override
  String get connectToServerSubtitle => 'Conectar a tu servidor de Subsonic';

  @override
  String get pleaseEnterServerUrl =>
      'Por favor, introduzca la URL del servidor';

  @override
  String get invalidUrlFormat =>
      'La dirección URL debe comenzar con http:// o https://';

  @override
  String get pleaseEnterUsername => 'Por favor, introduzca nombre de usuario';

  @override
  String get pleaseEnterPassword => 'Por favor, introduzca contraseña';

  @override
  String get legacyAuthentication => 'Autenticación heredada';

  @override
  String get legacyAuthSubtitle => 'Usar para servidores Subsonic antiguos';

  @override
  String get allowSelfSignedCerts => 'Permitir certificados autofirmados';

  @override
  String get allowSelfSignedSubtitle =>
      'Para servidores con certificados TLS/SSL personalizados';

  @override
  String get advancedOptions => 'Opciones Avanzadas';

  @override
  String get customTlsCertificate => 'Certificado TLS/SSL personalizado';

  @override
  String get customCertificateSubtitle =>
      'Subir un certificado personalizado para servidores con CA no estándar';

  @override
  String get selectCertificateFile => 'Seleccionar archivo de certificado';

  @override
  String get clientCertificate => 'Certificado de Cliente (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticar este cliente usando un certificado (requiere un servidor con mTLS)';

  @override
  String get selectClientCertificate => 'Seleccionar Certificado de Cliente';

  @override
  String get clientCertPassword => 'Certificar contraseña (opcional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'No se pudo seleccionar el certificado del cliente: $error';
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
  String get useLocalFiles => 'Usar Archivos Locales';

  @override
  String get startingScan => 'Iniciando escaneo...';

  @override
  String get storagePermissionRequired =>
      'Permiso de almacenamiento necesario para escanear archivos locales';

  @override
  String get noMusicFilesFound =>
      'No se han encontrado archivos de música en tu dispositivo';

  @override
  String get remove => 'Eliminar';

  @override
  String failedToSetRating(Object error) {
    return 'Error al establecer la valoración: $error';
  }

  @override
  String get home => 'Inicio';

  @override
  String get playlistsSection => 'LISTAS';

  @override
  String get collapse => 'Contraer';

  @override
  String get expand => 'Expandir';

  @override
  String get createPlaylist => 'Crear Lista';

  @override
  String get likedSongsSidebar => 'Canciones que te gustan';

  @override
  String playlistSongsCount(int count) {
    return 'Lista • $count canciones';
  }

  @override
  String get failedToLoadLyrics => 'No se pudo cargar la letra';

  @override
  String get lyricsNotFoundSubtitle =>
      'No se pudo encontrar la letra de esta canción';

  @override
  String get backToCurrent => 'Volver a la actual';

  @override
  String get exitFullscreen => 'Salir de pantalla completa';

  @override
  String get fullscreen => 'Pantalla Completa';

  @override
  String get noLyrics => 'Sin letra';

  @override
  String get internetRadioMiniPlayer => 'Radio de Internet';

  @override
  String get liveBadge => 'EN DIRECTO';

  @override
  String get localFilesModeBanner => 'Modo archivos locales';

  @override
  String get offlineModeBanner =>
      'Modo sin conexión - Reproduciendo solo música descargada';

  @override
  String get updateAvailable => 'Actualización Disponible';

  @override
  String get updateAvailableSubtitle =>
      '¡Una nueva versión de Luobo está disponible!';

  @override
  String updateCurrentVersion(String version) {
    return 'Versión actual: $version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Última versión: $version';
  }

  @override
  String get whatsNew => 'Novedades';

  @override
  String get downloadUpdate => 'Descargar';

  @override
  String get remindLater => 'Más tarde';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get artistDataNotFound => 'Artista no encontrado';

  @override
  String get addedArtistToQueue => 'Artista añadido a la cola';

  @override
  String get addedArtistToQueueError => 'Error al añadir artista a la cola';

  @override
  String get casting => 'Casting';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Casting / DL';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get searchingDevices => 'Buscando dispositivos';

  @override
  String get castWifiHint =>
      'Asegúrate de que tu dispositivo Cast / DLNA\nesté en la misma red Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Conectado a \$$name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'No se pudo conectar a $name';
  }

  @override
  String get removedFromLikedSongs => 'Eliminado de Canciones que te gustan';

  @override
  String get addedToLikedSongs => 'Añadido a Canciones que te gustan';

  @override
  String get enableShuffle => 'Activar aleatorio';

  @override
  String get enableRepeat => 'Activar repetición';

  @override
  String get closeLyrics => 'Cerrar Letra';

  @override
  String errorStartingDownload(Object error) {
    return 'Error al iniciar la descarga: $error';
  }

  @override
  String get errorLoadingGenres => 'Error al cargar géneros';

  @override
  String get noGenresFound => 'No se encontraron géneros';

  @override
  String get noAlbumsInGenre => 'No hay álbumes en este género';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount canciones • $albumCount  ábumes';
  }

  @override
  String get musicFoldersDialogTitle => 'Seleccionar Carpetas de Música';

  @override
  String get musicFoldersHint =>
      'Deja todo activado para usar todas las carpetas (predeterminado).';

  @override
  String get musicFoldersSaved => 'Selección de carpeta de música guardada';

  @override
  String get artworkStyleSection => 'Estilo de Carátula';

  @override
  String get artworkCornerRadius => 'Radio de Esquinas';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Ajusta cómo aparecen las esquinas de las portadas del álbum';

  @override
  String get artworkCornerRadiusNone => 'Ninguna';

  @override
  String get artworkShape => 'Forma';

  @override
  String get artworkShapeRounded => 'Redondeado';

  @override
  String get artworkShapeCircle => 'Círculo';

  @override
  String get artworkShapeSquare => 'Cuadrado';

  @override
  String get artworkShadow => 'Sombra';

  @override
  String get artworkShadowNone => 'Ninguna';

  @override
  String get artworkShadowSoft => 'Suave';

  @override
  String get artworkShadowMedium => 'Medio';

  @override
  String get artworkShadowStrong => 'Fuerte';

  @override
  String get artworkShadowColor => 'Color de la sombra';

  @override
  String get artworkShadowColorBlack => 'Negra';

  @override
  String get artworkShadowColorAccent => 'Acento';

  @override
  String get artworkPreview => 'Vista previa';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Sin carátula';

  @override
  String get serverUnreachableTitle => 'No se puede acceder al servidor';

  @override
  String get serverUnreachableSubtitle =>
      'Compruebe su conexión o configuración del servidor.';

  @override
  String get openOfflineMode => 'Abrir en modo sin conexión';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Color acentuado';

  @override
  String get circularDesignLabel => 'Diseño circular';

  @override
  String get circularDesignSubtitle =>
      'Interfaz flotante y redondeada con paneles translúcidos y efecto desenfoque de cristal en el reproductor y la barra de navegación.';

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
  String get themeModeDark => 'Oscuro';

  @override
  String get liveLabel => 'EN DIRECTO';

  @override
  String get discordStatusText => 'Texto de estado de Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Segunda línea mostrada en la actividad de Discord';

  @override
  String get discordRpcStyleArtist => 'Nombre del artista';

  @override
  String get discordRpcStyleSong => 'Título de canción';

  @override
  String get discordRpcStyleApp => 'Nombre de la aplicación (Luobo)';

  @override
  String get sectionVolumeNormalization =>
      'NORMALIZACIÓN DE VOLUMEN (REPLAYGAIN)';

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
  String get replayGainModeOff => 'Desactivado';

  @override
  String get replayGainModeTrack => 'Pista';

  @override
  String get replayGainModeAlbum => 'Álbum';

  @override
  String replayGainPreamp(String value) {
    return 'Preamplificador: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Evitar recorte';

  @override
  String replayGainFallbackGain(String value) {
    return 'Ganancia de reserva: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Canciones a añadir: $count';
  }

  @override
  String get transcodingEnable => 'Habilitar Transcodificación';

  @override
  String get transcodingEnableSubtitle =>
      'Reducir el uso de datos con menor calidad';

  @override
  String get smartTranscoding => 'Transcodificación Inteligente';

  @override
  String get smartTranscodingSubtitle =>
      'Ajusta automáticamente la calidad en función de tu conexión (WiFi vs datos móviles)';

  @override
  String get smartTranscodingDetectedNetwork => 'Red detectada: ';

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
  String get transcodingWifiQuality => 'Calidad WiFi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Utilizado automáticamente con WiFi';

  @override
  String get transcodingMobileQuality => 'Calidad Móvil';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Utilizado automáticamente en datos móviles';

  @override
  String get transcodingFormat => 'Formato';

  @override
  String get transcodingFormatSubtitle =>
      'Códec de audio usado para la transmisión';

  @override
  String get transcodingBitrateOriginal => 'Original (Sin Transcodificación)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Caché de imagen';

  @override
  String get imageCacheSubtitle => 'Guardar carátulas de álbumes localmente';

  @override
  String get musicCacheTitle => 'Caché de Música';

  @override
  String get musicCacheSubtitle => 'Guardar metadatos de la canción localmente';

  @override
  String get bpmCacheTitle => 'Caché de BPM';

  @override
  String get bpmCacheSubtitle => 'Guardar el análisis de BPM localmente';

  @override
  String get sectionAboutInformation => 'INFORMACIÓN';

  @override
  String get sectionAboutDeveloper => 'DESARROLLADOR';

  @override
  String get sectionAboutLinks => 'ENLACES';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutPlatform => 'Plataforma';

  @override
  String get aboutMadeBy => 'Hecho por chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'Repositorio de GitHub';

  @override
  String get aboutLinkChangelog => 'Historial de actualizaciones';

  @override
  String get aboutLinkReportIssue => 'Reportar problema';

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
