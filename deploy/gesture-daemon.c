// deploy/gesture-daemon.c
// Démon : détecte la séquence des 4 coins sur le touchscreen evdev et lance
// kioskdiag. Logique pure isolée pour être testable (-DSELFTEST), I/O en dessous.
#include <stdio.h>
#include <stdlib.h>

enum corner { C_NONE = 0, C_TL, C_TR, C_BR, C_BL };

// Zone-coin : < 15% ou > 85% des bornes ABS sur CHAQUE axe. Centre -> C_NONE.
int corner_of(int x, int y, int xmin, int xmax, int ymin, int ymax) {
  int xr = xmax - xmin, yr = ymax - ymin;
  if (xr <= 0 || yr <= 0) return C_NONE;
  int left   = (x - xmin) * 100 < xr * 15;
  int right  = (x - xmin) * 100 > xr * 85;
  int top    = (y - ymin) * 100 < yr * 15;
  int bottom = (y - ymin) * 100 > yr * 85;
  if (top && left)    return C_TL;
  if (top && right)   return C_TR;
  if (bottom && right)return C_BR;
  if (bottom && left) return C_BL;
  return C_NONE;
}

struct seq { int idx; long last_ms; };

// Séquence attendue (repère brut ; labels calibrés au test physique).
static const int EXPECTED[4] = { C_TL, C_TR, C_BR, C_BL };
#define SEQ_WINDOW_MS 5000

int seq_feed(struct seq *s, int corner, long now_ms) {
  if (corner == C_NONE) return 0;
  if (s->idx > 0 && now_ms - s->last_ms > SEQ_WINDOW_MS) s->idx = 0;
  if (corner == EXPECTED[s->idx]) {
    s->idx++;
    s->last_ms = now_ms;
    if (s->idx == 4) { s->idx = 0; return 1; }
  } else {
    s->idx = (corner == EXPECTED[0]) ? 1 : 0;
    s->last_ms = now_ms;
  }
  return 0;
}

#ifdef SELFTEST
int main(void) {
  // corner_of : bornes 0..1000 sur les 2 axes.
  if (corner_of(50, 50, 0, 1000, 0, 1000)   != C_TL) { puts("FAIL TL"); return 1; }
  if (corner_of(950, 50, 0, 1000, 0, 1000)  != C_TR) { puts("FAIL TR"); return 1; }
  if (corner_of(950, 950, 0, 1000, 0, 1000) != C_BR) { puts("FAIL BR"); return 1; }
  if (corner_of(50, 950, 0, 1000, 0, 1000)  != C_BL) { puts("FAIL BL"); return 1; }
  if (corner_of(500, 500, 0, 1000, 0, 1000) != C_NONE){ puts("FAIL center"); return 1; }

  struct seq s = {0, 0};
  // Séquence complète dans la fenêtre -> déclenche au 4e.
  if (seq_feed(&s, C_TL, 0)) { puts("FAIL early1"); return 1; }
  if (seq_feed(&s, C_TR, 100)) { puts("FAIL early2"); return 1; }
  if (seq_feed(&s, C_BR, 200)) { puts("FAIL early3"); return 1; }
  if (!seq_feed(&s, C_BL, 300)) { puts("FAIL trigger"); return 1; }

  // Timeout au milieu -> reset, pas de déclenchement.
  struct seq t = {0, 0};
  seq_feed(&t, C_TL, 0);
  seq_feed(&t, C_TR, 100);
  if (seq_feed(&t, C_BR, 6000)) { puts("FAIL timeout"); return 1; }

  // Mauvais coin -> reset (mais un C_TL relance idx=1).
  struct seq u = {0, 0};
  seq_feed(&u, C_TL, 0);
  seq_feed(&u, C_BL, 100);   // hors séquence -> reset à 0
  seq_feed(&u, C_TL, 200);   // relance
  seq_feed(&u, C_TR, 300);
  seq_feed(&u, C_BR, 400);
  if (!seq_feed(&u, C_BL, 500)) { puts("FAIL recover"); return 1; }

  puts("OK");
  return 0;
}
#endif
