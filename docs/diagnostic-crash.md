# Crash kernel à l'arrêt de flutter-pi (stop / restart / reboot)

## Symptôme

Sur la carte RK3568, arrêter, redémarrer ou rebooter le service
`kioskdiag-kiosk` fait planter le kernel.

## Cause racine (confirmée par pstore/ramoops)

```
Unable to handle kernel paging request at virtual address 006572662e6772e7
Internal error: Oops: 96000004 [#1] SMP
CPU: 2 PID: 609 Comm: io.flutter.rast
pc : drm_gem_object_release_handle+0x7c/0x88
lr : idr_for_each+0x64/0xec
x0 : 656572662e67726f      ; = ASCII "org.free…"  (slot GEM libéré puis réutilisé)

Call trace:
 drm_gem_object_release_handle
 idr_for_each
 drm_gem_release
 drm_file_free.part.0
 drm_close_helper.isra.0
 drm_release              ; fermeture du fd DRM card0
 __fput → ____fput → task_work_run
 do_exit → do_group_exit → get_signal   ; le process est tué par un signal
```

1. flutter-pi n'installe **aucun handler de signal** (ni `sigaction`, ni
   `signalfd`, ni `sd_event_add_signal`). Au `systemctl stop/restart` et au
   reboot, systemd envoie SIGTERM ; le process meurt net (`get_signal →
   do_group_exit`), **sans teardown GBM**.
2. À la mort du process, le kernel ferme le fd `card0` (`drm_release`) et itère
   la table des handles GEM du fichier (`object_idr`) pour les libérer.
3. Un handle y pointe vers un `drm_gem_object` **déjà libéré** (son slot
   contient maintenant du texte « org.free… ») → use-after-free →
   `drm_gem_object_release_handle` déréférence une valeur invalide → oops.

Ce n'est pas un NULL mais un pointeur pendouillant : refcount/lifetime incorrect
des handles GEM importés (PRIME) côté driver, exposé par l'arrêt brutal. SIGTERM,
SIGKILL ou reboot mènent tous au même `drm_release` : agir sur `KillSignal` ou
`KillMode` ne change rien.

## Comment c'est résolu aujourd'hui

Le bug ne se déclenche que si l'appli possède `card0` et le ferme à sa mort.
flutter-pi faisait exactement ça. On a donc abandonné flutter-pi : kioskdiag est
maintenant un client de weston, qui détient `card0` en permanence. L'appli ne
touche plus au DRM, donc le chemin `drm_release` à sa fermeture n'est jamais
emprunté et l'oops ne se produit plus.

C'est la bascule décrite dans
[troubleshooting-affichage-mali-weston.md](troubleshooting-affichage-mali-weston.md).
Une ancienne piste (capter SIGTERM dans l'appli pour fermer GBM proprement avant
flutter-pi) a été tentée puis retirée, sans objet maintenant qu'il n'y a plus de
fd DRM côté appli.

## Piste de fond (kernel)

Le vrai bug reste le cycle de vie des handles GEM importés dans le driver
rockchip/mali out-of-tree (référence manquante sur l'objet importé, ou
double-free). Le contournement weston suffit ; corriger le driver ne serait utile
que pour une robustesse indépendante du compositeur.
