/* Omarchy theme colors for Firefox chrome. Generated from colors.toml on
   every theme change; userChrome.css imports this file. */
:root {
  --lwt-accent-color: {{ background }} !important;
  --lwt-text-color: {{ foreground }} !important;
  --toolbar-bgcolor: {{ background }} !important;
  --toolbar-color: {{ foreground }} !important;
  --toolbarbutton-icon-fill: {{ foreground }} !important;
  --toolbarbutton-hover-background: {{ selection }} !important;
  --toolbarbutton-active-background: {{ muted }} !important;
  --toolbar-field-background-color: {{ dark_background }} !important;
  --toolbar-field-color: {{ foreground }} !important;
  --toolbar-field-border-color: {{ lighter_background }} !important;
  --toolbar-field-focus-background-color: {{ dark_background }} !important;
  --toolbar-field-focus-color: {{ bright_foreground }} !important;
  --toolbar-field-focus-border-color: {{ muted }} !important;
  --urlbar-box-bgcolor: {{ selection }} !important;
  --urlbar-box-hover-bgcolor: {{ muted }} !important;
  --arrowpanel-background: {{ background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: {{ muted }} !important;
  --panel-separator-color: {{ muted }} !important;
  --sidebar-background-color: {{ background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --tabpanel-background-color: {{ background }} !important;
  --focus-outline-color: {{ muted }} !important;
}
#navigator-toolbox, #nav-bar, #PersonalToolbar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}
#urlbar-background, #searchbar {
  background-color: {{ dark_background }} !important;
  border-color: {{ muted }} !important;
}
.urlbarView { background-color: {{ background }} !important; color: {{ foreground }} !important; }
.urlbarView-row[selected] > .urlbarView-row-inner { background-color: {{ selection }} !important; }

/* Quiet address bar: hairline border, no glow or thick focus ring. */
#urlbar-background, #searchbar {
  border: 1px solid {{ lighter_background }} !important;
  box-shadow: none !important;
  outline: none !important;
}
#urlbar[focused] > #urlbar-background,
#urlbar[focused="true"] > #urlbar-background,
#urlbar:focus-within > #urlbar-background {
  border-color: {{ muted }} !important;
  box-shadow: none !important;
  outline: none !important;
}
:root { --focus-outline-width: 1px !important; --focus-outline: 1px solid {{ muted }} !important; }
