-- Picker de projets (<leader>fp) : fait le cd vers le projet et restaure sa
-- session (persistence.nvim). Sans ça, nvim lancé depuis ~ traite tout le home
-- comme un seul projet géant.
--
-- Sources : les répertoires contenant un marqueur de racine sous `dev`, plus la
-- base zoxide (alimentée par les cd du shell — voir l'init zoxide dans .zshrc).
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          -- `ignored = true` désactive le .gitignore (--no-ignore côté fd) pour
          -- voir les .env & co. Effet de bord : le var/ de chaque application
          -- Symfony revient dans l'arbre ET dans la recherche par nom — 13 000
          -- fichiers de cache/log générés sur monorepo, qui noient tout.
          -- On les réexclut donc explicitement, avec les autres répertoires
          -- générés qui reviennent pour la même raison. Les patterns sont
          -- ancrés à droite : `**/var` attrape applications/*/var sans toucher
          -- aux pickers files/grep, qui respectent déjà le .gitignore.
          exclude = { "**/var", "**/vendor", "**/node_modules", "**/public/build" },
        },
        projects = {
          dev = { "~/www" },
          -- Reprend les patterns par défaut de snacks + castor.php, pour que les
          -- projets sans .git à la racine (ex. ~/www/admin-bundle, un conteneur
          -- de sous-dépôts) soient quand même détectés.
          patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "package.json", "Makefile", "castor.php" },
        },
      },
    },
  },
}
