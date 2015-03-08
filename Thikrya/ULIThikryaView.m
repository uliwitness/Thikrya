//
//  ULIThikryaView.m
//  Thikrya
//
//  Created by Uli Kusterer on 2014-05-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "ULIThikryaView.h"


@interface ULIThikryaView ()
{
	BOOL		isFirstResponder;
	NSInteger	editedCapsule;
	NSRange		selectedRange;
	NSTimer*	insertionMarkTimer;
	BOOL		insertionMarkVisible;
}

@end


@implementation ULIThikryaCapsule

-(id)	init
{
	self = [super init];
	if( self )
	{
		self.name = @"";
	}
	return self;
}

-(void)	drawInRect: (NSRect)inBox selected: (BOOL)isSelected selectedRange: (NSRange)selectedRange insertionMarkVisible: (BOOL)insertionMarkVisible
{
	[[NSColor lightGrayColor] set];
	[NSBezierPath fillRect: inBox];
	
	if( isSelected )
	{
		[[NSColor keyboardFocusIndicatorColor] set];
	}
	else
	{
		[[NSColor darkGrayColor] set];
	}
	[NSBezierPath strokeRect: inBox];
	
	NSDictionary				*	attrs = @{ NSFontAttributeName: [NSFont fontWithName: @"Avenir Next" size: 16] };
	NSMutableAttributedString	*	attrStr = [[NSMutableAttributedString alloc] initWithString: self.name attributes: attrs];
	NSPoint							textPos = NSMakePoint(NSMinX(inBox) +12,NSMinY(inBox));
	if( isSelected )
	{
		if( selectedRange.length > 0 )
		{
			[attrStr addAttribute: NSBackgroundColorAttributeName value: [NSColor selectedTextBackgroundColor] range: selectedRange];
			[attrStr addAttribute: NSForegroundColorAttributeName value: [NSColor selectedTextColor] range: selectedRange];
		}
		else if( insertionMarkVisible )
		{
			NSSize	beforeSelectionSize = [[self.name substringToIndex: selectedRange.location] sizeWithAttributes: attrs];
			[NSColor.blackColor set];
			CGFloat	xpos = truncf(textPos.x +beforeSelectionSize.width) +0.5;
			[NSBezierPath strokeLineFromPoint: NSMakePoint( xpos, textPos.y) toPoint:NSMakePoint(xpos, textPos.y +beforeSelectionSize.height)];
		}
	}
	[attrStr drawAtPoint: textPos];
}

@end


@implementation ULIThikryaView

-(id)	initWithFrame: (NSRect)frame
{
	self = [super initWithFrame: frame];
	if( self )
	{
		self.capsules = [NSMutableArray array];
		[self.capsules addObject: [ULIThikryaCapsule new]];
		
		insertionMarkTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(toggleInsertionMark:) userInfo: nil repeats: YES];
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if( self )
	{
		self.capsules = [NSMutableArray array];
		[self.capsules addObject: [ULIThikryaCapsule new]];
	}
	return self;
}


-(void)	toggleInsertionMark: (NSTimer*)sender
{
	insertionMarkVisible = !insertionMarkVisible;
	[self setNeedsDisplay: YES];
}


-(void)	drawRect: (NSRect)dirtyRect
{
	NSRect		box = self.bounds;
	NSRect		selectedRect = NSZeroRect;
	
	box.size.height = 32;
	
	NSInteger	idx = 0;
	for( ULIThikryaCapsule* currCapsule in self.capsules )
	{
		BOOL	isSelected = (idx++) == editedCapsule && isFirstResponder;
		[currCapsule drawInRect: box selected: isSelected selectedRange: selectedRange insertionMarkVisible: insertionMarkVisible];
		if( isSelected )
			selectedRect = box;
		box.origin.y += box.size.height;
	}
	
	[NSColor.keyboardFocusIndicatorColor set];
	[NSBezierPath setDefaultLineWidth: 2];
	[NSBezierPath setDefaultLineJoinStyle: NSRoundLineJoinStyle];
	[NSBezierPath strokeRect: NSInsetRect(selectedRect,1,1)];
	[NSBezierPath setDefaultLineWidth: 1];
	[NSBezierPath setDefaultLineJoinStyle: NSMiterLineJoinStyle];
}


