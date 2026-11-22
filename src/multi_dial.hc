/* 2026-11-22 xcraft-sdl: title widths use font_text_width of the SDL window
   layer instead of XLoadQueryFont/XTextWidth (no Xlib).
   Functions multi_dial::press returned no value on some paths (undefined behaviour,
   modern compilers trap there); they now return one.
   Load reads the bool values through an int. */

/*======================================================================*/
/*= CHANGES AND UPDATES                                                =*/
/*======================================================================*/
/*= date   person file          subject                                =*/
/*=--------------------------------------------------------------------=*/
/*=                                                                    =*/
/*= 060794 hua    multi_dial.hc created                                =*/
/*=                                                                    =*/
/*======================================================================*/

#include "multi_dial.h"
#include "masks.h"

#define font "-misc-*-*-*-*-*-*-*-*-*-*-*-*-*"

#define line_dy  20

multi_dial::multi_dial (char name    [], 
                        char buttons [],
                        bool used_history)

  {init;
   pharse_params;
   open_w;
   init_values;
   perhaps_load;
   open_dials;
   
.  init
     {is_history = used_history;
      strcpy (title, name);
     }.

.  init_values
     {for (int i = 0; i < num_buttons; i++)
        values [i] = true;
     }.

.  perhaps_load
     {if (is_history)
         load (name);
     }.

.  open_w
     {w = new win (title, "", by_fix, by_fix,
                   max_b_title_dx + 44,
                   num_buttons * line_dy + 24);
      background  (w);
     }.

.  open_dials
     {for (int i = 0; i < num_buttons; i++)
        d_buttons [i] = new dial (w,
                                  b_title [i],
                                  max_b_title_dx + 12,
                                  12, i * line_dy + 14,
                                  values [i]); 
     }.

.  pharse_params
     {int         p = 0;

      num_buttons    = 0;
      max_b_title_dx = 0;
      while (get_cmd (buttons, p, act_title))
        {grab_button;
        };
     }.

.  grab_button
     {max_b_title_dx = i_max (max_b_title_dx, title_length);
      num_buttons++;
     }.

.  title_length
     font_text_width (font, act_title).

.  act_title
     b_title [num_buttons].

  }

multi_dial::~multi_dial ()
  {if (is_history)
      save (title);
   for (int i = 0; i < num_buttons; i++)
     delete (d_buttons [i]);
   delete (w);
  }

void multi_dial::save (char name [])
  {FILE *f;

   open_f;
   write_values;
   fclose (f);

.  open_f
     {f = fopen (complete (name, ".mulopt"), "w");
     }.

.  write_values
     {for (int i = 0; i < num_buttons; i++)
        fprintf (f, "%d\n", values [i]);
     }.

  }

void multi_dial::load (char name [])
  {FILE *f;
   bool exists;

   if (open_f)
      perform_load;

.  perform_load
    {read_values;
     fclose (f);
    }. 

.  open_f
     (f = fopen (complete (name, ".mulopt"), "r")) != NULL.

.  read_values
     {for (int i = 0; i < num_buttons; i++)
        {int v = 0;                 /* xcraft-sdl: %d needs int, not bool */

         fscanf (f, "%d", &v);
         values [i] = v;
        };
     }.

  }

bool multi_dial::eval ()
  {bool anything = false;

   w->mark_mouse ();
   for (int i = 0; i < num_buttons; i++)
     anything |= d_buttons [i]->eval (values [i]);
   w->scratch_mouse ();
   return anything;
  }

bool multi_dial::pressed (int bno)
  {return values [bno];
  }

bool multi_dial::press (int bno, bool mode)
  {values [bno] = mode;
   eval ();
   return true;   /* xcraft-sdl */
  }

bool multi_dial::get_cmd (char cmds [], int &p, char cmd [])
  {if   (eof)
        return false;
   else read_cmd;
   return true;

.  read_cmd
     {int  c         = 0;
      bool skip_mode = false;

      skip_icon_symbol;
      while (cmd_char != ':' && ! eof)
        {handle_skip_mode;
         store_char;
         p++;
        };
      cmd [c] = 0;
      p++;
     }.

.  handle_skip_mode
     {if (cmd_char == ';')
         switch_skip_mode;
     }.

.  store_char
     {if (! skip_mode)
         cmd [c++] = cmd_char;
     }.
       
.  switch_skip_mode
     {skip_mode = ! skip_mode;
      p++;
     }.

.  skip_icon_symbol
     if (cmd_char == '$' || cmd_char == '&')
        p++.

.  eof 
     (p >= strlen (cmds)).

.  cmd_char 
     cmds [p].

  }
