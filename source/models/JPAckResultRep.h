// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>
#import "JPAckResult.h"

@interface JPAckResultRep: NSObject {
  JPAckResultRep* parentObject;
  JPAckResult* resultObject;
  NSMutableArray* childObjects;
  
  CGFloat constrainedWidth;
  CGFloat calculatedHeight;
  BOOL alternate;
  BOOL collapsed;
}
@property(nonatomic, readonly) JPAckResultRep* parentObject;
@property(nonatomic, readonly) JPAckResult* resultObject;

@property(nonatomic, assign) CGFloat constrainedWidth;
@property(nonatomic, assign) CGFloat calculatedHeight;
@property(nonatomic, readonly) BOOL alternate;
@property(nonatomic, assign) BOOL collapsed;

+ (id)withResultObject:(JPAckResult*)ro parent:(JPAckResultRep*)po alternate:(BOOL)alt;
+ (id)withResultObject:(JPAckResult*)ro alternate:(BOOL)alt;

- (NSArray*)children;
- (void)addChild:(JPAckResultRep*)childObject;

- (JPAckResultType)resultType;
@end
