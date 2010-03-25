//
//  NSTableView+NoodleExtensions.h
//  NoodleKit
//
//  Created by Paul Kim on 10/22/09.
//  Copyright 2009 Noodlesoft, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NSUInteger		NoodleStickyRowTransition;

enum
{
	NoodleStickyRowTransitionNone,
	NoodleStickyRowTransitionFadeIn
};


@interface NSTableView (NoodleExtensions)

#pragma mark Sticky Row Header methods
// Note: see NoodleTableView's -drawRect on how to hook in this functionality in a subclass

/*
 Currently set to any groups rows (as dictated by the delegate). The
 delegate can implement -tableView:isStickyRow: to override this.
 */
- (BOOL)isRowSticky:(NSInteger)rowIndex;

/*
 Does the actual drawing of the sticky row. Override if you want a custom look.
 You shouldn't invoke this directly. See -drawStickyRowHeader.
 */
- (void)drawStickyRow:(NSInteger)row clipRect:(NSRect)clipRect;

/*
 Draws the sticky row at the top of the table. You have to override -drawRect 
 and call this method, that being all you need to get the sticky row stuff
 to work in your subclass. Look at NoodleStickyRowTableView.
 Note that you shouldn't need to override this. To modify the look of the row,
 override -drawStickyRow: instead.
 */
- (void)drawStickyRowHeader;

/*
 Returns the rect of the sticky view header. Will return NSZeroRect if there is no current
 sticky row.
 */
- (NSRect)stickyRowHeaderRect;

/*
 Does an animated scroll to the current sticky row. Clicking on the sticky
 row header will trigger this.
 */
- (IBAction)scrollToStickyRow:(id)sender;

/*
 Returns what kind of transition you want when the row becomes sticky. Fade-in 
 is the default.
 */
- (NoodleStickyRowTransition)stickyRowHeaderTransition;

#pragma mark Row Spanning methods

/*
 Returns the range of the span at the given column and row indexes. The span is determined by
 a range of contiguous rows having the same object value.
 */
- (NSRange)rangeOfRowSpanAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex;

@end

@class NoodleRowSpanningCell;

@interface NSTableColumn (NoodleExtensions)

#pragma mark Row Spanning methods
/*
 Returns whether this column will try to consolidate rows into spans.
 */
- (BOOL)isRowSpanningEnabled;

/*
 Returns the cell used to draw the spanning regions. Default implementation returns nil.
 */
- (NoodleRowSpanningCell *)spanningCell;

@end


@interface NSOutlineView (NoodleExtensions)

#pragma mark Sticky Row Header methods
/*
 Currently set to any groups rows (or as dictated by the delegate). The
 delegate can implement -outlineView:isStickyRow: to override this.
 */
- (BOOL)isRowSticky:(NSInteger)rowIndex;

@end


@interface NSObject (NoodleStickyRowDelegate)

/*
 Allows the delegate to specify if a row is sticky. By default, group rows
 are sticky. The delegate can override that by implementing this method.
 */
- (BOOL)tableView:(NSTableView *)tableView isStickyRow:(NSInteger)rowIndex;

/*
 Allows the delegate to specify whether a certain cell should be drawn in the sticky row header
 */
- (BOOL)tableView:(NSTableView *)tableView shouldDisplayCellInStickyRowHeaderForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex;

/*
 Same as above but for outline views.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView isStickyItem:(id)item;

@end

