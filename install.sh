#!/usr/bin/env bash
# Installe l'écosystème Hyprland : paquets (pacman + AUR) puis dotfiles.
# Les configs sont déployées par LIENS SYMBOLIQUES vers ce dépôt : garde donc
# ce dépôt cloné à un emplacement stable (ex. ~/www/archlinux). Modifier un
# fichier ici met à jour la config live, et inversement.
#
# Usage : ./install.sh [--no-packages] [--no-dotfiles]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$REPO_DIR/dotfiles"

DO_PACKAGES=1
DO_DOTFILES=1
for arg in "$@"; do
    case "$arg" in
        --no-packages) DO_PACKAGES=0 ;;
        --no-dotfiles) DO_DOTFILES=0 ;;
        -h | --help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Option inconnue: $arg" >&2; exit 1 ;;
    esac
done

info() { printf '\n\e[1;36m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
ok()   { printf '  \e[32m✓\e[0m %s\n' "$*"; }
warn() { printf '  \e[33m!\e[0m %s\n' "$*"; }

read_pkgs() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

if [[ ${EUID} -eq 0 ]]; then
    echo "Ne lance pas ce script en root ; il appelle sudo lui-même au besoin." >&2
    exit 1
fi

# ---------------------------------------------------------------- Paquets ---
if [[ $DO_PACKAGES -eq 1 ]]; then
    info "Paquets officiels (pacman)"
    mapfile -t PACMAN_PKGS < <(read_pkgs "$REPO_DIR/packages/pacman.txt")
    sudo pacman -S --needed "${PACMAN_PKGS[@]}"

    if ! command -v yay >/dev/null 2>&1; then
        info "Installation de yay (assistant AUR)"
        sudo pacman -S --needed --noconfirm git base-devel
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        ok "yay installé"
    fi

    info "Paquets AUR (yay)"
    mapfile -t AUR_PKGS < <(read_pkgs "$REPO_DIR/packages/aur.txt")
    yay -S --needed "${AUR_PKGS[@]}"

    # Services système à activer au démarrage.
    if [[ -f "$REPO_DIR/packages/services.txt" ]]; then
        mapfile -t SERVICES < <(read_pkgs "$REPO_DIR/packages/services.txt")
        if [[ ${#SERVICES[@]} -gt 0 ]]; then
            info "Services (activation au démarrage)"
            sudo systemctl enable --now "${SERVICES[@]}"
            for s in "${SERVICES[@]}"; do ok "$s"; done
        fi
    fi

    # Ajout de l'utilisateur aux groupes nécessaires (ex. docker pour utiliser
    # docker sans sudo). Prend effet à la prochaine ouverture de session.
    USER_GROUPS=("docker")
    for g in "${USER_GROUPS[@]}"; do
        if getent group "$g" >/dev/null 2>&1 && ! id -nG | tr ' ' '\n' | grep -qx "$g"; then
            sudo usermod -aG "$g" "$USER"
            warn "ajouté au groupe '$g' — déconnecte/reconnecte-toi pour l'appliquer"
        fi
    done

    # Shell par défaut : zsh (config dans dotfiles/.zshrc). Idempotent : on ne
    # bascule que si le shell de connexion actuel n'est pas déjà zsh. chsh
    # demandera ton mot de passe. Prend effet à la prochaine ouverture de session.
    ZSH_BIN="$(command -v zsh || true)"
    if [[ -n "$ZSH_BIN" ]]; then
        CUR_SHELL="$(getent passwd "$USER" | awk -F: '{print $NF}')"
        if [[ "$CUR_SHELL" != "$ZSH_BIN" ]]; then
            info "Shell par défaut → zsh"
            chsh -s "$ZSH_BIN"
            ok "shell basculé sur zsh (effectif à la prochaine session)"
        fi
    fi
fi

# --------------------------------------------------------------- Dotfiles ---
# Répertoires liés en ENTIER (le dossier ~/... devient un lien vers le repo).
# À réserver aux configs qu'on possède intégralement et qu'on édite souvent :
# tout nouveau fichier créé dedans est alors versionné automatiquement (ex.
# nvim : nouveaux fichiers de plugins). NE PAS mettre un dossier partagé avec
# d'autres apps (ex. ~/.config/rofi où rofi peut déposer ses propres fichiers).
DIR_LINKS=(".config/nvim")

under_dir_link() { # $1 = chemin relatif ; vrai s'il est sous un DIR_LINKS
    local rel="$1" d
    for d in "${DIR_LINKS[@]}"; do
        [[ "$rel" == "$d" || "$rel" == "$d"/* ]] && return 0
    done
    return 1
}

link_into_home() { # $1 = source (repo), $2 = chemin relatif
    local src="$1" rel="$2" dest="$HOME/$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        mv "$dest" "$dest.bak"
        warn "sauvegarde : $rel -> $rel.bak"
    fi
    # -f -n : remplace le lien existant en une seule commande (fenêtre minimale,
    # évite qu'un démon surveillant le fichier le voie absent).
    ln -sfn "$src" "$dest"
    ok "$rel"
}

if [[ $DO_DOTFILES -eq 1 ]]; then
    info "Déploiement des configs (liens symboliques)"
    # 1) Répertoires liés en entier.
    for d in "${DIR_LINKS[@]}"; do
        [[ -d "$DOTFILES/$d" ]] && link_into_home "$DOTFILES/$d" "$d"
    done
    # 2) Fichiers individuels (en sautant ceux couverts par un lien-dossier).
    while IFS= read -r -d '' src; do
        rel="${src#"$DOTFILES"/}"
        under_dir_link "$rel" && continue
        link_into_home "$src" "$rel"
    done < <(find "$DOTFILES" -type f -print0)

    # Base des applications → régénère ~/.local/share/applications/mimeinfo.cache
    # (côté glib). Nécessaire parce qu'on y dépose imv.desktop, une surcharge du
    # fichier du paquet dont le seul but est de passer NoDisplay à false. Le
    # cache n'est PAS reconstruit tout seul au dépôt d'un .desktop.
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        ok "base des applications"
    fi
    # Cache de services KDE (ksycoca) : Dolphin y lit les associations de
    # fichiers, pas ~/.config/mimeapps.list directement. Étape INDISPENSABLE, et
    # pas juste « au cas où » : sous Hyprland aucun démon (pas de kded6) ne
    # reconstruit ce cache, et il ne devient correct qu'une fois déployé
    # dotfiles/.config/menus/applications.menu (fait juste au-dessus par la
    # boucle de symlinks). Sans ce menu, kbuildsycoca ne recense AUCUNE
    # application comme service et toutes les associations sont ignorées, PDF
    # comme image. Voir l'en-tête d'applications.menu pour le détail du piège.
    if command -v kbuildsycoca6 >/dev/null 2>&1; then
        kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
        ok "cache de services KDE"
    fi

    # Thèmes d'icônes vendorés (archives .tar.xz) → ~/.local/share/icons/.
    # Non symlinkés (ce sont des assets installés, pas des configs à éditer).
    # Ex. Zafiro-Nord-Black, utilisé par le lanceur rofi (extrait du thème
    # HyDE "Tundra", absent des dépôts).
    if compgen -G "$REPO_DIR/assets/*.tar.xz" >/dev/null; then
        info "Thèmes d'icônes"
        mkdir -p "$HOME/.local/share/icons"
        for tb in "$REPO_DIR"/assets/*.tar.xz; do
            tar -xf "$tb" -C "$HOME/.local/share/icons/"
            ok "$(basename "$tb")"
        done
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            find "$HOME/.local/share/icons" -maxdepth 2 -name index.theme -printf '%h\n' |
                sort -u | while read -r d; do
                gtk-update-icon-cache -f "$d" >/dev/null 2>&1 || true
            done
        fi
    fi

    # Thème SDDM (écran de connexion) vendorisé + son drop-in de config.
    # Va dans /usr (thème) et /etc (drop-in) → nécessite sudo, et n'est PAS
    # symlinké : SDDM lit ces fichiers en root avant l'ouverture de session,
    # un lien vers le home utilisateur ne serait pas résolu. Version allégée
    # (on ne garde qu'un fond animé perso — cat.mp4 — au lieu des multiples
    # vidéos/captures du paquet AUR sddm-silent-theme) ; ses dépendances
    # runtime (dont qt6-multimedia-ffmpeg pour la vidéo) sont dans pacman.txt.
    if [[ -d "$REPO_DIR/assets/sddm/themes" ]]; then
        info "Thème SDDM"
        for t in "$REPO_DIR"/assets/sddm/themes/*/; do
            [[ -d "$t" ]] || continue
            name="$(basename "$t")"
            sudo cp -rT "$t" "/usr/share/sddm/themes/$name"
            ok "thème $name → /usr/share/sddm/themes/"
        done
        if compgen -G "$REPO_DIR/assets/sddm/sddm.conf.d/*.conf" >/dev/null; then
            sudo mkdir -p /etc/sddm.conf.d
            sudo cp "$REPO_DIR"/assets/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/
            ok "drop-in → /etc/sddm.conf.d/"
        fi
        # Avatar (face icon) : SDDM le cherche sous le NOM de l'utilisateur,
        # donc on renomme la version vendorisée à la volée pour l'utilisateur
        # courant. Image 256×256 déjà prête (pas besoin d'ImageMagick).
        if [[ -f "$REPO_DIR/assets/sddm/faces/avatar.face.icon" ]]; then
            sudo mkdir -p /usr/share/sddm/faces
            sudo cp "$REPO_DIR/assets/sddm/faces/avatar.face.icon" \
                "/usr/share/sddm/faces/$USER.face.icon"
            ok "avatar → /usr/share/sddm/faces/$USER.face.icon"
        fi
    fi
fi

info "Terminé."
echo "  Relance ta session Hyprland (ou : hyprctl reload puis relance waybar)."
