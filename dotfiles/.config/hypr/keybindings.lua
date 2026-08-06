-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- KEYBINDINGS                                            --
-- Extracted from hyprland.lua. Mapping inspired by HyDE's --
-- keybindings.conf (github.com/hyde-project/hyde),        --
-- ported dispatcher-by-dispatcher to the native Lua API — --
-- no hyde-shell wrapper scripts.                           --
--                                                          --
-- Every bind carries a `description` so keybind-hint       --
-- (SUPER+/, also on the waybar button) can list them live  --
-- via `hyprctl binds -j` -- no separate doc to keep in     --
-- sync.                                                    --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local mainMod     = "SUPER"

-- Programs
local terminal    = "kitty"
local fileManager = "dolphin"
local browser     = "google-chrome-stable"
-- --class kitty-nvim : classe dédiée pour distinguer l'éditeur du terminal nu
-- (même binaire kitty) et les router sur deux workspaces — voir userprefs.lua.
local editor      = "kitty --class kitty-nvim --title Neovim -e nvim"
local menu        = "rofi-launcher"

----------------------------
---- WINDOW MANAGEMENT ----
----------------------------

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Fermer la fenêtre active" })
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Fermer la fenêtre active" })
-- Session lancée par uwsm (hyprland-uwsm.desktop via SDDM) : on quitte avec
-- `uwsm stop` et NON `dispatch exit`, sinon les unités systemd de la session
-- ne sont pas démontées et on ne revient pas au greeter SDDM.
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("uwsm stop"), { description = "Quitter la session Hyprland" })
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }), { description = "Basculer flottant" })
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Basculer le groupement de fenêtres" })
hl.bind("SHIFT + F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
  { description = "Basculer plein écran" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
  { description = "Basculer plein écran" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("screenlock"), { description = "Verrouiller l'écran" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pin(), { description = "Épingler la fenêtre active" })
hl.bind("CONTROL + ALT + Delete", hl.dsp.exec_cmd("wlogout-launch"), { description = "Menu de déconnexion" })
-- La logique est dans ~/.local/bin/waybar-toggle et PAS en clair ici : elle doit
-- tuer `waybar-launch` via `pkill -f`, qui matcherait alors le `sh -c` exécutant
-- ce bind (sa ligne de commande contiendrait « waybar-launch »). Voir l'en-tête
-- du script. Elle passe par waybar-launch, pas par waybar nu, pour conserver la
-- config « une barre par écran » et le superviseur anti-crash.
hl.bind("ALT_R + CONTROL_R", hl.dsp.exec_cmd("waybar-toggle"), { description = "Basculer waybar" })

hl.bind(mainMod .. " + CONTROL + H", hl.dsp.group.prev(), { description = "Groupe actif précédent" })
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.group.next(), { description = "Groupe actif suivant" })

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus à gauche" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus à droite" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus en haut" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus en bas" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Cycler le focus" })

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
  { repeating = true, description = "Agrandir vers la droite" })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
  { repeating = true, description = "Rétrécir vers la gauche" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
  { repeating = true, description = "Rétrécir vers le haut" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
  { repeating = true, description = "Agrandir vers le bas" })

hl.bind(mainMod .. " + CONTROL + SHIFT + left", hl.dsp.window.move({ direction = "l" }),
  { description = "Déplacer la fenêtre à gauche" })
hl.bind(mainMod .. " + CONTROL + SHIFT + right", hl.dsp.window.move({ direction = "r" }),
  { description = "Déplacer la fenêtre à droite" })
hl.bind(mainMod .. " + CONTROL + SHIFT + up", hl.dsp.window.move({ direction = "u" }),
  { description = "Déplacer la fenêtre en haut" })
hl.bind(mainMod .. " + CONTROL + SHIFT + down", hl.dsp.window.move({ direction = "d" }),
  { description = "Déplacer la fenêtre en bas" })

-- Envoi de la fenêtre active sur l'écran voisin, quelle que soit sa place dans
-- le pavage. À distinguer de SUPER+CONTROL+SHIFT+flèche juste au-dessus, qui
-- déplace d'abord DANS le workspace et ne franchit l'écran que si la fenêtre est
-- déjà au bord. La fenêtre atterrit sur le workspace affiché par l'écran visé.
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.move({ monitor = "l" }),
  { description = "Envoyer la fenêtre sur l'écran de gauche" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ monitor = "r" }),
  { description = "Envoyer la fenêtre sur l'écran de droite" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Maintenir pour déplacer" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(),
  { mouse = true, description = "Maintenir pour redimensionner" })
hl.bind(mainMod .. " + Z", hl.dsp.window.drag(), { description = "Maintenir pour déplacer" })
hl.bind(mainMod .. " + X", hl.dsp.window.resize(), { description = "Maintenir pour redimensionner" })

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Basculer le split" })

----------------------
---- LAUNCHER ----
----------------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Explorateur de fichiers" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor), { description = "Éditeur de texte" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Navigateur web" })

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu .. " d"), { description = "Lanceur d'applications" })
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd(menu .. " w"), { description = "Changeur de fenêtres" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(menu .. " f"), { description = "Explorateur de fichiers (rofi)" })
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("keybind-hint"), { description = "Aide-mémoire des raccourcis" })

