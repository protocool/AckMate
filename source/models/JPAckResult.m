// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckResult.h"

@interface JPAckResult ()
- (id)initWithType:(JPAckResultType)resultType_ lineNumber:(NSString*)lineNumber_ content:(NSString*)lineContent_ ranges:(NSArray*)matchRanges_;
@end

@implementation JPAckResult
@synthesize resultType;
@synthesize lineNumber;
@synthesize lineContent;
@synthesize matchRanges;

+ (id)resultErrorWithString:(NSString*)errorString
{
  return [[[JPAckResult alloc] initWithType:JPResultTypeError lineNumber:nil content:errorString ranges:nil ] autorelease];
}

+ (id)resultFileWithName:(NSString*)fileName_
{
  NSString* fileName = ([fileName_ hasPrefix:@"/"]) ? [fileName_ substringFromIndex:1] : fileName_; // blech
  return [[[JPAckResult alloc] initWithType:JPResultTypeFilename lineNumber:nil content:fileName ranges:nil ] autorelease];
}

+ (id)resultContextBreak
{
  return [[[JPAckResult alloc] initWithType:JPResultTypeContextBreak lineNumber:nil content:nil ranges:nil ] autorelease];
}

+ (id)resultContextLineWithNumber:(NSString*)ln content:(NSString*)lc
{
  return [[[JPAckResult alloc] initWithType:JPResultTypeContext lineNumber:ln content:lc ranges:nil] autorelease];
}

+ (id)resultMatchingLineWithNumber:(NSString*)ln content:(NSString*)lc ranges:(NSArray*)mr
{
  return [[[JPAckResult alloc] initWithType:JPResultTypeMatchingLine lineNumber:ln content:lc ranges:mr] autorelease];
}

- (id)initWithType:(JPAckResultType)resultType_ lineNumber:(NSString*)lineNumber_ content:(NSString*)lineContent_ ranges:(NSArray*)matchRanges_
{
  if (self = [super init])
  {
    resultType = resultType_;
    lineNumber = [lineNumber_ copy];
    lineContent = [lineContent_ copy];
    matchRanges = [matchRanges_ copy];
  }
  return self;
}

- (void)dealloc
{
  [lineNumber release], lineNumber = nil;
  [lineContent release], lineContent = nil;
  [matchRanges release], matchRanges = nil;
  [super dealloc];
}

@end
