// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

@protocol TMPlugInController
- (float)version;
@end

@interface AckMatePlugin : NSObject
{
  NSMutableDictionary* ackWindows;
  NSMutableDictionary* ackPreferences;
}
- (id)initWithPlugInController:(id <TMPlugInController>)aController;
@end