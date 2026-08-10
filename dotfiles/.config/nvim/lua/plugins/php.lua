-- PHP / Symfony.
--
-- Surcouche de l'extra `lazyvim.plugins.extras.lang.php` (activé dans
-- lazyvim.json), qui suppose un projet PHP « classique » : un composer.json à
-- la racine, les outils QA dans ./vendor/bin, phpcs pour le lint. Les
-- monorepos Symfony ne ressemblent pas à ça — d'où ce fichier.
--
-- Hypothèses volontairement DÉDUITES du projet ouvert, jamais codées en dur :
-- les binaires et les fichiers de config sont cherchés en remontant depuis le
-- fichier courant. La même config marche donc sur un projet mono-app.
--
-- Le runtime applicatif reste Docker : PHP côté hôte ne sert qu'à faire tourner
-- phpactor, php-cs-fixer et phpstan. Inutile d'aligner sa version sur celle du
-- conteneur — ces trois-là sont tolérants. En revanche les extensions doivent
-- être activées côté hôte (cf. assets/php/conf.d/ dans ce dépôt) : sans iconv,
-- phpactor refuse même de démarrer.

-- Analyser SANS la baseline PHPStan dans l'éditeur (la CI, elle, la garde via
-- `castor qa`). Choix assumé : une baseline est de la dette explicitement mise
-- de côté, et invisible elle ne diminue jamais. Sur le monorepo qui a motivé
-- ce fichier, elle masque 7 563 erreurs réparties sur 1 658 fichiers ; les
-- voir en éditant, c'est se donner l'occasion de les traiter au passage.
--
-- Effet de bord à connaître : sur un fichier legacy très chargé (jusqu'à 80
-- erreurs ici), l'erreur qu'on vient d'introduire se noie dans les anciennes.
-- Mettre à false pour revenir au comportement fidèle à la CI.
local PHPSTAN_IGNORE_BASELINE = true

-- Remonte depuis `from` à la recherche d'un exécutable, en testant plusieurs
-- emplacements relatifs. Sert à trouver les outils là où le projet les met
-- vraiment : un monorepo isole souvent ses outils QA dans leur propre
-- composer.json (tools/phpstan/vendor/bin/…) pour que leurs dépendances
-- n'entrent pas en conflit avec celles des applications.
---@param paths string[] chemins relatifs, du plus spécifique au plus général
---@param from string répertoire de départ
---@return string|nil chemin absolu de l'exécutable
local function find_bin(paths, from)
  for _, rel in ipairs(paths) do
    local anchor = rel:match("^[^/]+")
    local subpath = rel:sub(#anchor + 1)
    -- limit=math.huge : on veut TOUS les répertoires « tools »/« vendor » de la
    -- remontée, pas seulement le plus proche — dans un monorepo le premier
    -- rencontré est souvent celui d'une application, pas celui de l'outillage.
    for _, hit in ipairs(vim.fs.find(anchor, { path = from, upward = true, limit = math.huge })) do
      local full = hit .. subpath
      if vim.fn.executable(full) == 1 then
        return full
      end
    end
  end
end

-- Emplacements possibles de php-cs-fixer, du plus spécifique au plus général.
local CS_FIXER_PATHS = {
  "tools/php-cs-fixer/vendor/bin/php-cs-fixer",
  "vendor/bin/php-cs-fixer",
}

-- PHP-CS-Fixer s'arrête net au-delà de PHP 8.4 (« currently supports PHP
-- syntax only up to PHP 8.4 ») : il sort en affichant l'avertissement, sans
-- rien formater — silencieusement du point de vue de conform. Sur un système
-- où le php principal est plus récent, on l'exécute donc via php-legacy.
-- Détecté à chaque appel plutôt que mémorisé au chargement : la config est
-- versionnée et déployée sur des machines où php-legacy n'est pas installé.
local function php_runner()
  if vim.fn.executable("php-legacy") == 1 then
    return "php-legacy"
  end
end

local NEON_NAMES = { "phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon" }

