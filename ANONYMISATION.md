# Note d'anonymisation

Ce dépôt est la publication d'un travail réalisé pendant un stage de fin de
deuxième année de BUT Informatique (avril – juillet 2026). Le code et la
documentation sont authentiques, **mais tous les noms propres ont été
remplacés** avant publication, y compris dans l'historique git.

Si vous croyez reconnaître une entreprise, un produit ou un client dans ce qui
suit : ce n'est pas le cas.

## Ce qui a été remplacé

| Dans ce dépôt | Nature |
|---|---|
| `Orbinea` | l'entreprise d'accueil |
| `Fluxia` | sa branche « équipements » (tourniquets, bornes) |
| `kioskdiag` | cette application de diagnostic |
| `kioskview` | l'application d'affichage public qui tourne sur la même borne |
| `gatectl` | le logiciel embarqué des tourniquets, dont on lit le `/metrics` |
| `beacon` | la supervision qui relaie ces métriques |
| les plages `10.30-50.x`, `192.168.10/20/30/40.x` | adressage privé |

Sont authentiques et conservés : Flutter, Dart, weston, Wayland, flutter-elinux,
Puppet, ainsi que les références matérielles (carte RK3568, GPU Mali Bifrost
G52) et le diagnostic du bug noyau DRM — c'est le cœur technique du projet.

## Visuels

Les deux images de marque de l'entreprise (`assets/logo.png` et le wordmark)
ont été remplacées par des visuels neutres, dans l'arbre **et** dans
l'historique — y compris les copies encodées en base64 à l'intérieur de
`assets/logo.svg` et `assets/footer_version.svg`. L'illustration du tourniquet
(`assets/illus_test_poussoir.svg`) est un schéma générique, sans marque : elle
est d'origine.

## Binaire absent

`deploy/blobs/` contenait le pilote graphique propriétaire Mali
(`libmali-bifrost-g52-*.so.xz`, 15 Mo), fourni par le fabricant de la carte.
**Il n'est pas redistribué ici** — ce n'est pas notre licence. Son `README.md`
est conservé et explique à quoi il sert et où le récupérer. Sans lui, le
déploiement sur borne décrit dans `deploy/PROVISIONING.md` ne peut pas être
rejoué tel quel.

## État du code

Le dernier commit reconstitue l'état de fin de stage (20/07/2026), qui n'avait
jamais été commité à l'époque : l'onglet de configuration réseau et ses tests.
Le reste de l'historique est celui d'origine, réécrit pour l'anonymisation.

## Droits

Code écrit dans le cadre d'un stage salarié, publié à titre de portfolio, sans
licence d'utilisation : aucun droit de réutilisation n'est concédé.
