// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckWindowController.h"
#import "JPAckResultSource.h"
#import "JPAckResultRep.h"
#import "JPAckResultTableView.h"
#import "JPAckResultCell.h"

@interface JPAckResultSource ()
@property(nonatomic, copy) NSString* longestLineNumber;
@property(nonatomic, retain) NSMutableArray* resultRows;
@property(nonatomic, copy, readwrite) NSString* resultStats;
- (void)toggleFileRep:(JPAckResultRep*)rep atIndex:(NSInteger)index;
- (void)configureFontAttributes;
- (CGFloat)lineContentWidth;
- (void)adjustForLongestLineNumber:(NSString*)linenumber;
@end

@implementation JPAckResultSource

NSString* const amLineNumberColumn = @"amLineNumberColumn";
NSString* const amContentColumn  = @"amContentColumn";

@synthesize longestLineNumber;
@synthesize searchRoot;
@synthesize resultStats;
@synthesize resultRows;
@synthesize matchedFiles;
@synthesize matchedLines;

- (void)awakeFromNib
{
  currentResultFileRep = nil;
  resultStats = nil;
  searchRoot = nil;
  longestLineNumber = nil;

  self.resultRows = [NSMutableArray array];

  [resultView setIntercellSpacing:NSMakeSize(0,0)];

  NSArray* rvColumns = [resultView tableColumns];
  NSAssert([rvColumns count] == 2, @"Expected 2 columns in output table");
  [[rvColumns objectAtIndex:0] setIdentifier:amLineNumberColumn];
  [[rvColumns objectAtIndex:1] setIdentifier:amContentColumn];

  [self configureFontAttributes];
}

- (void)clearContents
{
  alternateRow = NO;
  matchedFiles = 0;
  matchedLines = 0;
  currentResultFileRep = nil;
  self.resultStats = nil;
  [self.resultRows removeAllObjects];
  [resultView reloadData];

  // reset column 0 to be 3 chars wide in the current font
  self.longestLineNumber = nil;
  [self adjustForLongestLineNumber:@"..."];
}

- (void)updateStats
{
  // 5 lines matched in 2 files
  NSString* insel = (searchingSelection) ? @"In selection: " : @"";
  
  self.resultStats = [NSString stringWithFormat:@"%@%d line%@ matched in %d file%@", insel, matchedLines, (matchedLines == 1) ? @"" : @"s", matchedFiles, (matchedFiles == 1) ? @"" : @"s"];
}

- (void)searchingFor:(NSString*)term inRoot:(NSString*)searchRoot_ inFolder:(NSString*)searchFolder
{
  self.searchRoot = searchRoot_;
  searchingSelection = (searchFolder) ? YES : NO;
  [self updateStats];
}

- (void)parsedError:(NSString*)errorString
{
  alternateRow = NO;
  JPAckResult* jpar = [JPAckResult resultErrorWithString:errorString];
  [self.resultRows addObject:[JPAckResultRep withResultObject:jpar alternate:alternateRow]];
  [resultView noteNumberOfRowsChanged];
}

- (void)parsedFilename:(NSString*)filename
{
  alternateRow = NO;
  matchedFiles++;
  [self updateStats];

  JPAckResult* fileResult = [JPAckResult resultFileWithName:[filename substringFromIndex:[self.searchRoot length]]];
  currentResultFileRep = [JPAckResultRep withResultObject:fileResult alternate:NO];
  [self.resultRows addObject:currentResultFileRep];
  [resultView noteNumberOfRowsChanged];
}

- (void)parsedContextBreak
{
  alternateRow = NO;
  JPAckResult* jpar = [JPAckResult resultContextBreak];
  JPAckResultRep* jparrep = [JPAckResultRep withResultObject:jpar parent:currentResultFileRep alternate:NO];
  if (![currentResultFileRep collapsed])
  {
    [self.resultRows addObject:jparrep];
    [resultView noteNumberOfRowsChanged];
  }
}

- (void)parsedContextLine:(NSString*)lineNumber content:(NSString*)content
{
  if (currentResultFileRep)
  {
    JPAckResult* jpar = [JPAckResult resultContextLineWithNumber:lineNumber content:content];
    JPAckResultRep* jparrep = [JPAckResultRep withResultObject:jpar parent:currentResultFileRep alternate:alternateRow];
    if (![currentResultFileRep collapsed])
    {
      [self.resultRows addObject:jparrep];
      [resultView noteNumberOfRowsChanged];
    }
    [self adjustForLongestLineNumber:lineNumber];
    alternateRow = !alternateRow;
  }
}

