#include "stdio.h"
#include "sys/types.h"
/* 2026-11-22 xcraft-sdl: sys/timeb.h (ftime) is no longer needed */
#include "sys/time.h"

/*----------------------------------------------------------------------*/
/* CLASS xtimer (deklarations)                                          */
/*----------------------------------------------------------------------*/

#ifndef xtimer_h
#define xtimer_h

class xtimer
  {private :

     long   stamp;
     double dt;

   public :

     void   start ();
     void   cont  ();
     void   stop  ();
     double read  ();
     double exec  ();

  };

long x_sys_time ();
void delay (int dt);

#endif
