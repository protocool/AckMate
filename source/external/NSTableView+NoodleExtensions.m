//
//  NSTableView-NoodleExtensions.m
//  NoodleKit
//
//  Created by Paul Kim on 10/22/09.
//  Copyright 2009 Noodlesoft, LLC. All rights reserved.
//

#import "NSTableView+NoodleExtensions.h"
#import "NSImage-NoodleExtensions.h"

#define NOODLE_STICKY_ROW_VIEW_TAG		233931134

void NoodleClearRect(NSRect rect)
{
	[[NSColor clearColor] set];
	NSRectFill(rect);
}

@interface NSTableView ()

#pragma mark Sticky Row Header methods

// Returns index of the sticky row previous to the first visible row.
- (NSInteger)_previousStickyRow;

// Returns index of the sticky row after the first visible row.
- (NSInteger)_nextStickyRow;

- (void)_updateStickyRowHeaderImageWithRow:(NSInteger)row;

// Returns the view used for the sticky row header
- (id)_stickyRowHeaderView;

@end


@implementation NSTableView (NoodleExtensions)

#pragma mark Sticky Row Header methods

- (BOOL)isRowSticky:(NSInteger)rowIndex
{
	id		delegate;
	
	delegate = [self delegate];
	
	if ([delegate respondsToSelector:@selector(tableView:isStickyRow:)])
	{
		return [delegate tableView:self isStickyRow:rowIndex];
	}
	else if ([delegate respondsToSelector:@selector(tableView:isGroupRow:)])
	{
		return [delegate tableView:self isGroupRow:rowIndex];
	}
	return NO;
}

- (void)drawStickyRowHeader
{	
	id			stickyView;
	NSInteger	row;
	
	stickyView = [self _stickyRowHeaderView];
	row = [self _previousStickyRow];
	if (row != -1)
	{
		[stickyView setFrame:[self stickyRowHeaderRect]];
		[self _updateStickyRowHeaderImageWithRow:row];	
	}
	else
	{
		[stickyView setFrame:NSZeroRect];
	}
}

- (IBAction)peformClickOnStickyRow:(id)sender
{
	NSInteger		row;
	
	row = [self _previousStickyRow];
	if (row != -1)
	{
		[self clickedStickyRow:row];
	}
}

- (void)clickedStickyRow:(NSInteger)row
{
  [self scrollRowToVisible:row];
}

- (NSMenu*)contextMenuForStickyRow:(id)sender
{
	NSInteger		row;
	
	row = [self _previousStickyRow];
	if (row != -1)
	{
    return [[self delegate] tableView:self contextMenuForRow:row];
	}
  return nil;
}

- (id)_stickyRowHeaderView
{
	NSButton		*view;
	
	view = [self viewWithTag:NOODLE_STICKY_ROW_VIEW_TAG];
	
	if (view == nil)
	{
		view = [[StickyRowButton alloc] initWithFrame:NSZeroRect];
		[view setEnabled:YES];
		[view setBordered:NO];
		[view setImagePosition:NSImageOnly];
		[view setTitle:nil];
		[[view cell] setHighlightsBy:NSNoCellMask];
		[[view cell] setShowsStateBy:NSNoCellMask];
		[[view cell] setImageScaling:NSImageScaleNone];
		[[view cell] setImageDimsWhenDisabled:NO];
		
		[view setTag:NOODLE_STICKY_ROW_VIEW_TAG];
		
		[view setTarget:self];
		[view setAction:@selector(peformClickOnStickyRow:)];
		
		[self addSubview:view];
		[view release];
	}
	return view;
}

- (void)drawStickyRow:(NSInteger)row clipRect:(NSRect)clipRect
{
	NSRect				rowRect, cellRect;
	NSCell				*cell;
	NSInteger			colIndex, count;
	id					delegate;
	
	delegate = [self delegate];
	
	if (![delegate respondsToSelector:@selector(tableView:shouldDisplayCellInStickyRowHeaderForTableColumn:row:)])
	{
		delegate = nil;
	}
	
	rowRect = [self rectOfRow:row];
	
	[[[self backgroundColor] highlightWithLevel:0.5] set];
	NSRectFill(rowRect);
	
	// PENDING: -drawRow:clipRect: is too smart for its own good. If the row is not visible,
	//	this method won't draw anything. Useless for row caching.
	//	[self drawRow:row clipRect:rowRect];
	
	count = [self numberOfColumns];
	for (colIndex = 0; colIndex < count; colIndex++)
	{
		if ((delegate == nil) ||
			[delegate tableView:self shouldDisplayCellInStickyRowHeaderForTableColumn:[[self tableColumns] objectAtIndex:colIndex] row:row])
		{
			cell = [self preparedCellAtColumn:colIndex row:row];
			cellRect = [self frameOfCellAtColumn:colIndex row:row];
			[cell drawWithFrame:cellRect inView:self];
		}
	}
	
	[[self gridColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect), NSMaxY(rowRect)) toPoint:NSMakePoint(NSMaxX(rowRect), NSMaxY(rowRect))];
}

