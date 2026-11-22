/*-------------------------------------------------------------------------*/
/* bool.inc                                                                */
/*                                                                         */
/* 2026-11-22 xcraft-sdl: C++ has bool, true and false built in; the old   */
/*            "#define bool int" only remains for C compilers.             */
/*-------------------------------------------------------------------------*/

#ifndef __cplusplus

#ifndef false
#define false 0
#endif

#ifndef true
#define true  1
#endif

#ifndef bool
#define bool  int
#endif

#endif
