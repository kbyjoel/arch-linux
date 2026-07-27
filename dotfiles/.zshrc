#
# ~/.zshrc — shell interactif zsh
#
# Portage de l'ancien .bashrc (alias + PATH + starship + fastfetch au lancement)
# avec, en plus, les complétions zsh, les suggestions à la frappe
# (zsh-autosuggestions) et la coloration syntaxique (zsh-syntax-highlighting).
# Les plugins viennent des paquets officiels (voir packages/pacman.txt) et sont
# sourcés depuis /usr/share/zsh/ — chaque source est gardée par un test
# d'existence pour rester robuste si un paquet manque.

# --- Alias & PATH ---
alias ls='ls --color=auto'
alias grep='grep --color=auto'
typeset -U path                       # pas de doublons dans le PATH
path=("$HOME/.local/bin" $path)

# --- Docker Compose : rendu de progression ---
# En mode « auto », Compose fait un ioctl(TIOCGWINSZ) sur sa sortie pour choisir
# son rendu. Quand il est lancé par castor, Symfony Process crée un pty sans
# jamais lui donner de taille (stty size = 0 0) : Compose déclasse alors en mode
# « plain », d'où des lignes empilées sans couleur ni états qui se réécrivent.
# Forcer « tty » court-circuite cette détection. Ici et pas dans .zshenv : seuls
# les shells interactifs sont concernés, la CI et les scripts gardent « auto ».
export COMPOSE_PROGRESS=tty

# --- Historique ---
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups           # supprime les doublons de l'historique
setopt hist_ignore_space              # ignore les commandes préfixées d'un espace
setopt hist_reduce_blanks
setopt share_history                  # historique partagé entre shells

# --- Complétion ---
# zsh-completions ajoute ses définitions dans /usr/share/zsh/site-functions,
# déjà sur le fpath : rien à sourcer, il suffit d'initialiser compinit.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
compinit -d "$_zcompdump"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # insensible à la casse
zstyle ':completion:*' menu select                         # menu navigable
zstyle ':completion:*' list-colors ''

# --- Raccourcis clavier (style emacs, comme bash) ---
bindkey -e

# --- fzf : Ctrl+R (historique), Ctrl+T (fichiers), Alt+C (cd) ---
# Rebinde ces raccourcis sur un sélecteur flou. Layout « default » = liste
# AU-DESSUS de la ligne de saisie (comme sur HyDE). Thème accordé au turquoise
# aropixel (#03F1C5) ; fond transparent (bg:-1 = fond du terminal).
export FZF_DEFAULT_OPTS="--height=45% --layout=default --border=rounded --info=inline --cycle \
--color=fg:#cdd6f4,bg:-1,fg+:#ffffff,bg+:#232735,hl:#03f1c5,hl+:#03f1c5 \
--color=border:#03f1c5,prompt:#03f1c5,pointer:#03f1c5,marker:#f9e2af,info:#8a90ac,spinner:#03f1c5,header:#8a90ac"
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)               # widgets Ctrl+R / Ctrl+T / Alt+C
fi

# fzf-tab : remplace le menu de complétion Tab par une UI fzf (paquet AUR
# fzf-tab-git). DOIT être sourcé après compinit et avant zsh-autosuggestions /
# zsh-syntax-highlighting (qui enveloppent des widgets zle).
_fzftab=0
for _ft in /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh \
           /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh \
           /usr/share/fzf-tab/fzf-tab.plugin.zsh; do
    [[ -r $_ft ]] && { source "$_ft"; _fzftab=1; break; }
done
if (( _fzftab )); then
    zstyle ':completion:*' menu no                                  # fzf-tab gère le menu (sinon menu natif, voir plus haut)
    zstyle ':fzf-tab:*' use-fzf-default-opts yes                    # reprend le thème
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always -- "$realpath"'
fi

# --- Suggestions à la frappe (zsh-autosuggestions) ---
# Stratégie : d'abord l'historique, sinon la complétion (chemins, commandes) —
# ainsi des suggestions apparaissent même quand l'historique est vide/neuf.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Couleur explicite : le défaut (fg=8) tombe sur #43465A, illisible sur le fond
# noir pur du terminal. On force un gris nettement visible.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
_zas=/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $_zas ]] && source "$_zas"

# --- zoxide : cd intelligent (commande `z`) ---
# Le hook enregistre chaque cd dans sa base ; c'est elle que lit le picker de
# projets de LazyVim (<leader>fp). À sourcer avant le highlighting.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# --- Prompt starship (config dans ~/.config/starship.toml) ---
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# --- Coloration syntaxique (zsh-syntax-highlighting) ---
# DOIT être sourcé en dernier des plugins (après la définition des widgets zle).
_zsh=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -r $_zsh ]] && source "$_zsh"

# --- fastfetch au démarrage d'un shell interactif ---
# La config (~/.config/fastfetch/config.jsonc) définit un logo image de type
# kitty : parfait dans kitty, illisible ailleurs. Hors kitty on force donc le
# logo ASCII intégré de la distro.
if command -v fastfetch >/dev/null 2>&1; then
    if [[ -n "$KITTY_WINDOW_ID" ]]; then
        fastfetch
    else
        fastfetch --logo-type builtin
    fi
fi
alias castor-starter='"/home/kbyjoel/www/castor-starter/vendor/bin/castor" --castor-file="/home/kbyjoel/www/castor-starter/castor.php"'
