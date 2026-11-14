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
// Trackpad fling: decelerate sooner (default 0.002).
user_pref("apz.fling_friction", 0.0045);
