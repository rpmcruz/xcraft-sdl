/* 2026-11-22 xcraft-sdl: class getline renamed getline_field; the old name
   clashes with POSIX getline () from stdio.h. */

#ifndef getline_h
#define getline_h

#include "win.h"
#include "history.h"
#include "buttons.h"
#include "bool.h"

class getline_field
  {public:

   win     *w;
   int     x;
   int     y;
   int     dx;
   int     dy;
   char    name [128];   

   bool    with_history;
   history *hist;
   button  *hist_button;

   int    c_light;
   int    c_dark;
   int    c_background;
   int    c_foreground;
   int    c_cursor;

   int     pos_0;
   int     pos;
   char    *line;
   int     lx;
   int     ly;   
   int     key;
   int     key_cnt;
   bool    is_active;
   bool    was_deactive;
   bool    is_single_char;
   
   getline_field      (char name [],
                 win  *w,
                 char string [],
                 int  x,
                 int  y,
                 int  dx,
                 int  dy,
                 bool with_history     = false,
                 bool show_histroy_top = false,
                 bool single_char      = false);

   ~getline_field     ();

   bool on               ();
   void check_activation ();
   void refresh          ();
   void active           (bool mode);
   bool eval             ();
   bool get              ();

  }; 

#endif