-- Le résolveur intégré de nvim-lint ne teste que ./vendor/bin/phpstan
-- relativement au CWD de Neovim : inutilisable dès que l'outillage est isolé
-- dans son propre composer.json, ou simplement quand on ouvre nvim ailleurs
-- que dans le répertoire de l'application.
local function phpstan_bin(from)
  return find_bin({
    "tools/bin/phpstan",
    "tools/phpstan/vendor/bin/phpstan",
    "vendor/bin/phpstan",
  }, from)
end

-- Chemin absolu, sans slash final, avec les `..` résolus.
local function abspath(path)
  return (vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("/+$", ""))
end

-- Répertoires couverts par le bloc `paths:` d'une config PHPStan, en absolu.
--
-- Volontairement un parseur de trois lignes plutôt qu'un vrai lecteur NEON :
-- on ne cherche qu'à savoir quels répertoires une config déclare analyser, et
-- `paths` est en pratique toujours une liste plate de chaînes. Les chemins y
-- sont relatifs AU FICHIER DE CONFIG, pas au CWD.
local function neon_paths(config)
  local ok, lines = pcall(vim.fn.readfile, config)
  if not ok then
    return {}
  end

  local base = vim.fn.fnamemodify(config, ":h")
  local dirs, in_block = {}, false

  local function add(item)
    item = vim.trim(item):gsub("^['\"]", ""):gsub("['\"]$", "")
    if item ~= "" then
      table.insert(dirs, abspath(base .. "/" .. item))
    end
  end

  for _, line in ipairs(lines) do
    local inline = line:match("^%s*paths:%s*%[(.*)%]")
    if inline then -- forme `paths: [src, ../lib]`
      for item in inline:gmatch("[^,]+") do
        add(item)
      end
      in_block = false
    elseif line:match("^%s*paths:%s*$") then
      in_block = true
    elseif in_block then
      local item = line:match("^%s*%-%s*(.-)%s*$")
      if line:match("^%s*#") or line:match("^%s*$") then
        -- Commentaire ou ligne vide AU MILIEU de la liste : on continue.
        -- Ne pas les ignorer serait le pire des cas — une entrée commentée
        -- (`# - application/src`, une exclusion volontaire) couperait le
        -- parsing, `paths` ressortirait vide, et la config serait interprétée
        -- comme couvrant tout son répertoire : exactement l'inverse de ce que
        -- le mainteneur a écrit.
        _ = item
      elseif item and item ~= "" then
        add((item:gsub("%s+#.*$", ""))) -- commentaire de fin de ligne
      else
        in_block = false -- une clé au même niveau : fin de la liste
      end
    end
  end

  return dirs
end

