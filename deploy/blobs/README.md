# Blob Mali 

Pilote userspace Mali g24p0 strictement nécessaire à l'affichage accéléré de
l'UI sur la borne RK3568. C'est le seul binaire runtime non reconstructible
depuis le dépôt, il est matché au driver kernel Mali DDK g18p0 de la carte.

Le reste de la stack se rebuild : le bundle via `Dockerfile.elinux`, `eglshim.so`
en une ligne `gcc` et weston via le gestionnaire de paquets.

## Fichier

`libmali-bifrost-g52-g24p0-x11-wayland-gbm.so.xz`, variante combinée
x11-wayland-gbm. Ne pas confondre avec `g24p0-gbm` seul, qui cible la mauvaise
plateforme et ne marche pas.

- Compression : `xz -9`.
- sha256 du `.so` décompressé :
  `c6ef2752efa47e3656b28be6a6602aa4b37410d20a730a9c39a06f32e740a056`

## Restaurer sur la carte

```sh
xz -dc libmali-bifrost-g52-g24p0-x11-wayland-gbm.so.xz \
  > /data/mali/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so
sha256sum /data/mali/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so
```

Le script `deploy/run-weston-elinux.sh` attend le `.so` à ce chemin.