-(void)	mouseDown: (NSEvent *)theEvent
{
	NSPoint	pos = [self convertPoint: theEvent.locationInWindow fromView: nil];
	
	NSRect		box = self.bounds;
	box.size.height = 32;
	
	editedCapsule = NSNotFound;
	NSInteger	idx = 0, count = self.capsules.count;
	for( idx = 0; idx < count; idx++ )
	{
		if( NSPointInRect( pos, box) )
			editedCapsule = idx;
		box.origin.y += box.size.height;
	}
	
	if( editedCapsule == NSNotFound )	// Click below existing rows?
	{
		[self.capsules addObject: [ULIThikryaCapsule new]];
		editedCapsule = count;
	}
	selectedRange = NSMakeRange( [self.capsules[editedCapsule] name].length, 0 );
	
	[self setNeedsDisplay: YES];
}


-(void)	keyDown: (NSEvent *)theEvent
{
	[self interpretKeyEvents: @[theEvent]];
}


-(void)	deleteBackward: (id)sender
{
	ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
	NSString			*	oldName = caps.name;
	if( oldName.length == 0 )
	{
		[self.capsules removeObjectAtIndex: editedCapsule];
		if( editedCapsule > 0 )
			editedCapsule--;
		selectedRange = NSMakeRange( [self.capsules[editedCapsule] name].length, 0 );
	}
	else if( selectedRange.length == 0 && (selectedRange.location > 0) )
	{
		selectedRange = [oldName rangeOfComposedCharacterSequenceAtIndex: selectedRange.location -1];
		
		NSString			*	newName = [oldName stringByReplacingCharactersInRange: selectedRange withString: @""];
		caps.name = newName;
		selectedRange.length = 0;
	}
	else
	{
		NSString			*	newName = [oldName stringByReplacingCharactersInRange: selectedRange withString: @""];
		caps.name = newName;
		selectedRange.length = 0;
	}
}


-(void)	deleteForward: (id)sender
{
	ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
	NSString			*	oldName = caps.name;
	if( oldName.length == 0 )
	{
		[self.capsules removeObjectAtIndex: editedCapsule];
		if( editedCapsule >= self.capsules.count )
			editedCapsule = self.capsules.count -1;
		selectedRange = NSMakeRange( [self.capsules[editedCapsule] name].length, 0 );
	}
	else if( selectedRange.length == 0 && (selectedRange.location < oldName.length) )
	{
		selectedRange = [oldName rangeOfComposedCharacterSequenceAtIndex: selectedRange.location];
		
		NSString			*	newName = [oldName stringByReplacingCharactersInRange: selectedRange withString: @""];
		caps.name = newName;
		selectedRange.length = 0;
	}
	else
	{
		NSString			*	newName = [oldName stringByReplacingCharactersInRange: selectedRange withString: @""];
		caps.name = newName;
		selectedRange.length = 0;
	}
}