-- `path` est-il `ancestor`, ou situé dessous ?
local function under(path, ancestor)
  return path == ancestor or path:sub(1, #ancestor + 1) == ancestor .. "/"
end

-- Fichier de config PHPStan qui gouverne `file`, ou nil s'il n'y en a pas.
--
-- RÈGLE : une config ne gouverne un fichier que si son bloc `paths:` le
-- couvre. « Il y a un phpstan.neon au-dessus » ne suffit pas — c'est même le
-- piège principal. Un projet qui commente `- application/src` dans ses paths
-- l'a fait exprès (typiquement parce qu'aucun autoloader n'est déclaré pour
-- lui) ; forcer l'analyse quand même produit des dizaines de faux
-- « class.notFound » / « trait.notFound » à chaque sauvegarde. Respecter
-- `paths` fait coïncider ce que montre l'éditeur avec ce que voit la CI.
local function phpstan_config(file)
  file = abspath(file)
  local dir = vim.fn.fnamemodify(file, ":h")

  -- Candidates : les configs au-dessus du fichier, plus celles du reste du
  -- dépôt (une bibliothèque partagée est souvent analysée par la config d'une
  -- APPLICATION SŒUR qui la tire via `paths`, ex. `- ../lib-shop/`).
  local candidates =
    vim.fs.find(NEON_NAMES, { path = dir, upward = true, type = "file", limit = math.huge })

  local root = vim.fs.root(dir, ".git")
  if root then
    -- Profondeurs figées plutôt qu'une descente récursive : un `vim.fs.find`
    -- vers le bas traverserait les vendor/ et node_modules/ à chaque analyse.
    -- Deux niveaux couvrent les dispositions habituelles (applications/<app>/).
    for _, depth in ipairs({ "", "/*", "/*/*" }) do
      for _, name in ipairs(NEON_NAMES) do
        vim.list_extend(candidates, vim.fn.glob(root .. depth .. "/" .. name, true, true))
      end
    end
  end

  local best, best_len, seen = nil, -1, {}
  for _, config in ipairs(candidates) do
    config = abspath(config)
    if not seen[config] then
      seen[config] = true
      local owner = vim.fn.fnamemodify(config, ":h")
      -- Une config posée au-dessus du fichier est « la sienne » ; une config
      -- située ailleurs dans le dépôt lui est EMPRUNTÉE. La distinction sert
      -- juste en dessous.
      local sienne = under(dir, owner)

      local paths = neon_paths(config)
      if #paths == 0 then
        -- Config sans bloc `paths:` (périmètre passé en ligne de commande) :
        -- elle ne dit rien de sa portée, on retombe sur la convention « elle
        -- gouverne son propre répertoire » plutôt que de la rendre inerte.
        paths = { owner }
      end

      for _, covered in ipairs(paths) do
        -- Anti-ratissage, appliqué aux seules configs EMPRUNTÉES : une config
        -- qui déclare son propre parent (`- ../`, `- .`) ne désigne pas une
        -- bibliothèque voisine, elle balaie le dépôt entier. L'emprunter
        -- imposerait son niveau et ses règles à des applications qui n'ont
        -- rien demandé. Sur sa propre arborescence, en revanche, `- .` est
        -- parfaitement légitime : c'est le cas du projet mono-app.
        local ratisse = not sienne and under(owner, covered)
        -- Plusieurs applications peuvent tirer la même bibliothèque : on garde
        -- la déclaration la plus SPÉCIFIQUE (le chemin le plus long), pour que
        -- le choix soit stable et non tributaire de l'ordre du glob.
        if under(file, covered) and not ratisse and #covered > best_len then
          best, best_len = config, #covered
        end
      end
    end
  end

  return best
end

-- Variante de `config` privée de son include de baseline, générée À CÔTÉ de
-- l'originale. Renvoie `config` telle quelle si elle n'inclut pas de baseline.
--
-- POURQUOI À CÔTÉ et pas dans un répertoire de cache : les chemins d'un .neon
-- (paths, tmpDir, includes, excludePaths…) sont résolus relativement AU
-- FICHIER DE CONFIG. Déplacer la copie ailleurs les casserait tous, et les
-- réécrire en absolu supposerait de connaître toutes les clés de PHPStan qui
-- portent un chemin — un pari qui se perdrait en silence sur le premier projet
-- utilisant une clé oubliée.
--
-- L'alternative « propre » a été essayée et écartée : un wrapper qui inclut
-- l'originale puis remet `ignoreErrors!: []` peut vivre n'importe où, mais
-- (a) il ne gagne que 1 200 → 930 ms, la baseline restant lue avant d'être
-- jetée, et (b) il écrase du même coup les ignoreErrors délibérés du projet,
-- qui ne sont pas de la dette. La copie amputée, elle, coûte 182 ms et ne
-- retire que la baseline.
local function without_baseline(config)
  local ok, lines = pcall(vim.fn.readfile, config)
  if not ok then
    return config
  end

  local out, i, dropped = {}, 1, false
  while i <= #lines do
    local line = lines[i]
    if line:match("^%s*includes:%s*$") then
      -- Collecte le bloc qui suit, en écartant la seule ligne de baseline.
      local items, j = {}, i + 1
      while j <= #lines do
        local l = lines[j]
        if l:match("^%s*%-") then
          if l:match("phpstan%-baseline") then
            dropped = true
          else
            table.insert(items, l)
          end
        elseif l:match("^%s*#") or l:match("^%s*$") then
          table.insert(items, l) -- commentaire ou ligne vide : on traverse
        else
          break -- une clé au même niveau : fin du bloc
        end
        j = j + 1
      end

      -- N'émettre la clé que s'il reste un include réel : un `includes:` vide
      -- fait échouer PHPStan au démarrage.
      local reste = false
      for _, l in ipairs(items) do
        if l:match("^%s*%-") then
          reste = true
        end
      end
      if reste then
        table.insert(out, line)
        vim.list_extend(out, items)
      end
      i = j
    else
      table.insert(out, line)
      i = i + 1
    end
  end

  if not dropped then
    return config
  end

  local derived = vim.fn.fnamemodify(config, ":h") .. "/.phpstan-nvim.neon"
  local src, dst = vim.uv.fs_stat(config), vim.uv.fs_stat(derived)
  -- Régénérée seulement si la source a bougé : écrire à chaque analyse
  -- coûterait plus cher que ce qu'on cherche à économiser.
  if not dst or (src and dst.mtime.sec < src.mtime.sec) then
    if not pcall(vim.fn.writefile, out, derived) then
      return config -- dépôt en lecture seule : on retombe sur l'originale
    end
  end
  return derived
