// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckResultRep.h"

@interface JPAckResultRep ()
- (id)initWithResultObject:(JPAckResult*)resultObject_ parent:(JPAckResultRep*)parentObject_ alternate:(BOOL)alternate_;
@end;

@implementation JPAckResultRep
@synthesize parentObject;
@synthesize resultObject;

@synthesize constrainedWidth;
@synthesize calculatedHeight;
@synthesize alternate;
@synthesize collapsed;

+ (id)withResultObject:(JPAckResult*)ro parent:(JPAckResultRep*)po alternate:(BOOL)alt
{
  return [[[JPAckResultRep alloc] initWithResultObject:ro parent:po alternate:alt] autorelease];
}

+ (id)withResultObject:(JPAckResult*)ro alternate:(BOOL)alt
{
  return [[[JPAckResultRep alloc] initWithResultObject:ro parent:nil alternate:alt] autorelease];
}

- (id)initWithResultObject:(JPAckResult*)resultObject_ parent:(JPAckResultRep*)parentObject_ alternate:(BOOL)alternate_
{
  if (self = [super init])
  {
    parentObject = [parentObject_ retain];
    resultObject = [resultObject_ retain];
    alternate = alternate_;

    if (parentObject)
      [parentObject addChild:self];
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

- (NSArray*)children
{
  return childObjects;
}

- (void)addChild:(JPAckResultRep*)childObject
{
  if (!childObjects)
    childObjects = [[NSMutableArray alloc] initWithCapacity:1];

  [childObjects addObject:childObject];
}

- (void)dealloc
{
  [parentObject release], parentObject = nil;
  [resultObject release], resultObject = nil;
  [childObjects release], childObjects = nil;
  [super dealloc];
}

@end
