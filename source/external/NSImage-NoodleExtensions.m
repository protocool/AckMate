//
//  NSImage-NoodleExtensions.m
//  NoodleKit
//
//  Created by Paul Kim on 3/24/07.
//  Copyright 2007-2009 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#import "NSImage-NoodleExtensions.h"


@implementation NSImage (NoodleExtensions)

- (void)drawAdjustedAtPoint:(NSPoint)aPoint fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
{
	NSSize		size = [self size];
	
	[self drawAdjustedInRect:NSMakeRect(aPoint.x, aPoint.y, size.width, size.height) fromRect:srcRect operation:op fraction:delta];
}

- (void)drawAdjustedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
{
	NSGraphicsContext	*context;
	BOOL				contextIsFlipped;
	
	context = [NSGraphicsContext currentContext];
	contextIsFlipped = [context isFlipped];
	
	if (contextIsFlipped)
	{
		NSAffineTransform			*transform;
		
		[context saveGraphicsState];
		
		// Flip the coordinate system back.
		transform = [NSAffineTransform transform];
		[transform translateXBy:0 yBy:NSMaxY(dstRect)];
		[transform scaleXBy:1 yBy:-1];
		[transform concat];
		
		// The transform above places the y-origin right where the image should be drawn.
		dstRect.origin.y = 0.0;
	}
	
	[self drawInRect:dstRect fromRect:srcRect operation:op fraction:delta];
	
	if (contextIsFlipped)
	{
		[context restoreGraphicsState];
	}
}

- (NSImage *)unflippedImage
{
	if ([self isFlipped])
	{
		NSImage		*newImage;
		
		newImage = [[[NSImage alloc] initWithSize:[self size]] autorelease];
		[newImage lockFocus];
		[self drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		[newImage unlockFocus];
		
		return newImage;
	}
	return self;
}

@end