end

-- Le consommateur d'un paquet monté en dépôt composer `path`, s'il existe.
--
-- Un paquet du monorepo tiré par une application n'a pas de vendor/ à lui :
-- ses propres dépendances sont installées chez son consommateur, qui le
-- référence par un lien symbolique dans son vendor/. Typiquement, lib-shop est
-- tiré par frontend via applications/frontend/vendor/<éditeur>/lib-shop.
-- L'ouvrir avec lui-même pour racine couperait le serveur de tout Symfony.
--
-- Déduit du LIEN SYMBOLIQUE et non des composer.json : c'est l'installation
-- réelle qui détermine ce que l'autoloader peut résoudre, pas la déclaration.
---@param pkg string racine du paquet dépourvu de vendor/
---@return string|nil racine de l'application qui l'installe
local function path_consumer(pkg)
  local root = vim.fs.root(pkg, ".git")
  if not root then
    return nil
  end
  local target = vim.uv.fs_realpath(pkg)
  -- Profondeurs figées plutôt qu'une descente récursive : un glob non borné
  -- traverserait les vendor/ eux-mêmes à chaque ouverture de fichier.
  for _, depth in ipairs({ "", "/*", "/*/*" }) do
    for _, link in ipairs(vim.fn.glob(root .. depth .. "/vendor/*/*", true, true)) do
      if link ~= target and vim.uv.fs_realpath(link) == target then
        -- vendor/<éditeur>/<paquet> : trois crans pour revenir à l'application.
        return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(link)))
      end
    end
  end
end

-- Racine LSP d'un fichier PHP : l'application qui porte son autoloader.
--
-- lspconfig déclare `root_markers = { ".git", "composer.json", … }` pour
-- phpactor comme pour intelephense. Cette liste est PLATE, donc ordonnée par
-- PRIORITÉ et non par proximité : `.git` l'emporte quelle que soit sa
-- distance, et sur un monorepo la racine résolue est le dépôt entier. Mesuré :
--
--   vim.fs.root(f, { ".git", "composer.json" }) -> …/monorepo
--   vim.fs.root(f, { "composer.json" })         -> …/applications/lib-shop
--
-- L'effet de bord qui coûte cher n'est pas le mélange des espaces de noms mais
-- l'index : les indexer.exclude_patterns plus bas sont relatifs à la racine du
-- projet, donc avec la racine au monorepo `/vendor/**/*` désigne
-- `monorepo/vendor`, qui n'existe pas. Toutes les exclusions deviennent
-- inertes et l'index avale les vendor/ et var/ de chaque application — 1,2 Go
-- de cache constatés, pour des propositions noyées dans du code généré.
---@param bufnr integer
---@param on_dir fun(dir?: string)
local function php_root(bufnr, on_dir)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return on_dir(nil)
  end

  local from = vim.fs.dirname(file)
  local pkg = vim.fs.root(from, "composer.json")
  if not pkg then
    -- Répertoire sans composer.json (centralapi, legacy) : on retombe sur le
    -- dépôt faute de mieux — le comportement actuel, pas une régression.
    return on_dir(vim.fs.root(from, ".git"))
  end

  -- Un paquet qui porte son propre vendor/ est autonome ; sinon il est tiré
  -- par une application, et c'est celle-ci qui a l'autoloader complet.
  if vim.uv.fs_stat(pkg .. "/vendor") then
    return on_dir(pkg)
  end
  on_dir(path_consumer(pkg) or pkg)
