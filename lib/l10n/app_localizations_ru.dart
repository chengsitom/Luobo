// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => 'Emulator Detected';

  @override
  String get emulatorNotAllowed =>
      'This app cannot run on an emulator.\\nPlease use a physical device.';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get forYou => 'Для вас';

  @override
  String get quickPicks => 'Быстрые подборки';

  @override
  String get discoverMix => 'Микс «Открытия»';

  @override
  String get morningVibes => 'Morning Vibes';

  @override
  String get afternoonVibes => 'Afternoon Vibes';

  @override
  String get eveningVibes => 'Evening Vibes';

  @override
  String get nightVibes => 'Night Vibes';

  @override
  String get recentlyPlayed => 'Недавно играли';

  @override
  String get yourPlaylists => 'Ваши плейлисты';

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
  String get madeForYou => 'Сделано для вас';

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
  String get topRated => 'Высоко оценённые';

  @override
  String get noContentAvailable => 'Нет доступного контента';

  @override
  String get tryRefreshing =>
      'Попробуйте обновить или проверить подключение к серверу';

  @override
  String get refresh => 'Обновить';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount albums, $songCount songs';
  }

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get refreshLocalComplete => 'Library refreshed';

  @override
  String get errorLoadingSongs => 'Ошибка при загрузке треков';

  @override
  String get noSongsInGenre => 'Нет песен в этом жанре';

  @override
  String get errorLoadingAlbums => 'Ошибка при загрузке альбомов';

  @override
  String get noTopRatedAlbums => 'Нет высоко оценённых альбомов';

  @override
  String get login => 'Войти';

  @override
  String get serverUrl => 'URL-адрес сервера';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get selectCertificate => 'Выберите сертификат TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Не удалось выбрать сертификат: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'URL-адрес сервера должен начинаться с http:// или https://';

  @override
  String get failedToConnect => 'Не удалось подключиться';

  @override
  String get library => 'Библиотека';

  @override
  String get search => 'Поиск';

  @override
  String get settings => 'Настройки';

  @override
  String get albums => 'Альбомы';

  @override
  String get artists => 'Исполнители';

  @override
  String get songs => 'Песни';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get genres => 'Жанры';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Избранное';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get queue => 'Очередь';

  @override
  String get lyrics => 'Текст';

  @override
  String get play => 'Играть';

  @override
  String get pause => 'Пауза';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Предыдущий';

  @override
  String get shuffle => 'Перемешивание';

  @override
  String get repeat => 'Повтор';

  @override
  String get repeatOne => 'Повтор одного';

  @override
  String get repeatOff => 'Повтор выкл.';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get removeFromPlaylist => 'Удалить трек из плейлиста';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get download => 'Скачать';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get general => 'Общее';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get playback => 'Проигрывание';

  @override
  String get storage => 'Хранилище';

  @override
  String get about => 'Информация';

  @override
  String get darkMode => 'Тёмный режим';

  @override
  String get language => 'Язык';

  @override
  String get version => 'Версия';

  @override
  String get githubRepository => 'Репозиторий на GitHub';

  @override
  String get reportIssue => 'Сообщить о проблеме';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get unknownAlbum => 'Неизвестный альбом';

  @override
  String get playAll => 'Проиграть все';

  @override
  String get shuffleAll => 'Перемешать все';

  @override
  String get sortBy => 'Сортировать по';

  @override
  String get sortByName => 'Название';

  @override
  String get sortByArtist => 'Исполнитель';

  @override
  String get sortByAlbum => 'Альбом';

  @override
  String get sortByDate => 'Дата';

  @override
  String get sortByDuration => 'Длительность';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get descending => 'По убыванию';

  @override
  String get noLyricsAvailable => 'Нет доступных текстов';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get searchHint => 'Поиск песен, альбомов, исполнителей...';

  @override
  String get allSongs => 'Все песни';

  @override
  String get allAlbums => 'Все альбомы';

  @override
  String get allArtists => 'Все исполнители';

  @override
  String trackNumber(int number) {
    return 'Трек $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен',
      one: '1 песня',
      zero: 'Нет песен',
      many: '$count песен',
      few: '$count песни',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбомов',
      one: '1 альбом',
      zero: 'Нет альбомов',
      many: '$count альбомов',
      few: '$count альбома',
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
  String get logout => 'Выйти';

  @override
  String get confirmLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get offlineMode => 'Автономный режим';

  @override
  String get radio => 'Радио';

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
  String get changelog => 'Список изменений';

  @override
  String get platform => 'Платформа';

  @override
  String get server => 'Сервер';

  @override
  String get display => 'Дисплей';

  @override
  String get playerInterface => 'Интерфейс плеера';

  @override
  String get smartRecommendations => 'Умные рекомендации';

  @override
  String get showVolumeSlider => 'Показать ползунок громкости';

  @override
  String get showVolumeSliderSubtitle =>
      'Отображать управление громкостью на экране воспроизведения';

  @override
  String get showStarRatings => 'Отображать оценку звёздами';

  @override
  String get showStarRatingsSubtitle =>
      'Оценивайте песни и просматривайте рейтинги';

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
  String get enableRecommendations => 'Включить рекомендации';

  @override
  String get enableRecommendationsSubtitle =>
      'Получайте персональные рекомендации';

  @override
  String get listeningData => 'Данные о прослушивании';

  @override
  String totalPlays(int count) {
    return 'Всего прослушиваний: $count ';
  }

  @override
  String get clearListeningHistory => 'Очистить историю прослушивания';

  @override
  String get confirmClearHistory =>
      'Это сбросит все ваши данные и рекомендации. Вы уверены?';

  @override
  String get historyCleared => 'История прослушивания очищена';

  @override
  String get discordStatus => 'Discord Статус';

  @override
  String get discordStatusSubtitle =>
      'Показывать проигрываемую песню в профиле Discord';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get systemDefault => 'Системный по умолчанию';

  @override
  String get yourLibrary => 'Ваша библиотека';

  @override
  String get filterAll => 'Все';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Плейлисты';

  @override
  String get filterAlbums => 'Альбомы';

  @override
  String get filterArtists => 'Исполнители';

  @override
  String get likedSongs => 'Понравившиеся песни';

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
  String get radioStations => 'Радиостанции';

  @override
  String get playlist => 'Плейлист';

  @override
  String get internetRadio => 'Интернет-радио';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get create => 'Создать';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Вы уверены, что хотите удалить плейлист «$name»?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Плейлист с названием «$name» удалён';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Ошибка при создании плейлиста: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Ошибка при удалении плейлиста: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Плейлист с названием «$name» создан';
  }

  @override
  String get searchTitle => 'Поиск';

  @override
  String get searchPlaceholder => 'Исполнители, Песни, Альбомы';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get noSuggestions => 'Нет подходящих вариантов';

  @override
  String get browseCategories => 'Просмотреть категории';

  @override
  String get liveSearchSection => 'Поиск';

  @override
  String get liveSearch => 'Мгновенный поиск';

  @override
  String get liveSearchSubtitle =>
      'Сразу показывать результаты при вводе текста';

  @override
  String get categoryMadeForYou => 'Подборка для вас';

  @override
  String get categoryNewReleases => 'Новые выпуски';

  @override
  String get categoryTopRated => 'С лучшим рейтингом';

  @override
  String get categoryGenres => 'Жанры';

  @override
  String get categoryFavorites => 'Избранное';

  @override
  String get categoryRadio => 'Радио';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get tabPlayback => 'Воспроизведение';

  @override
  String get tabStorage => 'Хранилище';

  @override
  String get tabServer => 'Сервер';

  @override
  String get tabDisplay => 'Дисплей';

  @override
  String get tabAiPlaylist => 'AI Playlist';

  @override
  String get tabAbout => 'Информация';

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
  String get sectionAutoDj => 'Авто-диджей';

  @override
  String get autoDjMode => 'Режим авто-диджея';

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
    return 'Песни для добавления: $count';
  }

  @override
  String get sectionReplayGain => 'НОРМАЛИЗАЦИЯ ГРОМКОСТИ (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Режим';

  @override
  String preamp(String value) {
    return 'Предусиление: $value дБ';
  }

  @override
  String get preventClipping => 'Предотвращение клиппинга';

  @override
  String fallbackGain(String value) {
    return 'Усиление по умолчанию: $value дБ';
  }

  @override
  String get sectionStreamingQuality => 'КАЧЕСТВО СТРИМИНГА';

  @override
  String get enableTranscoding => 'Включить транскодирование';

  @override
  String get qualityWifi => 'Качество WiFi';

  @override
  String get qualityMobile => 'Мобильное качество';

  @override
  String get format => 'Формат';

  @override
  String get transcodingSubtitle => 'Экономить трафик при низком качестве';

  @override
  String get modeOff => 'Выкл.';

  @override
  String get modeTrack => 'Трек';

  @override
  String get modeAlbum => 'Альбом';

  @override
  String get sectionServerConnection => 'ПОДКЛЮЧЕНИЕ К СЕРВЕРУ';

  @override
  String get serverType => 'Тип сервера';

  @override
  String get notConnected => 'Нет подключения';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get sectionMusicFolders => 'КАТАЛОГИ МУЗЫКИ';

  @override
  String get musicFolders => 'Папки с музыкой';

  @override
  String get noMusicFolders => 'Папки с музыкой не найдены';

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
  String get sectionAccount => 'АККАУНТ';

  @override
  String get logoutConfirmation =>
      'Вы уверены, что хотите выйти? Это также удалит все кэшированные данные.';

  @override
  String get sectionCacheSettings => 'НАСТРОЙКИ КЭША';

  @override
  String get imageCache => 'Кэш изображений';

  @override
  String get musicCache => 'Кэш музыки';

  @override
  String get bpmCache => 'Кэш BPM';

  @override
  String get saveAlbumCovers => 'Сохранить обложки альбома локально';

  @override
  String get saveSongMetadata => 'Сохранить метаданные песни локально';

  @override
  String get saveBpmAnalysis => 'Сохранить определение BPM локально';

  @override
  String get sectionCacheCleanup => 'ОЧИСТКА КЭША';

  @override
  String get clearAllCache => 'Очистить весь кэш';

  @override
  String get allCacheCleared => 'Весь кэш очищен';

  @override
  String get sectionOfflineDownloads => 'АВТОНОМНЫЕ ЗАГРУЗКИ';

  @override
  String get downloadedSongs => 'Загруженные треки';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Загрузка библиотеки... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Загрузить всю библиотеку';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Будет скачано $count песен. Это может занять некоторое время и потребовать значительного объёма памяти.\n\nПродолжить?';
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
  String get libraryDownloadStarted => 'Загрузка библиотеки началась';

  @override
  String get deleteDownloads => 'Удалить все загрузки';

  @override
  String get downloadsDeleted => 'Все загрузки удалены';

  @override
  String get noSongsAvailable =>
      'Нет доступных треков. Пожалуйста, сначала добавьте файлы в библиотеку.';

  @override
  String get sectionBpmAnalysis => 'ОПРЕДЕЛЕНИЕ BPM';

  @override
  String get cachedBpms => 'Кэшированные BPM';

  @override
  String get cacheAllBpms => 'Кэшировать все BPM';

  @override
  String get clearBpmCache => 'Очистить кэш BPM';

  @override
  String get bpmCacheCleared => 'Кэш BPM очищен';

  @override
  String downloadedStats(int count, String size) {
    return '$count пес. • $size';
  }

  @override
  String get sectionInformation => 'ИНФОРМАЦИЯ';

  @override
  String get sectionDeveloper => 'РАЗРАБОТЧИК';

  @override
  String get sectionLinks => 'ССЫЛКИ';

  @override
  String get githubRepo => 'Репозиторий на GitHub';

  @override
  String get playingFrom => 'ИГРАЕТ ИЗ';

  @override
  String get live => 'В ЭФИРЕ';

  @override
  String get streamingLive => 'Прямая трансляция';

  @override
  String get stopRadio => 'Остановить радио';

  @override
  String get removeFromLiked => 'Удалить из понравившихся песен';

  @override
  String get addToLiked => 'Добавить в понравившиеся песни';

  @override
  String get playNext => 'Воспроизвести следующим';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get goToAlbum => 'Перейти к альбому';

  @override
  String get goToArtist => 'Перейти к исполнителю';

  @override
  String get rateSong => 'Оценить песню';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Оценка песни ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Оценка удалена';

  @override
  String rated(int rating, String stars) {
    return 'Оценка $rating $stars';
  }

  @override
  String get removeRating => 'Удалить оценку';

  @override
  String get downloaded => 'Скачано';

  @override
  String downloading(int percent) {
    return 'Скачивание... $percent%';
  }

  @override
  String get removeDownload => 'Удалить загрузку';

  @override
  String get removeDownloadConfirm =>
      'Удалить эту песню из автономного хранилища?';

  @override
  String get downloadRemoved => 'Загрузка удалена';

  @override
  String downloadedTitle(String title) {
    return 'Загружено «$title»';
  }

  @override
  String get downloadFailed => 'Не удалось загрузить';

  @override
  String downloadError(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Добавлено «$title» в плейлист «$playlist»';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Ошибка при добавлении в плейлист: $error';
  }

  @override
  String get noPlaylists => 'Нет доступных плейлистов';

  @override
  String get createNewPlaylist => 'Создать новый плейлист';

  @override
  String artistNotFound(String name) {
    return 'Исполнитель «$name» не найден';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Ошибка при поиске исполнителя: $error';
  }

  @override
  String get selectArtist => 'Выберите исполнителя';

  @override
  String get removedFromFavorites => 'Удалено из избранного';

  @override
  String get addedToFavorites => 'Добавлено в избранное';

  @override
  String get star => 'зв.';

  @override
  String get stars => 'зв.';

  @override
  String get albumNotFound => 'Альбом не найден';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ЧАС. $minutes МИН.';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes МИН.';
  }

  @override
  String get topSongs => 'Лучшие песни';

  @override
  String get connected => 'Подключено';

  @override
  String get failedToLoadProfiles => 'Failed to load saved servers';

  @override
  String get noSongPlaying => 'Трек не воспроизводится';

  @override
  String get internetRadioUppercase => 'ИНТЕРНЕТ-РАДИО';

  @override
  String get playingNext => 'Проигрывание следующей';

  @override
  String get createPlaylistTitle => 'Создать плейлист';

  @override
  String get playlistNameHint => 'Название плейлиста';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Создан плейлист «$name» с этой песней';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Ошибка при загрузке плейлистов: $error';
  }

  @override
  String get playlistNotFound => 'Плейлист не найден';

  @override
  String get noSongsInPlaylist => 'Нет песен в этом плейлисте';

  @override
  String get noFavoriteSongsYet => 'Нет избранных песен';

  @override
  String get noFavoriteAlbumsYet => 'Нет избранных альбомов';

  @override
  String get listeningHistory => 'История прослушивания';

  @override
  String get noListeningHistory => 'Нет истории прослушивания';

  @override
  String get songsWillAppearHere => 'Здесь будут появляться прослушанные песни';

  @override
  String get sortByArtistAZ => 'Исполнитель (А-Я)';

  @override
  String get sortByArtistZA => 'Исполнитель (Я-А)';

  @override
  String get sortByAlbumAZ => 'Альбом (А-Я)';

  @override
  String get sortByAlbumZA => 'Альбом (Я-А)';

  @override
  String get recentlyAdded => 'Недавно добавлено';

  @override
  String get noSongsFound => 'Не найдено песен';

  @override
  String get noAlbumsFound => 'Альбомы не найдены';

  @override
  String get noHomepageUrl => 'URL-адрес главной страницы не найден';

  @override
  String get playStation => 'Включить станцию';

  @override
  String get openHomepage => 'Открыть главную страницу';

  @override
  String get copyStreamUrl => 'Копировать URL-адрес трансляции';

  @override
  String get failedToLoadRadioStations => 'Не удалось загрузить радиостанции';

  @override
  String get noRadioStations => 'Нет радиостанций';

  @override
  String get noRadioStationsHint =>
      'Добавьте радиостанции в настройках сервера Navidrome, чтобы они появились здесь.';

  @override
  String get connectToServerSubtitle =>
      'Подключиться к вашему серверу Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Пожалуйста, введите URL-адрес сервера';

  @override
  String get invalidUrlFormat =>
      'URL-адрес должен начинаться с http:// или https://';

  @override
  String get pleaseEnterUsername => 'Пожалуйста, введите имя пользователя';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get legacyAuthentication => 'Устаревший метод аутентификации';

  @override
  String get legacyAuthSubtitle => 'Использовать для старых серверов Subsonic';

  @override
  String get allowSelfSignedCerts => 'Разрешить самоподписанные сертификаты';

  @override
  String get allowSelfSignedSubtitle =>
      'Для серверов с собственными TLS/SSL-сертификатами';

  @override
  String get advancedOptions => 'Дополнительные настройки';

  @override
  String get customTlsCertificate => 'Собственный TLS/SSL-сертификат';

  @override
  String get customCertificateSubtitle =>
      'Загрузите собственный сертификат для серверов с нестандартным центром сертификации (CA)';

  @override
  String get selectCertificateFile => 'Выбрать файл сертификата';

  @override
  String get clientCertificate => 'Сертификат клиента (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Авторизовать клиент по сертификату (требуется сервер с поддержкой mTLS)';

  @override
  String get selectClientCertificate => 'Выбрать сертификат клиента';

  @override
  String get clientCertPassword => 'Пароль сертификата (необязательно)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Не удалось выбрать сертификат клиента: $error';
  }

  @override
  String get connect => 'Подключиться';

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
  String get or => 'ИЛИ';

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
  String get useLocalFiles => 'Использовать локальные файлы';

  @override
  String get startingScan => 'Запуск сканирования...';

  @override
  String get storagePermissionRequired =>
      'Для сканирования локальных файлов требуется разрешение на доступ к памяти';

  @override
  String get noMusicFilesFound =>
      'На вашем устройстве не найдено музыкальных файлов';

  @override
  String get remove => 'Удалить';

  @override
  String failedToSetRating(Object error) {
    return 'Не удалось задать оценку: $error';
  }

  @override
  String get home => 'Главная';

  @override
  String get playlistsSection => 'ПЛЕЙЛИСТЫ';

  @override
  String get collapse => 'Свернуть';

  @override
  String get expand => 'Развернуть';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get likedSongsSidebar => 'Понравившиеся песни';

  @override
  String playlistSongsCount(int count) {
    return 'Плейлист • $count пес.';
  }

  @override
  String get failedToLoadLyrics => 'Не удалось загрузить текст';

  @override
  String get lyricsNotFoundSubtitle => 'Тексты для этой песни не найдены';

  @override
  String get backToCurrent => 'Назад к текущей';

  @override
  String get exitFullscreen => 'Выйти из полноэкранного режима';

  @override
  String get fullscreen => 'Полный экран';

  @override
  String get noLyrics => 'Нет текста';

  @override
  String get internetRadioMiniPlayer => 'Интернет-радио';

  @override
  String get liveBadge => 'В ЭФИРЕ';

  @override
  String get localFilesModeBanner => 'Режим локальных файлов';

  @override
  String get offlineModeBanner => 'Автономный режим — только скачанная музыка';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updateAvailableSubtitle => 'Доступна новая версия Luobo!';

  @override
  String updateCurrentVersion(String version) {
    return 'Текущая: в$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Последняя: в$version';
  }

  @override
  String get whatsNew => 'Что нового';

  @override
  String get downloadUpdate => 'Скачать';

  @override
  String get remindLater => 'Позже';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get artistDataNotFound => 'Исполнитель не найден';

  @override
  String get addedArtistToQueue => 'Исполнитель добавлен в очередь';

  @override
  String get addedArtistToQueueError =>
      'Не удалось добавить исполнителя в очередь';

  @override
  String get casting => 'Трансляция';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Трансляция / DLNA (Бета-версия)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get searchingDevices => 'Поиск устройств';

  @override
  String get castWifiHint =>
      'Убедитесь, что устройство Cast / DLNA \nподключено к той же сети Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Подключено к $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Не удалось подключиться к $name';
  }

  @override
  String get removedFromLikedSongs => 'Удалено из понравившихся песен';

  @override
  String get addedToLikedSongs => 'Добавлено в понравившиеся песни';

  @override
  String get enableShuffle => 'Включить перемешивание';

  @override
  String get enableRepeat => 'Включить повтор';

  @override
  String get closeLyrics => 'Закрыть текст';

  @override
  String errorStartingDownload(Object error) {
    return 'Ошибка при запуске загрузки: $error';
  }

  @override
  String get errorLoadingGenres => 'Ошибка при загрузке жанров';

  @override
  String get noGenresFound => 'Жанры не найдены';

  @override
  String get noAlbumsInGenre => 'Нет альбомов в этом жанре';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount пес. • $albumCount альб.';
  }

  @override
  String get musicFoldersDialogTitle => 'Выберите папки с музыкой';

  @override
  String get musicFoldersHint =>
      'Оставьте всё включенным, чтобы использовать все папки (по умолчанию).';

  @override
  String get musicFoldersSaved => 'Выбор папки для музыки сохранён';

  @override
  String get artworkStyleSection => 'Стиль обложек';

  @override
  String get artworkCornerRadius => 'Радиус углов';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Настройте степень скругления углов у обложек альбомов';

  @override
  String get artworkCornerRadiusNone => 'Нет';

  @override
  String get artworkShape => 'Форма';

  @override
  String get artworkShapeRounded => 'Скругление';

  @override
  String get artworkShapeCircle => 'Круг';

  @override
  String get artworkShapeSquare => 'Квадрат';

  @override
  String get artworkShadow => 'Тень';

  @override
  String get artworkShadowNone => 'Нет';

  @override
  String get artworkShadowSoft => 'Мягко';

  @override
  String get artworkShadowMedium => 'Сред.';

  @override
  String get artworkShadowStrong => 'Сильно';

  @override
  String get artworkShadowColor => 'Цвет тени';

  @override
  String get artworkShadowColorBlack => 'Чёрный';

  @override
  String get artworkShadowColorAccent => 'Акцент';

  @override
  String get artworkPreview => 'Предпросмотр';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Нет обложки';

  @override
  String get serverUnreachableTitle => 'Не удаётся подключиться к серверу';

  @override
  String get serverUnreachableSubtitle =>
      'Проверьте подключение или настройки сервера.';

  @override
  String get openOfflineMode => 'Открыть в автономном режиме';

  @override
  String get appearanceSection => 'Оформление';

  @override
  String get themeLabel => 'Тема оформления';

  @override
  String get accentColorLabel => 'Основной цвет';

  @override
  String get circularDesignLabel => 'Дизайн с круглыми элементами';

  @override
  String get circularDesignSubtitle =>
      'Интерфейс с плавающими, округлыми элементами и стеклянным размытием на плеере и панели.';

  @override
  String get themeModeSystem => 'Системная';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get clearAppCache => 'Clear App Cache';

  @override
  String get appearanceGlassHint =>
      'Glass and card styling is defined by the design system and is not user-adjustable.';

  @override
  String get themeModeLight => 'Светлая';

  @override
  String get themeModeDark => 'Тёмная';

  @override
  String get liveLabel => 'В ЭФИРЕ';

  @override
  String get discordStatusText => 'Текст статуса Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Вторая строка, отображаемая в активности Discord';

  @override
  String get discordRpcStyleArtist => 'Имя исполнителя';

  @override
  String get discordRpcStyleSong => 'Название песни';

  @override
  String get discordRpcStyleApp => 'Название приложения (Luobo)';

  @override
  String get sectionVolumeNormalization =>
      'ВЫРАВНИВАНИЕ ГРОМКОСТИ (REPLAYGAIN)';

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
  String get replayGainModeOff => 'Выкл';

  @override
  String get replayGainModeTrack => 'Трек';

  @override
  String get replayGainModeAlbum => 'Альбом';

  @override
  String replayGainPreamp(String value) {
    return 'Предварительное усиление: $value дБ';
  }

  @override
  String get replayGainPreventClipping => 'Предотвращать искажения звука';

  @override
  String replayGainFallbackGain(String value) {
    return 'Усиление по умолчанию: $value дБ';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Треков для добавления: $count';
  }

  @override
  String get transcodingEnable => 'Использовать перекодирование';

  @override
  String get transcodingEnableSubtitle =>
      'Экономия трафика за счёт снижения качества';

  @override
  String get smartTranscoding => 'Умное перекодирование';

  @override
  String get smartTranscodingSubtitle =>
      'Автоподбор качества по типу сети (Wi-Fi / мобильные данные)';

  @override
  String get smartTranscodingDetectedNetwork => 'Сеть обнаружена: ';

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
  String get transcodingWifiQuality => 'Качество Wi-Fi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Автоматически используется в Wi-Fi сети';

  @override
  String get transcodingMobileQuality => 'Качество при мобильной сети';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Автоматически используется в мобильной сети';

  @override
  String get transcodingFormat => 'Формат';

  @override
  String get transcodingFormatSubtitle => 'Аудиокодек используется для вещания';

  @override
  String get transcodingBitrateOriginal => 'Оригинал (без перекодирования)';

  @override
  String get transcodingFormatOriginal => 'Оригинал';

  @override
  String get transcodingLanForceOriginal =>
      'LAN connection — always original (no transcoding)';

  @override
  String get imageCacheTitle => 'Кэш изображений';

  @override
  String get imageCacheSubtitle => 'Сохранить обложки альбома локально';

  @override
  String get musicCacheTitle => 'Кэш аудиозаписей';

  @override
  String get musicCacheSubtitle => 'Сохранить метаданные трека локально';

  @override
  String get bpmCacheTitle => 'Кэш BPM';

  @override
  String get bpmCacheSubtitle => 'Хранить локально данные анализа BPM';

  @override
  String get sectionAboutInformation => 'ИНФОРМАЦИЯ';

  @override
  String get sectionAboutDeveloper => 'РАЗРАБОТЧИК';

  @override
  String get sectionAboutLinks => 'ССЫЛКИ';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutPlatform => 'Платформа';

  @override
  String get aboutMadeBy => 'Сделано chengsitom';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'GitHub репозиторий';

  @override
  String get aboutLinkChangelog => 'Список изменений';

  @override
  String get aboutLinkReportIssue => 'Сообщить о проблеме';

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
  String get connecting => 'Подключение';

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
  String get edit => 'Изменить';

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
