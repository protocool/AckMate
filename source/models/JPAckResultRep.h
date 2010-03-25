// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>
#import "JPAckResult.h"

@interface JPAckResultRep: NSObject {
  JPAckResult* parentObject;
  JPAckResult* resultObject;

  CGFloat constrainedWidth;
  CGFloat calculatedHeight;
  BOOL alternate;
}
@property(nonatomic, readonly) JPAckResult* parentObject;
@property(nonatomic, readonly) JPAckResult* resultObject;

@property(nonatomic, assign) CGFloat constrainedWidth;
@property(nonatomic, assign) CGFloat calculatedHeight;
@property(nonatomic, readonly) BOOL alternate;

+ (id)withResultObject:(JPAckResult*)ro parent:(JPAckResult*)po alternate:(BOOL)alt;
+ (id)withResultObject:(JPAckResult*)ro alternate:(BOOL)alt;

- (JPAckResultType)resultType;
@end
