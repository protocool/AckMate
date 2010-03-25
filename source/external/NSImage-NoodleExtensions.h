//
//  NSImage-NoodleExtensions.h
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

#import <Cocoa/Cocoa.h>


/*
 This category provides methods for dealing with flipped images. These should draw images correctly regardless of
 whether the current context or the current image are flipped. Unless you know what you are doing, these should be used 
 in lieu of the normal  NSImage drawing/compositing methods.
 
 For more details, check out the related blog post at http://www.noodlesoft.com/blog/2009/02/02/understanding-flipped-coordinate-systems/
 */

@interface NSImage (NoodleExtensions)

/*!
 @method	drawAdjustedAtPoint:fromRect:operation:fraction:
 @abstract	Draws all or part of the image at the specified point in the current coordinate system. Unlike other methods in NSImage, this will orient the image properly in flipped coordinate systems.
 @param		point The location in the current coordinate system at which to draw the image.
 @param		srcRect The source rectangle specifying the portion of the image you want to draw. The coordinates of this rectangle are specified in the image's own coordinate system. If you pass in NSZeroRect, the entire image is drawn.
 @param	    op The compositing operation to use when drawing the image. See the NSCompositingOperation constants.
 @param		delta The opacity of the image, specified as a value from 0.0 to 1.0. Specifying a value of 0.0 draws the image as fully transparent while a value of 1.0 draws the image as fully opaque. Values greater than 1.0 are interpreted as 1.0.
 @discussion The image content is drawn at its current resolution and is not scaled unless the CTM of the current coordinate system itself contains a scaling factor. The image is otherwise positioned and oriented using the current coordinate system, except that it takes the flipped status into account, drawing right-side-up in a such a case.
 
 Unlike the compositeToPoint:fromRect:operation: and compositeToPoint:fromRect:operation:fraction: methods, this method checks the rectangle you pass to the srcRect parameter and makes sure it does not lie outside the image bounds.
 */
- (void)drawAdjustedAtPoint:(NSPoint)aPoint fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta;

/*!
 @method	drawAdjustedInRect:fromRect:operation:fraction:
 @abstract	Draws all or part of the image in the specified rectangle in the current coordinate system. Unlike other methods in NSImage, this will orient the image properly in flipped coordinate systems.
 @param		dstRect The rectangle in which to draw the image, specified in the current coordinate system.
 @param		srcRect The source rectangle specifying the portion of the image you want to draw. The coordinates of this rectangle must be specified using the image's own coordinate system. If you pass in NSZeroRect, the entire image is drawn.
 @param		op The compositing operation to use when drawing the image. See the NSCompositingOperation constants.
 @param		delta The opacity of the image, specified as a value from 0.0 to 1.0. Specifying a value of 0.0 draws the image as fully transparent while a value of 1.0 draws the image as fully opaque. Values greater than 1.0 are interpreted as 1.0.
 @discussion If the srcRect and dstRect rectangles have different sizes, the source portion of the image is scaled to fit the specified destination rectangle. The image is otherwise positioned and oriented using the current coordinate system, except that it takes the flipped status into account, drawing right-side-up in a such a case.
 
 Unlike the compositeToPoint:fromRect:operation: and compositeToPoint:fromRect:operation:fraction: methods, this method checks the rectangle you pass to the srcRect parameter and makes sure it does not lie outside the image bounds.
 */
- (void)drawAdjustedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta;

/*!
 @method	unflippedImage
 @abstract	Returns a version of the receiver but unflipped.
 @discussion This does not actually flip the image but returns an image with the same orientation but with an unflipped coordinate system internally (isFlipped returns NO). If the image is already unflipped, this method returns self.
 */
- (NSImage *)unflippedImage;


@end