- (NoodleStickyRowTransition)stickyRowHeaderTransition
{
	return NoodleStickyRowTransitionFadeIn;
}

- (void)_updateStickyRowHeaderImageWithRow:(NSInteger)row
{
	NSImage							*image;
	NSRect							rowRect, visibleRect, imageRect;
	CGFloat							offset, alpha;
	NSAffineTransform				*transform;
	id								stickyView;
	NoodleStickyRowTransition		transition;
	BOOL							isSelected;
	
	rowRect = [self rectOfRow:row];
	imageRect = NSMakeRect(0.0, 0.0, NSWidth(rowRect), NSHeight(rowRect));
	stickyView = [self _stickyRowHeaderView];
	
	isSelected = [self isRowSelected:row];
	if (isSelected)
	{
		[self deselectRow:row];
	}
	
	// Optimization: instead of creating a new image each time (and since we can't
	// add ivars in a category), just use the image in the sticky view. We're going
	// to put it there in the end anyways, why not reuse it?
	image = [stickyView image];
	
	if ((image == nil) || !NSEqualSizes(rowRect.size, [image size]))
	{
		image = [[NSImage alloc] initWithSize:rowRect.size];
		[image setFlipped:[self isFlipped]];
		[stickyView setImage:image];
		[image release];
	}
	
	visibleRect = [self visibleRect];
	
	// Calculate a distance between the row header and the actual sticky row and normalize it 
	// over the row height (plus some extra). We use this to do the fade in effect as you
	// scroll away from the sticky row.
	offset = (NSMinY(visibleRect) - NSMinY(rowRect)) / (NSHeight(rowRect) * 1.25);
	
	// When the button is disabled, it passes through to the view underneath. So, until the
	// original header view is mostly out of view, allow mouse events to pass through. After
	// that, the header is clickable.
	// 
	// MODS Trevor Squires
	// Okay, changed it from if (offset < 0.5) because I only want pass-through
	// if the positions are equal. It's probably an issue for me b/c of my top margin.
	if (NSMinY(visibleRect) == NSMinY(rowRect))
	{
		[stickyView setEnabled:NO];
	}
	else
	{
		[stickyView setEnabled:YES];
	}
	
	// Row is drawn in tableview coord space.
	transform = [NSAffineTransform transform];
	[transform translateXBy:-NSMinX(rowRect) yBy:-NSMinY(rowRect)];
	
	transition = [self stickyRowHeaderTransition];
	if (transition == NoodleStickyRowTransitionFadeIn)
	{
		// Since we want to adjust the transparency based on position, we draw the row into an
		// image which we then draw with alpha into the final image.		
		NSImage *rowImage;
		
		// Optimization: Since this is a category and we can't add any ivars, we instead use
		// the unused alt image of the sticky view (which is a button) as a cache so we don't
		// have to keep creating images. Yes, a little hackish.
		rowImage = [stickyView alternateImage];
		if ((rowImage == nil) || !NSEqualSizes(rowRect.size, [rowImage size]))
		{
			rowImage = [[NSImage alloc] initWithSize:rowRect.size];
			[rowImage setFlipped:[self isFlipped]];
			
			[stickyView setAlternateImage:rowImage];
			[rowImage release];
		}
		
		// Draw the original image
		[rowImage lockFocus];
		NoodleClearRect(imageRect);
		
		[transform concat];
		[self drawStickyRow:row clipRect:rowRect];
		
		[rowImage unlockFocus];
		
		alpha = MIN(offset, 0.9);
		
		// Draw it with transparency in the final image
		[image lockFocus];
		
		NoodleClearRect(imageRect);
		[rowImage drawAdjustedAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:alpha];
		
		[image unlockFocus];
	}
	else if (transition == NoodleStickyRowTransitionNone)
	{
		[image lockFocus];
		NoodleClearRect(imageRect);
		
		[transform concat];
		[self drawStickyRow:row clipRect:rowRect];
		
		[image unlockFocus];
	}
	else 
	{
		[image lockFocus];
		NoodleClearRect(imageRect);
		
		[@"You returned a bad NoodleStickyRowTransition value. Tsk. Tsk." drawInRect:imageRect withAttributes:nil];
		
		[image unlockFocus];
	}
	
	if (isSelected)
	{
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
	}
	
}

