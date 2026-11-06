/*
 * tlsinit.c --
 *
 *	Registers tcltls, linked statically into libmain.so, as a static
 *	package, so that [load {} Tls] works in every interpreter. The
 *	constructor runs when the activity loads the library, before Tcl
 *	creates an interpreter (Tcl_StaticLibrary allows a NULL interp then).
 */

#include <tcl.h>

extern Tcl_LibraryInitProc Tls_Init;
extern Tcl_LibraryInitProc Tls_SafeInit;

__attribute__((constructor))
static void
RegisterTls(void)
{
    Tcl_StaticLibrary(NULL, "Tls", Tls_Init, Tls_SafeInit);
}
