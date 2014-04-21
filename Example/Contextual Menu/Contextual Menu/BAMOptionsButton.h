//
//  BAMOptionsButton.h
//  Contextual Menu
//
//  Created by Hector on 4/19/14.
//  Copyright (c) 2014 CodeNinja. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BAMOptionsButton : UIButton

@property (nonatomic) BOOL optionSelected;
@property (nonatomic) NSUInteger index;

- (void)selectOption:(BOOL)selectOption;

@end
