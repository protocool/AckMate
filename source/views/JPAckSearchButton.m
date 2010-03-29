// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckSearchButton.h"

@implementation JPAckSearchButton

- (BOOL)performKeyEquivalent:(NSEvent*)event
{
  if ([[event charactersIgnoringModifiers] isEqualToString:[self keyEquivalent]] && ([event modifierFlags] & NSCommandKeyMask))
  {
    [self performClick:nil];
    return YES;
  }

  return [super performKeyEquivalent:event];
}

@end
