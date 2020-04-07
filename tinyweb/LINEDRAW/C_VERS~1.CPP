///////////////////////////////////////////////////////////////////////////////
// DrawBresenhamLine()
//	
//	Description:
//		Routine to draw a line on the given surface from x1, y1 to x2, y2
//		with the given R, G, and B color components. Uses the Bresenham 
//		algorithm for the line.
//
//	Input:
//		- Buffer to draw on
//		- Pitch of a line (in dwords per line)
//		- X1, Y1 and X2, Y2 Coordinates
//		- Red, Green, and Blue color components
//
//	Output:
//		- N/A
//
//	Speed:
//		- Random Seed of 100
//		- 300,000 Lines
//		- 5.810 Seconds
//		- 51,635 lines per second
//
//		- Drawing a line from (0, 0) - (799, 599)
//		- Is 1K pixels per line
//		- Runs around 17,000 lines per second
//		- Total of 17,000,000 pixels per second
//
///////////////////////////////////////////////////////////////////////////////
void DrawBresenhamLine(void* buffer, int pitch, int x1, int y1, int x2, int y2, 
					   Uint8 R, Uint8 G, Uint8 B)
{
	int x, y;
	int index;
	int dx, dy;
	int incx, incy;
	int iErrorTerm;
	DWORD* pBuffer = (DWORD*)buffer;
	DWORD color;

	// We are always going to draw top to bottom so swap things if needed
	if( y1 > y2 )
	{
		int Temp = y1;
		y1 = y2;
		y2 = Temp;
		Temp = x1;
		x1 = x2;
		x2 = x1;
	}

	// Is our X Axis moving in a positive direction?
	if( x2 >= x1 )
	{
		// Yes, we are going positive so calculate
		// the distance and set the X increment to be
		// a positive 1
		dx = x2 - x1;
		incx = 1;
	}
	else
	{
		// No, we are going negative so calculate
		// the distance and set the X increment to be
		// a negative 1
		dx = x1 - x2;
		incx = -1;
	}

	// Since the Y is always positive we can just
	// calc the distance and set the Y increment to be
	// a positive 1
	dy = y2 - y1;
	incy = 1;

	// Set the current X and Y coordinate to the start
	// of the line specified
	x = x1;
	y = y1;

	// Set our starting point for the buffer
	pBuffer = (DWORD*)buffer + (y * pitch) + x;

	// Compute the color we will use
	color = (R << 16 | G << 8 | B);

	// Special case the horixontal, vertical, and diagonal lines
	// since they don't need "normal calculations"

	// Is the line vertical?
	if( dx == 0 )
	{
		// The line is vertical
		for(index = 0; index <= dy; index++)
		{
			// Draw the pixel at the current location
			*pBuffer = color;

			// Move down one line
			pBuffer += pitch;
		}

		// Done drawing
		return;
	}

	// Is the line horizontal?
	if( dy == 0 )
	{
		// The line is horizontal
		for(index = 0; index <= dx; index++)
		{
			// Draw the pixel at the current location
			*pBuffer = color;

			// Move to the next pixel on this line
			pBuffer += incx;
		}

		// Done drawing
		return;
	}

	// Is this line diagonal
	if( dx == dy )
	{
		// The line is diagonal
		for(index = 0; index <= dx; index++)
		{
			// Draw the pixel at the current location
			*pBuffer = color;

			// Move down one line and over by the x increment
			pBuffer += (pitch + incx);
		}

		// Done drawing
		return;
	}

	// Is this an X major or Y major line?
	if( dx >= dy )
	{
		// The line is X Major 

		// Scale the Y length up by a factor of 2
		// Compute the starting ErrorTerm
		// Then scale the X length up by a factor of 2
		dy <<= 1;
		iErrorTerm = dy - dx;
		dx <<= 1;

		// Loop until we reach the end of the X axis
		while( x != x2 )
		{
			// Draw the pixel at the current location
			*pBuffer = color;

			// Does our ErrorTerm indicate we need to move to
			// the next pixel on our minor axis (the Y axis)?
			if( iErrorTerm >= 0 )
			{
				// Move to the next Y line in the buffer
				pBuffer += pitch;

				// Adjust the error term back down again
				iErrorTerm -= dx;
			}

			// Add another Y delta on since we moved a pixel
			// along the X axis
			iErrorTerm += dy;

			// Move to the next coordinate along the X axis
			x += incx;
			pBuffer += incx;
		}
		
		// Draw the pixel at the final location
		*pBuffer = color;
	}
	else
	{
		// The line is Y major

		// Scale the X length up by a factor of 2
		// Compute the starting ErrorTerm
		// Then scale the Y length up by a factor of 2
		dx <<= 1;
		iErrorTerm = dx - dy;
		dy <<= 1;

		// Loop until we reach the end of the Y axis
		while( y != y2 )
		{
			// Draw a pixel at the current location
			*pBuffer = color;

			// Does our ErrorTerm indicate we need to move to
			// the next pixel on our minor axis (the X axis)?
			if( iErrorTerm >= 0 )
			{
				// Move to the next X coordinate in the buffer
				pBuffer += incx;

				// Adjust the error term back down again
				iErrorTerm -= dy;
			}
			
			// Add another X delta on since we moved a pixel
			// along the Y axis
			iErrorTerm += dx;

			// Move to the next coordinate along the Y axis
			y += incy;
			pBuffer += pitch;
		}

		// Draw the pixel at the final location
		*pBuffer = color;
	}

	// Done drawing
	return;
}
///////////////////////////////////////////////////////////////////////////////
// END DrawBresenhamLine()
///////////////////////////////////////////////////////////////////////////////
