// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

@interface JPAckResultTableView : NSTableView {
  BOOL _isDrawingStickyRow;
}

- (NSInteger)spanningColumnForRow:(NSInteger)rowIndex;

@end

@interface NSObject (JPAckResultTableViewDelegate)
- (BOOL)tableView:(NSTableView *)tableView activateSelectedRow:(NSInteger)row;
- (NSInteger)tableView:(NSTableView *)tableView spanningColumnForRow:(NSInteger)row;
@end
