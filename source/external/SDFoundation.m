//
//  SDFoundation.m
//  SDToolkit
//
//  Created by Steven Degutis on 6/14/09.
//  Copyright 2009 Steven Degutis Software. All rights reserved.
//

#import "SDFoundation.h"


void SDDivideRect(NSRect inRect, NSRect* slice, NSRect* rem, CGFloat amount, NSRectEdge edge) {
	NSRect temp;
	NSRect* slice2 = (slice ? slice : &temp);
	NSRect* rem2 = (rem ? rem : &temp);
	NSDivideRect(inRect, slice2, rem2, amount, edge);
}
