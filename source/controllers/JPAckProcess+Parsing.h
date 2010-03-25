// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>
#import "JPAckProcess.h"

@interface JPAckProcess (Parsing)
- (void)consumeInputLines:(NSData*)data;
@end
