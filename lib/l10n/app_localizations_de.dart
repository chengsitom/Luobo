// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Nachmittag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get forYou => 'Für dich';

  @override
  String get quickPicks => 'Quick Picks';

  @override
  String get discoverMix => 'Neues entdecken';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Zuletzt abgespielt';

  @override
  String get yourPlaylists => 'Deine Playlisten';

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
  String get madeForYou => 'Für dich gemacht';

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
  String get topRated => 'Am besten bewertet';

  @override
  String get noContentAvailable => 'Kein Inhalt verfügbar';

  @override
  String get tryRefreshing =>
      'Versuche es nochmal oder überprüfe die Serververbindung';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs =>
      'Beim Laden der Songs ist ein Fehler aufgetreten';

  @override
  String get noSongsInGenre => 'Keine Songs in diesem Genre verfügbar';

  @override
  String get errorLoadingAlbums =>
      'Beim Laden der Alben ist ein Fehler aufgetreten';

  @override
  String get noTopRatedAlbums => 'Keine bewerteten Alben verfügbar';

  @override
  String get login => 'Anmelden';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get selectCertificate => 'TLS/SSL Zertifikat auswählen';

  @override
  String failedToSelectCertificate(String error) {
    return 'Beim Auswählen des Zertifikates ist ein Fehler aufgetreten: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'Die Server URL muss mit http:// oder https:// starten';

  @override
  String get failedToConnect => 'Verbindungsaufbau fehlgeschlagen';

  @override
  String get library => 'Bibliothek';

  @override
  String get search => 'Suchen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get albums => 'Alben';

  @override
  String get artists => 'Künstler*innen';

  @override
  String get songs => 'Songs';

  @override
  String get playlists => 'Playlisten';

  @override
  String get genres => 'Genres';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoriten';

  @override
  String get nowPlaying => 'Jetzt spielt';

  @override
  String get queue => 'Warteschlange';

  @override
  String get lyrics => 'Songtext';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Nächster';

  @override
  String get previous => 'Vorheriger';

  @override
  String get shuffle => 'Mischen';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get repeatOne => 'Einmal wiederholen';

  @override
  String get repeatOff => 'Nicht wiederholen';

  @override
  String get addToPlaylist => 'Zur Playliste hinzufügen';

  @override
  String get removeFromPlaylist => 'Von der Playliste entfernen';

  @override
  String get addToFavorites => 'Zu den Favoriten hinzufügen';

  @override
  String get removeFromFavorites => 'Von den Favoriten entfernen';

  @override
  String get download => 'Herunterladen';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'Ok';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get general => 'Allgemein';

  @override
  String get appearance => 'Aussehen';

  @override
  String get playback => 'Wiedergabe';

  @override
  String get storage => 'Speicher';

  @override
  String get about => 'Über';

  @override
  String get darkMode => 'Dunkel-Modus';

  @override
  String get language => 'Sprache';

  @override
  String get version => 'Version';

  @override
  String get githubRepository => 'GitHub Bibliothek';

  @override
  String get reportIssue => 'Problem melden';

  @override
  String get unknownArtist => 'Unbekannte*r Künstler*in';

  @override
  String get unknownAlbum => 'Unbekanntes Album';

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get shuffleAll => 'Alle mischen';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByArtist => 'Künstler*in';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Datum';

  @override
  String get sortByDuration => 'Dauer';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get descending => 'Absteigend';

  @override
  String get noLyricsAvailable => 'Keine Songtexte verfügbar';

  @override
  String get loading => 'Lädt...';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get searchHint => 'Suche nach Songs, Alben, Künstler*innen...';

  @override
  String get allSongs => 'Alle Songs';

  @override
  String get allAlbums => 'Alle Alben';

  @override
  String get allArtists => 'Alle Künstler*innen';

  @override
  String trackNumber(int number) {
    return 'Titel $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
      zero: 'Keine Songs',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
      zero: 'Keine Alben',
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
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Bist du sicher, dass du dich abmelden möchtest?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get offlineMode => 'Offline-Modus';

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
  String get changelog => 'Änderungsprotokoll';

  @override
  String get platform => 'Plattform';

  @override
  String get server => 'Server';

  @override
  String get display => 'Display';

  @override
  String get playerInterface => 'Player-Oberfläche';

  @override
  String get smartRecommendations => 'Smarte Empfehlungen';

  @override
  String get showVolumeSlider => 'Zeige Lautstärkeregler';

  @override
  String get showVolumeSliderSubtitle =>
      'Lautstärkeregler in Wiedergabebildschirm anzeigen';

  @override
  String get showStarRatings => 'Sternbewertungen anzeigen';

  @override
  String get showStarRatingsSubtitle => 'Bewerte Songs und sehe Bewertungen an';

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
  String get enableRecommendations => 'Empfehlungen aktivieren';

  @override
  String get enableRecommendationsSubtitle =>
      'Erhalte personalisierte Musikvorschläge';

  @override
  String get listeningData => 'Hördaten';

  @override
  String totalPlays(int count) {
    return '$count Plays insgesamt';
  }

  @override
  String get clearListeningHistory => 'Hörverlauf löschen';

  @override
  String get confirmClearHistory =>
      'Dies wird all deine Hördaten und Empfehlungen zurücksetzen. Bist du sicher?';

  @override
  String get historyCleared => 'Hörverlauf gelöscht';

  @override
  String get discordStatus => 'Discord Status';

  @override
  String get discordStatusSubtitle =>
      'Spielenden Song in Discord Profil anzeigen';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get systemDefault => 'Standardeinstellung';

  @override
  String get yourLibrary => 'Deine Bibliothek';

  @override
  String get filterAll => 'Alle';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Playlisten';

  @override
  String get filterAlbums => 'Alben';

  @override
  String get filterArtists => 'Künstler';

  @override
  String get likedSongs => 'Lieblingssongs';

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
  String get radioStations => 'Radiosender';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Internetradio';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get playlistName => 'Name der Playlist';

  @override
  String get create => 'Erstellen';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Bist du sicher, dass du die Playlist \"$name \" löschen möchtest?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" gelöscht';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Fehler beim Erstellen der Playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Fehler beim Löschen der Playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" erstellt';
  }

  @override
  String get searchTitle => 'Suche';

  @override
  String get searchPlaceholder => 'Künstler, Songs, Alben';

  @override
  String get tryDifferentSearch => 'Versuche es mit einer anderen Suchanfrage';

  @override
  String get noSuggestions => 'Keine Empfehlungen';

  @override
  String get browseCategories => 'Kategorien durchstöbern';

  @override
  String get liveSearchSection => 'Suche';

  @override
  String get liveSearch => 'Live Search';

  @override
  String get liveSearchSubtitle =>
      'Update results as you type instead of showing a dropdown';

  @override
  String get categoryMadeForYou => 'Für dich';

  @override
  String get categoryNewReleases => 'Neuerscheinungen';

  @override
  String get categoryTopRated => 'Top bewertet';

  @override
  String get categoryGenres => 'Genres';

  @override
  String get categoryFavorites => 'Favoriten';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get tabPlayback => 'Wiedergabe';

  @override
  String get tabStorage => 'Speicher';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Anzeige';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Über';

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
  String get autoDjMode => 'Auto DJ-Modus';

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
    return 'Zu hinzufügende Songs: $count';
  }

  @override
  String get sectionReplayGain => 'LAUTSTÄRKE NORMALISIEREN ';

  @override
  String get replayGainMode => 'Modus';

  @override
  String preamp(String value) {
    return 'Vorverstärker: $value dB';
  }

  @override
  String get preventClipping => 'Clipping verhindern';

  @override
  String fallbackGain(String value) {
    return 'Fallback-Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'STREAMING QUALITÄT';

  @override
  String get enableTranscoding => 'Transkodierung aktivieren';

  @override
  String get qualityWifi => 'Qualität im Wlan';

  @override
  String get qualityMobile => 'Qualität bei Mobilen Daten';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle =>
      'Datenverbrauch mit niedrigerer Qualität reduzieren';

  @override
  String get modeOff => 'Aus';

  @override
  String get modeTrack => 'Titel';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'SERVERVERBINDUNG';

  @override
  String get serverType => 'Servertyp';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get sectionMusicFolders => 'MUSIK ORDNER';

  @override
  String get musicFolders => 'Musik Ordner';

  @override
  String get noMusicFolders => 'Keine Musik Ordner gefunden';

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
  String get sectionAccount => 'KONTO';

  @override
  String get logoutConfirmation =>
      'Bist du sicher, dass du dich abmelden möchten? Dies wird alle Daten im Cache löschen.';

  @override
  String get sectionCacheSettings => 'CACHE-EINSTELLUNGEN';

  @override
  String get imageCache => 'Bilder Cache';

  @override
  String get musicCache => 'Musik Cache';

  @override
  String get bpmCache => 'BPM Cache';

  @override
  String get saveAlbumCovers => 'Albumcover lokal speichern';

  @override
  String get saveSongMetadata => 'Song Metadaten lokal speichern';

  @override
  String get saveBpmAnalysis => 'BPM Analyse lokal speichern';

  @override
  String get sectionCacheCleanup => 'CACHE LÖSCHEN';

  @override
  String get clearAllCache => 'Alle Caches löschen';

  @override
  String get allCacheCleared => 'Alle Caches gelöscht';

  @override
  String get sectionOfflineDownloads => 'OFFLINE DOWNLOADS';

  @override
  String get downloadedSongs => 'Heruntergeladene Songs';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Lade Bibliothek herunter... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Gesamte Bibliothek herunterladen';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Dies wird $count Lieder auf dein Gerät herunterladen. Dies kann eine Weile dauern und viel Speicherplatz nutzen.\n\nFortfahren?';
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
  String get libraryDownloadStarted => 'Herunterladen der Bibliothek gestartet';

  @override
  String get deleteDownloads => 'Alle Downloads löschen';

  @override
  String get downloadsDeleted => 'Alle Downloads gelöscht';

  @override
  String get noSongsAvailable =>
      'Keine Songs verfügbar. Bitte laden zuerst deine Bibliothek.';

  @override
  String get sectionBpmAnalysis => 'BPM ANALYSE';

  @override
  String get cachedBpms => 'BPMs im Cache';

  @override
  String get cacheAllBpms => 'Alle BPMs im Cache speichern';

  @override
  String get clearBpmCache => 'BPM Cache leeren';

  @override
  String get bpmCacheCleared => 'BPM Cache gelöscht';

  @override
  String downloadedStats(int count, String size) {
    return '$count Songs • $size';
  }

  @override
  String get sectionInformation => 'INFORMATIONEN';

  @override
  String get sectionDeveloper => 'ENTWICKLER';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'GitHub';

  @override
  String get playingFrom => 'WIEDERGABE AUS';

  @override
  String get live => 'LIVE';

  @override
  String get streamingLive => 'Live Streaming';

  @override
  String get stopRadio => 'Radio stoppen';

  @override
  String get removeFromLiked => 'Aus Lieblingssongs entfernen';

  @override
  String get addToLiked => 'Zu Lieblingssongs hinzufügen';

  @override
  String get playNext => 'Als Nächstes wiedergeben';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get goToAlbum => 'Zum Album';

  @override
  String get goToArtist => 'Zum Künstler';

  @override
  String get rateSong => 'Song bewerten';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Song bewerten ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Bewertung entfernt';

  @override
  String rated(int rating, String stars) {
    return 'Bewertet $rating $stars';
  }

  @override
  String get removeRating => 'Bewertung entfernen';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String downloading(int percent) {
    return 'Herunterladen... $percent%';
  }

  @override
  String get removeDownload => 'Download entfernen';

  @override
  String get removeDownloadConfirm =>
      'Diesen Song aus dem Offline Speicher löschen?';

  @override
  String get downloadRemoved => 'Download entfernt';

  @override
  String downloadedTitle(String title) {
    return '\"$title \" heruntergeladen';
  }

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String downloadError(Object error) {
    return 'Download-Fehler: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return '\"$title\" zu $playlist hinzugefügt';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Fehler beim Hinzufügen zur Playlist: $error';
  }

  @override
  String get noPlaylists => 'Keine Playlists verfügbar';

  @override
  String get createNewPlaylist => 'Neue Playlist erstellen';

  @override
  String artistNotFound(String name) {
    return 'Künstler \"$name\" nicht gefunden';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Fehler bei der Suche nach Künstler: $error';
  }

  @override
  String get selectArtist => 'Künstler auswählen';

  @override
  String get removedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get addedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get star => 'Stern';

  @override
  String get stars => 'Sterne';

  @override
  String get albumNotFound => 'Album nicht gefunden';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Top Songs';

  @override
  String get connected => 'Verbunden';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'Kein Song spielt';

  @override
  String get internetRadioUppercase => 'INTERNET RADIO';

  @override
  String get playingNext => 'Nächste Wiedergabe';

  @override
  String get createPlaylistTitle => 'Playlist erstellen';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist \"$name\" mit diesem Song erstellt';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Fehler beim Laden der Playlists: $error';
  }

  @override
  String get playlistNotFound => 'Playlist nicht gefunden';

  @override
  String get noSongsInPlaylist => 'Keine Songs in dieser Playlist';

  @override
  String get noFavoriteSongsYet => 'Noch keine Lieblingslieder';

  @override
  String get noFavoriteAlbumsYet => 'Noch keine Lieblingsalben';

  @override
  String get listeningHistory => 'Hörverlauf';

  @override
  String get noListeningHistory => 'Kein Hörverlauf';

  @override
  String get songsWillAppearHere =>
      'Songs, die du spielst, werden hier angezeigt';

  @override
  String get sortByArtistAZ => 'Künstler (A-Z)';

  @override
  String get sortByArtistZA => 'Künstler (A-Z)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (A-Z)';

  @override
  String get recentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get noSongsFound => 'Keine Songs gefunden';

  @override
  String get noAlbumsFound => 'Keine Alben gefunden';

  @override
  String get noHomepageUrl => 'Keine Homepage-URL verfügbar';

  @override
  String get playStation => 'Sender abspielen';

  @override
  String get openHomepage => 'Öffne Homepage';

  @override
  String get copyStreamUrl => 'Stream-URL kopieren';

  @override
  String get failedToLoadRadioStations => 'Fehler beim Laden der Radiosender';

  @override
  String get noRadioStations => 'Keine Radiosender';

  @override
  String get noRadioStationsHint =>
      'Füge Radiosender in den Navidrome Server-Einstellungen ein, um sie hier zu sehen.';

  @override
  String get connectToServerSubtitle =>
      'Verbinde dich mit deinem Subsonic-Server';

  @override
  String get pleaseEnterServerUrl => 'Bitte Server-URL eingeben';

  @override
  String get invalidUrlFormat =>
      'Die URL muss mit http:// oder https:// beginnen';

  @override
  String get pleaseEnterUsername => 'Bitte Benutzername eingeben';

  @override
  String get pleaseEnterPassword => 'Bitte Passwort eingeben';

  @override
  String get legacyAuthentication => 'Legacy Authentifizierung';

  @override
  String get legacyAuthSubtitle => 'Für ältere Subsonic-Server';

  @override
  String get allowSelfSignedCerts => 'Selbstsignierte Zertifikate zulassen';

  @override
  String get allowSelfSignedSubtitle =>
      'Für Server mit benutzerdefinierten TLS/SSL-Zertifikat';

  @override
  String get advancedOptions => 'Erweiterte Einstellungen';

  @override
  String get customTlsCertificate => 'Benutzerdefiniertes TLS/SSL-Zertifikat';

  @override
  String get customCertificateSubtitle =>
      'Ein benutzerdefiniertes Zertifikat für Server mit nicht standardmäßiger CA hochladen';

  @override
  String get selectCertificateFile => 'Zertifikatsdatei auswählen';

  @override
  String get clientCertificate => 'Client Zertifikat (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Authentifiziere diesen Client mit einem Zertifikat (benötigt mTLS-fähigen Server)';

  @override
  String get selectClientCertificate => 'Client Zertifikat auswählen';

  @override
  String get clientCertPassword => 'Zertifikatspasswort (optional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Beim Auswählen des Zertifikates ist ein Fehler aufgetreten: $error';
  }

  @override
  String get connect => 'Verbinden';

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
  String get or => 'ODER';

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
  String get useLocalFiles => 'Lokale Dateien verwenden';

  @override
  String get startingScan => 'Scan wird gestartet ...';

  @override
  String get storagePermissionRequired =>
      'Speicherberechtigung erforderlich, um lokale Dateien zu scannen';

  @override
  String get noMusicFilesFound => 'Keine Songdateien auf Ihrem Gerät gefunden';

  @override
  String get remove => 'Entfernen';

  @override
  String failedToSetRating(Object error) {
    return 'Fehler bei der Bewertung: $error';
  }

  @override
  String get home => 'Startseite';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Einklappen';

  @override
  String get expand => 'erweitern';

  @override
  String get createPlaylist => 'Playlist erstellen';

  @override
  String get likedSongsSidebar => 'Lieblingssongs';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count Songs';
  }

  @override
  String get failedToLoadLyrics => 'Fehler beim Laden der Lyrics';

  @override
  String get lyricsNotFoundSubtitle =>
      'Songtext für diesen Song konnte nicht gefunden werden';

  @override
  String get backToCurrent => 'Zurück zum aktuellen';

  @override
  String get exitFullscreen => 'Vollbild verlassen';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get noLyrics => 'Kein Songtext';

  @override
  String get internetRadioMiniPlayer => 'Internetradio';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get localFilesModeBanner => 'Lokale Dateien Modus';

  @override
  String get offlineModeBanner =>
      'Offline-Modus - Nur heruntergeladene Songs abspielen';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateAvailableSubtitle =>
      'Eine neue Version von Luobo ist verfügbar!';

  @override
  String updateCurrentVersion(String version) {
    return 'Aktuell: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Neueste: $version';
  }

  @override
  String get whatsNew => 'Neuigkeiten';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get remindLater => 'Später';

  @override
  String get seeAll => 'Alle ansehen';

  @override
  String get artistDataNotFound => 'Künstler nicht gefunden';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'Übertragen';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Übertragen/DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Verbindung trennen';

  @override
  String get searchingDevices => 'Suche nach Geräten';

  @override
  String get castWifiHint =>
      'Stelle sicher, dass sich dein Cast / DLNA Gerät\nim selben Wi-Fi-Netzwerk befindet';

  @override
  String connectedToDevice(String name) {
    return 'Verbunden mit $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Verbindung zu $name fehlgeschlagen';
  }

  @override
  String get removedFromLikedSongs => 'Aus Lieblingssongs entfernen';

  @override
  String get addedToLikedSongs => 'Zu Lieblingssongs hinzufügen';

  @override
  String get enableShuffle => 'Shuffle aktivieren';

  @override
  String get enableRepeat => 'Wiederholung aktivieren';

  @override
  String get closeLyrics => 'Songtext schließen';

  @override
  String errorStartingDownload(Object error) {
    return 'Fehler beim Starten des Downloads: $error';
  }

  @override
  String get errorLoadingGenres => 'Fehler beim Laden des Genres';

  @override
  String get noGenresFound => 'Kein Genre gefunden';

  @override
  String get noAlbumsInGenre => 'Kein Album in diesem Genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount songs • $albumCount albums';
  }

  @override
  String get musicFoldersDialogTitle => 'Select Music Folders';

  @override
  String get musicFoldersHint =>
      'Leave all enabled to use all folders (default).';

  @override
  String get musicFoldersSaved => 'Music folder selection saved';

  @override
  String get artworkStyleSection => 'Artwork Style';

  @override
  String get artworkCornerRadius => 'Corner Radius';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Adjust how round the corners of album covers appear';

  @override
  String get artworkCornerRadiusNone => 'None';

  @override
  String get artworkShape => 'Shape';

  @override
  String get artworkShapeRounded => 'Rounded';

  @override
  String get artworkShapeCircle => 'Circle';

  @override
  String get artworkShapeSquare => 'Square';

  @override
  String get artworkShadow => 'Shadow';

  @override
  String get artworkShadowNone => 'None';

  @override
  String get artworkShadowSoft => 'Soft';

  @override
  String get artworkShadowMedium => 'Medium';

  @override
  String get artworkShadowStrong => 'Strong';

  @override
  String get artworkShadowColor => 'Shadow Color';

  @override
  String get artworkShadowColorBlack => 'Black';

  @override
  String get artworkShadowColorAccent => 'Accent';

  @override
  String get artworkPreview => 'Vorschau';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'No artwork';

  @override
  String get serverUnreachableTitle => 'Server nicht erreichbar';

  @override
  String get serverUnreachableSubtitle =>
      'Check your connection or server settings.';

  @override
  String get openOfflineMode => 'Open in offline mode';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get circularDesignLabel => 'Circular Design';

  @override
  String get circularDesignSubtitle =>
      'Floating, rounded UI with translucent panels and glass-blur effect on the player and navigation bar.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get clearAppCache => 'Clear App Cache';

  @override
  String get appearanceGlassHint =>
      'Glass and card styling is defined by the design system and is not user-adjustable.';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Discord status text';

  @override
  String get discordStatusTextSubtitle =>
      'Second line shown in Discord activity';

  @override
  String get discordRpcStyleArtist => 'Artist name';

  @override
  String get discordRpcStyleSong => 'Song title';

  @override
  String get discordRpcStyleApp => 'App name (Luobo)';

  @override
  String get sectionVolumeNormalization => 'VOLUME NORMALIZATION (REPLAYGAIN)';

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
  String get replayGainModeTrack => 'Track';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Prevent Clipping';

  @override
  String replayGainFallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Songs to Add: $count';
  }

  @override
  String get transcodingEnable => 'Enable Transcoding';

  @override
  String get transcodingEnableSubtitle =>
      'Reduce data usage with lower quality';

  @override
  String get smartTranscoding => 'Smart Transcoding';

  @override
  String get smartTranscodingSubtitle =>
      'Automatically adjusts quality based on your connection (WiFi vs mobile data)';

  @override
  String get smartTranscodingDetectedNetwork => 'Detected network: ';

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
  String get transcodingWifiQuality => 'WiFi Quality';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Used automatically on WiFi';

  @override
  String get transcodingMobileQuality => 'Mobile Quality';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Used automatically on cellular data';

  @override
  String get transcodingFormat => 'Format';

  @override
  String get transcodingFormatSubtitle => 'Audio codec used for streaming';

  @override
  String get transcodingBitrateOriginal => 'Original (No Transcoding)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Image Cache';

  @override
  String get imageCacheSubtitle => 'Save album covers locally';

  @override
  String get musicCacheTitle => 'Music Cache';

  @override
  String get musicCacheSubtitle => 'Save song metadata locally';

  @override
  String get bpmCacheTitle => 'BPM Cache';

  @override
  String get bpmCacheSubtitle => 'Save BPM analysis locally';

  @override
  String get sectionAboutInformation => 'INFORMATION';

  @override
  String get sectionAboutDeveloper => 'DEVELOPER';

  @override
  String get sectionAboutLinks => 'LINKS';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPlatform => 'Platform';

  @override
  String get aboutMadeBy => 'Made by chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'GitHub Repository';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Report Issue';

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
  String get connecting => 'Verbinde';

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
  String get edit => 'Bearbeiten';

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