-(void)	moveLeft:(id)sender
{
	ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
	if( selectedRange.length > 0 )
		selectedRange.length = 0;
	else if( selectedRange.location > 0 )
	{
		selectedRange.location--;
		selectedRange.location = [caps.name rangeOfComposedCharacterSequenceAtIndex: selectedRange.location].location;	// Make sure we didn't just jump half a 4-byte Unicode character backwards.
	}
	else if( selectedRange.location == 0 && editedCapsule > 0 )
	{
		editedCapsule --;
		selectedRange.length = 0;
		selectedRange.location = [self.capsules[editedCapsule] name].length;
	}
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(void)	moveRight:(id)sender
{
	ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
	if( selectedRange.length > 0 )
	{
		selectedRange.location += selectedRange.length;
		selectedRange.length = 0;
	}
	else if( (selectedRange.location +selectedRange.length) < caps.name.length )
	{
		NSRange	sequenceRange = [caps.name rangeOfComposedCharacterSequenceAtIndex: selectedRange.location];	// Determine length of character in case it was a 4-byte sequence like an Emoji.
		selectedRange.location = sequenceRange.location +sequenceRange.length;
	}
	else if( editedCapsule < (self.capsules.count -1) )
	{
		editedCapsule ++;
		selectedRange.location = 0;
		selectedRange.length = 0;
	}
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(void)	moveUp:(id)sender
{
	if( editedCapsule > 0 )
	{
		editedCapsule --;
		if( (selectedRange.location +selectedRange.length) >= [self.capsules[editedCapsule] name].length )
		{
			selectedRange.location = [self.capsules[editedCapsule] name].length;
			selectedRange.length = 0;
		}
		else
		{
			ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
			selectedRange.location = [caps.name rangeOfComposedCharacterSequenceAtIndex: selectedRange.location].location;	// Make sure we didn't just jump into the middle of a 4-byte Unicode character.
		}
	}
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(void)	moveDown:(id)sender
{
	if( editedCapsule < (self.capsules.count -1) )
	{
		editedCapsule ++;
		if( (selectedRange.location +selectedRange.length) >= [self.capsules[editedCapsule] name].length )
		{
			selectedRange.location = [self.capsules[editedCapsule] name].length;
			selectedRange.length = 0;
		}
		else
		{
			ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
			selectedRange.location = [caps.name rangeOfComposedCharacterSequenceAtIndex: selectedRange.location].location;	// Make sure we didn't just jump into the middle of a 4-byte Unicode character.
		}
	}
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(void)	insertNewline:(id)sender
{
	[self.capsules insertObject: [ULIThikryaCapsule new] atIndex: editedCapsule +1];
	editedCapsule++;
	selectedRange = NSMakeRange( [self.capsules[editedCapsule] name].length, 0 );
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(void)	insertText: (NSString*)insertString
{
	ULIThikryaCapsule	*	caps = self.capsules[editedCapsule];
	
	NSString			*	oldName = caps.name;
	NSString			*	newName = [oldName stringByReplacingCharactersInRange: selectedRange withString: insertString];
	caps.name = newName;
	selectedRange.length = 0;
		selectedRange.location += insertString.length;
	
	insertionMarkVisible = YES;
	[self setNeedsDisplay: YES];
}


-(NSRange)	markedRange
{
	return selectedRange;
}


-(BOOL)	hasMarkedText
{
	return NO;
}


-(NSRange)	selectedRange
{
	return selectedRange;
}


-(void)	setMarkedText:(id)inString
        selectedRange:(NSRange)inSelectedRange
     replacementRange:(NSRange)inReplacementRange
{
//	selectedRange = inSelectedRange;
	
}


-(void)	unmarkText
{

}


-(NSArray *)	validAttributesForMarkedText
{
	return @[];
}


-(NSAttributedString *)	attributedSubstringForProposedRange:(NSRange)aRange
                                                actualRange:(NSRangePointer)actualRange
{
	NSString*	str = [self.capsules[editedCapsule] name];
	if( (aRange.location +aRange.length) > str.length )
		return nil;
	return [[NSAttributedString alloc] initWithString: [str substringWithRange: aRange] attributes: @{}];
}


-(void)	insertText: (id)aString replacementRange: (NSRange)replacementRange
{
	BOOL	moveCursor = NO;
	if( replacementRange.location == NSNotFound )
	{
		replacementRange = selectedRange;
		moveCursor = YES;
	}
	NSString*	str = [self.capsules[editedCapsule] name];
	str = [str stringByReplacingCharactersInRange: replacementRange withString: aString];
	[(ULIThikryaCapsule*)self.capsules[editedCapsule] setName: str];
	
	if( moveCursor )
	{
		selectedRange.location += [aString length];
		selectedRange.length = 0;
	}
	
	[self setNeedsDisplay: YES];
}


-(NSUInteger)	characterIndexForPoint:(NSPoint)aPoint
{
	return NSNotFound;
}


-(NSRect)	firstRectForCharacterRange: (NSRange)aRange actualRange: (NSRangePointer)actualRange
{
	return NSZeroRect;
}


-(void)	doCommandBySelector: (SEL)aSelector
{
	if( [self respondsToSelector: aSelector] )
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    	// We know aSelector is a void return, and this warning complains about not knowing
		//	the return type, so it's erroneous in this case. If it wasn't, we'd have to
		//	somehow explicitly release it.
		[self performSelector: aSelector withObject: self];
#pragma clang diagnostic pop
	}
}


-(BOOL)	isFlipped
{
	return YES;
}


-(BOOL)	acceptsFirstResponder
{
	return YES;
}


-(BOOL)	becomeFirstResponder
{
	isFirstResponder = YES;
	[self setNeedsDisplay: YES];
	return YES;
}


-(BOOL)	resignFirstResponder
{
	isFirstResponder = NO;
	[self setNeedsDisplay: YES];
	return YES;
}

@end
