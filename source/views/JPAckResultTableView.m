// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckResultTableView.h"
#import "JPAckResultCell.h"
#import "NSTableView+NoodleExtensions.h"
#import "SDFoundation.h"

@interface JPAckResultTableView ()
- (void)activationAction:(id)sender;
- (BOOL)activateRow:(NSInteger)row atPoint:(NSPoint)point;
@end

@implementation JPAckResultTableView

- (void)awakeFromNib
{
  [self setTarget:self];
  [self setAction:@selector(activationAction:)];
}

- (void)activationAction:(id)sender
{
  NSInteger crow = [self clickedRow];
  NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];

  if (crow != -1 && [self isRowSelected:crow] && NSPointInRect(mouseLocation, [self rectOfRow:crow]))
    [self activateRow:crow atPoint:mouseLocation];
}

- (BOOL)activateRow:(NSInteger)row atPoint:(NSPoint)point;
{
  if ([self isRowSelected:row])
  {
    return [[self delegate] tableView:self activateSelectedRow:row atPoint:point];
  }
  return NO;
}

- (void)sizeLastColumnToFit
{
  // Brute-force the column resizing - blech.
  
  NSArray* cols = [self tableColumns];
  CGFloat fixedWidth = [[cols objectAtIndex:0] width];
  [[cols objectAtIndex:1] setWidth:NSWidth([self visibleRect]) - fixedWidth];
}

- (NSInteger)spanningColumnForRow:(NSInteger)rowIndex
{
  if ([[self delegate] respondsToSelector:@selector(tableView:spanningColumnForRow:)])
    return [[self delegate] tableView:self spanningColumnForRow:rowIndex];

  return NSNotFound;
}

// // Don't like this - removing it for now. Perhaps spacebar is a better activation trigger
// - (void)keyDown:(NSEvent *)event
// {
//   unichar u = [[event charactersIgnoringModifiers] characterAtIndex: 0];
//   if ((u == NSEnterCharacter || u == NSCarriageReturnCharacter) && [self activateRow:[self selectedRow]])
//     return;
//   else
//     [super keyDown:event];
// }

- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex
{
  NSInteger spanningColumn = [self spanningColumnForRow:rowIndex];
  if (spanningColumn != NSNotFound)
    return (columnIndex != spanningColumn) ? NSZeroRect : NSInsetRect([self rectOfRow:rowIndex], RESULT_ROW_PADDING, 0);

  NSRect foc = [super frameOfCellAtColumn:columnIndex row:rowIndex];

  if (columnIndex == 0)
    SDDivideRect(foc, nil, &foc, RESULT_ROW_PADDING, NSMinXEdge);
  else
    SDDivideRect(foc, nil, &foc, RESULT_ROW_PADDING, NSMaxXEdge);

  return foc;
}

- (void)setFrameSize:(NSSize)newSize
{
  [super setFrameSize:newSize];
  [self sizeLastColumnToFit];
  
  NSRange allRows = NSMakeRange(0, [self numberOfRows]);
  NSRange rangeToRefresh;

  if ([self inLiveResize])
    rangeToRefresh = NSIntersectionRange([self rowsInRect:[self visibleRect]], allRows);
  else
    rangeToRefresh = allRows;

  NSIndexSet* refreshIndexes = [NSIndexSet indexSetWithIndexesInRange:rangeToRefresh];
  [self noteHeightOfRowsWithIndexesChanged:refreshIndexes];
}

- (void)viewDidEndLiveResize
{
  NSIndexSet* refreshIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])];
  [self noteHeightOfRowsWithIndexesChanged:refreshIndexes];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
  // No selection highlighting thanks.
}

- (void)drawRect:(NSRect)rect
{
  [super drawRect:rect];
  [self drawStickyRowHeader];
}

// Since we are going to ensure that the regular and sticky versions of a row
// look the same, no transition is needed here.
- (NoodleStickyRowTransition)stickyRowHeaderTransition
{
  return NoodleStickyRowTransitionNone;
}

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
  if ([self isRowSticky:rowIndex])
  {
    NSRect rowRect = [self rectOfRow:rowIndex];

    if (!_isDrawingStickyRow)
    {
      // Note that NSTableView will still draw the special background that it does
      // for group row so we re-draw the background over it.
      [self drawBackgroundInClipRect:rowRect];

      if (NSIntersectsRect(rowRect, [self stickyRowHeaderRect]))
      {
        // You can barely notice it but if the sticky view is showing, the actual
        // row it represents is still seen underneath. We check for this and don't
        // draw the row in such a case.
        return;
      }
    }

    NSInteger scol = [self spanningColumnForRow:rowIndex];
    if (scol == NSNotFound)
      scol = 0;
      
    NSCell* cell = [self preparedCellAtColumn:scol row:rowIndex];
    NSRect cellRect = [self frameOfCellAtColumn:scol row:rowIndex];
    [cell drawWithFrame:cellRect inView:self];
  }
  else
  {
    [super drawRow:rowIndex clipRect:clipRect];
  }
}

- (void)drawStickyRow:(NSInteger)row clipRect:(NSRect)clipRect
{
  _isDrawingStickyRow = YES;
  [self drawRow:row clipRect:clipRect];
  _isDrawingStickyRow = NO;
}

@end
