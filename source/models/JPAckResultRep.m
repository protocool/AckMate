// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckResultRep.h"

@interface JPAckResultRep ()
- (id)initWithResultObject:(JPAckResult*)resultObject_ parent:(JPAckResult*)parentObject_ alternate:(BOOL)alternate_;
@end;

@implementation JPAckResultRep
@synthesize parentObject;
@synthesize resultObject;

@synthesize constrainedWidth;
@synthesize calculatedHeight;
@synthesize alternate;

+ (id)withResultObject:(JPAckResult*)ro parent:(JPAckResult*)po alternate:(BOOL)alt
{
  return [[[JPAckResultRep alloc] initWithResultObject:ro parent:po alternate:alt] autorelease];
}

+ (id)withResultObject:(JPAckResult*)ro alternate:(BOOL)alt
{
  return [[[JPAckResultRep alloc] initWithResultObject:ro parent:nil alternate:alt] autorelease];
}

- (id)initWithResultObject:(JPAckResult*)resultObject_ parent:(JPAckResult*)parentObject_ alternate:(BOOL)alternate_
{
  if (self = [super init])
  {
    parentObject = [parentObject_ retain];
    resultObject = [resultObject_ retain];
    alternate = alternate_;
  }
  return self;
}

- (NSString*)description
{
  return resultObject.lineContent;
}

- (JPAckResultType)resultType
{
  return resultObject.resultType;
}

- (void)dealloc
{
  [parentObject release], parentObject = nil;
  [resultObject release], resultObject = nil;
  [super dealloc];
}

@end
