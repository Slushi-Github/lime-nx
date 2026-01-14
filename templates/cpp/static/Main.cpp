#include <stdio.h>

#if defined(__SWITCH__)
#include "switch.h"
#include <unistd.h>
#endif

#if defined(HX_WINDOWS) && !defined(HXCPP_DEBUGGER)
#include <windows.h>
#endif

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();

extern "C" int zlib_register_prims ();
extern "C" int lime_cairo_register_prims ();
extern "C" int lime_openal_register_prims ();
::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();
::end:: ::end::

#if defined(__SWITCH__)
static int s_nxlinkSocket = -1;

static void initNXLink()
{
	if (R_FAILED(socketInitializeDefault()))
		return;

	s_nxlinkSocket = nxlinkStdio();
	if (s_nxlinkSocket >= 0)
		printf("Connected to nxlink!\n");
	else
		socketExit();
}

static void deInitNXLink()
{
	if (s_nxlinkSocket >= 0)
	{
		close(s_nxlinkSocket);
		socketExit();
		s_nxlinkSocket = -1;
	}
}
#endif

#if defined(HX_WINDOWS) && !defined(HXCPP_DEBUGGER)
int __stdcall WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
#else
extern "C" int main(int argc, char *argv[]) {
#endif
#if defined(__SWITCH__)
	initNXLink();
	Result rc = romfsInit();
	if (R_FAILED(rc))
		printf("[Main.cpp] ERROR: romfsInit: %08X\n", rc);
	else
	{
		printf("RomFS Init Successful!\n");
	}
#endif

	hxcpp_set_top_of_stack ();
	
	zlib_register_prims ();
	lime_cairo_register_prims ();
	lime_openal_register_prims ();
	::foreach ndlls::::if (registerStatics)::
	::nameSafe::_register_prims ();::end::::end::
	
	const char *err = NULL;
 	err = hxRunLibrary ();
	
	if (err) {
		printf("Error: %s\n", err);
#if defined(__SWITCH__)
		deInitNXLink();
		romfsExit();
#endif
		return -1;
	}

#if defined(__SWITCH__)
	deInitNXLink();
	romfsExit();
#endif

	return 0;
}
