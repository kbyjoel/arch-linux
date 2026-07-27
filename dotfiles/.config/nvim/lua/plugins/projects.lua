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