- (void)parsedMatchLine:(NSString*)lineNumber ranges:(NSArray*)ranges content:(NSString*)content
{
  if (currentResultFileRep)
  {
    NSMutableArray* matchRanges = (ranges) ? [NSMutableArray arrayWithCapacity:[ranges count]] : nil;
    matchedLines++;

    for (NSString* rangeString in ranges)
      [matchRanges addObject:[NSValue valueWithRange:NSRangeFromString(rangeString)]];

    JPAckResult* jpar = [JPAckResult resultMatchingLineWithNumber:lineNumber content:content ranges:matchRanges];
    JPAckResultRep* jparrep = [JPAckResultRep withResultObject:jpar parent:currentResultFileRep alternate:alternateRow];
    if (![currentResultFileRep collapsed])
    {
      [self.resultRows addObject:jparrep];
      [resultView noteNumberOfRowsChanged];
    }
    [self adjustForLongestLineNumber:lineNumber];
    alternateRow = !alternateRow;
  }
}

- (void)adjustForLongestLineNumber:(NSString*)lineNumber
{
  if ([lineNumber length] > [self.longestLineNumber length])
  {
    self.longestLineNumber = lineNumber;
    CGFloat lineNumberWidth = ceil(RESULT_ROW_PADDING + (RESULT_CONTENT_INTERIOR_PADDING * 2.0) + (RESULT_TEXT_XINSET * 2.0) + [lineNumber sizeWithAttributes:bodyNowrapAttributes].width);

    [[resultView tableColumnWithIdentifier:amLineNumberColumn] setWidth:lineNumberWidth];
    [resultView sizeLastColumnToFit];
    
    NSIndexSet* refreshIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [resultView numberOfRows])];
    [resultView noteHeightOfRowsWithIndexesChanged:refreshIndexes];
  }
}

- (CGFloat)lineContentWidth
{
  return NSWidth([resultView rectOfColumn:1]) - RESULT_ROW_PADDING - (RESULT_TEXT_XINSET * 2.0) - (RESULT_CONTENT_INTERIOR_PADDING * 2);
}

- (NSInteger)tableView:(NSTableView *)tableView spanningColumnForRow:(NSInteger)row
{
  JPAckResultType rt = [[self.resultRows objectAtIndex:row] resultType];
  if (rt == JPResultTypeFilename || rt == JPResultTypeError)
    return 1;

  return NSNotFound;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  JPAckResultRep* resultRep = [self.resultRows objectAtIndex:row];

  switch([resultRep resultType])
  {
    case JPResultTypeFilename:
      return headerHeight;
    case JPResultTypeContextBreak:
      return contextBreakHeight;
  }

  CGFloat maxWidth = [self lineContentWidth];

  if (resultRep.constrainedWidth != maxWidth)
  {
    NSSize constraints = NSMakeSize(maxWidth, MAXFLOAT);
    resultRep.constrainedWidth = maxWidth;
    resultRep.calculatedHeight = (RESULT_TEXT_YINSET * 2) + NSHeight([[resultRep.resultObject lineContent] boundingRectWithSize:constraints options:(NSStringDrawingUsesLineFragmentOrigin) attributes:bodyAttributes]);
  }
  return resultRep.calculatedHeight;
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return NO;
}

