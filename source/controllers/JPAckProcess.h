// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

@class JPAckResultSource;
extern NSString * const JPAckProcessComplete;

@interface JPAckProcess : NSObject {
  NSMutableData* trailing;
  NSMutableData* errorData;
  JPAckResultSource* ackResult;
  NSTask* ackTask;
  NSInteger ackState;
}

- (id)initWithResultHolder:(JPAckResultSource*)resultHolder;
- (void)invokeWithTerm:(NSString*)term path:(NSString*)path searchFolder:(NSString*)searchFolder literal:(BOOL)literal nocase:(BOOL)nocase words:(BOOL)words context:(BOOL)context symlinks:(BOOL)symlinks folderPattern:(NSString*)folderPattern options:(NSArray*)options;

- (void)parseData:(NSData*)data;
- (void)saveTrailing:(char*)bytes length:(NSUInteger)length;

- (void)terminate;

@end
