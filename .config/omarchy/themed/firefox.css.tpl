/* Omarchy theme colors for Firefox chrome. Generated from colors.toml on
   every theme change; userChrome.css imports this file. The toolbar and frame
   colours are left to the Adaptive Tab Bar Colour extension (installed by
   /etc/firefox/policies/policies.json), which tints them with each page's
   background like Safari; menus and popups keep the theme. */
:root {
  --toolbarbutton-hover-background: {{ selection }} !important;
  --toolbarbutton-active-background: {{ muted }} !important;
  --arrowpanel-background: {{ background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: {{ muted }} !important;
  --panel-separator-color: {{ muted }} !important;
  --sidebar-background-color: {{ background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --tabpanel-background-color: {{ background }} !important;
  --focus-outline-color: {{ muted }} !important;
}
.urlbarView { background-color: {{ background }} !important; color: {{ foreground }} !important; }
.urlbarView-row[selected] > .urlbarView-row-inner { background-color: {{ selection }} !important; }

/* Quiet address bar: part of the toolbar until used. No box at rest, a faint
   fill on hover, and a hairline only while focused; no glow or focus ring. */
#urlbar-background, #searchbar {
  background-color: transparent !important;
  border: 1px solid transparent !important;
  box-shadow: none !important;
  outline: none !important;
}
#urlbar:hover:not([focused]) > #urlbar-background {
  background-color: rgba(127, 127, 127, 0.12) !important;
}
#urlbar[focused] > #urlbar-background,
#urlbar[focused="true"] > #urlbar-background,
#urlbar:focus-within > #urlbar-background {
  background-color: rgba(127, 127, 127, 0.16) !important;
}
#urlbar[focused] > #urlbar-background,
#urlbar[focused="true"] > #urlbar-background,
#urlbar:focus-within > #urlbar-background {
  border-color: rgba(127, 127, 127, 0.45) !important;
  box-shadow: none !important;
  outline: none !important;
}
:root { --focus-outline-width: 1px !important; --focus-outline: 1px solid {{ muted }} !important; }
