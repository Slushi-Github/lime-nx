#ifndef NATIVE_TOOLKIT_LZMA_H
#define NATIVE_TOOLKIT_LZMA_H

#include <hx/CFFI.h>

namespace native_toolkit_lzma {

	class Lzma {

		public:

			static void Encode( buffer input_buffer, buffer output_buffer );
			static void Decode( buffer input_buffer, buffer output_buffer );

	}; //Lzma

} //native_toolkit_lzma

#endif //NATIVE_TOOLKIT_LZMA_H
