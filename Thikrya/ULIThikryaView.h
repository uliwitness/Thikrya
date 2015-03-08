//
//  ULIThikryaView.h
//  Thikrya
//
//  Created by Uli Kusterer on 2014-05-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ULIThikryaCapsule : NSObject

@property (strong) NSString*	name;

-(void)	drawInRect: (NSRect)inBox selected: (BOOL)isSelected selectedRange: (NSRange)selectedRange insertionMarkVisible: (BOOL)insertionMarkVisible;

@end


@interface ULIThikryaView : NSView <NSTextInputClient>

@property (retain) NSMutableArray*	capsules;

@end
