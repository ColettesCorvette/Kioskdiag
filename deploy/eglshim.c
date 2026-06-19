/* eglshim.c — contournement de la sélection de plateforme EGL du blob Mali.
 *
 * Le blob Mali g24p0 COMBINÉ (libmali-bifrost-g52-g24p0-x11-wayland-gbm.so) fait
 * du X11 PAR DÉFAUT dans eglGetDisplay() (l'API legacy est ambiguë : elle ne
 * dit pas la plateforme). Sans serveur X, il traite le wl_display comme un
 * Display X11 et crashe dans libX11 (_XFlush). EGL_PLATFORM=wayland ne suffit
 * pas pour l'API legacy.
 *
 * On intercepte eglGetDisplay et on appelle à la place
 * eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT=0x31D8, wl_display, NULL),
 * que le blob gère correctement -> plateforme Wayland forcée.
 *
 * Compile :  gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl
 * Usage   :  LD_PRELOAD=/chemin/eglshim.so  ./kioskdiag ...
 */
#include <dlfcn.h>

void *eglGetDisplay(void *native_display) {
    void *(*getproc)(const char *) = dlsym(RTLD_NEXT, "eglGetProcAddress");
    if (getproc) {
        void *(*getplat)(unsigned int, void *, const int *) =
            (void *)getproc("eglGetPlatformDisplayEXT");
        if (getplat)
            return getplat(0x31D8u /* EGL_PLATFORM_WAYLAND_EXT */, native_display, 0);
    }
    void *(*real)(void *) = dlsym(RTLD_NEXT, "eglGetDisplay");
    return real(native_display);
}
