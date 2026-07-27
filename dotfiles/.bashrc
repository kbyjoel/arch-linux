#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
export PATH="$HOME/.local/bin:$PATH"

# Prompt starship (config reprise de HyDE dans ~/.config/starship.toml).
# starship définit lui-même PS1, donc plus besoin de la ligne PS1 manuelle.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='[\u@\h \W]\$ '
fi

# Affiche fastfetch au démarrage d'un shell interactif.
# La config (~/.config/fastfetch/config.jsonc) définit un logo image de type
# kitty : parfait dans kitty, mais illisible ailleurs. Hors kitty on force donc
# le logo ASCII intégré de la distro.
if command -v fastfetch >/dev/null 2>&1; then
    if [[ -n "$KITTY_WINDOW_ID" ]]; then
        fastfetch
    else
        fastfetch --logo-type builtin
    fi
fi
