/* Persistent virtual pointer for a headless wlroots compositor (used by
   tools/headless/hl.sh to drive xcraft in tests and recordings).
   Reads commands from a FIFO, one per line:
     move X Y        absolute position in an W x H layout (set with extent)
     extent W H
     press B | release B               (B = 1 left, 2 middle, 3 right)
     quit                                                                   */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>
#include "wlr-virtual-pointer-unstable-v1-client-protocol.h"

static struct wl_seat *seat;
static struct zwlr_virtual_pointer_manager_v1 *mgr;

static void reg_global (void *d, struct wl_registry *r, uint32_t name,
                        const char *iface, uint32_t ver)
{
  (void) d; (void) ver;
  if (strcmp (iface, wl_seat_interface.name) == 0)
    seat = wl_registry_bind (r, name, &wl_seat_interface, 1);
  else if (strcmp (iface, zwlr_virtual_pointer_manager_v1_interface.name) == 0)
    mgr = wl_registry_bind (r, name, &zwlr_virtual_pointer_manager_v1_interface, 1);
}
static void reg_remove (void *d, struct wl_registry *r, uint32_t n) {(void) d; (void) r; (void) n;}
static const struct wl_registry_listener reg_listener = {reg_global, reg_remove};

static uint32_t now_ms (void)
{
  struct timespec ts;
  clock_gettime (CLOCK_MONOTONIC, &ts);
  return ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int main (int argc, char **argv)
{
  struct wl_display *dpy = wl_display_connect (NULL);
  if (!dpy || argc < 2) {fprintf (stderr, "usage: vptr FIFO\n"); return 1;}
  struct wl_registry *reg = wl_display_get_registry (dpy);
  wl_registry_add_listener (reg, &reg_listener, NULL);
  wl_display_roundtrip (dpy);
  if (!mgr) {fprintf (stderr, "no virtual pointer manager\n"); return 1;}
  struct zwlr_virtual_pointer_v1 *p =
    zwlr_virtual_pointer_manager_v1_create_virtual_pointer (mgr, seat);
  wl_display_roundtrip (dpy);

  unsigned ew = 1280, eh = 900;
  for (;;)
    {
      FILE *f = fopen (argv[1], "r");
      char line[128];
      if (!f) return 1;
      while (fgets (line, sizeof line, f))
        {
          unsigned a, b;
          if (sscanf (line, "extent %u %u", &a, &b) == 2) {ew = a; eh = b;}
          else if (sscanf (line, "move %u %u", &a, &b) == 2)
            zwlr_virtual_pointer_v1_motion_absolute (p, now_ms (), a, b, ew, eh);
          else if (sscanf (line, "press %u", &a) == 1)
            zwlr_virtual_pointer_v1_button (p, now_ms (), 0x110 + a - 1 + (a == 2 ? 1 : a == 3 ? -1 : 0), 1);
          else if (sscanf (line, "release %u", &a) == 1)
            zwlr_virtual_pointer_v1_button (p, now_ms (), 0x110 + a - 1 + (a == 2 ? 1 : a == 3 ? -1 : 0), 0);
          else if (strncmp (line, "quit", 4) == 0)
            return 0;
          zwlr_virtual_pointer_v1_frame (p);
          wl_display_roundtrip (dpy);
        }
      fclose (f);
    }
}
