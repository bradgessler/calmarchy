// Allow userChrome.css to load.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Keep tabs in the titlebar area (no separate GTK title bar).
user_pref("browser.tabs.inTitlebar", 1);
// Use the system dark/light theme and the OS monospace font.
user_pref("browser.theme.content-theme", 0);
user_pref("font.name.monospace.x-western", "Berkeley Mono");
// Compact UI density: shorter tabs and toolbar.
user_pref("browser.uidensity", 1);
// Skip the first-run privacy notice and welcome tabs.
user_pref("datareporting.policy.firstRunURL", "");
user_pref("browser.aboutwelcome.enabled", false);
// Trackpad fling, closer to macOS: a long, gently decaying glide (0.0045
// stopped it abruptly; Firefox's default 0.002 glides a little too far),
// rubber-band overscroll at the edges, and repeated flicks speeding up.
user_pref("apz.fling_friction", 0.0028);
user_pref("apz.fling_stopped_threshold", 0.005);
user_pref("apz.overscroll.enabled", true);
user_pref("apz.fling_accel_base_mult", 1.5);
user_pref("apz.gtk.kinetic_scroll.enabled", true);
// Match macOS "looks like 1440x900" on a 13" MacBook: 1.75 device px per CSS px
// instead of the compositor's 2x, which made everything ~14% too big.
user_pref("layout.css.devPixelsPerPx", "1.75");