end

return {
  -- ------------------------------------------------------------------ LSP ---
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Racine par application, et non au monorepo : cf. php_root plus haut,
        -- qui explique pourquoi la détection par défaut ne le fait PAS malgré
        -- les apparences. Posé sur les deux serveurs pour que basculer
        -- `vim.g.lazyvim_php_lsp` ne réintroduise pas le problème.
        intelephense = { root_dir = php_root },
        phpactor = {
          root_dir = php_root,
          init_options = {
            -- phpactor sait lancer phpstan/php-cs-fixer lui-même. On coupe :
            -- ils sont déjà pilotés par nvim-lint et conform plus bas, avec la
            -- config du projet. Sans ça, chaque erreur remonte en double et
            -- phpactor relance une analyse à chaque frappe.
            ["language_server_phpstan.enabled"] = false,
            ["language_server_php_cs_fixer.enabled"] = false,
            ["language_server_psalm.enabled"] = false,

            -- Ajoute automatiquement le `\` devant les fonctions natives dans
            -- un namespace (strlen -> \strlen). Attendu par le fixer
            -- `native_function_invocation` du preset @Symfony:risky, actif
            -- sur le monorepo : évite que chaque sauvegarde reformate ce que
            -- phpactor vient d'écrire.
            ["code_transform.import_globals"] = true,

            -- LIMITE CONNUE, pas de contournement ici : les motifs d'inclusion
            -- de phpactor (`/**/*.php`) ignorent tout ce qui est masqué, un
            -- `*` de glob ne matchant pas un point initial. Éditer un
            -- castor.php donne donc une vingtaine de « Function "io" not
            -- found » : le stub `.castor.stub.php`, généré exprès pour les
            -- IDE, n'est jamais indexé. Ajouter `/.*.php` et `/.*/**/*.php`
            -- à indexer.include_patterns ne corrige rien (testé, cache purgé
            -- et index reconstruit) — et écraserait la liste par défaut au
            -- passage. À reprendre côté phpactor.

            -- INDISPENSABLE sur un monorepo à dépôts composer `path`. La racine
            -- résolue par php_root est l'application qui porte l'autoloader
            -- (frontend) ; depuis là, le paquet du monorepo n'est atteignable
            -- que par le lien posé par composer :
            --
            --   applications/frontend/vendor/<éditeur>/lib-shop
            --     -> ../../../lib-shop/
            --
            -- phpactor n'entre pas dans les liens symboliques par défaut, donc
            -- les ~2785 classes de lib-shop restent HORS de l'index — celles-là
            -- mêmes qu'on édite toute la journée. Symptôme trompeur : Symfony et
            -- Doctrine complètent très bien (vrais répertoires), seul le code du
            -- projet est muet, et la complétion ne propose plus que Copilot.
            -- Mesuré sur l'index avant correction : 1160 fichiers indexés sous
            -- vendor/doctrine, 0 sous lib-shop.
            --
            -- Sans danger ici : `vendor/` ne contient qu'un seul lien, qui pointe
            -- vers un paquet dépourvu de vendor/ — pas de cycle, pas de double
            -- indexation. À revoir si le monorepo ajoutait d'autres paquets path.
            ["indexer.follow_symlinks"] = true,

            -- Indexation : un vendor/ Symfony fait des dizaines de milliers de
            -- fichiers. On écarte ce qui n'apporte aucune complétion utile.
            -- Les motifs sont relatifs à la racine du projet (le `/` initial
            -- n'est PAS la racine du système de fichiers).
            ["indexer.exclude_patterns"] = {
              "/vendor/**/Tests/**/*",
              "/vendor/**/tests/**/*",
              "/vendor/composer/**/*",
              -- var/ contient le cache Symfony : des conteneurs d'injection
              -- générés, énormes et régénérés en permanence. Les indexer fait
              -- exploser le temps de démarrage pour des classes qui
              -- n'existent qu'à l'exécution.
              "/var/**/*",
              "/node_modules/**/*",
              "/public/build/**/*",
            },
          },
        },
      },
    },
  },

  -- ------------------------------------------------------------ Formatage ---
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        php_cs_fixer = {
          -- Quand php-legacy est là, c'est LUI l'exécutable lancé, et le
          -- fixer devient son premier argument (on ne peut pas se reposer sur
          -- le shebang `#!/usr/bin/env php` du binaire, qui pointerait sur le
          -- php trop récent).
          command = function(_, ctx)
            return php_runner() or find_bin(CS_FIXER_PATHS, ctx.dirname) or "php-cs-fixer"
          end,
          args = function(_, ctx)
            local fixer = find_bin(CS_FIXER_PATHS, ctx.dirname) or "php-cs-fixer"
            if php_runner() then
              return { fixer, "fix", "$FILENAME" }
            end
            return { "fix", "$FILENAME" }
          end,

          -- php-cs-fixer cherche son .php-cs-fixer.php dans le CWD, et nulle
          -- part ailleurs. Le défaut de conform (le composer.json le plus
          -- proche) le placerait dans applications/<app>/ alors que la config
          -- est à la racine du monorepo : le fichier serait reformaté avec les
          -- règles par défaut au lieu du preset @Symfony du projet — soit un
          -- diff énorme et faux à chaque sauvegarde.
          cwd = function(_, ctx)
            return vim.fs.root(ctx.dirname, { ".php-cs-fixer.php", ".php-cs-fixer.dist.php" })
              -- Repli pour un projet mono-app sans config dédiée.
              or vim.fs.root(ctx.dirname, "composer.json")
          end,
        },
      },
    },
  },

  -- ----------------------------------------------------------------- Lint ---
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      -- LazyVim déclenche aussi les linters sur InsertLeave. À retirer ici :
      -- PHPStan met ~3 s sur un seul fichier (mesuré sur le monorepo, niveau
      -- 7), donc sortir du mode insertion lancerait une analyse complète
      -- toutes les quelques secondes. À la sauvegarde et à l'ouverture, c'est
      -- le bon rythme pour de l'analyse statique.
      events = { "BufWritePost", "BufReadPost" },

      linters_by_ft = {
        -- Remplace phpcs (défaut LazyVim). phpcs ne vérifie que le style —
        -- ce que php-cs-fixer corrige déjà tout seul à la sauvegarde, donc
        -- ses diagnostics n'ont aucune valeur ici. PHPStan, lui, trouve de
        -- vraies erreurs (types, appels impossibles, null non gardés).
        php = { "phpstan" },
      },

      linters = {
        phpstan = {
          -- Le résolveur intégré de nvim-lint ne teste que ./vendor/bin/phpstan
          -- relativement au CWD de Neovim : inutilisable dès que l'outillage
          -- est isolé, ou simplement quand on ouvre nvim ailleurs que dans le
          -- répertoire de l'application.
          cmd = function()
            return phpstan_bin(vim.fn.expand("%:p:h")) or "phpstan"
          end,

          -- Deux garde-fous, chacun pour une erreur qui remonterait sinon à
          -- CHAQUE sauvegarde :
          --  * sans fichier de config, PHPStan analyse au niveau 0 avec des
          --    chemins devinés et crache du texte au lieu du JSON attendu ;
          --  * sans binaire (projet qui déclare un phpstan.neon mais dont les
          --    dépendances ne sont pas installées, ou vendor/ resté dans le
          --    conteneur), nvim-lint échoue sur « Error running phpstan:
          --    ENOENT » — un message opaque pour une situation parfaitement
          --    normale.
          condition = function(ctx)
            return phpstan_bin(ctx.dirname) ~= nil and phpstan_config(ctx.filename) ~= nil
          end,

          args = {
            "analyse",
            "--error-format=json",
            "--no-progress",

            -- PHPStan tourne ici avec le php de l'HÔTE, dont le memory_limit
            -- vaut 128 Mo par défaut sur Arch — largement insuffisant pour
            -- analyser une application Symfony, et l'échec est violent : un
            -- « PHP Fatal error: Allowed memory size exhausted » à la place du
            -- JSON. Les conteneurs applicatifs, eux, n'ont pas cette limite,
            -- d'où un écart invisible entre l'éditeur et la CI.
            "--memory-limit=-1",

            function()
              -- L'autoloader. PHPStan le cherche sinon dans le CWD, qui est
              -- celui de Neovim : ouvrir nvim à la racine d'un monorepo donne
              -- alors un mur de « class.notFound » (18 sur un simple
              -- Kernel.php), parce que l'autoload vit dans l'application,
              -- pas à la racine. On le déduit de l'emplacement de la config,
              -- ce qui reproduit exactement ce que fait la CI du projet.
              local config = phpstan_config(vim.fn.expand("%:p"))
              local autoload = vim.fn.fnamemodify(config, ":h") .. "/vendor/autoload.php"
              if vim.uv.fs_stat(autoload) then
                return "--autoload-file=" .. autoload
              end
              -- Aucun argument à ajouter. nvim-lint évalue chaque élément de
              -- la liste sans savoir en sauter un, et renvoyer nil y percerait
              -- un trou qui tronquerait les arguments suivants : on répète donc
              -- un drapeau idempotent, sans effet (vérifié).
              return "--no-progress"
            end,
            function()
              -- Chemin ABSOLU : les chemins internes du .neon (paths, tmpDir,
              -- includes) sont résolus par PHPStan relativement au fichier de
              -- config lui-même, pas au CWD. Le passer en absolu rend donc
              -- l'analyse indépendante du répertoire d'où tourne Neovim.
              --
              -- Le fichier à analyser est ajouté ensuite par nvim-lint et
              -- prend le pas sur le `paths` de la config : quand on emprunte
              -- celle d'une application sœur (cf. phpstan_config), on hérite
              -- de son niveau, de ses règles et de sa baseline, mais l'analyse
              -- reste bien limitée au fichier courant.
              local config = phpstan_config(vim.fn.expand("%:p"))
              if PHPSTAN_IGNORE_BASELINE then
                config = without_baseline(config)
              end
              return "--configuration=" .. config
            end,
          },

          -- Le parser intégré fait un vim.json.decode() sec. Quand PHPStan
          -- échoue (extension PHP manquante, .neon invalide, mémoire), il
          -- écrit du texte : le decode lève une erreur Lua qui remonte en
          -- pleine figure à chaque sauvegarde. On absorbe.
          parser = function(output, bufnr, cwd)
            local builtin = require("lint.linters.phpstan").parser
            local ok, diagnostics = pcall(builtin, output, bufnr, cwd)
            if not ok then
              vim.notify_once(
                "PHPStan n'a pas renvoyé de JSON :\n" .. vim.trim(output):sub(1, 500),
                vim.log.levels.WARN,
                { title = "nvim-lint" }
              )
              return {}
            end
            return diagnostics
          end,
        },
      },
    },
  },

  -- --------------------------------------------------------------- Mason ---
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = function(_, opts)
      -- L'extra LazyVim installe phpcs ; on ne s'en sert plus (cf. plus haut).
      -- php-cs-fixer est gardé : il sert de repli quand un projet ne fournit
      -- pas le sien. Note : retirer d'ensure_installed ne désinstalle pas —
      -- pour faire le ménage : `:MasonUninstall phpcs`.
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "phpcs"
      end, opts.ensure_installed or {})
    end,
  },
}
