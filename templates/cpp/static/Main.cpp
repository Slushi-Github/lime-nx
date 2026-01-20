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
static bool s_socketInitialized = true;

/**
 * Initialize the nxlink socket, for remote printing and debugging
 */
static void initNXLink() {
	if (!s_socketInitialized) {
		printf("[Main.cpp - initNXLink()] Socket not initialized\n");
		return;
	}

	s_nxlinkSocket = nxlinkStdio();
	if (s_nxlinkSocket >= 0)
		printf("[Main.cpp - initNXLink()] Connected to nxlink!\n");
	else {
		printf("[Main.cpp - initNXLink()] Failed to connect to nxlink...\n");
		s_nxlinkSocket = -1;
	}
}

/**
 * Deinitialize the nxlink socket
 * This is called when the program exits, if not we can crash on exit
 */
static void deInitNXLink()
{
	if (s_socketInitialized && s_nxlinkSocket >= 0)
	{
		close(s_nxlinkSocket);
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
	// We need to initialize the socket even if we're not going to use it with nxlink
	// Haxe needs to be able to handle their own sockets, if we don't do this it will crash
	Result result = socketInitializeDefault();
	if (R_FAILED(result))
	{
		printf("[Main.cpp - socketInitializeDefault()] ERROR: Failed to initialize default socket: %08X\n", result);
		s_socketInitialized = false;
	}

	initNXLink();

	Result rc = romfsInit();
	if (R_FAILED(rc))
		printf("[Main.cpp - romfsInit()] ERROR: romfsInit: %08X\n", rc);
	else
	{
		printf("[Main.cpp - romfsInit()] RomFS Init Successful!\n");
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
		printf("[Main.cpp - hxRunLibrary()] ERROR: %s\n", err);
#if defined(__SWITCH__)
		deInitNXLink();
		romfsExit();
		socketExit();
#endif
		return -1;
	}

#if defined(__SWITCH__)
	deInitNXLink();
	romfsExit();
	socketExit();
#endif

	return 0;
}
