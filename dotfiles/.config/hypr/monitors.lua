-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- MONITORS                                              --
-- Répartition des workspaces entre les écrans.          --
-- Inclus depuis hyprland.lua via require().             --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Poste fixe (2 écrans) : les workspaces 1 à 5 vivent sur l'écran de GAUCHE et
-- le 6 « Web » (google-chrome, cf. le plan dans userprefs.lua) sur celui de
-- DROITE. Éditeur / terminal / mail à gauche, navigateur à droite, à chaque
-- démarrage et sans rien avoir à replacer à la main.
--
-- POURQUOI ÉPINGLER, et pas seulement le 6 : un workspace vit sur l'écran où il
-- a été créé, et au démarrage chaque écran s'attribue le premier workspace
-- libre (gauche -> 1, droite -> 2). Le second écran captait donc le workspace 2
-- à chaque boot, et tout ce qui y est routé (les PWA Gmail / Outlook / Agenda)
-- s'ouvrait à droite. Épingler nommément lève l'ambiguïté.
--
-- CE QUE ÇA N'APPORTE PAS : un workspace ne peut pas s'étendre sur deux écrans.
-- Hyprland l'affiche sur un écran et un seul — il n'existe pas de disposition
-- « la 1re fenêtre à gauche, la 2e à droite, les suivantes en split ». Pour
-- envoyer ponctuellement une fenêtre sur l'autre écran, voir les raccourcis
-- SUPER+ALT+gauche/droite dans keybindings.lua.
--
-- Portable entre machines : AUCUN nom d'écran n'est codé en dur, gauche et
-- droite sont déduits de la géométrie (x le plus petit / le plus grand). Sur le
-- portable, un seul écran -> aucune règle posée, comportement d'origine.

-- Workspaces épinglés par côté. Le PREMIER de chaque liste devient le workspace
-- par défaut de son écran (attribut `default`), c'est-à-dire celui sur lequel
-- l'écran s'ouvre au démarrage.
local PLAN = {
    left  = { "1", "2", "3", "4", "5" },
    right = { "6" },
}

local rules = {}    -- "<ws>@<écran>" -> handle de règle (mémorisé, jamais recréé)
local applied = {}  -- ws -> écran actuellement ciblé (nil = aucune règle active)

-- Écrans le plus à gauche et le plus à droite, ou nil, nil s'il y en a moins de
-- deux. La liste peut être vide au tout premier passage (config évaluée avant
-- l'énumération des sorties) : c'est justement pourquoi apply() est aussi
-- rebranché sur les événements moniteur plus bas. pcall par prudence — une
-- erreur ici ferait échouer le chargement de toute la config.
local function extremes()
    local ok, mons = pcall(hl.get_monitors)
    if not ok or type(mons) ~= "table" or #mons < 2 then return nil, nil end
    local lo, hi
    for _, m in ipairs(mons) do
        if m.name and m.name ~= "" then
            if lo == nil or m.x < lo.x then lo = m end
            if hi == nil or m.x > hi.x then hi = m end
        end
    end
    if not lo or not hi then return nil, nil end
    return lo.name, hi.name
end

-- Épingle un workspace sur un écran (monitor = nil : plus d'épinglage du tout).
local function pin(ws, monitor, is_default)
    if applied[ws] == monitor then return end

    -- Le moniteur d'une règle de workspace ne peut pas être changé après coup
    -- (le handle n'expose que set_enabled). On désactive donc l'ancienne règle
    -- et on (ré)active celle de la cible, en réutilisant les handles déjà créés
    -- pour ne pas empiler une règle de plus à chaque branchement d'écran.
    local previous = applied[ws]
    if previous and rules[ws .. "@" .. previous] then
        rules[ws .. "@" .. previous]:set_enabled(false)
    end
    applied[ws] = monitor
    if not monitor then return end

    local key = ws .. "@" .. monitor
    if rules[key] then
        rules[key]:set_enabled(true)
    else
        rules[key] = hl.workspace_rule({
            workspace = ws,
            monitor   = monitor,
            default   = is_default or nil,
        })
    end

    -- La règle ne s'applique qu'à la CRÉATION du workspace : s'il existe déjà
    -- sur le mauvais écran (rechargement de config, écran branché à chaud), il
    -- faut le déplacer explicitement.
    local w = hl.get_workspace(tonumber(ws))
    if w and w.monitor and w.monitor.name ~= monitor then
        pcall(hl.dispatch, hl.dsp.workspace.move({ workspace = ws, monitor = monitor }))
    end
end

local function apply()
    local left, right = extremes()
    for i, ws in ipairs(PLAN.left) do pin(ws, left, i == 1) end
    for i, ws in ipairs(PLAN.right) do pin(ws, right, i == 1) end
end

pcall(apply)

-- Rejoue la répartition quand la disposition des écrans change : au démarrage
-- (les sorties peuvent ne pas être encore énumérées quand la config est lue),
-- au branchement/débranchement d'un écran, et quand leurs positions bougent (ce
-- qui peut changer lequel est « à gauche » ou « à droite »).
for _, evt in ipairs({
    "hyprland.start",
    "monitor.added",
    "monitor.removed",
    "monitor.layout_changed",
}) do
    hl.on(evt, function() pcall(apply) end)
end
