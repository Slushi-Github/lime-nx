#include <stdio.h>


extern "C" int SDL_RunApp(int argc, char *argv[], int (*mainFunction)(int argc, char *argv[]), void *reserved);
extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();


int hxcpp_main (int argc, char *argv[]) {

	hxcpp_set_top_of_stack ();

	const char *err = hxRunLibrary ();

	if (err) {

		printf ("Error %s\n", err);
		return -1;

	}

	return 0;

}


int main(int argc, char *argv[]) {

	return SDL_RunApp (argc, argv, hxcpp_main, NULL);

}
