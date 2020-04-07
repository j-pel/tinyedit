///////////////////////////////////////////////////////////////////////////////
// LowLevel.h
//
//	Description:
//		Header file for the low level optimized drawing functions. These
//		functions are implemented in assembly and contained in the 
//		LowLevel.lib library file.
//
//
//	Usage:
//		In order to use the low level routines do the following:
//
//			1 - Include this header file
//
//			2 - Add LowLevel.lib as a dependency to the project
//
//
//	Author: Chris Hobbs
//
//	Date: 10-10-02
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// PUBLIC PROTOTYPES
///////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////////
	// DrawLine32()
	//		Function to draw a line on the given buffer from (x1, y1) to (x2, y2)
	//		using the color specified. This function is only meant for 32-bit
	//		color depth thefore the color should be a 32-bit color. The pitch 
	//		passed in must be the number of BYTES per scan line.
	//
	///////////////////////////////////////////////////////////////////////////////
extern "C" void DrawLine32(int x1, int y1, int x2, int y2, unsigned 
									int color, void* buffer, int pitch);

///////////////////////////////////////////////////////////////////////////////
// END PUBLIC PROTOTYPES
///////////////////////////////////////////////////////////////////////////////