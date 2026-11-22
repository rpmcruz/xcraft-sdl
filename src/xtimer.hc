 
/* 2026-11-22 xcraft-sdl: x_sys_time uses gettimeofday instead of the
   obsolete ftime; delay () moved to win.cc, where it waits the given number
   of milliseconds while keeping the SDL window alive. The original itimer
   version slept dt * 10 microseconds instead of dt milliseconds, so the
   50 ms game cycle of craft.hc was never enforced on fast machines. */

#include "xtimer.h"

#include "unistd.h"
#include "sys/time.h"

/*----------------------------------------------------------------------*/
/* CLASS xtimer (funktions)                                              */
/*----------------------------------------------------------------------*/

long x_sys_time ()
  {struct timeval tv;

   gettimeofday (&tv, 0);
   return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
  }

void xtimer::start ()
  {stamp = x_sys_time ();
   dt    = 0;
  }

void xtimer::stop ()
  {dt    += (double) (x_sys_time () - stamp);
   stamp =  x_sys_time ();
  }

void xtimer::cont ()
  {stamp = x_sys_time ();
  }

double xtimer::exec ()
  {return (double) (x_sys_time () - stamp) + dt;
  }

double xtimer::read ()
  {return dt;
  }
