// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckControlView.h"

#define START_COLOR_GRAY [NSColor colorWithCalibratedWhite:0.75 alpha:0.8]
#define END_COLOR_GRAY [NSColor colorWithCalibratedWhite:0.90 alpha:0.5]
#define BORDER_WIDTH 1.0

@implementation JPAckControlView

- (void)drawRect:(NSRect)rect
{
  NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:START_COLOR_GRAY
    endingColor:END_COLOR_GRAY] autorelease];
  [gradient drawInRect:[self bounds] angle:90.0];

  NSRect lineRect = [self bounds];
  lineRect.size.height = BORDER_WIDTH;
  [[NSColor colorWithCalibratedWhite:0.40 alpha:1.0] set];
  NSRectFill(lineRect);
}

@end
