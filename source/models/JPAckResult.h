// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

enum {
  JPResultTypeError = 0,
  JPResultTypeFilename,
  JPResultTypeMatchingLine,
  JPResultTypeContext,
  JPResultTypeContextBreak
};
typedef NSInteger JPAckResultType;

@interface JPAckResult : NSObject {
  JPAckResultType resultType;
  NSString* lineNumber;
  NSString* lineContent;
  NSArray* matchRanges;
}
@property(nonatomic, readonly) JPAckResultType resultType;
@property(nonatomic, readonly) NSString* lineNumber;
@property(nonatomic, readonly) NSString* lineContent;
@property(nonatomic, readonly) NSArray* matchRanges;

+ (id)resultErrorWithString:(NSString*)errorString;
+ (id)resultFileWithName:(NSString*)fileName;
+ (id)resultContextBreak;
+ (id)resultContextLineWithNumber:(NSString*)ln content:(NSString*)lc;
+ (id)resultMatchingLineWithNumber:(NSString*)ln content:(NSString*)lc ranges:(NSArray*)mr;

@end