- (BOOL)tableView:(NSTableView *)tableView activateSelectedRow:(NSInteger)row atPoint:(NSPoint)pointHint
{
  JPAckResultRep* rep = [self.resultRows objectAtIndex:row];
  JPAckResult* resultObject = [rep resultObject];

  if (resultObject.resultType == JPResultTypeFilename)
  {
    [self toggleFileRep:rep atIndex:row];
    return YES;
  }
  else if (resultObject.resultType == JPResultTypeContext || resultObject.resultType == JPResultTypeMatchingLine)
  {
    NSString* filenameToOpen = [[[rep parentObject] resultObject] lineContent];
    NSRange selectionRange = NSMakeRange(0,0);
    
    // I feel like such a bandit... oh well.
    if (NSPointInRect(pointHint, [tableView frameOfCellAtColumn:1 row:row]) && [resultObject matchRanges])
    {
      // Quickly load up the field editor so we can find out where the click was
      [tableView editColumn:1 row:row withEvent:nil select:NO];
      NSTextView* tv = (NSTextView*)[tableView currentEditor];
      NSPoint adjustedPoint = [tv convertPoint:pointHint fromView:tableView];
      NSUInteger clickIndex = [tv characterIndexForInsertionAtPoint:adjustedPoint];
      
      NSRange closestRange = NSMakeRange(NSNotFound, 0);
      
      // get rid of the field editor right away
      if (![[tableView window] makeFirstResponder:tableView])
        [[tableView window] endEditingFor:nil];

      NSRange lastRange = NSMakeRange(NSNotFound, 0);
      for (NSValue* rv in [resultObject matchRanges])
      {
        NSRange matchRange = [rv rangeValue];
        if (NSLocationInRange(clickIndex, matchRange))
        {
          closestRange = matchRange;
          break;
        }
        else if (clickIndex < matchRange.location)
        {
          if (lastRange.location != NSNotFound && (clickIndex - (lastRange.location + lastRange.length)) < (matchRange.location - clickIndex))
            closestRange = lastRange;
          else
            closestRange = matchRange;
            
          break;
        }
        lastRange = matchRange;
      }
      
      if (closestRange.location == NSNotFound)
        closestRange = [[[resultObject matchRanges] lastObject] rangeValue];

      selectionRange = closestRange;
    }

    [windowController openProjectFile:filenameToOpen atLine:[resultObject lineNumber] selectionRange:selectionRange];
    return YES;
  }

  return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
  JPAckResultType itemtype = [[self.resultRows objectAtIndex:row] resultType];
  return ((itemtype == JPResultTypeMatchingLine || itemtype == JPResultTypeContext) && !([[NSApp currentEvent] modifierFlags] & NSControlKeyMask));
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.resultRows count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  JPAckResultRep* rep = [self.resultRows objectAtIndex:row];
  JPAckResultType resultType = [rep resultType];
  id value = nil;
  
  if ([tableColumn identifier] == amLineNumberColumn)
  {
    value = (resultType == JPResultTypeContextBreak) ? @"..." : [[rep resultObject] lineNumber];
  }
  else if ([tableColumn identifier] == amContentColumn)
  {
    NSString* lineContent = [[rep resultObject] lineContent];
    if (!lineContent)
      lineContent = @"";

    if ([rep resultType] == JPResultTypeMatchingLine)
    {
      NSRange contentRange = NSMakeRange(0, [lineContent length]);

      NSMutableAttributedString* attributedContent = [[[NSMutableAttributedString alloc] initWithString:lineContent attributes:bodyAttributes] autorelease];
      for (NSValue* rv in [[rep resultObject] matchRanges])
        [attributedContent setAttributes:bodyHighlightAttributes range:NSIntersectionRange([rv rangeValue], contentRange)];

      value = attributedContent;
    }
    else if ([rep resultType] == JPResultTypeFilename)
      value = [[[NSMutableAttributedString alloc] initWithString:lineContent attributes:headingAttributes] autorelease];
    else
      value = lineContent;
  }
  
  return value;
}

- (BOOL)tableView:(NSTableView *)tableView isStickyRow:(NSInteger)row
{
  return ([[self.resultRows objectAtIndex:row] resultType] == JPResultTypeFilename);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
  JPAckResultRep* rep = [self.resultRows objectAtIndex:row];
  [(JPAckResultCell*)aCell configureType:[rep resultType] alternate:[rep alternate] collapsed:[rep collapsed] contentColumn:([aTableColumn identifier] != amLineNumberColumn)];
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return NO;
}

- (BOOL)tableView:(NSTableView*)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
  // if ([tableColumn identifier] == amContentColumn && [tableView isRowSelected:row])
  //   return YES;

  return NO;
}

