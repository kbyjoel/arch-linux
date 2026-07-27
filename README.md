# archlinux — mon écosystème Hyprland

Configs et script d'installation pour reconstruire mon environnement Hyprland
sur une install Arch Linux fraîche.

## Installation

```bash
git clone https://github.com/<utilisateur>/archlinux ~/www/archlinux
cd ~/www/archlinux
./install.sh
```

Le script :
1. installe les paquets officiels (`packages/pacman.txt`) via `pacman` ;
2. installe `yay` s'il est absent, puis les paquets AUR (`packages/aur.txt`) ;
3. active au démarrage les services de `packages/services.txt`, ajoute
   l'utilisateur aux groupes requis (ex. `docker`) et bascule le shell par
   défaut sur **zsh** (`chsh`) ;
4. déploie les configs de `dotfiles/` par **liens symboliques** vers `$HOME`
   (une config existante est sauvegardée en `.bak`) ;
5. extrait les thèmes d'icônes vendorés (`assets/*.tar.xz`) dans
   `~/.local/share/icons/` et rafraîchit le cache d'icônes ;
6. déploie le thème SDDM vendoré (`assets/sddm/`) dans
   `/usr/share/sddm/themes/` et son drop-in dans `/etc/sddm.conf.d/` (sudo).

Options : `./install.sh --no-packages` ou `--no-dotfiles` (cette dernière saute
aussi l'extraction des icônes).

### Étape manuelle : les PWA Chrome

`install.sh` ne peut pas installer les applications web (Chrome les crée dans son
propre profil). À faire une fois, dans Chrome, via
`⋮ → Caster, enregistrer et partager → Installer cette page…` :

| PWA | URL |
|---|---|
| Gmail | <https://mail.google.com> |
| Google Agenda | <https://calendar.google.com> |
| Outlook | <https://outlook.office.com/mail/> |

Leurs règles de workspace (voir ci-dessous) fonctionnent ensuite sans rien
ajuster : Chrome dérive l'identifiant d'une PWA par hachage de son URL, donc la
classe de fenêtre `chrome-<app-id>-Default` est la même sur toute machine.

## Fonctionnement des dotfiles

`dotfiles/` reproduit l'arborescence de `$HOME`. Chaque fichier y est lié
symboliquement dans `$HOME` : **ce dépôt est la source de vérité**. Modifier
un fichier ici (ou la config live, c'est le même fichier) puis `git commit`
suffit à garder tout à jour. Garde le dépôt cloné à un emplacement stable.

Cas particulier : certains dossiers qu'on possède intégralement et qu'on édite
souvent (ex. `nvim`) sont liés **en entier** (le dossier `~/…` est lui-même un
lien), pas fichier par fichier — ainsi tout nouveau fichier créé dedans (plugin,
`lazy-lock.json`…) est versionné automatiquement. La liste est dans `DIR_LINKS`
au début d'`install.sh`.

## Contenu

| Chemin | Rôle |
|---|---|
| `dotfiles/.config/hypr/` | Hyprland (`hyprland.lua` + `keybindings.lua`), verrou (`hyprlock.conf`) et hooks de veille (`hypridle.conf`) |
| `dotfiles/.config/rofi/` | Thème + lanceur d'apps + thème dmenu |
| `dotfiles/.config/waybar/` | Barre (config, style, modules media) |
| `dotfiles/.config/mako/` | Notifications (daemon `mako`) — thème aropixel : police kitty, fond noir, bordure turquoise arrondie, rouge pour les critiques |
| `dotfiles/.config/kitty/` | Terminal (réglages + couleurs) |
| `dotfiles/.config/fastfetch/` | Fastfetch (layout + logo) |
| `dotfiles/.config/nvim/` | Neovim / LazyVim (dossier lié en entier) |
| `dotfiles/.config/starship.toml` | Prompt sur-mesure « aropixel » : ruban powerline à blocs (deux teintes d'ardoise, chevrons durs) construit autour du turquoise du logo (`#03F1C5`), bloc ambre dédié aux modifs git. Ancienne version HyDE dans `backups/` |
| `dotfiles/.config/wlogout/` | Menu de déconnexion (thème + layout + icônes) |
| `dotfiles/.config/wallpapers/` | Fonds d'écran par workspace (voir ci-dessous) |
| `dotfiles/.config/mimeapps.list` | Associations fichier → application pour le double-clic dans Dolphin : **imv** pour les images, **Chrome** pour les PDF. Voir la section « Associations de fichiers » plus bas pour le piège qui les rendait toutes inopérantes |
| `dotfiles/.config/menus/applications.menu` | **Chaînon manquant des associations sous Hyprland** : sans lui, KDE ne recense aucune application dans son cache `ksycoca` et Dolphin ignore tout `mimeapps.list`. Aucun paquet ne le fournit sur un système sans DE complet. Voir la section « Associations de fichiers » et l'en-tête du fichier |
| `dotfiles/.local/share/applications/` | Surcharge d'`imv.desktop` : le fichier du paquet porte `NoDisplay=true`, qui l'exclut des listes « Ouvrir avec ». Voir l'en-tête du fichier |
| `dotfiles/.zshrc` | Shell **zsh** (starship + fastfetch au lancement, suggestions/coloration/complétions, **fzf** : Ctrl+R/Ctrl+T/Alt+C + fzf-tab) — shell par défaut basculé par `install.sh` |
| `dotfiles/.bashrc` | Ancien shell bash, conservé en repli |
| `dotfiles/.local/bin/` | Scripts : `rofi-launcher`, `keybind-hint`, `screenshot`, `system-update`, `wlogout-launch`, `screenlock`, `lock-before-sleep` (retient la veille le temps que le verrou s'affiche), `wallpaper-daemon`, `waybar-launch` (relance waybar s'il crashe au boot), `wsbtn` + `waybar-ws-refresh` (workspaces waybar) |
| `assets/*.tar.xz` | Thèmes d'icônes extraits par `install.sh` (ex. `Zafiro-Nord-Black` pour le lanceur rofi) |
| `assets/sddm/` | Thème SDDM `silent` allégé (config `rei` active, fond vidéo perso `cat.mp4`) + drop-in `/etc/sddm.conf.d/` + avatar (`faces/avatar.face.icon`), déployés par `install.sh` |

## Fond d'écran par workspace

Le script `wallpaper-daemon` (lancé au démarrage par `hyprland.lua`) fait tourner
**swww** et écoute les bascules de workspace pour changer l'image à la volée.

Les images vivent dans `~/.config/wallpapers/` (symlinké depuis le repo). La
convention de nommage suffit — **rien d'autre à configurer** :

| Fichier | Effet |
|---|---|
| `default.jpg` (ou `.png`/`.jpeg`/`.webp`) | fond de repli, sur tout workspace sans image dédiée |
| `1.jpg`, `2.png`, … | fond du workspace correspondant |

Pour ajouter/changer un fond : dépose (ou remplace) un fichier nommé d'après le
numéro de workspace dans `dotfiles/.config/wallpapers/`, puis `git commit`. Tant
qu'il n'existe qu'un `default`, tous les workspaces l'affichent.

## Plan des workspaces

Les applications sont routées par des règles de fenêtre (`hypr/userprefs.lua`) :

| WS | Rôle | Applications |
|---|---|---|
| 1 | Musique | Spotify |
| 2 | Mail & agenda | PWA Gmail, Outlook, Google Agenda |
| 3 | Discussion | Teams (`teams-for-linux`), Discord (`webcord`) |
| 4 | Terminal | kitty « nu » |
| 5 | Éditeur | kitty portant nvim |
| 6 | Web | Chrome |

Terminal et éditeur sont le **même binaire kitty** : l'éditeur est lancé avec
`--class kitty-nvim` (voir `keybindings.lua`) précisément pour que Hyprland
puisse les distinguer et les router séparément.

Dolphin et les DevTools de Chrome sont flottants (respectivement centré et collé
à droite) plutôt que rattachés à un workspace.

> **Piège** : dans l'API Lua, `size` et `move` n'acceptent que des **pixels**.
> Un pourcentage est accepté sans erreur puis ignoré silencieusement. D'où le
> helper `px()` d'`userprefs.lua`, qui calcule les pixels depuis la résolution
> du moniteur.

## Verrouillage et veille

`SUPER+L` (et le bouton de wlogout) appellent `screenlock`, qui lance hyprlock
avec la vidéo du login SDDM en fond animé — voir l'en-tête du script pour
l'astuce mpvpaper.

> **Limite connue et assumée** : une à deux secondes où le bureau reste visible
> sous l'horloge, au verrouillage comme au réveil. hyprlock s'affiche tout de
> suite, mpvpaper met ce temps à monter, et le verrou étant transparent, xray
> laisse voir les fenêtres tant que rien n'est dessiné par-dessus. Le délai vient
> du démarrage de mpvpaper, pas du décodage vidéo : glisser une image fixe
> dessous ne change rien (essayé). Le seul correctif serait un fond opaque avec
> `session_lock_xray = false`, au prix de l'animation — voir l'en-tête de
> `screenlock` pour le détail des tentatives.

**Rabattre le couvercle verrouille la session.** La mise en veille elle-même
vient de systemd-logind (`HandleLidSwitch=suspend`, valeur par défaut : rien à
configurer). Ce qui est ajouté ici, c'est le verrouillage *avant* la veille,
sans quoi on retombe sur le bureau à la réouverture : **hypridle** (lancé par
`hyprland.lua`) écoute logind et exécute `screenlock` sur le signal de veille.

Le `before_sleep_cmd` passe par le script `lock-before-sleep` plutôt que par un
`loginctl lock-session` direct : cette commande rend la main aussitôt, hypridle
relâcherait son inhibiteur avant que le verrou soit dessiné, et `user.slice`
serait gelé avec un hyprlock à mi-démarrage — d'où un bureau visible une à deux
secondes au réveil. Le script bloque jusqu'à l'affichage effectif, dans la limite
des 5 s d'`InhibitDelayMaxSec`.

Sur inactivité, `hypridle.conf` enchaîne (délais repris de HyDE, largement
rallongés) :

| Délai | Effet |
|---|---|
| 10 min | écran tamisé à 1 % (`brightnessctl`) — réversible au moindre mouvement |
| 15 min | verrouillage (`loginctl lock-session` → `screenlock`) |
| 25 min | mise en veille |

Une inhibition (vidéo plein écran, appel Teams) suspend ce décompte —
`ignore_dbus_inhibit = false`.

> **Piège** : HyDE coupe aussi l'écran (DPMS) entre le verrou et la veille, via
> `hyprctl dispatch dpms off`. C'est la syntaxe du format `.conf`, qui échoue
> sur une config Lua, et le stub `/usr/share/hypr/stubs/hl.meta.lua` ne déclare
> `dpms` que comme `fun(...)`, sans types. Ce listener est donc absent ici. Ne
> cherche pas la bonne syntaxe en tapant `hyprctl dispatch` sur la session en
> cours : un mauvais argument éteint l'écran.

## Workspaces dans waybar

Ce Hyprland lit une **config Lua native** : l'IPC `dispatch` est évalué en Lua,
donc le clic figé du module `hyprland/workspaces` intégré (`dispatch workspace N`)
échoue. La barre utilise à la place des **modules custom** (`custom/ws1`…`ws10`,
script `wsbtn`) qui cliquent avec la bonne syntaxe `hl.dsp.focus{workspace=N}`.
Les workspaces **1 à 6 sont persistants** (toujours affichés, grisés si vides —
ce sont ceux du plan ci-dessus, tous utilisés au quotidien) ; 7 à 10
apparaissent à l'usage. Le seuil est `PERSISTENT` dans `wsbtn`. `waybar-ws-refresh` écoute la socket2 et envoie
`SIGRTMIN+1` à waybar pour garder la surbrillance synchro sans polling.

## Associations de fichiers (Dolphin)

Double-cliquer un fichier dans Dolphin l'ouvre avec l'appli par défaut : **imv**
pour les images, **Chrome** pour les PDF (voir `dotfiles/.config/mimeapps.list`).

> **Piège majeur, propre aux setups sans DE complet.** Poser un `mimeapps.list`
> correct ne suffit **pas**. Dolphin ne lit pas ce fichier directement : il
> résout l'appli par défaut via le cache de services KDE, **ksycoca**. Or
> `kbuildsycoca` ne recense les `.desktop` comme services **que** s'il trouve un
> `applications.menu` déclarant les répertoires d'applications (`<AppDir>`). Ce
> fichier est normalement fourni par un environnement de bureau ; **sous
> Hyprland seul, aucun paquet ne le livre** (`pacman -Qo
> /etc/xdg/menus/applications.menu` → rien). Sans lui, ksycoca reste **vide de
> services** et Dolphin ignore **toutes** les associations — il redemande
> l'appli à chaque double-clic, PDF comme image — alors même que `xdg-mime query
> default` répond correctement (glib et KDE ne lisent pas le même cache). Le
> repo corrige ça avec `dotfiles/.config/menus/applications.menu`.
>
> Second piège, en cascade : sous Hyprland il n'y a **pas de `kded6`** pour
> reconstruire ksycoca. `install.sh` le fait donc explicitement
> (`kbuildsycoca6 --noincremental`) après avoir déployé le menu.

Diagnostic reproductible — compter les services que KDE n'arrive pas à résoudre :

```bash
QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="kf.service*.debug=true" \
    kbuildsycoca6 --noincremental 2>&1 | grep -c 'unknown service'
```

Zéro = tout est résolu. Un nombre élevé (y compris pour des apps de
`/usr/share` comme `google-chrome.desktop`) = `applications.menu` manquant ou
invalide. **Attention** : ce menu est du XML, son commentaire ne doit contenir
**aucun double tiret** (interdit en XML) — sinon le fichier est rejeté en
silence et on retombe pile sur le bug.

Beaucoup de ces configs sont adaptées depuis le
[projet HyDE](https://github.com/hyde-project/hyde), rendues autonomes.
