// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>
#import "JPAckResultRep.h"

// left/right padding for the cell
#define RESULT_ROW_PADDING 15.0

// NSTextFieldCell seems to apply this X inset silently.
// Unsure why it's not reflected by titleRectForBounds...
#define RESULT_TEXT_XINSET 2.0

// This inset makes sure any result highlights are not
// mashed up against the top edge
#define RESULT_TEXT_YINSET 2.0

// some interior space so that text isn't mashed up 
// against left/right edges
#define RESULT_CONTENT_INTERIOR_PADDING 10.0

@interface JPAckResultCell : NSTextFieldCell {
  BOOL expectsFullCellDrawingRect;
  JPAckResultType resultType;
  BOOL alternate;
  BOOL contentColumn;
  CGFloat lineNumberWidth;
}

-(void)configureType:(JPAckResultType)resultType_ alternate:(BOOL)alternate_ contentColumn:(BOOL)contentColumn_;
@end