- (NSMenu*)tableView:(NSTableView *)tableView contextMenuForRow:(NSInteger)row;
{
  JPAckResultRep* clickRep = [self.resultRows objectAtIndex:row];
  JPAckResultRep* fileRep = [clickRep parentObject] ? [clickRep parentObject] : clickRep;

  if ([fileRep resultType] != JPResultTypeFilename)
    return nil;

  NSMenu* mfe = [[[NSMenu alloc] initWithTitle:@""] autorelease];
  NSString* fileName = [[[fileRep resultObject] lineContent] lastPathComponent];
  NSString* title = [NSString stringWithFormat:@"%@ %@", ([fileRep collapsed]) ? @"Expand" : @"Collapse", fileName];
  NSMenuItem *toggleThis = [[[NSMenuItem alloc] initWithTitle:title action:@selector(toggleCollapsingItem:) keyEquivalent:@""] autorelease];
  [toggleThis setTarget:self];
  [toggleThis setRepresentedObject:fileRep];
  [mfe addItem:toggleThis];
  [mfe addItem:[NSMenuItem separatorItem]];

  NSMenuItem *expandAll = [[[NSMenuItem alloc] initWithTitle:@"Expand All" action:@selector(expandAll:) keyEquivalent:@""] autorelease];
  [expandAll setTarget:self];
  [expandAll setRepresentedObject:fileRep];
  [mfe addItem:expandAll];
  NSMenuItem *collapseAll = [[[NSMenuItem alloc] initWithTitle:@"Collapse All" action:@selector(collapseAll:) keyEquivalent:@""] autorelease];
  [collapseAll setTarget:self];
  [collapseAll setRepresentedObject:fileRep];
  [mfe addItem:collapseAll];
  
  return mfe;
}

- (void)toggleCollapsingItem:(id)sender
{
  JPAckResultRep* rep = [sender representedObject];
  NSUInteger repindex = [self.resultRows indexOfObject:rep];
  if (repindex == NSNotFound)
    return;
  [self toggleFileRep:rep atIndex:repindex];
}

- (void)toggleFileRep:(JPAckResultRep*)rep atIndex:(NSInteger)index
{
  NSInteger selRow = [resultView selectedRow];
  NSIndexSet* effectiveSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index + 1, [[rep children] count])];
  
  if ([rep collapsed])
    [self.resultRows insertObjects:[rep children] atIndexes:effectiveSet];
  else
    [self.resultRows removeObjectsAtIndexes:effectiveSet];

  [resultView noteNumberOfRowsChanged];

  if (![rep collapsed]) // as in, not marked as collapsed yet - so we *removed* rows
  {
    if (selRow != -1 && selRow > [effectiveSet lastIndex])
      [resultView selectRowIndexes:[NSIndexSet indexSetWithIndex:(selRow - [[rep children] count])] byExtendingSelection:NO];
    else if (selRow != -1 && [effectiveSet containsIndex:selRow])
      [resultView deselectAll:self];
  }
  else if (selRow != -1 && selRow > index) // we expanded, do we need to shuffle selection along?
    [resultView selectRowIndexes:[NSIndexSet indexSetWithIndex:(selRow + [[rep children] count])] byExtendingSelection:NO];

  [rep setCollapsed:![rep collapsed]]; // *now* it's okay to flip the state
  [resultView scrollRowToVisible:index];
}

- (void)collapseAll:(id)sender
{
  NSUInteger contextRow = [self.resultRows indexOfObject:[sender representedObject]];
  CGFloat contextOffset = 0.0;
  if (contextRow != NSNotFound)
    contextOffset = [resultView viewportOffsetForRow:contextRow];
  
  NSMutableArray* collapsedResults = [NSMutableArray array];
  for (JPAckResultRep* rep in self.resultRows)
  {
    if (![rep parentObject]) {
      [collapsedResults addObject:rep];
      [rep setCollapsed:YES];
    }
  }
  [resultView deselectAll:self];
  self.resultRows = collapsedResults;
  [resultView noteNumberOfRowsChanged];

  contextRow = [self.resultRows indexOfObject:[sender representedObject]];
  if (contextRow != NSNotFound)
    [resultView scrollRowToVisible:contextRow withViewportOffset:contextOffset];
}