- (NSInteger)_previousStickyRow
{
	NSRect			visibleRect;
	NSInteger		row;
	
	visibleRect = [self visibleRect];
	row = [self rowAtPoint:visibleRect.origin];
	
	while (row >= 0)
	{
		if ([self isRowSticky:row])
		{
			return row;
		}
		row--;
	}
	return -1;
}

- (NSInteger)_nextStickyRow
{
	NSRect			visibleRect;
	NSInteger		row;
	NSInteger		numberOfRows;
	
	visibleRect = [self visibleRect];
	row = [self rowAtPoint:visibleRect.origin];
	if (row != -1)
	{
		numberOfRows = [self numberOfRows];
		while (++row < numberOfRows)
		{
			if ([self isRowSticky:row])
			{
				return row;
			}
		}
	}
	return -1;
}

- (NSRect)stickyRowHeaderRect
{
	NSInteger	row;
	
	row = [self _previousStickyRow];
	
	if (row != -1)
	{
		NSInteger		nextGroupRow;
		NSRect			visibleRect, rowRect;
		
		rowRect = [self rectOfRow:row];
		visibleRect = [self visibleRect];
		
		// Move it to the top of the visible area
		rowRect.origin.y = NSMinY(visibleRect);
		
		nextGroupRow = [self _nextStickyRow];
		if (nextGroupRow != -1)
		{
			NSRect		nextRect;
			
			// "Push" the row up if it's butting up against the next sticky row
			nextRect = [self rectOfRow:nextGroupRow];
			if (NSMinY(nextRect) < NSMaxY(rowRect))
			{
				rowRect.origin.y = NSMinY(nextRect) - NSHeight(rowRect);
			}
		}
		return rowRect;
	}
	return NSZeroRect;
}

#pragma mark Row Spanning methods

- (NSRange)rangeOfRowSpanAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex
{
	id				dataSource, objectValue, originalObjectValue;
	NSInteger		i, start, end, count;
	NSTableColumn	*column;
	
	dataSource = [self dataSource];
	
	column = [[self tableColumns] objectAtIndex:columnIndex];
	
	if ([column isRowSpanningEnabled])
	{
		originalObjectValue = [dataSource tableView:self objectValueForTableColumn:column row:rowIndex];
		
		// Figure out the span of this cell. We determine this by going up and down finding contiguous rows with
		// the same object value.
		i = rowIndex;
		while (i-- > 0)
		{
			objectValue = [dataSource tableView:self objectValueForTableColumn:column row:i];
			
			if (![objectValue isEqual:originalObjectValue])
			{
				break;
			}
		}
		start = i + 1;
		
		count = [self numberOfRows];
		i = rowIndex + 1;
		while (i < count)
		{
			objectValue = [dataSource tableView:self objectValueForTableColumn:column row:i];
			
			if (![objectValue isEqual:originalObjectValue])
			{
				break;
			}
			i++;
		}
		end = i - 1;
		
		return NSMakeRange(start, end - start + 1);
	}
	return NSMakeRange(rowIndex, 1);
}

@end

@implementation NSTableColumn (NoodleExtensions)

#pragma mark Row Spanning methods

- (BOOL)isRowSpanningEnabled
{
	return NO;
}

- (NoodleRowSpanningCell *)spanningCell
{
	return nil;
}

@end

@implementation NSOutlineView (NoodleExtensions)

#pragma mark Sticky Row Header methods

- (BOOL)isRowSticky:(NSInteger)rowIndex
{
	id		delegate;
	
	delegate = [self delegate];
	
	if ([delegate respondsToSelector:@selector(outlineView:isStickyItem:)])
	{
		return [delegate outlineView:self isStickyItem:[self itemAtRow:rowIndex]];
	}
	else if ([delegate respondsToSelector:@selector(outlineView:isGroupItem:)])
	{
		return [delegate outlineView:self isGroupItem:[self itemAtRow:rowIndex]];
	}
	return NO;
}

@end

@implementation StickyRowButton
- (NSMenu*)menuForEvent:(NSEvent*)event
{
  return [[self target] contextMenuForStickyRow:self];
}
@end