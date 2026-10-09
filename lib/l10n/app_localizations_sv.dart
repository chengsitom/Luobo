// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'God morgon';

  @override
  String get goodAfternoon => 'God eftermiddag';

  @override
  String get goodEvening => 'God kväll';

  @override
  String get forYou => 'För Dig';

  @override
  String get quickPicks => 'Snabba Val';

  @override
  String get discoverMix => 'Discover Mix';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Nyligen spelade';

  @override
  String get yourPlaylists => 'Dina Spellistor';

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
  String get madeForYou => 'Skapat För Dig';

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
  String get topRated => 'Top Rated';

  @override
  String get noContentAvailable => 'Inget innehåll tillgängligt';

  @override
  String get tryRefreshing =>
      'Försök ladda om eller kontrollera din servers anslutning';

  @override
  String get refresh => 'Ladda om';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs => 'Fel vid laddning av låtar';

  @override
  String get noSongsInGenre => 'Inga låtar i detta genre';

  @override
  String get errorLoadingAlbums => 'Fel vid laddning av album';

  @override
  String get noTopRatedAlbums => 'Inga högst rankade album';

  @override
  String get login => 'Logga in';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Användarnamn';

  @override
  String get password => 'Lösenord';

  @override
  String get selectCertificate => 'Välj TLS/SSL Certifikat';

  @override
  String failedToSelectCertificate(String error) {
    return 'Misslyckades välja certifikat: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'Server URL måste starta med http:// eller https://';

  @override
  String get failedToConnect => 'Misslyckades ansluta';

  @override
  String get library => 'Bibliotek';

  @override
  String get search => 'Sök';

  @override
  String get settings => 'Inställningar';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artister';

  @override
  String get songs => 'Låtar';

  @override
  String get playlists => 'Spellistor';

  @override
  String get genres => 'Genrer';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoriter';

  @override
  String get nowPlaying => 'Spelas Nu';

  @override
  String get queue => 'Kö';

  @override
  String get lyrics => 'Låttext';

  @override
  String get play => 'Spela';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Nästa';

  @override
  String get previous => 'Förra';

  @override
  String get shuffle => 'Blanda';

  @override
  String get repeat => 'Upprepa';

  @override
  String get repeatOne => 'Upprepa en gång';

  @override
  String get repeatOff => 'Upprepning av';

  @override
  String get addToPlaylist => 'Lägg till Spellista';

  @override
  String get removeFromPlaylist => 'Ta bort från Spellista';

  @override
  String get addToFavorites => 'Lägg till Favoriter';

  @override
  String get removeFromFavorites => 'Ta bort från Favoriter';

  @override
  String get download => 'Ladda ner';

  @override
  String get delete => 'Ta bort';

  @override
  String get cancel => 'Avbryt';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Spara';

  @override
  String get close => 'Stäng';

  @override
  String get general => 'Allmän';

  @override
  String get appearance => 'Utseende';

  @override
  String get playback => 'Uppspelning';

  @override
  String get storage => 'Lagring';

  @override
  String get about => 'Om';

  @override
  String get darkMode => 'Mörkt Läge';

  @override
  String get language => 'Språk';

  @override
  String get version => 'Version';

  @override
  String get githubRepository => 'Github Repository';

  @override
  String get reportIssue => 'Rapportera Problem';

  @override
  String get unknownArtist => 'Okänd Artist';

  @override
  String get unknownAlbum => 'Okänt Album';

  @override
  String get playAll => 'Spela Alla';

  @override
  String get shuffleAll => 'Blanda Alla';

  @override
  String get sortBy => 'Sortera efter';

  @override
  String get sortByName => 'Namn';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Datum';

  @override
  String get sortByDuration => 'Längd';

  @override
  String get ascending => 'Stigande ordning';

  @override
  String get descending => 'Fallande ordning';

  @override
  String get noLyricsAvailable => 'Ingen låttext tillgänglig';

  @override
  String get loading => 'Laddar...';

  @override
  String get error => 'Fel';

  @override
  String get retry => 'Försök igen';

  @override
  String get noResults => 'Inga resultat';

  @override
  String get searchHint => 'Sök efter låt, album, artist...';

  @override
  String get allSongs => 'Alla Låtar';

  @override
  String get allAlbums => 'Alla Album';

  @override
  String get allArtists => 'Alla Artister';

  @override
  String trackNumber(int number) {
    return 'Låt $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count låtar',
      one: '1 låt',
      zero: 'Inga låtar',
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
      zero: 'Inga album',
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
  String get logout => 'Logga ut';

  @override
  String get confirmLogout => 'Är du säker på att du vill logga ut?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nej';

  @override
  String get offlineMode => 'Offline Läge';

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
  String get changelog => 'Ändringslogg';

  @override
  String get platform => 'Plattform';

  @override
  String get server => 'Server';

  @override
  String get display => 'Display';

  @override
  String get playerInterface => 'Spelargränsnitt';

  @override
  String get smartRecommendations => 'Smarta Rekommendationer';

  @override
  String get showVolumeSlider => 'Visa Volym Slider';

  @override
  String get showVolumeSliderSubtitle =>
      'Visa volymkontroll i Spelas Nu skärmen';

  @override
  String get showStarRatings => 'Visa Stjärnbetyg';

  @override
  String get showStarRatingsSubtitle => 'Betygsätt låtar och visa betyg';

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
  String get enableRecommendations => 'Aktivera Rekommendationer';

  @override
  String get enableRecommendationsSubtitle => 'Få personliga musikförslag';

  @override
  String get listeningData => 'Lyssningsdata';

  @override
  String totalPlays(int count) {
    return '$count uppspelningar';
  }

  @override
  String get clearListeningHistory => 'Rensa lyssningshistorik';

  @override
  String get confirmClearHistory =>
      'Detta kommer nollställa all din lyssningsdata och rekommendationer. Är du säker?';

  @override
  String get historyCleared => 'Lyssningshistorik rensad';

  @override
  String get discordStatus => 'Discord Status';

  @override
  String get discordStatusSubtitle => 'Visa låt som spelas på Discord profil';

  @override
  String get selectLanguage => 'Välj Språk';

  @override
  String get systemDefault => 'Systemets Standard';

  @override
  String get yourLibrary => 'Ditt Bibliotek';

  @override
  String get filterAll => 'Alla';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Spellistor';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterArtists => 'Artister';

  @override
  String get likedSongs => 'Gillade Låtar';

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
  String get radioStations => 'Radio Stationer';

  @override
  String get playlist => 'Spellista';

  @override
  String get internetRadio => 'Internet Radio';

  @override
  String get newPlaylist => 'Ny Spellista';

  @override
  String get playlistName => 'Spellistans Namn';

  @override
  String get create => 'Skapa';

  @override
  String get deletePlaylist => 'Ta bort Spellista';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Är du säker på att du vill ta port spellistan \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Spellista \"$name\" borttagen';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Fel uppstod vid skapandet av spellista: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Fel uppstod vid borttagning av spellista: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Spellista \"$name\" skapad';
  }

  @override
  String get searchTitle => 'Sök';

  @override
  String get searchPlaceholder => 'Artister, Låtar, Album';

  @override
  String get tryDifferentSearch => 'Försök söka någonting annat';

  @override
  String get noSuggestions => 'Inga förslag';

  @override
  String get browseCategories => 'Bläddra Kategorier';

  @override
  String get liveSearchSection => 'Sök';

  @override
  String get liveSearch => 'Livesökning';

  @override
  String get liveSearchSubtitle =>
      'Uppdatera resultat medan du skriver istället för att visa en lista';

  @override
  String get categoryMadeForYou => 'Skapad För Dig';

  @override
  String get categoryNewReleases => 'Nytt Släpp';

  @override
  String get categoryTopRated => 'Högst rankade';

  @override
  String get categoryGenres => 'Genrer';

  @override
  String get categoryFavorites => 'Favoriter';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get tabPlayback => 'Uppspelning';

  @override
  String get tabStorage => 'Lagring';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Display';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Om';

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
  String get autoDjMode => 'Auto DJ läge';

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
    return 'Låtar att lägga till: $count';
  }

  @override
  String get sectionReplayGain => 'VOLYM NORMALISERING (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Läge';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Förhindra Ljudklippning';

  @override
  String fallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'STREAMING KVALITET';

  @override
  String get enableTranscoding => 'Aktivera Transkodning';

  @override
  String get qualityWifi => 'WiFi Kvalité';

  @override
  String get qualityMobile => 'Mobil Kvalité';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle => 'Minska dataanvändning med sämre kvalité';

  @override
  String get modeOff => 'Av';

  @override
  String get modeTrack => 'Låt';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'SERVER ANSLUTNING';

  @override
  String get serverType => 'Server Typ';

  @override
  String get notConnected => 'Inte ansluten';

  @override
  String get unknown => 'Okänd';

  @override
  String get sectionMusicFolders => 'MUSIK MAPPAR';

  @override
  String get musicFolders => 'Musik Mappar';

  @override
  String get noMusicFolders => 'Inga musik mappar hittades';

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
      'Är du säker på att du vill logga ut? Detta kommer även rensa all cachelagrad data.';

  @override
  String get sectionCacheSettings => 'CACHE INSTÄLLNINGAR';

  @override
  String get imageCache => 'Bild Cache';

  @override
  String get musicCache => 'Musik Cache';

  @override
  String get bpmCache => 'BPM Cache';

  @override
  String get saveAlbumCovers => 'Spara albumomslag lokalt';

  @override
  String get saveSongMetadata => 'Spara låt metadata lokalt';

  @override
  String get saveBpmAnalysis => 'Spara BPM analys lokalt';

  @override
  String get sectionCacheCleanup => 'CACHE RENSNING';

  @override
  String get clearAllCache => 'Rensa all cache';

  @override
  String get allCacheCleared => 'Alla cacher rensade';

  @override
  String get sectionOfflineDownloads => 'OFFLINE NERLADDNINGAR';

  @override
  String get downloadedSongs => 'Nedladdade Låtar';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Laddar ner Bibliotek... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Ladda ner Hela Biblioteket';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Detta kommer att ladda ner $count låtar till din enhet. Detta kan ta ett tag och använda en del lagringsutrymme.\n\nFortsätt?';
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
  String get libraryDownloadStarted => 'Nerladdning av bibliotek startad';

  @override
  String get deleteDownloads => 'Radera Alla Nedladdningar';

  @override
  String get downloadsDeleted => 'Alla nerladdningar raderades';

  @override
  String get noSongsAvailable =>
      'Inga låtar tillgängliga. Ladda ditt bibliotek först.';

  @override
  String get sectionBpmAnalysis => 'BPM ANALYS';

  @override
  String get cachedBpms => 'Cachade BPM:ar';

  @override
  String get cacheAllBpms => 'Cacha alla BPM:ar';

  @override
  String get clearBpmCache => 'Rensa BPM Cache';

  @override
  String get bpmCacheCleared => 'BPM cache rensad';

  @override
  String downloadedStats(int count, String size) {
    return '$count låtar • $size';
  }

  @override
  String get sectionInformation => 'INFORMATION';

  @override
  String get sectionDeveloper => 'UTVECKLARE';

  @override
  String get sectionLinks => 'LÄNKAR';

  @override
  String get githubRepo => 'GitHub Repository';

  @override
  String get playingFrom => 'SPELAR FRÅN';

  @override
  String get live => 'LIVE';

  @override
  String get streamingLive => 'Sänder Live';

  @override
  String get stopRadio => 'Stoppa Radio';

  @override
  String get removeFromLiked => 'Ta bort från Gillade Låtar';

  @override
  String get addToLiked => 'Lägg till Gillade låtar';

  @override
  String get playNext => 'Spela Nästa';

  @override
  String get addToQueue => 'Lägg till i Kö';

  @override
  String get goToAlbum => 'Gå till Album';

  @override
  String get goToArtist => 'Gå till Artist';

  @override
  String get rateSong => 'Betygsätt Låt';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Betygsätt Låt ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Betyg borttaget';

  @override
  String rated(int rating, String stars) {
    return 'Betygsatt $rating $stars';
  }

  @override
  String get removeRating => 'Ta bort Betyg';

  @override
  String get downloaded => 'Nerladdad';

  @override
  String downloading(int percent) {
    return 'Laddar ner... $percent%';
  }

  @override
  String get removeDownload => 'Ta bort Nerladdning';

  @override
  String get removeDownloadConfirm =>
      'Ta bort den här låten från offline lagring?';

  @override
  String get downloadRemoved => 'Nerladdning borttagen';

  @override
  String downloadedTitle(String title) {
    return 'Laddade ner \"$title\"';
  }

  @override
  String get downloadFailed => 'Nerladdning misslyckades';

  @override
  String downloadError(Object error) {
    return 'Nerladdningsfel: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Lade till \"$title\" till $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Fel vid tillägg till spellista: $error';
  }

  @override
  String get noPlaylists => 'Inga spellistor tillgängliga';

  @override
  String get createNewPlaylist => 'Skapa Ny Spellista';

  @override
  String artistNotFound(String name) {
    return 'Artist \"$name\" hittades inte';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Fel vid sökning av artist: $error';
  }

  @override
  String get selectArtist => 'Välj Artist';

  @override
  String get removedFromFavorites => 'Ta bort från Favoriter';

  @override
  String get addedToFavorites => 'Lades till i Favoriter';

  @override
  String get star => 'stjärna';

  @override
  String get stars => 'stjärnor';

  @override
  String get albumNotFound => 'Albumet hittades inte';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Topplåtar';

  @override
  String get connected => 'Ansluten';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'Ingen låt spelas';

  @override
  String get internetRadioUppercase => 'INTERNET RADIO';

  @override
  String get playingNext => 'Spelar Nästa';

  @override
  String get createPlaylistTitle => 'Skapa Spellista';

  @override
  String get playlistNameHint => 'Spellista namn';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Skapad spellista \"$name\" med den här låten';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Fel vid laddning av spellistor: $error';
  }

  @override
  String get playlistNotFound => 'Spellistan hittades inte';

  @override
  String get noSongsInPlaylist => 'Inga låtar i den här spellistan';

  @override
  String get noFavoriteSongsYet => 'Inga favoritlåtar än';

  @override
  String get noFavoriteAlbumsYet => 'Inga favoritalbum än';

  @override
  String get listeningHistory => 'Lyssnings Historik';

  @override
  String get noListeningHistory => 'Ingen Lyssningshistorik';

  @override
  String get songsWillAppearHere => 'Låtar du spelar visas här';

  @override
  String get sortByArtistAZ => 'Artist (A-Ö)';

  @override
  String get sortByArtistZA => 'Artist (Ö-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Ö)';

  @override
  String get sortByAlbumZA => 'Album (Ö-A)';

  @override
  String get recentlyAdded => 'Nyligen tillagda';

  @override
  String get noSongsFound => 'Inga låtar hittades';

  @override
  String get noAlbumsFound => 'Inget album hittades';

  @override
  String get noHomepageUrl => 'Ingen hemsida URL tillgänglig';

  @override
  String get playStation => 'Play Station';

  @override
  String get openHomepage => 'Öppna Hemsida';

  @override
  String get copyStreamUrl => 'Kopiera Stream URL';

  @override
  String get failedToLoadRadioStations =>
      'Misslyckades att ladda radiostationer';

  @override
  String get noRadioStations => 'Inga Radiostationer';

  @override
  String get noRadioStationsHint =>
      'Lägg till radiostationer i dina Navidrome serverinställningar för att se dem här.';

  @override
  String get connectToServerSubtitle => 'Anslut till din Subsonic server';

  @override
  String get pleaseEnterServerUrl => 'Ange server URL';

  @override
  String get invalidUrlFormat => 'URL måste börja med http:// eller https://';

  @override
  String get pleaseEnterUsername => 'Ange användarnamn';

  @override
  String get pleaseEnterPassword => 'Ange lösenord';

  @override
  String get legacyAuthentication => 'Legacy Autentisering';

  @override
  String get legacyAuthSubtitle => 'Använd för äldre Subsonic servrar';

  @override
  String get allowSelfSignedCerts => 'Tillåt självsignerade certifikat';

  @override
  String get allowSelfSignedSubtitle =>
      'För servrar med anpassade TLS/SSL certifikat';

  @override
  String get advancedOptions => 'Avancerade Inställningar';

  @override
  String get customTlsCertificate => 'Anpassad TLS/SSL Certifikat';

  @override
  String get customCertificateSubtitle =>
      'Ladda upp ett anpassat certifikat för servrar med icke-standard CA';

  @override
  String get selectCertificateFile => 'Välj Certifikat';

  @override
  String get clientCertificate => 'Klientcertifikat (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autentisera denna klient med ett certifikat (kräver mTLS-aktiverad server)';

  @override
  String get selectClientCertificate => 'Välj Klientcertifikat';

  @override
  String get clientCertPassword => 'Lösenord för certifikat (valfritt)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Misslyckades välja klientcertifikat: $error';
  }

  @override
  String get connect => 'Anslut';

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
  String get or => 'ELLER';

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
  String get useLocalFiles => 'Använd Lokala Filer';

  @override
  String get startingScan => 'Startar skanning...';

  @override
  String get storagePermissionRequired =>
      'Lagringsbehörighet krävs för att skanna lokala filer';

  @override
  String get noMusicFilesFound => 'Inga musikfiler hittades på din enhet';

  @override
  String get remove => 'Ta bort';

  @override
  String failedToSetRating(Object error) {
    return 'Misslyckades att ange betyg: $error';
  }

  @override
  String get home => 'Hem';

  @override
  String get playlistsSection => 'SPELLISTOR';

  @override
  String get collapse => 'Kollapsa';

  @override
  String get expand => 'Expandera';

  @override
  String get createPlaylist => 'Skapa spellista';

  @override
  String get likedSongsSidebar => 'Gillade Låtar';

  @override
  String playlistSongsCount(int count) {
    return 'Spellista • $count låtar';
  }

  @override
  String get failedToLoadLyrics => 'Misslyckades ladda låttext';

  @override
  String get lyricsNotFoundSubtitle =>
      'Låttext för denna låt kunde inte hittas';

  @override
  String get backToCurrent => 'Tillbaka till nuvarande';

  @override
  String get exitFullscreen => 'Avsluta Helskärmsläge';

  @override
  String get fullscreen => 'Helskärmsläge';

  @override
  String get noLyrics => 'Ingen låttext';

  @override
  String get internetRadioMiniPlayer => 'Internet Radio';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get localFilesModeBanner => 'Lokalt Filläge';

  @override
  String get offlineModeBanner =>
      'Offline-läge – Endast uppspelning av nerladdad musik';

  @override
  String get updateAvailable => 'Uppdatering Tillgänglig';

  @override
  String get updateAvailableSubtitle =>
      'En ny version av Luobo finns tillgänglig!';

  @override
  String updateCurrentVersion(String version) {
    return 'Nuvarande: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Senaste: v$version';
  }

  @override
  String get whatsNew => 'Nyheter';

  @override
  String get downloadUpdate => 'Ladda ner';

  @override
  String get remindLater => 'Senare';

  @override
  String get seeAll => 'Se Alla';

  @override
  String get artistDataNotFound => 'Artist hittades inte';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'Castar';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Koppla ifrån';

  @override
  String get searchingDevices => 'Söker efter enheter';

  @override
  String get castWifiHint =>
      'Se till att din Cast / DLNA-enhet\när kopplad till samma Wi-Fi nätverk';

  @override
  String connectedToDevice(String name) {
    return 'Ansluten till $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Misslyckades att ansluta till $name';
  }

  @override
  String get removedFromLikedSongs => 'Borttagen från Gillade Låtar';

  @override
  String get addedToLikedSongs => 'Lades till i Gillade Låtar';

  @override
  String get enableShuffle => 'Aktivera Blandning';

  @override
  String get enableRepeat => 'Aktivera Upprepning';

  @override
  String get closeLyrics => 'Stäng Låttext';

  @override
  String errorStartingDownload(Object error) {
    return 'Fel vid start av nerladdning: $error';
  }

  @override
  String get errorLoadingGenres => 'Fel vid laddning av genrer';

  @override
  String get noGenresFound => 'Inga genrer hittades';

  @override
  String get noAlbumsInGenre => 'Inga album i denna genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount låtar • $albumCount album';
  }

  @override
  String get musicFoldersDialogTitle => 'Välj Musikmappar';

  @override
  String get musicFoldersHint =>
      'Lämna alla aktiverade för att använda alla mappar (standard).';

  @override
  String get musicFoldersSaved => 'Val av musikmappar sparad';

  @override
  String get artworkStyleSection => 'Konststil';

  @override
  String get artworkCornerRadius => 'Hörnradie';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Justera hur runda hörnen på albumomslag ser ut';

  @override
  String get artworkCornerRadiusNone => 'Ingen';

  @override
  String get artworkShape => 'Form';

  @override
  String get artworkShapeRounded => 'Avrundad';

  @override
  String get artworkShapeCircle => 'Cirkel';

  @override
  String get artworkShapeSquare => 'Kvadrat';

  @override
  String get artworkShadow => 'Skugga';

  @override
  String get artworkShadowNone => 'Ingen';

  @override
  String get artworkShadowSoft => 'Mjuk';

  @override
  String get artworkShadowMedium => 'Medium';

  @override
  String get artworkShadowStrong => 'Stark';

  @override
  String get artworkShadowColor => 'Skuggfärg';

  @override
  String get artworkShadowColorBlack => 'Svart';

  @override
  String get artworkShadowColorAccent => 'Accentfärg';

  @override
  String get artworkPreview => 'Förhandsgranskning';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Ingen bild';

  @override
  String get serverUnreachableTitle => 'Kan inte nå servern';

  @override
  String get serverUnreachableSubtitle =>
      'Kontrollera din anslutning eller dina serverinställningar.';

  @override
  String get openOfflineMode => 'Öppna i offline läge';

  @override
  String get appearanceSection => 'Utseende';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Accentfärg';

  @override
  String get circularDesignLabel => 'Cirkulär Design';

  @override
  String get circularDesignSubtitle =>
      'Flytande, avrundat UI med genomskinliga paneler och glass-blur effekt på spelaren och navigationsfältet.';

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
  String get themeModeLight => 'Ljust';

  @override
  String get themeModeDark => 'Mörkt';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Discord statustext';

  @override
  String get discordStatusTextSubtitle =>
      'Andra raden visas i Discord-aktivitet';

  @override
  String get discordRpcStyleArtist => 'Artistnamn';

  @override
  String get discordRpcStyleSong => 'Låttitel';

  @override
  String get discordRpcStyleApp => 'Appnamn (Luobo)';

  @override
  String get sectionVolumeNormalization => 'VOLYM NORMALISERING (REPLAYGAIN)';

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
  String get replayGainModeOff => 'Av';

  @override
  String get replayGainModeTrack => 'Låt';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Förhindra Ljudklippning';

  @override
  String replayGainFallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Låtar att tillägga: $count';
  }

  @override
  String get transcodingEnable => 'Aktivera Transkodning';

  @override
  String get transcodingEnableSubtitle =>
      'Minska dataanvändningen med lägre kvalitet';

  @override
  String get smartTranscoding => 'Smart Transkodning';

  @override
  String get smartTranscodingSubtitle =>
      'Justerar kvaliteten automatiskt baserat på din anslutning (WiFi vs mobildata)';

  @override
  String get smartTranscodingDetectedNetwork => 'Upptäckt nätverk: ';

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
  String get transcodingWifiQuality => 'WiFi Kvalité';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Används automatiskt på WiFi';

  @override
  String get transcodingMobileQuality => 'Mobildata Kvalité';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Används automatiskt på mobildata';

  @override
  String get transcodingFormat => 'Format';

  @override
  String get transcodingFormatSubtitle => 'Ljudkodek som används för streaming';

  @override
  String get transcodingBitrateOriginal => 'Original (Ingen Omkodning)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Bildcache';

  @override
  String get imageCacheSubtitle => 'Spara albumomslag lokalt';

  @override
  String get musicCacheTitle => 'Musikcache';

  @override
  String get musicCacheSubtitle => 'Spara låt metadata lokalt';

  @override
  String get bpmCacheTitle => 'BPM-cache';

  @override
  String get bpmCacheSubtitle => 'Spara BPM analys lokalt';

  @override
  String get sectionAboutInformation => 'INFORMATION';

  @override
  String get sectionAboutDeveloper => 'UTVECKLARE';

  @override
  String get sectionAboutLinks => 'LÄNKAR';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPlatform => 'Plattform';

  @override
  String get aboutMadeBy => 'Gjord av chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'GitHub Repository';

  @override
  String get aboutLinkChangelog => 'Ändringshistorik';

  @override
  String get aboutLinkReportIssue => 'Rapportera Problem';

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
  String get connecting => 'Ansluter';

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
  String get edit => 'Redigera';

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
