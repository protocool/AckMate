// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

extern NSString * const JPAckTypesProcessComplete;
extern NSString * const kJPAckTypesResult;

@interface JPAckTypesProcess : NSObject {
  NSMutableData* typesData;
  NSMutableData* errorData;
  NSTask* ackTask;
  NSInteger ackState;
}

- (void)invokeWithPath:(NSString*)path options:(NSArray*)options;
- (void)terminate;

@end