- (void)expandAll:(id)sender
{
  NSUInteger contextRow = [self.resultRows indexOfObject:[sender representedObject]];
  CGFloat contextOffset = 0.0;
  if (contextRow != NSNotFound)
    contextOffset = [resultView viewportOffsetForRow:contextRow];

  JPAckResultRep* selectedRep = nil;
  NSInteger selRow = [resultView selectedRow];
  if (selRow != -1)
    selectedRep = [self.resultRows objectAtIndex:selRow];

  NSMutableArray* expandedResults = [NSMutableArray array];
  for (JPAckResultRep* rep in self.resultRows)
  {
    [expandedResults addObject:rep];
    if (![rep parentObject] && [rep collapsed]) {
      [rep setCollapsed:NO];
      [expandedResults addObjectsFromArray:[rep children]];
    }
  }
  self.resultRows = expandedResults;
  [resultView noteNumberOfRowsChanged];

  if (selectedRep) // restore previous selection
  {
    NSUInteger newIndex = [self.resultRows indexOfObject:selectedRep];
    if (newIndex != NSNotFound)
      [resultView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
  }

  contextRow = [self.resultRows indexOfObject:[sender representedObject]];
  if (contextRow != NSNotFound)
    [resultView scrollRowToVisible:contextRow withViewportOffset:contextOffset];
}

- (void)configureFontAttributes
{
  NSFontManager* fm = [NSFontManager sharedFontManager];

  NSFont* headingFont = [NSFont fontWithName:@"Trebuchet MS Bold" size:13.0];
  if (!headingFont)
    headingFont = [NSFont boldSystemFontOfSize:13.0];

  NSFont* bodyFont = [NSFont fontWithName:@"Menlo-Regular" size:11.0];
  if (!bodyFont)
    bodyFont = [NSFont fontWithName:@"Monaco" size:11.0];
  
  if (!bodyFont)
    bodyFont = [NSFont userFixedPitchFontOfSize:11.0];

  NSFont* boldBodyFont = [fm convertWeight:YES ofFont:bodyFont];

  // Heading (filename) attributes
  NSMutableParagraphStyle* nowrapStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  [nowrapStyle setLineBreakMode:NSLineBreakByTruncatingTail];

  headingAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    headingFont, NSFontAttributeName,
    nowrapStyle, NSParagraphStyleAttributeName,
    nil];

  // Body (output context/matches) sans-wrapping
  bodyNowrapAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    bodyFont, NSFontAttributeName,
    [[nowrapStyle copy] autorelease], NSParagraphStyleAttributeName,
    nil];

  // Body (output context/matches) attributes
  NSMutableParagraphStyle* wrapStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  [wrapStyle setLineBreakMode:NSLineBreakByWordWrapping];

  // Force tabstops to be 2 characters wide
  CGFloat tabWidth = [@".." sizeWithAttributes:bodyNowrapAttributes].width;
  [wrapStyle setTabStops:[NSArray array]];
  [wrapStyle setDefaultTabInterval:tabWidth];

  bodyAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    bodyFont, NSFontAttributeName,
    wrapStyle, NSParagraphStyleAttributeName,
    nil];

  // Body highlight (matched character ranges) attributes
  bodyHighlightAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
    boldBodyFont, NSFontAttributeName,
    [NSColor colorWithCalibratedRed:(255.0/255.0) green:(225.0/255.0) blue:(68.0/255.0) alpha:1.0], NSBackgroundColorAttributeName,
    nil];

  // Make sure the table is using our chosen font
  for (NSTableColumn* tc in [resultView tableColumns])
    [[tc dataCell] setFont:bodyFont];

  // Precalculate a few row heights:
  headerHeight = RESULT_ROW_PADDING + (RESULT_TEXT_YINSET * 2) + [@"Jiminy!" sizeWithAttributes:headingAttributes].height;
  contextBreakHeight = (RESULT_TEXT_YINSET * 2) + [@"Jiminy!" sizeWithAttributes:bodyAttributes].height;
}

- (void)dealloc
{
  [searchRoot release], searchRoot = nil;
  [resultStats release], resultStats = nil;
  [resultRows release], resultRows = nil;
  [longestLineNumber release], longestLineNumber = nil;

  [headingAttributes release], headingAttributes = nil;
  [bodyAttributes release], bodyAttributes = nil;
  [bodyNowrapAttributes release], bodyNowrapAttributes = nil;
  [bodyHighlightAttributes release], bodyHighlightAttributes = nil;

  [super dealloc];
}
@end
