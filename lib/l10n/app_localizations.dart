import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sq.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('az'),
    Locale('bn'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('ga'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sq'),
    Locale('sv'),
    Locale('te'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Luobo'**
  String get appName;

  /// Title shown when the app detects it's running on an emulator
  ///
  /// In en, this message translates to:
  /// **'Emulator Detected'**
  String get emulatorDetected;

  /// Message explaining that the app requires a physical device
  ///
  /// In en, this message translates to:
  /// **'This app cannot run on an emulator.\\nPlease use a physical device.'**
  String get emulatorNotAllowed;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// For You section title
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// Quick Picks section title
  ///
  /// In en, this message translates to:
  /// **'Quick Picks'**
  String get quickPicks;

  /// Discover Mix section title
  ///
  /// In en, this message translates to:
  /// **'Discover Mix'**
  String get discoverMix;

  /// Morning time-based mix section title
  ///
  /// In en, this message translates to:
  /// **'Morning Vibes'**
  String get morningVibes;

  /// Afternoon time-based mix section title
  ///
  /// In en, this message translates to:
  /// **'Afternoon Vibes'**
  String get afternoonVibes;

  /// Evening time-based mix section title
  ///
  /// In en, this message translates to:
  /// **'Evening Vibes'**
  String get eveningVibes;

  /// Night time-based mix section title
  ///
  /// In en, this message translates to:
  /// **'Night Vibes'**
  String get nightVibes;

  /// Recently played section title
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// Your playlists section title
  ///
  /// In en, this message translates to:
  /// **'Your Playlists'**
  String get yourPlaylists;

  /// Home quick-entry card: random playback across the whole library (fnos-style 'music roaming')
  ///
  /// In en, this message translates to:
  /// **'Roaming'**
  String get roaming;

  /// Subtitle under the Roaming card on the home screen
  ///
  /// In en, this message translates to:
  /// **'Shuffle the whole library'**
  String get roamingSubtitle;

  /// Home section title for the Roaming / Playlist / Favorites entry cards
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// Favorite playlists section title on home screen
  ///
  /// In en, this message translates to:
  /// **'Favorite Playlists'**
  String get favoritePlaylists;

  /// Section header for full albums in artist screen
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get sectionAlbums;

  /// Section header for EPs (extended plays) in artist screen
  ///
  /// In en, this message translates to:
  /// **'EPs'**
  String get sectionEPs;

  /// Section header for singles in artist screen
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get sectionSingles;

  /// Made for you section title
  ///
  /// In en, this message translates to:
  /// **'Made For You'**
  String get madeForYou;

  /// Daily recommendation banner title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Picks'**
  String get dailyRecommendation;

  /// Continue listening section title
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// Commute scene mix card title
  ///
  /// In en, this message translates to:
  /// **'Commute Mix'**
  String get commuteMix;

  /// Study scene mix card title
  ///
  /// In en, this message translates to:
  /// **'Study Mix'**
  String get studyMix;

  /// Sleep scene mix card title
  ///
  /// In en, this message translates to:
  /// **'Sleep Mix'**
  String get sleepMix;

  /// Favorites mix card title (top songs by behavior score)
  ///
  /// In en, this message translates to:
  /// **'Favorites Mix'**
  String get favoritesMix;

  /// Discover section title
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// AI playlist entry card title
  ///
  /// In en, this message translates to:
  /// **'AI Playlist'**
  String get aiPlaylist;

  /// AI playlist entry card subtitle
  ///
  /// In en, this message translates to:
  /// **'Describe what you want to hear'**
  String get aiPlaylistSubtitle;

  /// Placeholder text for a mix that has no content yet
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generating;

  /// Add all songs to the current playback queue
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToCurrentQueue;

  /// Snackbar shown after songs are added to the queue
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// Song count shown in the detail page hero
  ///
  /// In en, this message translates to:
  /// **'{count} Songs'**
  String songCount(int count);

  /// Daily recommendation detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'Updated daily'**
  String get dailySubtitle;

  /// Commute mix detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'High energy'**
  String get commuteSubtitle;

  /// Study mix detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'Stay focused'**
  String get studySubtitle;

  /// Sleep mix detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'Wind down'**
  String get sleepSubtitle;

  /// Favorites mix detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'Your favorites'**
  String get favoritesSubtitle;

  /// Discover section detail page hero subtitle
  ///
  /// In en, this message translates to:
  /// **'Fresh to you'**
  String get discoverSubtitle;

  /// No description provided for @dailySlogan1.
  ///
  /// In en, this message translates to:
  /// **'Start today with a great song'**
  String get dailySlogan1;

  /// No description provided for @dailySlogan2.
  ///
  /// In en, this message translates to:
  /// **'Something new every day'**
  String get dailySlogan2;

  /// No description provided for @dailySlogan3.
  ///
  /// In en, this message translates to:
  /// **'What do you feel like today?'**
  String get dailySlogan3;

  /// No description provided for @commuteSlogan1.
  ///
  /// In en, this message translates to:
  /// **'Power up your commute'**
  String get commuteSlogan1;

  /// No description provided for @commuteSlogan2.
  ///
  /// In en, this message translates to:
  /// **'Fuel up before you go'**
  String get commuteSlogan2;

  /// No description provided for @commuteSlogan3.
  ///
  /// In en, this message translates to:
  /// **'Make the ride your own rhythm'**
  String get commuteSlogan3;

  /// No description provided for @studySlogan1.
  ///
  /// In en, this message translates to:
  /// **'A quiet world, just you and the music'**
  String get studySlogan1;

  /// No description provided for @studySlogan2.
  ///
  /// In en, this message translates to:
  /// **'Stay focused, notes in flow'**
  String get studySlogan2;

  /// No description provided for @studySlogan3.
  ///
  /// In en, this message translates to:
  /// **'Let focus have its soundtrack'**
  String get studySlogan3;

  /// No description provided for @sleepSlogan1.
  ///
  /// In en, this message translates to:
  /// **'Make tonight\'s dreams a little softer'**
  String get sleepSlogan1;

  /// No description provided for @sleepSlogan2.
  ///
  /// In en, this message translates to:
  /// **'Take it slow, sleep well'**
  String get sleepSlogan2;

  /// No description provided for @sleepSlogan3.
  ///
  /// In en, this message translates to:
  /// **'A slow song for the night'**
  String get sleepSlogan3;

  /// No description provided for @favoritesSlogan1.
  ///
  /// In en, this message translates to:
  /// **'The ones you saved are the ones you love'**
  String get favoritesSlogan1;

  /// No description provided for @favoritesSlogan2.
  ///
  /// In en, this message translates to:
  /// **'Your most-played, all here'**
  String get favoritesSlogan2;

  /// No description provided for @favoritesSlogan3.
  ///
  /// In en, this message translates to:
  /// **'Every song you loved counts'**
  String get favoritesSlogan3;

  /// No description provided for @discoverSlogan1.
  ///
  /// In en, this message translates to:
  /// **'The next one might be your new favorite'**
  String get discoverSlogan1;

  /// No description provided for @discoverSlogan2.
  ///
  /// In en, this message translates to:
  /// **'Wander somewhere you haven\'t been'**
  String get discoverSlogan2;

  /// No description provided for @discoverSlogan3.
  ///
  /// In en, this message translates to:
  /// **'Switch it up, hear something fresh'**
  String get discoverSlogan3;

  /// Top rated albums title
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// Message when no content is available
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// Message to try refreshing
  ///
  /// In en, this message translates to:
  /// **'Try refreshing or check your server connection'**
  String get tryRefreshing;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Library refresh completed with counts
  ///
  /// In en, this message translates to:
  /// **'{albumCount} albums, {songCount} songs'**
  String refreshComplete(int albumCount, int songCount);

  /// Snackbar when a library refresh fails
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailed;

  /// Snackbar after reloading local library
  ///
  /// In en, this message translates to:
  /// **'Library refreshed'**
  String get refreshLocalComplete;

  /// Error state title when songs fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading songs'**
  String get errorLoadingSongs;

  /// Message when genre has no songs
  ///
  /// In en, this message translates to:
  /// **'No songs in this genre'**
  String get noSongsInGenre;

  /// Error state title when albums fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading albums'**
  String get errorLoadingAlbums;

  /// Empty state when there are no top rated albums
  ///
  /// In en, this message translates to:
  /// **'No top rated albums'**
  String get noTopRatedAlbums;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Server URL field label
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Certificate selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select TLS/SSL Certificate'**
  String get selectCertificate;

  /// Error message when certificate selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select certificate: {error}'**
  String failedToSelectCertificate(String error);

  /// Error message for invalid server URL
  ///
  /// In en, this message translates to:
  /// **'Server URL must start with http:// or https://'**
  String get serverUrlMustStartWith;

  /// Error message when connection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get failedToConnect;

  /// Library tab label
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Albums section label
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// Artists section label
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// Songs section label
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// Playlists section label
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Genres section label
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// Years filter tab label
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// Favorites section label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Now playing screen title
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// Queue section label
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// Lyrics section label
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// Play button label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button label
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button label
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Shuffle button label
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// Repeat button label
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Repeat one button label
  ///
  /// In en, this message translates to:
  /// **'Repeat One'**
  String get repeatOne;

  /// Repeat off button label
  ///
  /// In en, this message translates to:
  /// **'Repeat Off'**
  String get repeatOff;

  /// Add to playlist option
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// Remove from playlist option
  ///
  /// In en, this message translates to:
  /// **'Remove from Playlist'**
  String get removeFromPlaylist;

  /// Tooltip to add to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Tooltip to remove from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Download button label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Button to save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// General settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Playback settings section
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// Storage settings section
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// About settings section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Version info label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// GitHub repository link label
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepository;

  /// Report issue link label
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// Fallback displayed when a song has no artist
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// Placeholder for unknown album
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// Play all button label
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// Shuffle all button label
  ///
  /// In en, this message translates to:
  /// **'Shuffle All'**
  String get shuffleAll;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Sort by name option
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// Sort by artist option
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortByArtist;

  /// Sort by album option
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortByAlbum;

  /// Sort by date option
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// Sort by duration option
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortByDuration;

  /// Ascending sort order
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// Descending sort order
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// Message when lyrics are not available
  ///
  /// In en, this message translates to:
  /// **'No lyrics available'**
  String get noLyricsAvailable;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search for songs, albums, artists...'**
  String get searchHint;

  /// All songs title
  ///
  /// In en, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// All albums title
  ///
  /// In en, this message translates to:
  /// **'All Albums'**
  String get allAlbums;

  /// All artists title
  ///
  /// In en, this message translates to:
  /// **'All Artists'**
  String get allArtists;

  /// Track number label
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String trackNumber(int number);

  /// Songs count with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String songsCount(int count);

  /// Albums count with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No albums} =1{1 album} other{{count} albums}}'**
  String albumsCount(int count);

  /// No description provided for @topArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top artists'**
  String get topArtistsTitle;

  /// No description provided for @playsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No plays} =1{1 play} other{{count} plays}}'**
  String playsCount(num count);

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Offline mode label
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Radio section label
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radio;

  /// Audiobooks section label (Daoliyu)
  ///
  /// In en, this message translates to:
  /// **'Audiobooks'**
  String get audiobooks;

  /// Audiobook chapter progress subtitle
  ///
  /// In en, this message translates to:
  /// **'Played to {position}'**
  String playedTo(String position);

  /// Audiobook chapter finished label
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// Audiobook chapter count
  ///
  /// In en, this message translates to:
  /// **'{count} Chapters'**
  String chapterCount(int count);

  /// Audiobook chapter ordinal label (e.g. Chapter 3)
  ///
  /// In en, this message translates to:
  /// **'Chapter {count}'**
  String chapterX(int count);

  /// Error state message on the audiobook list screen
  ///
  /// In en, this message translates to:
  /// **'Failed to load audiobooks'**
  String get failedToLoadAudiobooks;

  /// Error state message on the audiobook detail screen
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapters, please retry'**
  String get failedToLoadChapters;

  /// Snackbar when queue operations are attempted while playing an audiobook
  ///
  /// In en, this message translates to:
  /// **'Please exit the audiobook first'**
  String get exitAudiobookFirst;

  /// Dialog title for jumping to a specific chapter (numbered audiobooks)
  ///
  /// In en, this message translates to:
  /// **'Jump to chapter'**
  String get jumpToChapter;

  /// In-book search hint and empty-state text (collection audiobooks)
  ///
  /// In en, this message translates to:
  /// **'Search chapters'**
  String get searchChapters;

  /// In-book search empty result state
  ///
  /// In en, this message translates to:
  /// **'No matching chapters'**
  String get noSearchResults;

  /// Changelog link label
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// Platform info label
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// Server settings section
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// Display settings section
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// Player Interface settings section
  ///
  /// In en, this message translates to:
  /// **'Player Interface'**
  String get playerInterface;

  /// Smart Recommendations settings section title
  ///
  /// In en, this message translates to:
  /// **'Smart Recommendations'**
  String get smartRecommendations;

  /// Show Volume Slider toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Volume Slider'**
  String get showVolumeSlider;

  /// Show Volume Slider toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Display volume control in Now Playing screen'**
  String get showVolumeSliderSubtitle;

  /// Show Star Ratings toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Star Ratings'**
  String get showStarRatings;

  /// Show Star Ratings toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Rate songs and view ratings'**
  String get showStarRatingsSubtitle;

  /// Show Heart button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Heart Button'**
  String get showMiniPlayerHeart;

  /// Show Heart button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Add to favorites from mini player'**
  String get showMiniPlayerHeartSubtitle;

  /// Show Repeat button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Repeat Button'**
  String get showMiniPlayerRepeat;

  /// Show Repeat button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Toggle repeat mode from mini player'**
  String get showMiniPlayerRepeatSubtitle;

  /// Show Shuffle button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Shuffle Button'**
  String get showMiniPlayerShuffle;

  /// Show Shuffle button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Toggle shuffle from mini player'**
  String get showMiniPlayerShuffleSubtitle;

  /// Enable Recommendations toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Recommendations'**
  String get enableRecommendations;

  /// Enable Recommendations toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Get personalized music suggestions'**
  String get enableRecommendationsSubtitle;

  /// Listening Data section label
  ///
  /// In en, this message translates to:
  /// **'Listening Data'**
  String get listeningData;

  /// Total plays count
  ///
  /// In en, this message translates to:
  /// **'{count} total plays'**
  String totalPlays(int count);

  /// Clear Listening History button label
  ///
  /// In en, this message translates to:
  /// **'Clear Listening History'**
  String get clearListeningHistory;

  /// Confirmation dialog for clearing history
  ///
  /// In en, this message translates to:
  /// **'This will reset all your listening data and recommendations. Are you sure?'**
  String get confirmClearHistory;

  /// SnackBar message when history is cleared
  ///
  /// In en, this message translates to:
  /// **'Listening history cleared'**
  String get historyCleared;

  /// Discord RPC toggle label
  ///
  /// In en, this message translates to:
  /// **'Discord Status'**
  String get discordStatus;

  /// Discord RPC toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Show playing song on Discord profile'**
  String get discordStatusSubtitle;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your Library'**
  String get yourLibrary;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @faves.
  ///
  /// In en, this message translates to:
  /// **'Faves'**
  String get faves;

  /// No description provided for @filterPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get filterPlaylists;

  /// No description provided for @filterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get filterAlbums;

  /// No description provided for @filterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get filterArtists;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get likedSongs;

  /// No description provided for @localMusicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Local Music Library'**
  String get localMusicLibrary;

  /// No description provided for @mergeLocalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Merge with Server Library'**
  String get mergeLocalLibrary;

  /// No description provided for @mergeLocalLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show local music alongside your server library'**
  String get mergeLocalLibrarySubtitle;

  /// No description provided for @localMusicStats.
  ///
  /// In en, this message translates to:
  /// **'Local Music Files'**
  String get localMusicStats;

  /// No description provided for @addMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Music Folder'**
  String get addMusicFolder;

  /// No description provided for @rescanLocalMusic.
  ///
  /// In en, this message translates to:
  /// **'Rescan Local Music'**
  String get rescanLocalMusic;

  /// No description provided for @localLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get localLibraryEmpty;

  /// No description provided for @localLibraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No local music files were found. Tap the button below to scan again.'**
  String get localLibraryEmptySubtitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add some songs to get started.'**
  String get libraryEmptySubtitle;

  /// No description provided for @scanForMusic.
  ///
  /// In en, this message translates to:
  /// **'Scan for Music'**
  String get scanForMusic;

  /// No description provided for @radioStations.
  ///
  /// In en, this message translates to:
  /// **'Radio Stations'**
  String get radioStations;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// Subtitle shown in the mini player and player bar when a radio station is playing
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get internetRadio;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the playlist \"{name}\"?'**
  String deletePlaylistConfirmation(String name);

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" deleted'**
  String playlistDeleted(String name);

  /// No description provided for @errorCreatingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error creating playlist: {error}'**
  String errorCreatingPlaylist(Object error);

  /// No description provided for @errorDeletingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error deleting playlist: {error}'**
  String errorDeletingPlaylist(Object error);

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" created'**
  String playlistCreated(String name);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Artists, Songs, Albums'**
  String get searchPlaceholder;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get tryDifferentSearch;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get noSuggestions;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @liveSearchSection.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get liveSearchSection;

  /// No description provided for @liveSearch.
  ///
  /// In en, this message translates to:
  /// **'Live Search'**
  String get liveSearch;

  /// No description provided for @liveSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update results as you type instead of showing a dropdown'**
  String get liveSearchSubtitle;

  /// No description provided for @categoryMadeForYou.
  ///
  /// In en, this message translates to:
  /// **'Made For You'**
  String get categoryMadeForYou;

  /// No description provided for @categoryNewReleases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get categoryNewReleases;

  /// No description provided for @categoryTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get categoryTopRated;

  /// No description provided for @categoryGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get categoryGenres;

  /// No description provided for @categoryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get categoryFavorites;

  /// No description provided for @categoryRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get categoryRadio;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @tabPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get tabPlayback;

  /// No description provided for @tabStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get tabStorage;

  /// No description provided for @tabServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get tabServer;

  /// No description provided for @tabDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get tabDisplay;

  /// No description provided for @tabAiPlaylist.
  ///
  /// In en, this message translates to:
  /// **'AI Playlist'**
  String get tabAiPlaylist;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @tabDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get tabDiagnostics;

  /// No description provided for @settingsGroupServer.
  ///
  /// In en, this message translates to:
  /// **'Server & Account'**
  String get settingsGroupServer;

  /// No description provided for @settingsServerSettings.
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get settingsServerSettings;

  /// No description provided for @serverManagement.
  ///
  /// In en, this message translates to:
  /// **'Server Management'**
  String get serverManagement;

  /// No description provided for @noSavedProfiles.
  ///
  /// In en, this message translates to:
  /// **'No saved server configurations yet'**
  String get noSavedProfiles;

  /// No description provided for @connectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get connectedSuccessfully;

  /// No description provided for @settingsGroupPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback & Quality'**
  String get settingsGroupPlayback;

  /// No description provided for @settingsPlaybackSettings.
  ///
  /// In en, this message translates to:
  /// **'Playback Settings'**
  String get settingsPlaybackSettings;

  /// No description provided for @settingsStreamingEntry.
  ///
  /// In en, this message translates to:
  /// **'Streaming Quality'**
  String get settingsStreamingEntry;

  /// No description provided for @settingsGroupStorage.
  ///
  /// In en, this message translates to:
  /// **'Download & Storage'**
  String get settingsGroupStorage;

  /// No description provided for @settingsStorageEntry.
  ///
  /// In en, this message translates to:
  /// **'Download & Storage'**
  String get settingsStorageEntry;

  /// No description provided for @settingsGroupDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display & Appearance'**
  String get settingsGroupDisplay;

  /// No description provided for @settingsDisplayEntry.
  ///
  /// In en, this message translates to:
  /// **'Player Interface'**
  String get settingsDisplayEntry;

  /// Settings root group title: about this app
  ///
  /// In en, this message translates to:
  /// **'About Luobo'**
  String get settingsGroupAbout;

  /// No description provided for @settingsGroupAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsGroupAi;

  /// No description provided for @settingsAiEntry.
  ///
  /// In en, this message translates to:
  /// **'AI Playlists & Knowledge'**
  String get settingsAiEntry;

  /// No description provided for @settingsGroupSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get settingsGroupSupport;

  /// No description provided for @settingsMechanicsEntry.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get settingsMechanicsEntry;

  /// No description provided for @mechanicsGroupRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Home Recommendations'**
  String get mechanicsGroupRecommendation;

  /// No description provided for @mechanicsGroupListeningReport.
  ///
  /// In en, this message translates to:
  /// **'Listening Report'**
  String get mechanicsGroupListeningReport;

  /// No description provided for @mechanicsGroupStorage.
  ///
  /// In en, this message translates to:
  /// **'Download & Storage'**
  String get mechanicsGroupStorage;

  /// No description provided for @mechanicsGroupAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get mechanicsGroupAi;

  /// No description provided for @mechanicsGroupAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mechanicsGroupAudio;

  /// No description provided for @mechanicsGroupConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connect & Cast'**
  String get mechanicsGroupConnectivity;

  /// No description provided for @mechanicsGroupDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics & Privacy'**
  String get mechanicsGroupDiagnostics;

  /// No description provided for @mechanicsTechDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get mechanicsTechDetails;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search event type / content'**
  String get diagnosticsSearchHint;

  /// No description provided for @diagnosticsNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get diagnosticsNoLogs;

  /// No description provided for @diagnosticsExported.
  ///
  /// In en, this message translates to:
  /// **'Logs exported: {path}'**
  String diagnosticsExported(Object path);

  /// No description provided for @diagnosticsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed, check storage space'**
  String get diagnosticsExportFailed;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard (latest 2000)'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear diagnostics logs'**
  String get diagnosticsClearTitle;

  /// No description provided for @diagnosticsClearMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all local diagnostics logs and metrics. Export first if needed.'**
  String get diagnosticsClearMessage;

  /// No description provided for @diagnosticsClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get diagnosticsClearAction;

  /// No description provided for @diagnosticsMetricFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get diagnosticsMetricFps;

  /// No description provided for @diagnosticsMetricJankRate.
  ///
  /// In en, this message translates to:
  /// **'jank rate'**
  String get diagnosticsMetricJankRate;

  /// No description provided for @diagnosticsMetricRequests.
  ///
  /// In en, this message translates to:
  /// **'requests'**
  String get diagnosticsMetricRequests;

  /// No description provided for @diagnosticsMetricNetP90.
  ///
  /// In en, this message translates to:
  /// **'net p90'**
  String get diagnosticsMetricNetP90;

  /// No description provided for @diagnosticsMetricErrorRate.
  ///
  /// In en, this message translates to:
  /// **'error rate'**
  String get diagnosticsMetricErrorRate;

  /// No description provided for @diagnosticsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get diagnosticsAll;

  /// No description provided for @diagnosticsLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'debug'**
  String get diagnosticsLevelDebug;

  /// No description provided for @diagnosticsLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'info'**
  String get diagnosticsLevelInfo;

  /// No description provided for @diagnosticsLevelWarn.
  ///
  /// In en, this message translates to:
  /// **'warn'**
  String get diagnosticsLevelWarn;

  /// No description provided for @diagnosticsLevelError.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get diagnosticsLevelError;

  /// No description provided for @diagnosticsTooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get diagnosticsTooltipCopy;

  /// No description provided for @diagnosticsTooltipExport.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get diagnosticsTooltipExport;

  /// No description provided for @diagnosticsTooltipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get diagnosticsTooltipClear;

  /// No description provided for @renderError.
  ///
  /// In en, this message translates to:
  /// **'Render error\n{err}'**
  String renderError(Object err);

  /// Playback settings section header for Auto DJ
  ///
  /// In en, this message translates to:
  /// **'AUTO DJ'**
  String get sectionAutoDj;

  /// No description provided for @autoDjMode.
  ///
  /// In en, this message translates to:
  /// **'Auto DJ Mode'**
  String get autoDjMode;

  /// Auto DJ mode option: disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoDjModeOff;

  /// Auto DJ mode option: shuffle library
  ///
  /// In en, this message translates to:
  /// **'Shuffle Library'**
  String get autoDjModeShuffleLibrary;

  /// Auto DJ mode option: similar songs
  ///
  /// In en, this message translates to:
  /// **'Similar Songs'**
  String get autoDjModeSimilarSongs;

  /// Auto DJ mode option: same genre
  ///
  /// In en, this message translates to:
  /// **'Same Genre'**
  String get autoDjModeSameGenre;

  /// Auto DJ mode option: same artist
  ///
  /// In en, this message translates to:
  /// **'Same Artist'**
  String get autoDjModeSameArtist;

  /// Auto DJ mode option: smart mix
  ///
  /// In en, this message translates to:
  /// **'Smart Mix'**
  String get autoDjModeSmartMix;

  /// No description provided for @songsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Songs to Add: {count}'**
  String songsToAdd(int count);

  /// No description provided for @sectionReplayGain.
  ///
  /// In en, this message translates to:
  /// **'VOLUME NORMALIZATION (REPLAYGAIN)'**
  String get sectionReplayGain;

  /// Label for the ReplayGain mode selector
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get replayGainMode;

  /// No description provided for @preamp.
  ///
  /// In en, this message translates to:
  /// **'Preamp: {value} dB'**
  String preamp(String value);

  /// No description provided for @preventClipping.
  ///
  /// In en, this message translates to:
  /// **'Prevent Clipping'**
  String get preventClipping;

  /// No description provided for @fallbackGain.
  ///
  /// In en, this message translates to:
  /// **'Fallback Gain: {value} dB'**
  String fallbackGain(String value);

  /// Playback settings section header for transcoding / streaming quality
  ///
  /// In en, this message translates to:
  /// **'STREAMING QUALITY'**
  String get sectionStreamingQuality;

  /// No description provided for @enableTranscoding.
  ///
  /// In en, this message translates to:
  /// **'Enable Transcoding'**
  String get enableTranscoding;

  /// No description provided for @qualityWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi Quality'**
  String get qualityWifi;

  /// No description provided for @qualityMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Quality'**
  String get qualityMobile;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @transcodingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce data usage with lower quality'**
  String get transcodingSubtitle;

  /// No description provided for @modeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get modeOff;

  /// No description provided for @modeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get modeTrack;

  /// No description provided for @modeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get modeAlbum;

  /// No description provided for @sectionServerConnection.
  ///
  /// In en, this message translates to:
  /// **'SERVER CONNECTION'**
  String get sectionServerConnection;

  /// Section title for server type selector
  ///
  /// In en, this message translates to:
  /// **'Server Type'**
  String get serverType;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @sectionMusicFolders.
  ///
  /// In en, this message translates to:
  /// **'MUSIC FOLDERS'**
  String get sectionMusicFolders;

  /// No description provided for @musicFolders.
  ///
  /// In en, this message translates to:
  /// **'Music Folders'**
  String get musicFolders;

  /// No description provided for @noMusicFolders.
  ///
  /// In en, this message translates to:
  /// **'No music folders found'**
  String get noMusicFolders;

  /// No description provided for @sectionSavedProfiles.
  ///
  /// In en, this message translates to:
  /// **'SAVED PROFILES'**
  String get sectionSavedProfiles;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @switchServer.
  ///
  /// In en, this message translates to:
  /// **'Switch Server'**
  String get switchServer;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfile;

  /// Button to show QR code for server config sharing
  ///
  /// In en, this message translates to:
  /// **'Share via QR Code'**
  String get shareQrCode;

  /// Button to scan QR code to add server config
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// Title of the QR code display dialog
  ///
  /// In en, this message translates to:
  /// **'Server QR Code'**
  String get qrCodeTitle;

  /// Subtitle of the QR code dialog
  ///
  /// In en, this message translates to:
  /// **'Scan this code to add server configuration'**
  String get qrCodeSubtitle;

  /// Button to save QR code image to photo gallery
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// Snackbar after QR code saved
  ///
  /// In en, this message translates to:
  /// **'QR code saved to gallery'**
  String get savedToGallery;

  /// Error snackbar when QR code save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save QR code'**
  String get failedToSaveQr;

  /// Tab label for scanning from camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get scanFromCamera;

  /// Tab label for scanning from photo gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scanFromGallery;

  /// Error when scanned QR code is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Not a valid server configuration.'**
  String get invalidQrCode;

  /// Snackbar after QR config imported
  ///
  /// In en, this message translates to:
  /// **'Server configuration imported successfully'**
  String get qrConfigImported;

  /// No description provided for @switchProfileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Connect to \"{profile}\"?'**
  String switchProfileConfirmation(String profile);

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout? This will also clear all cached data.'**
  String get logoutConfirmation;

  /// Storage settings section header
  ///
  /// In en, this message translates to:
  /// **'CACHE SETTINGS'**
  String get sectionCacheSettings;

  /// No description provided for @imageCache.
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get imageCache;

  /// No description provided for @musicCache.
  ///
  /// In en, this message translates to:
  /// **'Music Cache'**
  String get musicCache;

  /// No description provided for @bpmCache.
  ///
  /// In en, this message translates to:
  /// **'BPM Cache'**
  String get bpmCache;

  /// No description provided for @saveAlbumCovers.
  ///
  /// In en, this message translates to:
  /// **'Save album covers locally'**
  String get saveAlbumCovers;

  /// No description provided for @saveSongMetadata.
  ///
  /// In en, this message translates to:
  /// **'Save song metadata locally'**
  String get saveSongMetadata;

  /// No description provided for @saveBpmAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Save BPM analysis locally'**
  String get saveBpmAnalysis;

  /// Storage settings section header for cache cleanup
  ///
  /// In en, this message translates to:
  /// **'CACHE CLEANUP'**
  String get sectionCacheCleanup;

  /// Button to clear all cached data
  ///
  /// In en, this message translates to:
  /// **'Clear All Cache'**
  String get clearAllCache;

  /// No description provided for @allCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'All cache cleared'**
  String get allCacheCleared;

  /// Storage settings section header for offline downloads
  ///
  /// In en, this message translates to:
  /// **'OFFLINE DOWNLOADS'**
  String get sectionOfflineDownloads;

  /// No description provided for @downloadedSongs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Songs'**
  String get downloadedSongs;

  /// No description provided for @downloadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Downloading Library... {progress}/{total}'**
  String downloadingLibrary(int progress, int total);

  /// No description provided for @downloadAllLibrary.
  ///
  /// In en, this message translates to:
  /// **'Download All Library'**
  String get downloadAllLibrary;

  /// No description provided for @downloadLibraryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will download {count} songs to your device. This may take a while and use significant storage space.\n\nContinue?'**
  String downloadLibraryConfirm(int count);

  /// Toggle to keep screen on during library download
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get keepScreenOnDuringDownload;

  /// Subtitle explaining why to keep screen on during download
  ///
  /// In en, this message translates to:
  /// **'Prevents download from failing when device locks'**
  String get keepScreenOnDuringDownloadSubtitle;

  /// No description provided for @parallelDownloads.
  ///
  /// In en, this message translates to:
  /// **'Parallel Downloads'**
  String get parallelDownloads;

  /// No description provided for @parallelDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download multiple songs simultaneously'**
  String get parallelDownloadsSubtitle;

  /// No description provided for @downloadSingular.
  ///
  /// In en, this message translates to:
  /// **'download'**
  String get downloadSingular;

  /// No description provided for @downloadPlural.
  ///
  /// In en, this message translates to:
  /// **'downloads'**
  String get downloadPlural;

  /// No description provided for @slowerButStable.
  ///
  /// In en, this message translates to:
  /// **'Slower but more stable'**
  String get slowerButStable;

  /// No description provided for @fasterButMoreData.
  ///
  /// In en, this message translates to:
  /// **'Faster but uses more data'**
  String get fasterButMoreData;

  /// No description provided for @libraryDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Library download started'**
  String get libraryDownloadStarted;

  /// No description provided for @deleteDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete All Downloads'**
  String get deleteDownloads;

  /// No description provided for @downloadsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All downloads deleted'**
  String get downloadsDeleted;

  /// Empty state when no songs are available
  ///
  /// In en, this message translates to:
  /// **'No songs available'**
  String get noSongsAvailable;

  /// Storage settings section header for BPM analysis
  ///
  /// In en, this message translates to:
  /// **'BPM ANALYSIS'**
  String get sectionBpmAnalysis;

  /// No description provided for @cachedBpms.
  ///
  /// In en, this message translates to:
  /// **'Cached BPMs'**
  String get cachedBpms;

  /// No description provided for @cacheAllBpms.
  ///
  /// In en, this message translates to:
  /// **'Cache All BPMs'**
  String get cacheAllBpms;

  /// No description provided for @clearBpmCache.
  ///
  /// In en, this message translates to:
  /// **'Clear BPM Cache'**
  String get clearBpmCache;

  /// No description provided for @bpmCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'BPM cache cleared'**
  String get bpmCacheCleared;

  /// No description provided for @downloadedStats.
  ///
  /// In en, this message translates to:
  /// **'{count} songs • {size}'**
  String downloadedStats(int count, String size);

  /// No description provided for @sectionInformation.
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get sectionInformation;

  /// No description provided for @sectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get sectionDeveloper;

  /// No description provided for @sectionLinks.
  ///
  /// In en, this message translates to:
  /// **'LINKS'**
  String get sectionLinks;

  /// No description provided for @githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepo;

  /// No description provided for @playingFrom.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM'**
  String get playingFrom;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @streamingLive.
  ///
  /// In en, this message translates to:
  /// **'Streaming Live'**
  String get streamingLive;

  /// No description provided for @stopRadio.
  ///
  /// In en, this message translates to:
  /// **'Stop Radio'**
  String get stopRadio;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from Liked Songs'**
  String get removeFromLiked;

  /// No description provided for @addToLiked.
  ///
  /// In en, this message translates to:
  /// **'Add to Liked Songs'**
  String get addToLiked;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play Next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @goToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to Album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to Artist'**
  String get goToArtist;

  /// No description provided for @rateSong.
  ///
  /// In en, this message translates to:
  /// **'Rate Song'**
  String get rateSong;

  /// No description provided for @rateSongValue.
  ///
  /// In en, this message translates to:
  /// **'Rate Song ({rating} {stars})'**
  String rateSongValue(int rating, String stars);

  /// Snackbar after removing a rating
  ///
  /// In en, this message translates to:
  /// **'Rating removed'**
  String get ratingRemoved;

  /// No description provided for @rated.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} {stars}'**
  String rated(int rating, String stars);

  /// No description provided for @removeRating.
  ///
  /// In en, this message translates to:
  /// **'Remove Rating'**
  String get removeRating;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String downloading(int percent);

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownload;

  /// No description provided for @removeDownloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this song from offline storage?'**
  String get removeDownloadConfirm;

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed'**
  String get downloadRemoved;

  /// No description provided for @downloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded \"{title}\"'**
  String downloadedTitle(String title);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download error: {error}'**
  String downloadError(Object error);

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to {playlist}'**
  String addedToPlaylist(String title, String playlist);

  /// No description provided for @errorAddingToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error adding to playlist: {error}'**
  String errorAddingToPlaylist(Object error);

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists available'**
  String get noPlaylists;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// No description provided for @artistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Artist \"{name}\" not found'**
  String artistNotFound(String name);

  /// No description provided for @errorSearchingArtist.
  ///
  /// In en, this message translates to:
  /// **'Error searching for artist: {error}'**
  String errorSearchingArtist(Object error);

  /// No description provided for @selectArtist.
  ///
  /// In en, this message translates to:
  /// **'Select Artist'**
  String get selectArtist;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'star'**
  String get star;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'stars'**
  String get stars;

  /// Message when album data is not available
  ///
  /// In en, this message translates to:
  /// **'Album not found'**
  String get albumNotFound;

  /// Album duration formatted as hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours} HR {minutes} MIN'**
  String durationHoursMinutes(int hours, int minutes);

  /// Album duration in minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN'**
  String durationMinutes(int minutes);

  /// Top songs section header on artist screen
  ///
  /// In en, this message translates to:
  /// **'Top Songs'**
  String get topSongs;

  /// Server connection status — connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Error message when reading saved profiles fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load saved servers'**
  String get failedToLoadProfiles;

  /// Placeholder when no song is loaded in the player
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get noSongPlaying;

  /// Uppercase badge shown in the now-playing radio player
  ///
  /// In en, this message translates to:
  /// **'INTERNET RADIO'**
  String get internetRadioUppercase;

  /// Title of the queue / playing-next bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Playing Next'**
  String get playingNext;

  /// Title of the create-new-playlist dialog
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylistTitle;

  /// Hint text for the playlist name input field
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// Snackbar shown after creating a playlist with the current song
  ///
  /// In en, this message translates to:
  /// **'Created playlist \"{name}\" with this song'**
  String playlistCreatedWithSong(String name);

  /// Snackbar shown when playlists fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists: {error}'**
  String errorLoadingPlaylists(Object error);

  /// Empty state when playlist cannot be found
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// Empty state when playlist has no songs
  ///
  /// In en, this message translates to:
  /// **'No songs in this playlist'**
  String get noSongsInPlaylist;

  /// Empty state for the favorite songs list
  ///
  /// In en, this message translates to:
  /// **'No favorite songs yet'**
  String get noFavoriteSongsYet;

  /// Empty state for the favorite albums list
  ///
  /// In en, this message translates to:
  /// **'No favorite albums yet'**
  String get noFavoriteAlbumsYet;

  /// App bar title for listening history screen
  ///
  /// In en, this message translates to:
  /// **'Listening History'**
  String get listeningHistory;

  /// Empty state title for listening history
  ///
  /// In en, this message translates to:
  /// **'No Listening History'**
  String get noListeningHistory;

  /// Empty state subtitle on the history screen
  ///
  /// In en, this message translates to:
  /// **'Songs you play will appear here'**
  String get songsWillAppearHere;

  /// Sort option: artist ascending
  ///
  /// In en, this message translates to:
  /// **'Artist (A-Z)'**
  String get sortByArtistAZ;

  /// Sort option: artist descending
  ///
  /// In en, this message translates to:
  /// **'Artist (Z-A)'**
  String get sortByArtistZA;

  /// Sort option: album ascending
  ///
  /// In en, this message translates to:
  /// **'Album (A-Z)'**
  String get sortByAlbumAZ;

  /// Sort option: album descending
  ///
  /// In en, this message translates to:
  /// **'Album (Z-A)'**
  String get sortByAlbumZA;

  /// Sort option: recently added
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// Empty state when no songs match a filter
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// Empty state when no albums match a filter
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// Snackbar when a radio station has no homepage URL
  ///
  /// In en, this message translates to:
  /// **'No homepage URL available'**
  String get noHomepageUrl;

  /// Context menu option to play a radio station
  ///
  /// In en, this message translates to:
  /// **'Play Station'**
  String get playStation;

  /// Context menu option to open a radio station's homepage
  ///
  /// In en, this message translates to:
  /// **'Open Homepage'**
  String get openHomepage;

  /// Context menu option to copy a radio station stream URL
  ///
  /// In en, this message translates to:
  /// **'Copy Stream URL'**
  String get copyStreamUrl;

  /// Error state title when radio stations fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load radio stations'**
  String get failedToLoadRadioStations;

  /// Empty state title when there are no radio stations
  ///
  /// In en, this message translates to:
  /// **'No Radio Stations'**
  String get noRadioStations;

  /// Empty state hint for radio stations
  ///
  /// In en, this message translates to:
  /// **'Add radio stations in your Navidrome server settings to see them here.'**
  String get noRadioStationsHint;

  /// Subtitle below the app name on the login screen
  ///
  /// In en, this message translates to:
  /// **'Connect to your Subsonic server'**
  String get connectToServerSubtitle;

  /// Validation message when server URL is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter server URL'**
  String get pleaseEnterServerUrl;

  /// Validation message when server URL format is invalid
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get invalidUrlFormat;

  /// Validation message when username is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseEnterUsername;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// Toggle label for legacy Subsonic authentication
  ///
  /// In en, this message translates to:
  /// **'Legacy Authentication'**
  String get legacyAuthentication;

  /// Subtitle for the legacy authentication toggle
  ///
  /// In en, this message translates to:
  /// **'Use for older Subsonic servers'**
  String get legacyAuthSubtitle;

  /// Toggle label to allow self-signed TLS certificates
  ///
  /// In en, this message translates to:
  /// **'Allow Self-Signed Certificates'**
  String get allowSelfSignedCerts;

  /// Subtitle for the self-signed certificate toggle
  ///
  /// In en, this message translates to:
  /// **'For servers with custom TLS/SSL certificates'**
  String get allowSelfSignedSubtitle;

  /// Expandable section label for advanced login options
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// Label for the custom certificate upload section
  ///
  /// In en, this message translates to:
  /// **'Custom TLS/SSL Certificate'**
  String get customTlsCertificate;

  /// Subtitle for the custom certificate upload section
  ///
  /// In en, this message translates to:
  /// **'Upload a custom certificate for servers with non-standard CA'**
  String get customCertificateSubtitle;

  /// Button label to open the certificate file picker
  ///
  /// In en, this message translates to:
  /// **'Select Certificate File'**
  String get selectCertificateFile;

  /// Label for the mutual TLS client certificate section
  ///
  /// In en, this message translates to:
  /// **'Client Certificate (mTLS)'**
  String get clientCertificate;

  /// Subtitle for the client certificate (mTLS) section
  ///
  /// In en, this message translates to:
  /// **'Authenticate this client using a certificate (requires mTLS-enabled server)'**
  String get clientCertificateSubtitle;

  /// File picker dialog title for client certificate
  ///
  /// In en, this message translates to:
  /// **'Select Client Certificate'**
  String get selectClientCertificate;

  /// Hint text for the PKCS12 client certificate password field
  ///
  /// In en, this message translates to:
  /// **'Certificate password (optional)'**
  String get clientCertPassword;

  /// Error message when client certificate selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select client certificate: {error}'**
  String failedToSelectClientCert(String error);

  /// Login submit button label
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Label for the local network URL field on login screen
  ///
  /// In en, this message translates to:
  /// **'LAN URL (optional)'**
  String get lanUrl;

  /// Hint text for the local network URL field
  ///
  /// In en, this message translates to:
  /// **'http://192.168.x.x:4533'**
  String get lanUrlHint;

  /// Hint text for the server URL field
  ///
  /// In en, this message translates to:
  /// **'https://your-server.com'**
  String get serverUrlHint;

  /// Hint text for the username field
  ///
  /// In en, this message translates to:
  /// **'e.g. admin'**
  String get usernameHint;

  /// Hint text for the password field
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// Label for the optional profile name field
  ///
  /// In en, this message translates to:
  /// **'Profile Name (optional)'**
  String get profileNameLabel;

  /// Hint text for the profile name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Work, VPN'**
  String get profileNameHint;

  /// Divider label between Connect and Use Local Files
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Title of the privacy policy dialog header
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get privacyFirst;

  /// Subtitle in the privacy policy dialog header
  ///
  /// In en, this message translates to:
  /// **'Your data stays with you. Always.'**
  String get privacySubtitle;

  /// Privacy point title: no data selling
  ///
  /// In en, this message translates to:
  /// **'No Data Selling'**
  String get noDataSelling;

  /// Privacy point description: no data selling
  ///
  /// In en, this message translates to:
  /// **'We never sell, share, or transfer your personal data to third parties.'**
  String get noDataSellingDesc;

  /// Privacy point title: local storage
  ///
  /// In en, this message translates to:
  /// **'Local-First Storage'**
  String get localFirstStorage;

  /// Privacy point description: local storage
  ///
  /// In en, this message translates to:
  /// **'Your music library and credentials stay on your device.'**
  String get localFirstStorageDesc;

  /// Title for anonymous analytics toggle
  ///
  /// In en, this message translates to:
  /// **'Anonymous Analytics'**
  String get anonymousAnalytics;

  /// Privacy point description: anonymous analytics
  ///
  /// In en, this message translates to:
  /// **'With your consent, we collect only anonymous crash reports and usage stats. No personal identifiers.'**
  String get anonymousAnalyticsDesc;

  /// Link label to open the full privacy policy
  ///
  /// In en, this message translates to:
  /// **'Read Full Privacy Policy'**
  String get readFullPrivacyPolicy;

  /// Subtitle for the privacy policy link
  ///
  /// In en, this message translates to:
  /// **'View complete details on our website'**
  String get viewCompleteDetails;

  /// Accept button label in privacy dialog
  ///
  /// In en, this message translates to:
  /// **'I Understand & Continue'**
  String get agreeAndContinue;

  /// Decline button label in privacy dialog
  ///
  /// In en, this message translates to:
  /// **'Decline & Exit'**
  String get declineAndExit;

  /// Button label to start local-files mode
  ///
  /// In en, this message translates to:
  /// **'Use Local Files'**
  String get useLocalFiles;

  /// Scan status shown when starting a music scan
  ///
  /// In en, this message translates to:
  /// **'Starting scan...'**
  String get startingScan;

  /// Snackbar when storage permission is denied
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to scan local files'**
  String get storagePermissionRequired;

  /// Snackbar when a local scan finds no audio files
  ///
  /// In en, this message translates to:
  /// **'No music files found on your device'**
  String get noMusicFilesFound;

  /// Generic remove / delete confirm button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Snackbar shown when setting a star rating fails
  ///
  /// In en, this message translates to:
  /// **'Failed to set rating: {error}'**
  String failedToSetRating(Object error);

  /// Home navigation item label in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Uppercase section header for playlists in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'PLAYLISTS'**
  String get playlistsSection;

  /// Tooltip/label for the sidebar collapse button
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Tooltip/label for the sidebar expand button
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Tooltip/label for the create-playlist button in the sidebar library header
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylist;

  /// Liked Songs item label in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get likedSongsSidebar;

  /// Subtitle for a playlist item in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Playlist • {count} songs'**
  String playlistSongsCount(int count);

  /// Error state message when lyrics cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load lyrics'**
  String get failedToLoadLyrics;

  /// Empty/error subtitle in the lyrics view
  ///
  /// In en, this message translates to:
  /// **'Lyrics for this song couldn\'t be found'**
  String get lyricsNotFoundSubtitle;

  /// Button to scroll the lyrics view back to the current line
  ///
  /// In en, this message translates to:
  /// **'Back to current'**
  String get backToCurrent;

  /// Tooltip for the exit-fullscreen button in lyrics view
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen'**
  String get exitFullscreen;

  /// Tooltip for the enter-fullscreen button in lyrics view
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// Fallback text when no lyrics controller is available
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get noLyrics;

  /// Subtitle shown in the mini player when streaming internet radio
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get internetRadioMiniPlayer;

  /// Badge text shown in the mini player for live radio streams
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadge;

  /// Banner shown at the top of the screen in local-files mode
  ///
  /// In en, this message translates to:
  /// **'Local Files Mode'**
  String get localFilesModeBanner;

  /// Banner shown at the top of the screen in offline mode
  ///
  /// In en, this message translates to:
  /// **'Offline Mode – Playing downloaded music only'**
  String get offlineModeBanner;

  /// Title of the update available dialog
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// Subtitle in the update dialog
  ///
  /// In en, this message translates to:
  /// **'A new version of Luobo is available!'**
  String get updateAvailableSubtitle;

  /// Current version label in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Current: v{version}'**
  String updateCurrentVersion(String version);

  /// Latest version label in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Latest: v{version}'**
  String updateLatestVersion(String version);

  /// Section header for the changelog in the update dialog
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// Primary button in the update dialog that opens the release page
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadUpdate;

  /// Dismiss button in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get remindLater;

  /// See All button in horizontal scroll sections
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Error state on the artist screen when artist data fails to load
  ///
  /// In en, this message translates to:
  /// **'Artist not found'**
  String get artistDataNotFound;

  /// Snackbar when user adds artist to queue
  ///
  /// In en, this message translates to:
  /// **'Added artist to Queue'**
  String get addedArtistToQueue;

  /// Error shown in snackbar when adding artist to queue fails
  ///
  /// In en, this message translates to:
  /// **'Failed adding artist to Queue'**
  String get addedArtistToQueueError;

  /// Title shown in the Chromecast control dialog when actively casting
  ///
  /// In en, this message translates to:
  /// **'Casting'**
  String get casting;

  /// Title shown in the DLNA control dialog when connected
  ///
  /// In en, this message translates to:
  /// **'DLNA'**
  String get dlna;

  /// Title of the Cast/DLNA device picker dialog
  ///
  /// In en, this message translates to:
  /// **'Cast / DLNA (Beta)'**
  String get castDlnaBeta;

  /// Section header for Chromecast devices in the device picker
  ///
  /// In en, this message translates to:
  /// **'Chromecast'**
  String get chromecast;

  /// Section header for DLNA/UPnP devices in the device picker
  ///
  /// In en, this message translates to:
  /// **'DLNA / UPnP'**
  String get dlnaUpnp;

  /// Button to clear server credentials and go back to login
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Loading message in the device picker when no devices have been found yet
  ///
  /// In en, this message translates to:
  /// **'Searching for devices'**
  String get searchingDevices;

  /// Hint shown while searching for cast/DLNA devices
  ///
  /// In en, this message translates to:
  /// **'Make sure your Cast / DLNA device\nis on the same Wi-Fi network'**
  String get castWifiHint;

  /// Snackbar shown after successfully connecting to a cast/DLNA device
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String connectedToDevice(String name);

  /// Snackbar shown when connecting to a cast/DLNA device fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {name}'**
  String failedToConnectDevice(String name);

  /// Snackbar shown after un-liking a song in the song tile menu
  ///
  /// In en, this message translates to:
  /// **'Removed from Liked Songs'**
  String get removedFromLikedSongs;

  /// Snackbar shown after liking a song in the song tile menu
  ///
  /// In en, this message translates to:
  /// **'Added to Liked Songs'**
  String get addedToLikedSongs;

  /// Tooltip for the shuffle toggle button in the desktop player bar
  ///
  /// In en, this message translates to:
  /// **'Enable shuffle'**
  String get enableShuffle;

  /// Tooltip for the repeat toggle button in the desktop player bar
  ///
  /// In en, this message translates to:
  /// **'Enable repeat'**
  String get enableRepeat;

  /// Tooltip for the lyrics button when lyrics panel is open
  ///
  /// In en, this message translates to:
  /// **'Close Lyrics'**
  String get closeLyrics;

  /// Snackbar shown when the library background download fails to start
  ///
  /// In en, this message translates to:
  /// **'Error starting download: {error}'**
  String errorStartingDownload(Object error);

  /// Error message when the genre list fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading genres'**
  String get errorLoadingGenres;

  /// Empty state when no genres are returned from the server
  ///
  /// In en, this message translates to:
  /// **'No genres found'**
  String get noGenresFound;

  /// Empty state on the Albums tab of the genre screen
  ///
  /// In en, this message translates to:
  /// **'No albums in this genre'**
  String get noAlbumsInGenre;

  /// Tooltip shown when hovering a genre chip, showing song and album counts
  ///
  /// In en, this message translates to:
  /// **'{songCount} songs • {albumCount} albums'**
  String genreTooltip(int songCount, int albumCount);

  /// Title of the music folders selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Music Folders'**
  String get musicFoldersDialogTitle;

  /// Hint text in the music folders selection dialog
  ///
  /// In en, this message translates to:
  /// **'Leave all enabled to use all folders (default).'**
  String get musicFoldersHint;

  /// Snackbar shown after saving music folder selection
  ///
  /// In en, this message translates to:
  /// **'Music folder selection saved'**
  String get musicFoldersSaved;

  /// Display settings section header for artwork customisation
  ///
  /// In en, this message translates to:
  /// **'Artwork Style'**
  String get artworkStyleSection;

  /// Label for the album art corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get artworkCornerRadius;

  /// Subtitle for the album art corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Adjust how round the corners of album covers appear'**
  String get artworkCornerRadiusSubtitle;

  /// Label shown when corner radius is set to 0 (no rounded corners)
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get artworkCornerRadiusNone;

  /// Label for the artwork shape selector
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get artworkShape;

  /// Rounded rectangle artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get artworkShapeRounded;

  /// Circle artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get artworkShapeCircle;

  /// Square (no rounding) artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get artworkShapeSquare;

  /// Label for the artwork shadow intensity selector
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get artworkShadow;

  /// No shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get artworkShadowNone;

  /// Soft shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get artworkShadowSoft;

  /// Medium shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get artworkShadowMedium;

  /// Strong shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get artworkShadowStrong;

  /// Label for the artwork shadow color selector
  ///
  /// In en, this message translates to:
  /// **'Shadow Color'**
  String get artworkShadowColor;

  /// Black shadow color option
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get artworkShadowColorBlack;

  /// Accent color shadow (matches app accent color)
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get artworkShadowColorAccent;

  /// Label shown above the live artwork style preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get artworkPreview;

  /// Formatted corner radius value label
  ///
  /// In en, this message translates to:
  /// **'{value}px'**
  String artworkCornerRadiusLabel(int value);

  /// Placeholder label shown in the player when a song has no cover art
  ///
  /// In en, this message translates to:
  /// **'No artwork'**
  String get noArtwork;

  /// Title on the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server'**
  String get serverUnreachableTitle;

  /// Subtitle on the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Check your connection or server settings.'**
  String get serverUnreachableSubtitle;

  /// Button to enter offline mode from the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Open in offline mode'**
  String get openOfflineMode;

  /// Display settings section header for theme / appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// Label for the theme mode selector (System / Light / Dark)
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Label for the accent color picker
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColorLabel;

  /// Label for the Circular Design (glass-blur UI) toggle
  ///
  /// In en, this message translates to:
  /// **'Circular Design'**
  String get circularDesignLabel;

  /// Subtitle describing the Circular Design visual style
  ///
  /// In en, this message translates to:
  /// **'Floating, rounded UI with translucent panels and glass-blur effect on the player and navigation bar.'**
  String get circularDesignSubtitle;

  /// Theme mode option that follows the OS setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Appearance page section title: theme mode
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeTitle;

  /// App settings: clear cover image and app cache
  ///
  /// In en, this message translates to:
  /// **'Clear App Cache'**
  String get clearAppCache;

  /// Appearance page hint: glass effect is not customizable
  ///
  /// In en, this message translates to:
  /// **'Glass and card styling is defined by the design system and is not user-adjustable.'**
  String get appearanceGlassHint;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Badge shown next to a live radio stream
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// Settings label for the Discord Rich Presence second-line style
  ///
  /// In en, this message translates to:
  /// **'Discord status text'**
  String get discordStatusText;

  /// Subtitle for the Discord status text setting
  ///
  /// In en, this message translates to:
  /// **'Second line shown in Discord activity'**
  String get discordStatusTextSubtitle;

  /// Discord RPC state style option: show artist name
  ///
  /// In en, this message translates to:
  /// **'Artist name'**
  String get discordRpcStyleArtist;

  /// Discord RPC state style option: show song title
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get discordRpcStyleSong;

  /// Discord RPC state style option: show app name
  ///
  /// In en, this message translates to:
  /// **'App name (Luobo)'**
  String get discordRpcStyleApp;

  /// Playback settings section header for ReplayGain
  ///
  /// In en, this message translates to:
  /// **'VOLUME NORMALIZATION (REPLAYGAIN)'**
  String get sectionVolumeNormalization;

  /// Playback settings section header for fade in/out audio
  ///
  /// In en, this message translates to:
  /// **'FADE IN/OUT'**
  String get sectionFadeInOut;

  /// Toggle label to enable fade in/out audio effect
  ///
  /// In en, this message translates to:
  /// **'Enable Fade In/Out'**
  String get fadeInOutEnable;

  /// Subtitle explaining fade in/out functionality
  ///
  /// In en, this message translates to:
  /// **'Smoothly fade audio when playing or pausing'**
  String get fadeInOutSubtitle;

  /// Slider label showing fade duration in milliseconds
  ///
  /// In en, this message translates to:
  /// **'Fade Duration: {duration}ms'**
  String fadeDuration(int duration);

  /// ReplayGain mode: disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get replayGainModeOff;

  /// ReplayGain mode: per-track normalization
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get replayGainModeTrack;

  /// ReplayGain mode: album-level normalization
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get replayGainModeAlbum;

  /// ReplayGain preamp slider label
  ///
  /// In en, this message translates to:
  /// **'Preamp: {value} dB'**
  String replayGainPreamp(String value);

  /// Toggle label for ReplayGain prevent-clipping option
  ///
  /// In en, this message translates to:
  /// **'Prevent Clipping'**
  String get replayGainPreventClipping;

  /// ReplayGain fallback gain slider label
  ///
  /// In en, this message translates to:
  /// **'Fallback Gain: {value} dB'**
  String replayGainFallbackGain(String value);

  /// Auto DJ slider label showing how many songs to add
  ///
  /// In en, this message translates to:
  /// **'Songs to Add: {count}'**
  String autoDjSongsToAdd(int count);

  /// Toggle label to enable transcoding
  ///
  /// In en, this message translates to:
  /// **'Enable Transcoding'**
  String get transcodingEnable;

  /// Subtitle for the enable transcoding toggle
  ///
  /// In en, this message translates to:
  /// **'Reduce data usage with lower quality'**
  String get transcodingEnableSubtitle;

  /// Toggle label for smart (auto) transcoding mode
  ///
  /// In en, this message translates to:
  /// **'Smart Transcoding'**
  String get smartTranscoding;

  /// Subtitle for the smart transcoding toggle
  ///
  /// In en, this message translates to:
  /// **'Automatically adjusts quality based on your connection (WiFi vs mobile data)'**
  String get smartTranscodingSubtitle;

  /// Label shown before the live network type badge
  ///
  /// In en, this message translates to:
  /// **'Detected network: '**
  String get smartTranscodingDetectedNetwork;

  /// Dialog title explaining smart transcoding
  ///
  /// In en, this message translates to:
  /// **'Smart Transcoding'**
  String get smartTranscodingHelpTitle;

  /// Explains how smart transcoding picks bitrates
  ///
  /// In en, this message translates to:
  /// **'When on, the bitrate follows your network automatically:\n• Wi-Fi → Wi-Fi quality bitrate\n• Cellular → Mobile quality bitrate\nThe bitrate switches automatically when your network changes.'**
  String get smartTranscodingHelpBody;

  /// Label for the fixed bitrate selector shown when smart mode is off
  ///
  /// In en, this message translates to:
  /// **'Transcode Bitrate'**
  String get transcodingManualBitrate;

  /// Subtitle for the fixed bitrate selector
  ///
  /// In en, this message translates to:
  /// **'Fixed bitrate used when smart transcoding is off'**
  String get transcodingManualBitrateSubtitle;

  /// Label for WiFi bitrate selector
  ///
  /// In en, this message translates to:
  /// **'WiFi Quality'**
  String get transcodingWifiQuality;

  /// WiFi quality subtitle when smart mode is on
  ///
  /// In en, this message translates to:
  /// **'Used automatically on WiFi'**
  String get transcodingWifiQualitySubtitleSmart;

  /// Label for mobile data bitrate selector
  ///
  /// In en, this message translates to:
  /// **'Mobile Quality'**
  String get transcodingMobileQuality;

  /// Mobile quality subtitle when smart mode is on
  ///
  /// In en, this message translates to:
  /// **'Used automatically on cellular data'**
  String get transcodingMobileQualitySubtitleSmart;

  /// Label for the transcoding format selector
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get transcodingFormat;

  /// Subtitle for the transcoding format selector
  ///
  /// In en, this message translates to:
  /// **'Audio codec used for streaming'**
  String get transcodingFormatSubtitle;

  /// Transcoding bitrate option: no transcoding, use original
  ///
  /// In en, this message translates to:
  /// **'Original (No Transcoding)'**
  String get transcodingBitrateOriginal;

  /// Transcoding format option: original (no conversion)
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get transcodingFormatOriginal;

  /// Hint shown in streaming settings while connected via the local (LAN) URL: transcoding is forced off regardless of the bitrate settings
  ///
  /// In en, this message translates to:
  /// **'LAN connection — always original (no transcoding)'**
  String get transcodingLanForceOriginal;

  /// Toggle title for image (album art) cache
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get imageCacheTitle;

  /// Subtitle for image cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save album covers locally'**
  String get imageCacheSubtitle;

  /// Toggle title for music metadata cache
  ///
  /// In en, this message translates to:
  /// **'Music Cache'**
  String get musicCacheTitle;

  /// Subtitle for music cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save song metadata locally'**
  String get musicCacheSubtitle;

  /// Toggle title for BPM analysis cache
  ///
  /// In en, this message translates to:
  /// **'BPM Cache'**
  String get bpmCacheTitle;

  /// Subtitle for BPM cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save BPM analysis locally'**
  String get bpmCacheSubtitle;

  /// About screen section header
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get sectionAboutInformation;

  /// About screen developer section header
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get sectionAboutDeveloper;

  /// About screen links section header
  ///
  /// In en, this message translates to:
  /// **'LINKS'**
  String get sectionAboutLinks;

  /// About screen version row title
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// About screen platform row title
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get aboutPlatform;

  /// Developer credit text in the about tab
  ///
  /// In en, this message translates to:
  /// **'Made by chengsitom'**
  String get aboutMadeBy;

  /// Developer GitHub handle shown as subtitle
  ///
  /// In en, this message translates to:
  /// **'github.com/chengsitom'**
  String get aboutGitHub;

  /// Link tile title for the GitHub repo
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get aboutLinkGitHub;

  /// Link tile title for the app changelog
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get aboutLinkChangelog;

  /// Link tile title for reporting a bug
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get aboutLinkReportIssue;

  /// Analytics and Privacy section header
  ///
  /// In en, this message translates to:
  /// **'Analytics & Privacy'**
  String get sectionAnalyticsPrivacy;

  /// Device ID field label
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// Shows the anonymous device ID
  ///
  /// In en, this message translates to:
  /// **'Anonymous ID: {id}'**
  String deviceIdAnonymous(String id);

  /// Shown when analytics is disabled
  ///
  /// In en, this message translates to:
  /// **'Enable analytics to see your anonymous device ID'**
  String get deviceIdDisabled;

  /// Title for device ID info tile
  ///
  /// In en, this message translates to:
  /// **'About Device ID'**
  String get aboutDeviceId;

  /// Explanation of what device ID is
  ///
  /// In en, this message translates to:
  /// **'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.'**
  String get aboutDeviceIdSubtitle;

  /// Title of the playback speed bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// Label for 1× (normal) playback speed option
  ///
  /// In en, this message translates to:
  /// **'Normal (1×)'**
  String get normalSpeed;

  /// Toggle label to keep original pitch when changing speed
  ///
  /// In en, this message translates to:
  /// **'Preserve pitch'**
  String get preservePitch;

  /// Subtitle for the preserve-pitch toggle
  ///
  /// In en, this message translates to:
  /// **'Keep original pitch when changing speed'**
  String get preservePitchSubtitle;

  /// Label for the pitch slider in the speed dialog
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get pitch;

  /// Tooltip fragment shown when pitch correction is on
  ///
  /// In en, this message translates to:
  /// **'pitch preserved'**
  String get pitchPreserved;

  /// Tooltip for the speed button showing speed and pitch values
  ///
  /// In en, this message translates to:
  /// **'Speed {speed} · pitch {pitch}×'**
  String speedTooltipWithPitch(String speed, String pitch);

  /// Tooltip for the speed button when pitch is preserved
  ///
  /// In en, this message translates to:
  /// **'Speed {speed} · pitch preserved'**
  String speedTooltipPitchPreserved(String speed);

  /// Title of the sleep timer bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// Tooltip for the sleep timer button when a timer is running
  ///
  /// In en, this message translates to:
  /// **'Sleep timer active'**
  String get sleepTimerActive;

  /// Toggle label for the fade-out option in the sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut;

  /// Subtitle for the fade-out toggle, showing fade duration in seconds
  ///
  /// In en, this message translates to:
  /// **'Gradually lower volume in the last {seconds} s'**
  String fadeOutSubtitle(int seconds);

  /// Toggle label to stop after the current track finishes
  ///
  /// In en, this message translates to:
  /// **'Finish current song'**
  String get finishCurrentSong;

  /// Subtitle for the finish-current-song toggle
  ///
  /// In en, this message translates to:
  /// **'Stop after the current track ends'**
  String get finishCurrentSongSubtitle;

  /// Sleep timer option label for a duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String sleepTimerMinutes(int count);

  /// Sleep timer option label for a duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count} hour'**
  String sleepTimerHours(int count);

  /// Snackbar shown after setting the sleep timer
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {duration}'**
  String sleepTimerSetFor(String duration);

  /// List tile label to open the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Custom duration…'**
  String get customDuration;

  /// List tile label to cancel the active sleep timer
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// Title of the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Custom Sleep Timer'**
  String get customSleepTimer;

  /// Confirm button label in the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// Title of the add-to-playlist bottom sheet (distinct from the menu action)
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylistTitle;

  /// Section heading inside the add-to-playlist bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Your Playlists'**
  String get yourPlaylistsLabel;

  /// Toggle label for enabling LRCLIB lyrics fallback when the Subsonic server has no lyrics
  ///
  /// In en, this message translates to:
  /// **'Fetch lyrics from LRCLIB'**
  String get enableLrcLibFallback;

  /// Subtitle explaining the LRCLIB fallback toggle
  ///
  /// In en, this message translates to:
  /// **'Automatically search LRCLIB for lyrics when your server does not provide them'**
  String get lrcLibFallbackSubtitle;

  /// Snackbar message after saving a Now Playing theme
  ///
  /// In en, this message translates to:
  /// **'Theme saved'**
  String get themeSaved;

  /// Subtitle in AppBar when theme has unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get themeUnsavedChanges;

  /// Title of the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get themeUnsavedChangesTitle;

  /// Body of the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save before leaving?'**
  String get themeUnsavedChangesBody;

  /// Button to discard unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Button to confirm a color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Title of the color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Pick {label}'**
  String pickColor(String label);

  /// Section heading for title text style in theme editor
  ///
  /// In en, this message translates to:
  /// **'Title Style'**
  String get titleStyle;

  /// Section heading for artist text style in theme editor
  ///
  /// In en, this message translates to:
  /// **'Artist Style'**
  String get artistStyle;

  /// Badge shown on the active Now Playing theme card
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get themeActive;

  /// Badge shown when a theme is in safe mode
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get themeSafeMode;

  /// Badge shown when a theme has custom Flutter code enabled
  ///
  /// In en, this message translates to:
  /// **'CODE'**
  String get themeCodeMode;

  /// Badge shown on theme cards that have animations enabled
  ///
  /// In en, this message translates to:
  /// **'ANIM'**
  String get themeAnimBadge;

  /// Author attribution shown on theme preview card
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String themeAuthor(String author);

  /// Section title for gapless playback setting
  ///
  /// In en, this message translates to:
  /// **'Gapless Playback'**
  String get gaplessPlayback;

  /// Subtitle for gapless playback toggle
  ///
  /// In en, this message translates to:
  /// **'Eliminate silence between songs'**
  String get gaplessPlaybackSubtitle;

  /// Section title for lyrics settings
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsSection;

  /// Netease Cloud Music lyrics source
  ///
  /// In en, this message translates to:
  /// **'Netease Lyrics'**
  String get neteaseLyrics;

  /// Subtitle for Netease lyrics toggle
  ///
  /// In en, this message translates to:
  /// **'Fetch lyrics from Netease Cloud Music when LRCLIB has no results (recommended for Chinese songs)'**
  String get neteaseLyricsSubtitle;

  /// AI smart playlist section title
  ///
  /// In en, this message translates to:
  /// **'AI Smart Playlist'**
  String get aiSmartPlaylist;

  /// API Key field label
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// Status when API key is not configured
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// API URL field label
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get apiUrl;

  /// AI model field label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// Song knowledge base title
  ///
  /// In en, this message translates to:
  /// **'Song Knowledge Base'**
  String get songKnowledgeBase;

  /// Knowledge base indexed status
  ///
  /// In en, this message translates to:
  /// **'Indexed {cached} / {total} songs'**
  String knowledgeIndexed(int cached, int total);

  /// Knowledge base last update time
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// Button to generate knowledge base
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// Button to incrementally update knowledge base
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get incrementalUpdate;

  /// Snackbar after knowledge generation
  ///
  /// In en, this message translates to:
  /// **'Knowledge base generated for {count} songs'**
  String knowledgeGenerated(int count);

  /// Snackbar when knowledge generation aborts
  ///
  /// In en, this message translates to:
  /// **'Knowledge base generation failed: {reason}'**
  String knowledgeGenerationFailed(String reason);

  /// Hint for API URL field
  ///
  /// In en, this message translates to:
  /// **'https://api.deepseek.com'**
  String get apiUrlHint;

  /// Help text for API URL dialog
  ///
  /// In en, this message translates to:
  /// **'Any OpenAI-compatible API URL works\ne.g. DeepSeek, OpenAI, Kimi, Tongyi Qianwen'**
  String get apiUrlDescription;

  /// Model selector dialog title
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// AI connection settings section title
  ///
  /// In en, this message translates to:
  /// **'AI Connection'**
  String get aiConnectionSettings;

  /// Button/title to export song knowledge base
  ///
  /// In en, this message translates to:
  /// **'Export Knowledge Base'**
  String get exportKnowledgeBase;

  /// Subtitle for exporting knowledge base
  ///
  /// In en, this message translates to:
  /// **'Export as a file to share with others on the same NAS library'**
  String get exportKnowledgeBaseSubtitle;

  /// Export button label
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Snackbar after successful export
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String exportedTo(String path);

  /// Snackbar after failed export
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Button/title to import song knowledge base
  ///
  /// In en, this message translates to:
  /// **'Import Knowledge Base'**
  String get importKnowledgeBase;

  /// Subtitle for importing knowledge base
  ///
  /// In en, this message translates to:
  /// **'Import a knowledge base file shared by someone else'**
  String get importKnowledgeBaseSubtitle;

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Snackbar after successful import
  ///
  /// In en, this message translates to:
  /// **'Imported {count} songs into knowledge base'**
  String knowledgeImported(int count);

  /// Snackbar after failed import
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// Section title explaining AI features
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// Title for knowledge base explanation sheet
  ///
  /// In en, this message translates to:
  /// **'How the Knowledge Base Works'**
  String get knowledgeBaseExplanation;

  /// Title for playlist generation explanation sheet
  ///
  /// In en, this message translates to:
  /// **'How Playlist Generation Works'**
  String get playlistGenerationExplanation;

  /// WiFi network type label
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get networkWifi;

  /// Mobile network type label
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get networkMobile;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Analytics & Privacy'**
  String get analyticsAndPrivacy;

  /// Analytics switch label
  ///
  /// In en, this message translates to:
  /// **'Anonymous Analytics'**
  String get anonymousAnalyticsToggle;

  /// Analytics switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Help improve Luobo with anonymous crash reports and usage stats'**
  String get anonymousAnalyticsToggleSubtitle;

  /// Shows the anonymous device ID
  ///
  /// In en, this message translates to:
  /// **'Anonymous ID: {id}'**
  String anonymousIdLabel(String id);

  /// Hint when analytics disabled
  ///
  /// In en, this message translates to:
  /// **'Enable analytics to see your anonymous device ID'**
  String get enableAnalyticsToSeeId;

  /// Tooltip for copy device ID button
  ///
  /// In en, this message translates to:
  /// **'Copy device ID'**
  String get copyDeviceId;

  /// Snackbar after copying device ID
  ///
  /// In en, this message translates to:
  /// **'Device ID copied to clipboard'**
  String get deviceIdCopied;

  /// Description of what device ID is
  ///
  /// In en, this message translates to:
  /// **'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.'**
  String get aboutDeviceIdDescription;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Title after user rated the app
  ///
  /// In en, this message translates to:
  /// **'Thanks for Rating!'**
  String get thanksForRating;

  /// Subtitle after rated
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated the app'**
  String get alreadyRated;

  /// Rate app button title
  ///
  /// In en, this message translates to:
  /// **'Rate Luobo'**
  String get rateMusly;

  /// Rate app subtitle
  ///
  /// In en, this message translates to:
  /// **'Share your feedback'**
  String get shareFeedback;

  /// Rating dialog prompt
  ///
  /// In en, this message translates to:
  /// **'How would you rate your experience?'**
  String get howWouldYouRate;

  /// Rating feedback hint
  ///
  /// In en, this message translates to:
  /// **'Optional feedback...'**
  String get optionalFeedback;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Snackbar after rating submitted
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouFeedback;

  /// Snackbar after adding a scan folder
  ///
  /// In en, this message translates to:
  /// **'Added folder: {path}'**
  String addedFolder(String path);

  /// Dialog title for removing a folder
  ///
  /// In en, this message translates to:
  /// **'Remove Folder'**
  String get removeFolder;

  /// Dialog content for removing a folder
  ///
  /// In en, this message translates to:
  /// **'Remove \"{path}\" from scan paths?'**
  String removeFolderConfirm(String path);

  /// Snackbar after folder removed
  ///
  /// In en, this message translates to:
  /// **'Folder removed'**
  String get folderRemoved;

  /// Snackbar when library is loading
  ///
  /// In en, this message translates to:
  /// **'Loading library...'**
  String get loadingLibrary;

  /// Dialog content when library load fails
  ///
  /// In en, this message translates to:
  /// **'Library appears to be empty or failed to load. Make sure your server supports full library scanning.'**
  String get libraryEmptyOrFailed;

  /// Menu option to add song to liked songs
  ///
  /// In en, this message translates to:
  /// **'Add to Liked Songs'**
  String get addToLikedSongs;

  /// Menu option to remove song from liked songs
  ///
  /// In en, this message translates to:
  /// **'Remove from Liked Songs'**
  String get removeFromLikedSongs;

  /// Rate song menu item showing current rating
  ///
  /// In en, this message translates to:
  /// **'Rate Song ({rating} {rating, plural, =1{star} other{stars}})'**
  String rateSongWithRating(int rating);

  /// Snackbar after setting a rating
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} {rating, plural, =1{star} other{stars}}'**
  String songRated(int rating);

  /// Snackbar after removing a song from playlist
  ///
  /// In en, this message translates to:
  /// **'Song removed from playlist'**
  String get songRemovedFromPlaylist;

  /// Snackbar when removing a song fails
  ///
  /// In en, this message translates to:
  /// **'Error removing song: {error}'**
  String errorRemovingSong(Object error);

  /// Snackbar when removing multiple songs fails
  ///
  /// In en, this message translates to:
  /// **'Error removing songs: {error}'**
  String errorRemovingSongs(Object error);

  /// Snackbar when reordering songs fails
  ///
  /// In en, this message translates to:
  /// **'Error reordering song: {error}'**
  String errorReorderingSong(Object error);

  /// Dialog title for removing multiple songs
  ///
  /// In en, this message translates to:
  /// **'Remove songs'**
  String get removeSongs;

  /// Confirmation dialog for removing songs
  ///
  /// In en, this message translates to:
  /// **'Remove {count} {count, plural, =1{song} other{songs}} from this playlist?'**
  String removeSongsConfirm(int count);

  /// Snackbar after removing songs from playlist
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{song} other{songs}} removed from playlist'**
  String songsRemovedFromPlaylist(int count);

  /// Title for reorder songs mode
  ///
  /// In en, this message translates to:
  /// **'Reorder Songs'**
  String get reorderSongs;

  /// Tooltip for finishing reorder mode
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get doneReordering;

  /// Button to select all songs
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Button to deselect all songs
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Tooltip to remove selected songs
  ///
  /// In en, this message translates to:
  /// **'Remove selected'**
  String get removeSelected;

  /// Tooltip to enter multi-select mode
  ///
  /// In en, this message translates to:
  /// **'Select songs'**
  String get selectSongs;

  /// Tooltip to download a playlist
  ///
  /// In en, this message translates to:
  /// **'Download playlist'**
  String get downloadPlaylist;

  /// Confirmation dialog for removing a single song
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from this playlist?'**
  String removeSongFromPlaylistConfirm(String title);

  /// Snackbar after downloading songs
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} {count, plural, =1{song} other{songs}} from {name}'**
  String downloadedSongsFrom(int count, String name);

  /// Snackbar when download starts in background
  ///
  /// In en, this message translates to:
  /// **'Downloading {count} {count, plural, =1{song} other{songs}} in background…'**
  String downloadingSongsInBackground(int count);

  /// Playlist subtitle with song count and duration
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{song} other{songs}} • {duration}'**
  String songsCountWithDuration(int count, String duration);

  /// Artist count
  ///
  /// In en, this message translates to:
  /// **'{count} Artists'**
  String artistsCount(int count);

  /// Empty state hint for playlists screen
  ///
  /// In en, this message translates to:
  /// **'Create a playlist to get started'**
  String get createPlaylistToStart;

  /// Login error hint for self-signed certificate issue
  ///
  /// In en, this message translates to:
  /// **'Try enabling \"Allow Self-Signed Certificates\" below.'**
  String get enableSelfSignedCertsHint;

  /// Login error hint for wrong credentials
  ///
  /// In en, this message translates to:
  /// **'Check your username and password and try again.'**
  String get checkCredentialsHint;

  /// Login error hint for wrong server URL path
  ///
  /// In en, this message translates to:
  /// **'Verify the server URL path (e.g. /navidrome, /airsonic).'**
  String get verifyServerUrlHint;

  /// Login error hint for server timeout
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Check your network.'**
  String get serverTimeoutHint;

  /// Tooltip to copy the login error message
  ///
  /// In en, this message translates to:
  /// **'Copy error'**
  String get copyError;

  /// Snackbar after copying the error message
  ///
  /// In en, this message translates to:
  /// **'Error copied to clipboard'**
  String get errorCopiedToClipboard;

  /// Hint on touch devices to enable self-signed certificates
  ///
  /// In en, this message translates to:
  /// **'Tap to enable self-signed certificates'**
  String get tapToEnableSelfSignedCerts;

  /// Hint on desktop to enable self-signed certificates
  ///
  /// In en, this message translates to:
  /// **'Click to enable self-signed certificates'**
  String get clickToEnableSelfSignedCerts;

  /// Fallback error message when login fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to server'**
  String get failedToConnectToServer;

  /// Scan status shown while picking music files on iOS
  ///
  /// In en, this message translates to:
  /// **'Select your music files...'**
  String get selectMusicFiles;

  /// Snackbar when no music files were selected
  ///
  /// In en, this message translates to:
  /// **'No files selected. Tap \"Use Local Files\" and pick your music files.'**
  String get noFilesSelected;

  /// Description of YouTube Music login option
  ///
  /// In en, this message translates to:
  /// **'YouTube Music streams music directly from YouTube. No account required — tap Connect to start.'**
  String get youtubeMusicDescription;

  /// Section title for saved server profiles
  ///
  /// In en, this message translates to:
  /// **'Saved Profiles'**
  String get savedProfiles;

  /// Helper text for saved profiles section
  ///
  /// In en, this message translates to:
  /// **'Tap a profile to connect • tap × to delete'**
  String get tapProfileToConnect;

  /// Section title on the server gateway screen
  ///
  /// In en, this message translates to:
  /// **'My Servers'**
  String get myServers;

  /// Entry to add a new server configuration
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// App bar title when editing an existing server configuration
  ///
  /// In en, this message translates to:
  /// **'Edit Server'**
  String get editServer;

  /// Bottom sheet title for picking the server family
  ///
  /// In en, this message translates to:
  /// **'Select Server Type'**
  String get selectServerType;

  /// Server family option that auto-detects
  ///
  /// In en, this message translates to:
  /// **'Auto-detect (Recommended)'**
  String get serverTypeAuto;

  /// Subtitle under the auto-detect server family option
  ///
  /// In en, this message translates to:
  /// **'Subsonic / Jellyfin / 道理鱼'**
  String get serverTypeAutoSubtitle;

  /// Server family option label
  ///
  /// In en, this message translates to:
  /// **'Subsonic'**
  String get serverTypeSubsonic;

  /// Server family option label
  ///
  /// In en, this message translates to:
  /// **'Emby / Jellyfin'**
  String get serverTypeJellyfin;

  /// Server family option label
  ///
  /// In en, this message translates to:
  /// **'道理鱼'**
  String get serverTypeDaoliyu;

  /// Confirm dialog title when deleting a saved profile
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfileTitle;

  /// Confirm dialog body when deleting a saved profile
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteProfileConfirm(String name);

  /// Group title on the server form: server address fields
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get formSectionConnection;

  /// Group title on the server form: credentials fields
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get formSectionAccount;

  /// Progress text shown while switching server profiles
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// Default name for a newly created theme
  ///
  /// In en, this message translates to:
  /// **'New Theme'**
  String get newThemeDefaultName;

  /// Default author for a newly created theme
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get newThemeDefaultAuthor;

  /// Snackbar when a theme is deactivated
  ///
  /// In en, this message translates to:
  /// **'Theme deactivated (using default)'**
  String get themeDeactivated;

  /// Snackbar when default theme is activated
  ///
  /// In en, this message translates to:
  /// **'Default theme activated'**
  String get defaultThemeActivated;

  /// Snackbar when a theme is activated
  ///
  /// In en, this message translates to:
  /// **'{name} activated'**
  String themeActivated(String name);

  /// Prefilled name when duplicating a theme
  ///
  /// In en, this message translates to:
  /// **'{name} Copy'**
  String themeCopyName(String name);

  /// Snackbar after duplicating a theme
  ///
  /// In en, this message translates to:
  /// **'Duplicated as \"{name}\"'**
  String themeDuplicated(String name);

  /// File save dialog title for exporting a theme
  ///
  /// In en, this message translates to:
  /// **'Export Theme'**
  String get exportThemeTitle;

  /// Snackbar after exporting a theme
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String themeExported(String path);

  /// Snackbar after importing a theme
  ///
  /// In en, this message translates to:
  /// **'Theme imported'**
  String get themeImported;

  /// Snackbar after importing a theme in safe mode
  ///
  /// In en, this message translates to:
  /// **'Theme imported (Safe Mode)'**
  String get themeImportedSafeMode;

  /// Snackbar after successful theme import
  ///
  /// In en, this message translates to:
  /// **'Theme imported successfully'**
  String get themeImportedSuccess;

  /// Dialog title when theme import fails
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailedTitle;

  /// Dialog content listing theme file errors
  ///
  /// In en, this message translates to:
  /// **'The theme file contains errors:'**
  String get themeFileErrors;

  /// Dialog title warning about theme security
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get securityWarning;

  /// Dialog content warning about custom code in theme
  ///
  /// In en, this message translates to:
  /// **'This theme contains custom Flutter code which may pose security risks.'**
  String get customCodeSecurityRisk;

  /// Dialog section title for theme details
  ///
  /// In en, this message translates to:
  /// **'Theme Details:'**
  String get themeDetailsLabel;

  /// Generic label for a name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Generic label for an author field
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorLabel;

  /// Dialog section title for custom widgets
  ///
  /// In en, this message translates to:
  /// **'Custom Widgets:'**
  String get customWidgetsLabel;

  /// Dialog section title for dependencies
  ///
  /// In en, this message translates to:
  /// **'Dependencies:'**
  String get dependenciesLabel;

  /// Button to import a theme in safe mode
  ///
  /// In en, this message translates to:
  /// **'Safe Mode'**
  String get safeModeButton;

  /// Button to import a theme with custom code enabled
  ///
  /// In en, this message translates to:
  /// **'Enable Code'**
  String get enableCodeButton;

  /// Dialog title for deleting a theme
  ///
  /// In en, this message translates to:
  /// **'Delete Theme'**
  String get deleteTheme;

  /// Confirmation dialog for deleting a theme
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteThemeConfirm(String name);

  /// Snackbar after deleting a theme
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String themeDeleted(String name);

  /// Snackbar when safe mode is turned off
  ///
  /// In en, this message translates to:
  /// **'Safe Mode disabled'**
  String get safeModeDisabled;

  /// Snackbar when safe mode is turned on
  ///
  /// In en, this message translates to:
  /// **'Safe Mode enabled'**
  String get safeModeEnabled;

  /// Dialog title for duplicating a theme
  ///
  /// In en, this message translates to:
  /// **'Duplicate Theme'**
  String get duplicateTheme;

  /// Hint text for the new theme name field
  ///
  /// In en, this message translates to:
  /// **'New theme name'**
  String get newThemeNameHint;

  /// Button to confirm duplicating a theme
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateButton;

  /// Theme editor tab for general info
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get themeTabInfo;

  /// Theme editor tab for background
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeTabBackground;

  /// Theme editor tab for text styles
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get themeTabText;

  /// Theme editor tab for artwork
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get themeTabArtwork;

  /// Theme editor tab for progress bar
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get themeTabProgress;

  /// Theme editor tab for controls
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get themeTabControls;

  /// Theme editor tab for animations
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get themeTabAnimations;

  /// Label for the theme name field
  ///
  /// In en, this message translates to:
  /// **'Theme Name'**
  String get themeNameLabel;

  /// Label for background type dropdown
  ///
  /// In en, this message translates to:
  /// **'Background Type'**
  String get backgroundTypeLabel;

  /// Label for first color picker
  ///
  /// In en, this message translates to:
  /// **'Color 1'**
  String get color1Label;

  /// Label for second color picker
  ///
  /// In en, this message translates to:
  /// **'Color 2'**
  String get color2Label;

  /// Label for opacity slider
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacityLabel;

  /// Label for blur radius slider
  ///
  /// In en, this message translates to:
  /// **'Blur Sigma'**
  String get blurSigmaLabel;

  /// Generic label for a color picker
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// Label for font size slider
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSizeLabel;

  /// Label for font weight dropdown
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeightLabel;

  /// Generic label for a shape dropdown
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get shapeLabel;

  /// Label for size factor slider
  ///
  /// In en, this message translates to:
  /// **'Size Factor'**
  String get sizeFactorLabel;

  /// Label for corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get cornerRadiusLabel;

  /// Label for shadow switch
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get shadowLabel;

  /// Label for rotation animation switch
  ///
  /// In en, this message translates to:
  /// **'Rotation Animation'**
  String get rotationAnimationLabel;

  /// Label for active color picker
  ///
  /// In en, this message translates to:
  /// **'Active Color'**
  String get activeColorLabel;

  /// Label for inactive color picker
  ///
  /// In en, this message translates to:
  /// **'Inactive Color'**
  String get inactiveColorLabel;

  /// Label for height slider
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// Label for thumb visibility switch
  ///
  /// In en, this message translates to:
  /// **'Thumb Visible'**
  String get thumbVisibleLabel;

  /// Label for button color picker
  ///
  /// In en, this message translates to:
  /// **'Button Color'**
  String get buttonColorLabel;

  /// Label for play button color picker
  ///
  /// In en, this message translates to:
  /// **'Play Button Color'**
  String get playButtonColorLabel;

  /// Label for play button size slider
  ///
  /// In en, this message translates to:
  /// **'Play Button Size'**
  String get playButtonSizeLabel;

  /// Label for play button shape dropdown
  ///
  /// In en, this message translates to:
  /// **'Play Button Shape'**
  String get playButtonShapeLabel;

  /// Label for cover rotation switch
  ///
  /// In en, this message translates to:
  /// **'Cover Rotation'**
  String get coverRotationLabel;

  /// Label for rotation speed slider
  ///
  /// In en, this message translates to:
  /// **'Rotation Speed (s/turn)'**
  String get rotationSpeedLabel;

  /// Label for pulse effect switch
  ///
  /// In en, this message translates to:
  /// **'Pulse Effect'**
  String get pulseEffectLabel;

  /// Label for fade in switch
  ///
  /// In en, this message translates to:
  /// **'Fade In'**
  String get fadeInLabel;

  /// Empty state when there are no favorite songs
  ///
  /// In en, this message translates to:
  /// **'No favorite songs yet'**
  String get noFavoriteSongs;

  /// Empty state hint for listening history
  ///
  /// In en, this message translates to:
  /// **'Songs you play will appear here'**
  String get listeningHistoryHint;

  /// Search field placeholder in library search
  ///
  /// In en, this message translates to:
  /// **'Search in Library...'**
  String get searchInLibrary;

  /// Empty state hint for library search
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get searchYourLibrary;

  /// Empty state when no playlists match search
  ///
  /// In en, this message translates to:
  /// **'No playlists found'**
  String get noPlaylistsFound;

  /// Desktop songs table column header for title
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get tableHeaderTitle;

  /// Desktop songs table column header for album
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get tableHeaderAlbum;

  /// Desktop songs table column header for duration
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get tableHeaderTime;

  /// Snackbar showing the radio stream URL
  ///
  /// In en, this message translates to:
  /// **'Stream URL: {url}'**
  String streamUrl(String url);

  /// App bar title for new releases screen
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get newReleases;

  /// Empty state when there are no new releases
  ///
  /// In en, this message translates to:
  /// **'No new releases'**
  String get noNewReleases;

  /// Tooltip to download an album
  ///
  /// In en, this message translates to:
  /// **'Download album'**
  String get downloadAlbum;

  /// Album duration formatted as minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN'**
  String durationMinutesOnly(int minutes);

  /// Empty state when the playback queue is empty
  ///
  /// In en, this message translates to:
  /// **'No songs in queue'**
  String get noSongsInQueue;

  /// Subtitle for radio playback in mini player
  ///
  /// In en, this message translates to:
  /// **'Internet Radio • LIVE'**
  String get internetRadioLive;

  /// Tooltip for stop playback button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Placeholder label showing the custom widget name
  ///
  /// In en, this message translates to:
  /// **'Custom Widget: {name}'**
  String customWidgetLabel(String name);

  /// Error message when a custom widget fails
  ///
  /// In en, this message translates to:
  /// **'Custom widget error: {error}'**
  String customWidgetError(String error);

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Placeholder label when a custom widget is disabled in safe mode
  ///
  /// In en, this message translates to:
  /// **'Safe Mode: {name} disabled'**
  String safeModeDisabledLabel(String name);

  /// Status text while a custom widget is compiling
  ///
  /// In en, this message translates to:
  /// **'Compiling...'**
  String get compiling;

  /// Button to exit the app on the emulator warning screen
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// Audio quality status when transcoding is off
  ///
  /// In en, this message translates to:
  /// **'Original (not transcoded)'**
  String get noTranscoding;

  /// Short transcode status for compact rows (account card subtitle). 'No transcoding'.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get transcodeShortIdle;

  /// Short transcode status for compact rows: currently transcoding.
  ///
  /// In en, this message translates to:
  /// **'Transcoding'**
  String get transcodeShortActive;

  /// Short transcode status for compact rows: stream already transcoded.
  ///
  /// In en, this message translates to:
  /// **'Transcoded'**
  String get transcodeShortDone;

  /// Status label when playback will be transcoded on the current network
  ///
  /// In en, this message translates to:
  /// **'Will transcode on current network'**
  String get streamWillTranscode;

  /// Full-sentence status when playback will be transcoded on the current network (avoids duplicating the transcode result)
  ///
  /// In en, this message translates to:
  /// **'Will transcode to {format} {bitrate}kbps on current network ({network})'**
  String streamWillTranscodeTo(String format, int bitrate, String network);

  /// Audio quality status when transcoding is enabled
  ///
  /// In en, this message translates to:
  /// **'Transcoded to {format} {bitrate}kbps ({network})'**
  String transcodedTo(String format, int bitrate, String network);

  /// Audio quality status when transcoding is enabled (network type shown as an icon)
  ///
  /// In en, this message translates to:
  /// **'Transcoded to {format} {bitrate}kbps'**
  String transcodedToNoNetwork(String format, int bitrate);

  /// Status when playback is being/will be transcoded on the current network (network type shown by leading icon + text)
  ///
  /// In en, this message translates to:
  /// **'Transcoding to {format} {bitrate}kbps'**
  String transcodingInProgress(String format, int bitrate);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Server action panel entry leading to the server detail page
  ///
  /// In en, this message translates to:
  /// **'Server Status'**
  String get serverStatus;

  /// Server action panel entry that refreshes the library from the server
  ///
  /// In en, this message translates to:
  /// **'Rescan Library'**
  String get rescanLibrary;

  /// Destructive server action; removes the saved server profile
  ///
  /// In en, this message translates to:
  /// **'Remove Connection'**
  String get removeConnection;

  /// Title of the server management page
  ///
  /// In en, this message translates to:
  /// **'Connected Servers'**
  String get connectedServers;

  /// Hint shown below the server list
  ///
  /// In en, this message translates to:
  /// **'Tap to switch the active server; scan or add from the top right.'**
  String get serversHint;

  /// Toast shown after a successful library rescan
  ///
  /// In en, this message translates to:
  /// **'Library refreshed'**
  String get libraryRefreshed;

  /// Title of the server detail page (B4)
  ///
  /// In en, this message translates to:
  /// **'Server Details'**
  String get serverDetail;

  /// Footnote under the connect button on the server form. Deliberately does NOT claim encryption - credentials are kept in SharedPreferences, not encrypted.
  ///
  /// In en, this message translates to:
  /// **'This information is stored only on this device.'**
  String get formLocalOnlyNote;

  /// Hint under the server type grid on the add-server step
  ///
  /// In en, this message translates to:
  /// **'Pick a type, then fill in the address and account — the form is identical to \"Modify connection\".'**
  String get serverTypeGridHint;

  /// Section title for alternative add-server entries (QR scan)
  ///
  /// In en, this message translates to:
  /// **'Other ways'**
  String get otherWays;

  /// Generic toast for a failed local I/O or save operation
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// Confirm dialog title before switching to the on-device library
  ///
  /// In en, this message translates to:
  /// **'Switch to local music mode?'**
  String get useLocalFilesConfirmTitle;

  /// Confirm dialog body explaining that the server connection is dropped
  ///
  /// In en, this message translates to:
  /// **'This disconnects the current server and uses music files stored on this device instead.'**
  String get useLocalFilesConfirmBody;

  /// Sort field label: song title. Direction is shown by a separate arrow, not baked into the label (unlike the legacy sortTitleAz/Za keys).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortFieldTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'az',
        'bn',
        'da',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'ga',
        'hi',
        'id',
        'it',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sq',
        'sv',
        'te',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'az':
      return AppLocalizationsAz();
    case 'bn':
      return AppLocalizationsBn();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ga':
      return AppLocalizationsGa();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sq':
      return AppLocalizationsSq();
    case 'sv':
      return AppLocalizationsSv();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
