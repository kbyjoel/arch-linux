# Mémo LazyVim — raccourcis

Recueil des raccourcis vus au fil des questions.

## Sommaire

1. [Déplacements dans l'écran](#déplacements-dans-lécran)
2. [Aller à une ligne](#aller-à-une-ligne)
3. [Déplacements dans la ligne](#déplacements-dans-la-ligne)
4. [Naviguer par méthode / classe](#naviguer-par-méthode--classe)
5. [Plier / déplier le code](#plier--déplier-le-code)
6. [Explorateur de fichiers](#explorateur-de-fichiers-leadere)
7. [Buffers & fenêtres](#buffers--fenêtres)
8. [Incrémenter / décrémenter un nombre](#incrémenter--décrémenter-un-nombre)
9. [Copier / coller (yank & put)](#copier--coller-yank--put)
10. [Commenter / décommenter](#commenter--décommenter)
11. [Surround (mini.surround)](#surround-minisurround)
12. [Recherche](#recherche)
13. [Rechercher / remplacer (substitute)](#rechercher--remplacer-substitute)
14. [LSP](#lsp)
15. [Git dans le fichier (gitsigns)](#git-dans-le-fichier-gitsigns)
16. [lazygit](#lazygit-leadergg)

## Déplacements dans l'écran

### Défiler écran par écran

| Raccourci | Effet |
|---|---|
| `<C-f>` | un écran vers le bas (**f**orward) |
| `<C-b>` | un écran vers le haut (**b**ack) |
| `<C-d>` | un **demi**-écran vers le bas (**d**own) — le plus pratique |
| `<C-u>` | un demi-écran vers le haut (**u**p) |

### Placer le curseur dans l'écran (sans défiler)

| Raccourci | Position |
|---|---|
| `H` | en **h**aut de l'écran |
| `M` | au **m**ilieu de l'écran |
| `L` | en bas de l'écran (**l**ow) |

### Recentrer l'écran sur le curseur

| Raccourci | Effet |
|---|---|
| `zz` | ligne du curseur au **milieu** (réflexe après un saut : `gd`, `/`, `G`…) |
| `zt` | ligne du curseur en haut (**t**op) |
| `zb` | ligne du curseur en bas (**b**ottom) |

> `M` bouge le *curseur* vers le milieu de la vue ; `zz` bouge la *vue* pour suivre le curseur.

## Aller à une ligne

### Ligne absolue (numéro)

| Raccourci | Effet |
|---|---|
| `42G` | aller à la ligne 42 |
| `:42<CR>` | idem, via la ligne de commande |
| `gg` / `G` | première / dernière ligne du fichier |
| `50%` | à 50 % du fichier (proportion, pas numéro de ligne) |

### Nombre de lignes relatif au curseur

| Raccourci | Effet |
|---|---|
| `5j` / `5k` | 5 lignes en dessous / au-dessus |
| `5<CR>` | 5 lignes en dessous, sur le premier caractère non blanc |
| `5+` / `5-` | idem `5<CR>` / 5 lignes au-dessus, premier non blanc |

Le confort vient du **numérotage relatif** : chaque ligne affiche sa distance au
curseur, donc on lit `7` en marge et on tape `7j`.

| Raccourci | Effet |
|---|---|
| `<leader>ul` | affiche/masque les numéros de ligne |
| `<leader>uL` | bascule numérotage **relatif** ⇄ absolu |

- `42G` et `:42` sont enregistrés dans la **jumplist** → `<C-o>` ramène en arrière.
  `5j` / `5k` **non** (sauf au-delà du seuil `'jumpoptions'`).
- Combinable avec un opérateur : `d5j` supprime 6 lignes, `y42G` yank jusqu'à la
  ligne 42, `=5j` réindente.

> Bonus LazyVim : `s` (flash.nvim) affiche des étiquettes de saut — souvent plus
> rapide qu'un compte pour viser un mot précis à l'écran.

## Déplacements dans la ligne

### Par mot

| Raccourci | Effet |
|---|---|
| `w` / `b` | début du mot suivant / précédent |
| `e` / `ge` | **fin** du mot suivant / précédent |
| `W` `B` `E` | idem en **WORD** (délimité par les espaces seulement) |

> Distinction cruciale sur du code : sur `--ma-var`, `w` s'arrête à chaque tiret,
> `W` saute le token entier. Même logique que `viW` (voir *Rechercher / remplacer*).

### Début / fin de ligne

| Raccourci | Effet |
|---|---|
| `0` | tout début de ligne (colonne 1) |
| `^` | premier caractère **non blanc** — celui qu'on veut 90 % du temps |
| `$` | fin de ligne |
| `g_` | dernier caractère non blanc (utile si espaces en fin de ligne) |
| `42\|` | colonne 42 |

### Viser un caractère précis — le vrai gain

| Raccourci | Effet |
|---|---|
| `f{car}` | saute **sur** la prochaine occurrence de `{car}` (**f**ind) |
| `F{car}` | idem vers la gauche |
| `t{car}` | juste **avant** `{car}` (**t**ill) |
| `T{car}` | juste après `{car}`, vers la gauche |
| `;` / `,` | répète le dernier `f`/`t` en avant / en arrière |
| `f` (retapé) | occurrence suivante — style *clever-f*, apporté par flash |
| `F` (retapé) | occurrence précédente |
| `3fx` | 3ᵉ occurrence de `x` |
| `%` | saute à la parenthèse/accolade/crochet **correspondant** |

C'est la famille `f`/`t` qui remplace le pilonnage de `w`. Elle se combine avec
les opérateurs : `df,` supprime jusqu'à la virgule incluse, `ct)` remplace tout
jusqu'à la parenthèse fermante, `y$` yank jusqu'en fin de ligne.

### `%` — la paire correspondante

`%` bascule entre une ouvrante et sa fermante : `(` ⇄ `)`, `[` ⇄ `]`, `{` ⇄ `}`.

| Situation | Geste |
|---|---|
| curseur **sur** une parenthèse | `%` |
| curseur ailleurs sur la ligne | `f)` (ou `F(` puis `%`) |

> ⚠ Piège : si le curseur n'est **pas** sur une parenthèse, `%` cherche la
> première à partir du curseur puis saute à sa **correspondante** — depuis
> l'intérieur d'un appel, il trouve le `)` et te renvoie donc sur le `(`, en
> arrière. Pour aller à la fermante, `f)` est plus sûr.

Exemple — ajouter l'argument d'un `sprintf()`, curseur dans la chaîne :

```
f)                    → curseur sur la )
i, $paymentIntent->id → insère juste avant
<Esc>
```

`sprintf('TW-4277 : %s')` → `sprintf('TW-4277 : %s', $paymentIntent->id)`

> `i` et non `a` : `i` insère **avant** le caractère sous le curseur, donc à
> l'intérieur de la parenthèse. `a` écrirait après le `)`, hors de l'appel.

> **Ces touches sont natives** (aucun plugin à installer), mais **flash.nvim les
> intercepte** ici et change deux choses :
> - `multi_line = true` → `f`/`t` **dépassent la ligne courante** et continuent
>   dans le fichier ;
> - `jumplist = true` → ces sauts sont enregistrés, donc `<C-o>` ramène.
>
> Pas d'étiquettes sur `f`/`t` (`jump_labels = false`), seulement le surlignage
> des cibles ; les étiquettes restent réservées à `s`.

## Naviguer par méthode / classe

### Treesitter — le plus fiable (LazyVim, par défaut)

| Raccourci | Effet |
|---|---|
| `]f` / `[f` | début de la **fonction/méthode** suivante / précédente |
| `]F` / `[F` | **fin** de la fonction suivante / précédente |
| `]c` / `[c` | **classe** suivante / précédente |
| `]a` / `[a` | **argument** suivant / précédent (dans une signature) |

Treesitter comprend la structure du code : ça marche quelle que soit
l'indentation ou le style d'accolades.

> À vérifier selon la version : `:map ]f`, ou `<leader>sk` pour chercher dans les
> keymaps — LazyVim a utilisé `]m` avant `]f`.

Les mêmes objets servent d'**objets de texte**, souvent plus utiles que le
déplacement lui-même :

| Raccourci | Effet |
|---|---|
| `vaf` | sélectionne la méthode entière (signature + corps) |
| `dif` | supprime le **corps** de la méthode, garde la signature |
| `yaf` | copie la méthode complète |
| `gcaf` | commente toute la méthode |

### Vim natif — sans plugin

| Raccourci | Effet |
|---|---|
| `]m` / `[m` | début de la méthode suivante / précédente |
| `]M` / `[M` | fin de la méthode suivante / précédente |
| `]]` / `[[` | section suivante / précédente (`{` en **colonne 1**) |

Bon à connaître en secours, mais c'est de la reconnaissance d'accolades : `[[`
est peu fiable en PHP, où les `{` de méthodes sont indentés.

### Par le nom — souvent le plus rapide

`<leader>ss` liste les **symboles du fichier** : trois lettres du nom de la
méthode et on y est, sans parcourir. `<leader>sS` étend à tout le projet.

Sur un gros fichier : `zM` (replie tout) pour voir la liste des méthodes, puis
`zA` sur celle qui intéresse.

> Tous ces sauts alimentent la jumplist → `<C-o>` ramène en arrière.

## Plier / déplier le code

Les plis sont basés sur Treesitter dans LazyVim, et `foldlevel` vaut 99 au
démarrage : tout est déplié tant qu'on ne ferme rien.

### Un pli

| Raccourci | Effet |
|---|---|
| `za` | bascule le pli sous le curseur (**a**lterne) — le réflexe principal |
| `zc` | ferme (**c**lose) |
| `zo` | ouvre (**o**pen) |
| `zA` `zC` `zO` | idem mais **récursif** (plis imbriqués compris) |
| `zv` | ouvre juste ce qu'il faut pour voir le curseur |

### Tout le fichier

| Raccourci | Effet |
|---|---|
| `zR` | tout déplier (**R**educe le pliage) |
| `zM` | tout replier (**M**ore de pliage) |
| `zr` / `zm` | déplier / replier d'**un seul niveau** |

> `zr` / `zm` est le couple sous-estimé : sur une classe, `zM` puis deux `zr`
> donnent la liste des méthodes avec leur signature, sans le corps.

### Naviguer entre plis

| Raccourci | Effet |
|---|---|
| `zj` / `zk` | pli suivant / précédent (`j`/`k` comme les déplacements) |
| `[z` / `]z` | début / fin du pli courant |

### Bon à savoir

- `zi` désactive/réactive le pliage d'un coup (`foldenable`).
- `:set foldlevel=1` ferme tout au-delà du niveau 1 — équivalent contrôlé de
  `zm` répété.
- Les plis ne sont pas persistants : rouvrir le fichier les remet à zéro.
- ⚠ `zz`, `zt`, `zb` (section 1) sont dans la même famille `z…` mais concernent
  le **scroll**, pas le pliage.

## Explorateur de fichiers (`<leader>e`)

> Ici c'est **snacks.explorer** (et non neo-tree) : les touches sont `h` / `l`.

### Se repérer dans l'arborescence

| Touche | Effet |
|---|---|
| `h` | **replie le répertoire courant** — depuis un fichier, replie son dossier parent et remonte le curseur dessus |
| `l` | ouvre le fichier / déplie le dossier |
| `<CR>` | idem `l` |
| `<BS>` | remonte d'un niveau |

`h` est le geste clé : perdu au milieu d'un très gros dossier, un `h` replie tout
le dossier et remet le curseur sur sa ligne, avec le contexte visible autour.
Enchaîner les `h` remonte l'arborescence niveau par niveau — c'est le pendant du
`zm` des plis de code.

### Agir sur les fichiers

| Touche | Effet |
|---|---|
| `a` | créer (**a**dd) — un nom finissant par `/` crée un dossier |
| `d` | supprimer (**d**elete) |
| `r` | renommer (**r**ename) |
| `c` / `m` | copier / déplacer |
| `y` | copier le **chemin** dans le presse-papier |
| `H` | affiche/masque les fichiers **cachés** |
| `?` | liste tous les mappings — la référence à jour |
| `<leader>e` | ferme l'explorateur (bascule) |

> En neo-tree, l'équivalent de `h` est `C` (close node) et `z` replie tout.
> Dans les deux cas, `?` donne la liste réelle des touches.

## Buffers & fenêtres

### Naviguer entre buffers (fichiers ouverts / bufferline)

| Raccourci | Effet |
|---|---|
| `<S-h>` | buffer précédent (**gauche**) — Shift + `h` |
| `<S-l>` | buffer suivant (**droite**) — Shift + `l` |
| `[b` / `]b` | précédent / suivant (alternative) |
| `` <leader>` `` | revenir au **dernier** buffer utilisé (bascule) |
| `<leader>bd` | fermer le buffer courant (**d**elete) |
| `<leader>bo` | fermer tous les **autres** buffers |
| `<leader>bp` | épingler le buffer (**p**in) |

### Naviguer entre fenêtres (splits)

| Raccourci | Effet |
|---|---|
| `<C-h>` / `<C-l>` | fenêtre à gauche / à droite |
| `<C-j>` / `<C-k>` | fenêtre en bas / en haut |

> **Buffer** = un fichier ouvert ; **fenêtre** = une zone d'affichage.
> Buffer = `<S-…>` (Shift), fenêtre = `<C-…>` (Ctrl).

## Incrémenter / décrémenter un nombre

| Raccourci | Effet |
|---|---|
| `<C-a>` | incrémente (+1) |
| `<C-x>` | décrémente (−1) |
| `10<C-a>` | ajoute 10 (avec un compte) |
| `g<C-a>` | en mode visuel : numérotation progressive (1, 2, 3…) |

- Pas besoin d'être pile sur le chiffre : Vim saute au prochain nombre de la ligne.
- Attention aux `007` (interprétation octale possible) et à `<C-a>` capté par tmux/zsh.

## Copier / coller (yank & put)

| Raccourci | Effet |
|---|---|
| `yt]` | yank jusqu'à (sans inclure) `]` — `t` = *till* |
| `yi(` | yank l'**intérieur** des parenthèses → `--ma-var` |
| `ya(` | yank **avec** les parenthèses → `(--ma-var)` |
| `ya'` | yank une chaîne entre quotes, quotes comprises |
| `P` | coller **avant** le curseur (`p` = après) |

Exemple : transformer `['8.2', '8.3']` → `['8.2', '8.3', '8.4']`
curseur sur la virgule après `'8.3'` : `yt]` puis `$P`, puis `F4` + `<C-a>`.

## Commenter / décommenter

`gc` est un **opérateur** : même grammaire que `d`, `y`, `=`.

| Raccourci | Effet |
|---|---|
| `gcc` | commente/décommente la **ligne courante** |
| `gc3j` | ligne courante + les **3 suivantes** → 4 lignes |
| `4gcc` | 4 lignes à partir du curseur (compte devant l'opérateur) |
| `gcG` | du curseur jusqu'à la **fin du fichier** |
| `gc42G` | du curseur jusqu'à la **ligne 42** |
| `gcap` | tout le **paragraphe** (bloc entre lignes vides) |
| `gci{` | tout l'**intérieur** des accolades |
| `gc` (visuel) | la sélection — après `V5j` par exemple |

> ⚠ Décalage : `gc3j` fait **4** lignes (la courante + 3), alors que `4gcc` en
> fait 4 tout court. Pour « la ligne et les 5 suivantes » : `gc5j` **ou** `6gcc`.

Ajouter un commentaire (Neovim 0.10+, sans plugin) :

| Raccourci | Effet |
|---|---|
| `gco` | ouvre une ligne de commentaire **en dessous**, en insertion |
| `gcO` | idem **au-dessus** |
| `gcA` | commentaire en **fin** de ligne courante |

> Le type de commentaire (`//`, `#`, `<!-- -->`) est déduit du langage via
> Treesitter — y compris dans un fichier mixte (`.vue`, `.php` avec du HTML).

## Surround (mini.surround)

> ⚠ **Prérequis** : mini.surround est un *extra* LazyVim, pas un plugin de base.
> `:LazyExtras` → `/mini-surround` → `x` sur `coding.mini-surround` → redémarrer.
> Sans ça, `gsa` ne fait rien.

Entourer / modifier / retirer ce qui encadre un texte. Préfixe `gs` dans LazyVim.

| Raccourci | Effet |
|---|---|
| `gsa` | **a**joute un entourage (opérateur ou en visuel) |
| `gsd` | **d**élète l'entourage, garde l'intérieur |
| `gsr` | **r**emplace un entourage par un autre |
| `gsf` / `gsF` | va sur l'entourage à droite / à gauche (**f**ind) |
| `gsh` | surligne l'entourage (**h**ighlight) — pour vérifier avant d'agir |

Le caractère demandé ensuite désigne le type : `'` `"` `(` `[` `{` `t` (balise
HTML) et surtout **`f` = appel de fonction** (le nom est demandé).

### Envelopper une chaîne dans un `sprintf()`

Curseur dans la chaîne :

```
va'         → sélectionne la chaîne, quotes comprises
gsa         → add surround
f           → type « function call »
sprintf<CR> → le nom demandé
```

`'TW-4277 : %s : PaymentIntent créé'` → `sprintf('TW-4277 : %s : PaymentIntent créé')`

En une séquence : `va'gsafsprintf<CR>`. Sans le visuel, `gsa` étant un
opérateur : `gsaa'fsprintf<CR>`.

Pour l'argument du `%s` : `f)` puis `i, $paymentIntent->id<Esc>`.

### Cas courants

| Raccourci | Effet |
|---|---|
| `gsaf` | ajoute un appel de fonction (demande le nom) |
| `gsdf` | supprime l'appel de fonction, garde l'intérieur |
| `gsrf` | renomme la fonction (`sprintf` → `printf`), le reste intact |
| `gsr'"` | quotes simples → quotes doubles |
| `gsd'` | enlève les quotes |
| `gsa` + `(` | entoure de parenthèses |

> Repli sans plugin : `va'c` puis taper `sprintf(<C-r>")` — `<C-r>"` recolle ce
> qui vient d'être supprimé.

## Recherche

### Dans le fichier courant

| Raccourci | Effet |
|---|---|
| `/motif` / `?motif` | recherche vers le bas / vers le haut |
| `/<C-r>0` | colle le dernier yank (registre `0`) dans la barre de recherche |
| `*` | cherche le mot sous le curseur et saute à l'occurrence **suivante** |
| `#` | idem vers le **haut** |
| `n` / `N` | occurrence suivante / précédente |
| `g*` / `g#` | idem sans frontières de mot (trouve `maVarLongue` en cherchant `maVar`) |
| `<Esc>` | éteint le surlignage des résultats |

Le geste le plus rapide pour parcourir un mot : `*` puis `n`, `n`, `n`…

> Dans LazyVim, `n` va toujours vers le bas et `N` vers le haut, quel que soit le
> sens de la recherche initiale — et l'écran se recentre au passage.
>
> ⚠ `*` s'arrête aux frontières de mot selon `iskeyword` : sur `--ma-var` en CSS
> il n'attrape pas forcément le token entier. Replis : `g*`, ou `viW` + `y` puis
> `/<C-r>0`.

### Parcourir en modifiant : `cgn` + `.`

Pour *modifier* chaque occurrence plutôt que juste les visiter :

1. `*` sur le mot (puis `N` pour revenir sur la première si besoin)
2. `cgn` → remplace l'occurrence, taper le nouveau texte, `<Esc>`
3. `.` → applique le même remplacement à l'occurrence suivante
4. `n` pour **sauter** une occurrence sans la modifier, puis `.` pour reprendre

Remplacement « à la main mais rapide » : contrôle occurrence par occurrence sans
passer par `:%s/…/…/gc`. `gn` sélectionne le prochain match, donc `dgn`
(supprimer) et `ygn` (copier) marchent aussi.

### Dans tout le projet

| Raccourci | Effet |
|---|---|
| `<leader>/` | grep à la racine du projet (live grep) |
| `<leader>sg` | idem — « **s**earch **g**rep » |
| `<leader>sw` | grep le mot sous le curseur / la sélection |
| `<leader>ss` | symboles du document courant |

> Astuce variable CSS : chercher `--ma-var:` (avec les `:`) pour tomber sur la
> **déclaration** et non les usages `var(--ma-var)`.

## Rechercher / remplacer (substitute)

| Commande | Effet |
|---|---|
| `:s/old/new/g` | toutes les occurrences de la **ligne courante** |
| `:s/old/new/gc` | idem, avec **c**onfirmation (`y`/`n`) à chaque remplacement |
| `:%s/old/new/g` | tout le **fichier** (`%` = toutes les lignes) |
| `:'<,'>s/old/new/g` | seulement la **sélection visuelle** (la plage s'insère seule) |

- Sans le flag `g`, seule la **première** occurrence de la ligne est remplacée.
- Le tiret `-` n'est pas spécial dans les regex Vim : on l'écrit tel quel
  (`:s/mon-mot/nouveau-mot/g`).
- Éviter de retaper le mot : `viW` (mot délimité par les espaces, tiret inclus)
  puis `y`, et coller dans la commande avec `<C-r>0` → `:s/<C-r>0/nouveau/g`.

## LSP

| Raccourci | Effet |
|---|---|
| `gd` | aller à la **définition** (**g**oto **d**efinition) |
| `gD` | aller à la **déclaration** |
| `gy` | aller à la définition du **type** |
| `grr` | **r**éférences (tous les usages) |
| `gra` | code **a**ction (quick fix, import manquant…) |
| `grn` | **r**e**n**ommer le symbole dans tout le projet |
| `gri` | aller à l'**i**mplémentation |
| `K` | aperçu (hover) — docblock + signature, sans quitter le fichier |
| `<C-o>` | **revenir** d'où on venait (après un saut) |
| `<C-i>` | ré-avancer (inverse de `<C-o>`) |

> `<C-o>` est le compagnon de `gd` : on saute voir une classe (même dans
> `vendor/`), puis `<C-o>` ramène pile où on était.
>
> Marche bien en PHP (phpactor suit les `use`) : curseur sur `Story` dans
> `extends Story` → `gd` ouvre la classe. En CSS en revanche le LSP ne résout
> pas toujours les custom properties : si `gd` ne fait rien, repli sur le grep
> (`<leader>sw`).

## Git dans le fichier (gitsigns)

### Se déplacer de bloc modifié en bloc modifié

| Raccourci | Effet |
|---|---|
| `]h` / `[h` | bloc (**h**unk) modifié suivant / précédent |
| `]H` / `[H` | **dernier** / **premier** hunk du fichier |

En arrivant dans un fichier, `]h` en boucle fait la visite guidée des modifs non
commitées.

### L'objet de texte `ih`

`ih` = *inner hunk*, utilisable avec n'importe quel opérateur :

| Raccourci | Effet |
|---|---|
| `vih` | sélectionne le hunk courant |
| `dih` | supprime le hunk |
| `yih` | copie le hunk |
| `gcih` | commente tout le hunk |

### Agir sur le hunk (`<leader>gh…`)

| Raccourci | Effet |
|---|---|
| `<leader>ghp` | aperçu du diff **en ligne** (**p**review) |
| `<leader>ghs` / `<leader>ghr` | **s**tage / **r**eset le hunk |
| `<leader>ghS` / `<leader>ghR` | stage / reset tout le **buffer** |
| `<leader>ghu` | annule le dernier stage (**u**ndo) |
| `<leader>ghb` / `<leader>ghB` | blame de la ligne / du buffer |
| `<leader>ghd` | diff du fichier |

> Le combo naturel : `]h` pour arriver sur le bloc, `<leader>ghp` pour voir ce
> qui a changé, puis `<leader>ghs` (stager) ou `<leader>ghr` (annuler) — une
> revue de ses propres modifs sans quitter le fichier, en complément de lazygit.

## lazygit (`<leader>gg`)

| Touche | Contexte | Effet |
|---|---|---|
| `d` | panneau Files, sur un fichier | discard (annuler les changements) ⚠ irréversible |
| `s` | panneau Files | stash (mise de côté récupérable) |
| `<Entrée>` | sur un fichier | entrer dans le diff (discard par hunk/ligne avec `d`) |
| `f` | onglet Remotes, sur un remote | fetch ce remote |
| `F` | global | fetch all |
| `g` | sur un commit / une branche | menu reset (soft / mixed / **hard**) |
| `P` | — | push (propose le force push si divergence) |
| `<Espace>` | onglet Local branches | checkout la branche |
| `q` | — | quitter lazygit |

### Réaligner une branche sur upstream (après MR squash-mergée)

1. Fetch upstream : onglet Remotes → `upstream` → `f`
2. Checkout de sa branche : onglet Local branches → `<Espace>`
3. Sélectionner `upstream/main` → `g` → **hard reset**
4. `P` → accepter le **force push**

Équivalent CLI :
```bash
git fetch upstream
git checkout ma-branche
git reset --hard upstream/main
git push --force origin ma-branche
```

---

*Rappel : `<leader>` est en général la barre d'espace dans LazyVim.*
