// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

@class JPAckResult;
@class JPAckWindowController;

@interface JPAckResultSource : NSObject {
  NSUInteger matchedFiles;
  NSUInteger matchedLines;
  NSMutableArray* resultLines;

  NSDictionary* headingAttributes;
  NSDictionary* bodyAttributes;
  NSDictionary* bodyNowrapAttributes;
  NSDictionary* bodyHighlightAttributes;

  IBOutlet NSTableView* resultView;
  IBOutlet JPAckWindowController* windowController;

  JPAckResult* currentResultFile;

  NSString* resultStats;
  NSString* searchRoot;
  BOOL alternateRow;
  
  NSString* longestLineNumber;

  CGFloat headerHeight;
  CGFloat contextBreakHeight;
}

@property(nonatomic, copy) NSString* searchRoot;
@property(nonatomic, readonly) NSUInteger matchedFiles;
@property(nonatomic, readonly) NSUInteger matchedLines;
@property(nonatomic, copy, readonly) NSString* resultStats;

- (void)clearContents;
- (void)updateStats;
- (void)parsedError:(NSString*)errorString;
- (void)parsedFilename:(NSString*)filename;
- (void)parsedContextLine:(NSString*)lineNumber content:(NSString*)content;
- (void)parsedMatchLine:(NSString*)lineNumber ranges:(NSArray*)ranges content:(NSString*)content;
- (void)parsedContextBreak;

- (BOOL)tableView:(NSTableView *)tableView isStickyRow:(NSInteger)row;

@end
