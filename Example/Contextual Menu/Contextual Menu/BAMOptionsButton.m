//
//  BAMOptionsButton.m
//  Contextual Menu
//
//  Created by Hector on 4/19/14.
//  Copyright (c) 2014 CodeNinja. All rights reserved.
//

#import "BAMOptionsButton.h"

@interface BAMOptionsButton ()

@end

@implementation BAMOptionsButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)selectOption:(BOOL)selectOption
{
	self.optionSelected = selectOption;
	
	if (selectOption) {
		self.layer.borderColor = [UIColor whiteColor].CGColor;
		self.layer.borderWidth = 2.0;
	} else {
		self.layer.borderColor = [UIColor clearColor].CGColor;
		self.layer.borderWidth = 0.0;
	}
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
	[super setBackgroundImage:image forState:state];
	[super setBackgroundImage:image forState:UIControlStateHighlighted];
	[super setBackgroundImage:image forState:UIControlStateSelected];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