----------------------------
---- HARDWARE CONTROLS ----
----------------------------

hl.bind("F10", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, description = "Muet (sortie audio)" })
hl.bind("F11", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true, description = "Volume -" })
hl.bind("F12", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true, description = "Volume +" })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true, description = "Muet (sortie audio)" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true, description = "Muet (micro)" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true, description = "Volume -" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true, description = "Volume +" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
  { locked = true, repeating = true, description = "Luminosité +" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
  { locked = true, repeating = true, description = "Luminosité -" })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Média suivant" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Lecture/pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Lecture/pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Média précédent" })

----------------------
---- UTILITIES ----
----------------------

hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"),
  { description = "Changer la disposition clavier" })

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pipette à couleur" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("screenshot s"), { description = "Capture d'écran (sélection)" })
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("screenshot m"), { description = "Capture d'écran (moniteur actif)" })
hl.bind("Print", hl.dsp.exec_cmd("screenshot p"), { description = "Capture d'écran (tous les moniteurs)" })

----------------------
---- WORKSPACES ----
----------------------

-- Clavier AZERTY (kb_layout = "fr") : la rangée du haut émet & é " ' ( - è _ ç à
-- et les chiffres exigent Maj. Binder sur le symbole "1" ne déclenche donc jamais
-- sans Maj (la touche part au terminal → séquence ";9u"). On bind par KEYCODE
-- physique, indépendant de la disposition : keycode 10 = touche "1" … 19 = "0",
-- soit 9 + i (i=10 → 19, la touche "0"). Marche identique en QWERTY.
for i = 1, 10 do
  local code = "code:" .. (9 + i)
  hl.bind(mainMod .. " + " .. code, hl.dsp.focus({ workspace = i }), { description = "Aller à l'espace " .. i })
  hl.bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }),
    { description = "Déplacer vers l'espace " .. i })
  hl.bind(mainMod .. " + ALT + " .. code, hl.dsp.window.move({ workspace = i, follow = false }),
    { description = "Déplacer vers l'espace " .. i .. " (silencieux)" })
end

hl.bind(mainMod .. " + CONTROL + right", hl.dsp.focus({ workspace = "r+1" }), { description = "Espace suivant" })
hl.bind(mainMod .. " + CONTROL + left", hl.dsp.focus({ workspace = "r-1" }), { description = "Espace précédent" })
hl.bind(mainMod .. " + CONTROL + down", hl.dsp.focus({ workspace = "empty" }),
  { description = "Aller au premier espace vide" })

hl.bind(mainMod .. " + CONTROL + ALT + right", hl.dsp.window.move({ workspace = "r+1" }),
  { description = "Déplacer vers l'espace suivant" })
hl.bind(mainMod .. " + CONTROL + ALT + left", hl.dsp.window.move({ workspace = "r-1" }),
  { description = "Déplacer vers l'espace précédent" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Espace suivant (molette)" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Espace précédent (molette)" })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),
  { description = "Envoyer vers le scratchpad" })
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }),
  { description = "Envoyer vers le scratchpad (silencieux)" })
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Basculer le scratchpad" })
