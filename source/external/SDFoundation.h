//
//  SDFoundation.h
//  SDToolkit
//
//  Created by Steven Degutis on 6/14/09.
//  Copyright 2009 Steven Degutis Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// either slice or rem can be NULL.
void SDDivideRect(NSRect inRect, NSRect* slice, NSRect* rem, CGFloat amount, NSRectEdge edge);
