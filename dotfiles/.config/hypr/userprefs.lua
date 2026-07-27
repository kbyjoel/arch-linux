-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- USER PREFS                                             --
-- Repris de l'ancien userprefs.conf (format .conf) et    --
-- traduit vers l'API Lua : périphériques + règles de     --
-- fenêtres. Inclus depuis hyprland.lua via require().    --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-------------------
---- DEVICES ----
-------------------
-- Claviers ergonomiques (disposition fr / variante ergol).
-- Sans effet si le clavier n'est pas branché.

hl.device({
    name                 = "keebart-sofle-choc-pro",
    kb_layout            = "fr",
    kb_variant           = "ergol",
    resolve_binds_by_sym = true,
})

hl.device({
    name                 = "foostan-corne-v4",
    kb_layout            = "fr",
    kb_variant           = "ergol",
    resolve_binds_by_sym = true,
})

------------------------
---- WINDOW RULES ----
------------------------
-- Plan des workspaces. Les 6 sont permanents : voir PERSISTENT dans
-- ~/.local/bin/wsbtn, qui les garde affichés dans waybar même vides.
--
--   1  Musique        spotify
--   2  Mail & agenda  PWA Chrome : Gmail, Outlook, Google Agenda
--   3  Discussion     Teams, Discord (webcord)
--   4  Terminal       kitty « nu » (castor, symfony…)
--   5  Éditeur        kitty portant nvim — classe dédiée, voir keybindings.lua
--   6  Web            google-chrome

-- 1 — Musique
hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "1" })

-- 2 — Mail & agenda (PWA Chrome)
-- La classe d'une PWA est « chrome-<app-id>-Default ». L'app-id est dérivé par
-- hachage de l'URL de départ de l'app : il est donc identique sur toute machine
-- où la PWA est installée — ces règles sont portables telles quelles. En
-- revanche l'installation de la PWA elle-même reste manuelle (voir README,
-- étape post-installation).
hl.window_rule({ match = { class = "^(chrome-fmgjjmmmlfnkbppncabfkddbjimcfncm-Default)$" }, workspace = "2" }) -- Gmail
hl.window_rule({ match = { class = "^(chrome-eoficlgicibekocmfdomjbfnjmehnhcd-Default)$" }, workspace = "2" }) -- Outlook
hl.window_rule({ match = { class = "^(chrome-kjbdgfilnfhdoflbpgamdcdgpehopbep-Default)$" }, workspace = "2" }) -- Google Agenda

-- 3 — Discussion
hl.window_rule({ match = { class = "^(teams-for-linux)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(webcord)$" },         workspace = "3" })

-- 4 / 5 — Terminal et éditeur. Deux usages distincts du même binaire kitty :
-- le terminal « nu » (lancé en `kitty`) et celui qui porte nvim, lancé avec
-- --class kitty-nvim justement pour pouvoir les séparer ici. Le match du
-- terminal est ancré (^kitty$) pour ne pas attraper kitty-nvim.
hl.window_rule({ match = { class = "^(kitty)$" },      workspace = "4" })
hl.window_rule({ match = { class = "^(kitty-nvim)$" }, workspace = "5" })

-- 6 — Web
hl.window_rule({ match = { class = "^(google-chrome)$" }, workspace = "6" })

-- Géométrie des fenêtres flottantes.
-- ATTENTION : `size` et `move` n'acceptent que des PIXELS dans l'API Lua. Les
-- pourcentages sont acceptés sans erreur puis SILENCIEUSEMENT IGNORÉS, quelle
-- que soit la forme ("20% 100%" comme {"20%","100%"}) — vérifié empiriquement
-- sur Hyprland 0.55.4. C'est ce qui rendait l'ancienne règle DevTools inopérante.
-- On calcule donc les pixels depuis le moniteur. Repli 1920x1080 si la liste
-- n'est pas encore peuplée (prudence : le cas n'arrive pas au reload, mais le
-- tout premier chargement au boot n'a pas été vérifié — sans ce pcall, une
-- erreur ici ferait échouer toute la config).
local function px(w_ratio, h_ratio)
    local W, H = 1920, 1080
    local ok, mons = pcall(hl.get_monitors)
    if ok and mons and mons[1] then
        local m = mons[1]
        local scale = (m.scale and m.scale > 0) and m.scale or 1
        -- width/height sont en pixels physiques ; les règles sont en pixels
        -- logiques -> on divise par le scale.
        W, H = m.width / scale, m.height / scale
    end
    return { math.floor(W * w_ratio), math.floor(H * h_ratio) }
end

-- Dolphin : flottant centré. On l'ouvre pour déposer/récupérer un fichier, pas
-- pour y travailler — tuilé, il casserait la disposition du workspace courant.
hl.window_rule({
    match  = { class = "^(org\\.kde\\.dolphin)$" },
    float  = true,
    size   = px(0.60, 0.65),
    center = true,
})

-- DevTools de Chrome : panneau flottant, 20 % de large collé à droite.
hl.window_rule({
    match = { initial_title = "^(DevTools)$" },
    float = true,
    size  = px(0.20, 1.00),
    move  = px(0.80, 0),
})
