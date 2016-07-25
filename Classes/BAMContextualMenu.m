//
//  HMContextualMenuItem.m
//
//  Created by Hector Matos on 4/2/14.
//
//	Copyright (c) 2014 Hector Matos <hectormatos2011@gmail.com>
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "BAMContextualMenu.h"

//Circle View Constants
#define circleViewWidthHeight					50.0f
#define startCircleStrokeWidth					4.0f
#define defaultTotalAmountOfCirclesThatCanFit	6
#define topAndBottomTitleLabelPadding			5.0
#define titleLabelPadding						2.5
#define tapHighlightInset						-30.0

//Helpful Macros
#define radiansToDegrees(radians)			((radians) * (180.0 / M_PI))
#define degreesToRadians(degrees)			((degrees) * (M_PI / 180.0))
#define stringIsValid(string)				(string && ![string isEqualToString:@""])

#pragma mark HMContextualMenu Implementation

@interface BAMContextualMenu () <UIGestureRecognizerDelegate>
{
	CGPoint startingLocation;
	
	NSMutableArray *contextualMenuItems;
	NSMutableArray *highlightedMenuItems;
	NSMutableArray *defaultSelectedBackgroundViews;
	NSMutableArray *contextualMenuTitleViews;
	NSMutableArray *menuItemRectsInRootViewArray;
	
	UIView *shadowView;
	
	UIView *currentlyHighlightedMenuItem;
	UIView *startCircleView;
	
	UIView *rootView;
	
	CGFloat menuItemsCenterRadius;
	CGFloat biggestMenuItemWidthHeight;
	CGFloat currentStatusBarHeight;
	
	//properties used to calculate angle offset
	CGSize firstIndexTitleViewSize;
	CGSize lastIndexTitleViewSize;
	CGSize biggestTitleViewSize;
	CGFloat angleOffset;
	CGFloat angleIncrement;
	CGFloat defaultStartingAngle;
	CGFloat highlightRadiusOffset;
	
	NSUInteger startingTouchIndex;
	CGRect startingTouchMenuRect;
	UIView *startTapMenuItem;
	
	NSInteger startingLocationIndexOffset;
	NSInteger currentlyHighlightedMenuItemIndex;
	NSInteger totalAmountOfCirclesThatCanFit;
	
	UITapGestureRecognizer *tapGestureRecognizer;
	UILongPressGestureRecognizer *shadowGestureRecognizer;
	UILongPressGestureRecognizer *longPressActivationGestureRecognizer;
	
	BOOL shouldRelayoutSubviews;
	BOOL menuItemIsAnimating;
	BOOL shouldSelectMenuItem;
}

@property (nonatomic, weak) id <BAMContextualMenuDelegate> delegate;
@property (nonatomic, weak) id <BAMContextualMenuDataSource> dataSource;
@property (nonatomic, weak) UIView *containerView;

@end

@implementation BAMContextualMenu

#pragma mark Initialization Methods
- (id)initWithContainingView:(UIView *)containingView activateOption:(BAMContextualMenuActivateOption)startActivateOption delegate:(id <BAMContextualMenuDelegate>)contextualDelegate andDataSource:(id <BAMContextualMenuDataSource>)contextualDataSource
{
	self = [super init];
	if (self) {
		self.delegate = contextualDelegate;
		self.dataSource = contextualDataSource;
		self.shouldHighlightOutwards = YES;
		
		_menuIsShowing = NO;
		
		_menuItemDistancePadding = 30.0f;
		
		shouldRelayoutSubviews = YES;
		menuItemIsAnimating = NO;
		
		self.containerView = containingView;
		self.containerView.userInteractionEnabled = YES;
		
		biggestMenuItemWidthHeight = circleViewWidthHeight;
		angleOffset = 0.0;
		currentlyHighlightedMenuItemIndex = NSNotFound;
		
		//rootView = [[[[[UIApplication sharedApplication] delegate] window] rootViewController] view];
		rootView = [[UIApplication sharedApplication] windows][0];
		shadowView = [[UIView alloc] initWithFrame:rootView.bounds];
		shadowView.backgroundColor = [UIColor clearColor];
		shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		shadowView.alpha = 0.0f;
		
		startCircleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, circleViewWidthHeight, circleViewWidthHeight)];
		startCircleView.backgroundColor = [UIColor clearColor];
		startCircleView.layer.cornerRadius = circleViewWidthHeight / 2.0;
		startCircleView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.75f].CGColor;
		startCircleView.layer.borderWidth = startCircleStrokeWidth;
		[shadowView addSubview:startCircleView];
		
		self.activateOption = startActivateOption;
	}
	return self;
}

+ (BAMContextualMenu *)addContextualMenuToView:(UIView *)containingView delegate:(id<BAMContextualMenuDelegate>)delegate dataSource:(id<BAMContextualMenuDataSource>)dataSource activateOption:(BAMContextualMenuActivateOption)activateOption
{
	[BAMContextualMenu removeContextualMenuFromView:containingView];
	
	BAMContextualMenu *contextualMenu = [[BAMContextualMenu alloc] initWithContainingView:containingView activateOption:activateOption delegate:delegate andDataSource:dataSource];
	[containingView addSubview:contextualMenu];
	
	return contextualMenu;
}

+ (BAMContextualMenu *)contextualMenuForView:(UIView *)containingView
{
	for (UIView *subview in containingView.subviews) {
		if ([subview isKindOfClass:[BAMContextualMenu class]]) {
			return (BAMContextualMenu *)subview;
		}
	}
	return nil;
}

#pragma mark Setters

- (void)setShouldHighlightOutwards:(BOOL)shouldHighlightOutwards
{
	_shouldHighlightOutwards = shouldHighlightOutwards;
	
	if (shouldHighlightOutwards) {
		highlightRadiusOffset = 25.0f;
	} else {
		highlightRadiusOffset = 0.0f;
	}
}

- (void)setActivateOption:(BAMContextualMenuActivateOption)activateOption
{
	_activateOption = activateOption;
	
	if (longPressActivationGestureRecognizer) {
		[self.containerView removeGestureRecognizer:longPressActivationGestureRecognizer];
		longPressActivationGestureRecognizer = nil;
	}
	if (tapGestureRecognizer) {
		[self.containerView removeGestureRecognizer:tapGestureRecognizer];
		tapGestureRecognizer = nil;
	}
	if (shadowGestureRecognizer) {
		[shadowView removeGestureRecognizer:shadowGestureRecognizer];
		shadowGestureRecognizer = nil;
	}
	
	switch (_activateOption) {
		case kBAMContextualMenuActivateOptionLongPress: {
			longPressActivationGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressActivated:)];
			longPressActivationGestureRecognizer.delegate = self;
			[self.containerView addGestureRecognizer:longPressActivationGestureRecognizer];
			
			startCircleView.hidden = NO;
			break;
		}
		case kBAMContextualMenuActivateOptionTouchUp: {
			tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapActivated:)];
			tapGestureRecognizer.delegate = self;
			[self.containerView addGestureRecognizer:tapGestureRecognizer];
			
			shadowGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shadowViewGestureActivated:)];
			shadowGestureRecognizer.minimumPressDuration = 0.0001;
			shadowGestureRecognizer.delegate = self;
			[shadowView addGestureRecognizer:shadowGestureRecognizer];
			
			startCircleView.hidden = YES;
			break;
		}
		default:
			break;
	}
}

#pragma mark Gesture Recognizer Event Handlers
- (void)longPressActivated:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint gestureLocationInRootView = [gestureRecognizer locationInView:rootView];
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		startingLocation = gestureLocationInRootView;
		
		shadowView.frame = rootView.bounds;
		startCircleView.center = startingLocation;
		
		[self layoutMenuItemsIfNeeded];
	}
	
	if (!self.shouldActivateMenu) {
		return;
	}
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		currentStatusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden]) ? 0.0 : [[UIApplication sharedApplication] statusBarFrame].size.height;
		
		[rootView addSubview:shadowView];
		[rootView bringSubviewToFront:shadowView];
		
		[self showMenuItems:YES completion:nil];
	} else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		CGFloat innerCircleRectX = startingLocation.x - _menuItemDistancePadding;
		
		CGFloat innerCircleRadius = startingLocation.x - innerCircleRectX;
		CGFloat outerCircleRadius = innerCircleRadius + biggestMenuItemWidthHeight + circleViewWidthHeight;
		
		CGFloat angleOfGestureLocation = [self getAngleBetweenOrigin:startingLocation andSecondPoint:gestureLocationInRootView relativeToYAxis:YES];
		CGFloat distanceFromOrigin = [self calculateDistanceWithPoint:gestureLocationInRootView fromOrigin:startingLocation];
		
		if (distanceFromOrigin > innerCircleRadius + biggestMenuItemWidthHeight) {
			gestureLocationInRootView = [self circumferentialPointForViewWithRadius:innerCircleRadius + biggestMenuItemWidthHeight angle:angleOfGestureLocation andCenterPoint:startingLocation];
			distanceFromOrigin = innerCircleRadius + (biggestMenuItemWidthHeight / 2.0);
		}
		
		BOOL pointIsInsideInnerCircle = (distanceFromOrigin <= innerCircleRadius);
		BOOL pointIsInsideOuterCircle = !pointIsInsideInnerCircle && (distanceFromOrigin <= outerCircleRadius);
		
		if (pointIsInsideOuterCircle) {
			if (angleOfGestureLocation < (defaultStartingAngle - 180.0f)) {
				angleOfGestureLocation += 360.0f;
			}
			CGFloat circleLocationAnglePercentage = (defaultStartingAngle - angleOfGestureLocation) / 180.0f;
			NSInteger locationIndex = (NSInteger)(circleLocationAnglePercentage * (totalAmountOfCirclesThatCanFit-1));
			
			locationIndex = abs(locationIndex*2)-MIN(MAX(locationIndex, 0), 1);
			
			if (locationIndex < contextualMenuItems.count && locationIndex >= 0) {
				UIView *menuItem = [contextualMenuItems objectAtIndex:locationIndex];
				UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:locationIndex];
				UIView *titleView = [contextualMenuTitleViews objectAtIndex:locationIndex];
				
				[shadowView bringSubviewToFront:highlightedMenuItem];
				[shadowView bringSubviewToFront:menuItem];
				[shadowView bringSubviewToFront:titleView];
				
				if (currentlyHighlightedMenuItem && currentlyHighlightedMenuItem != menuItem) {
					//Unhighlight currently highlighted menu item
					CGPoint originalCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] withCircleRadius:menuItemsCenterRadius];
					[self animateMenuItem:currentlyHighlightedMenuItem atIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] toPoint:originalCenter highlighted:NO];
				}
				if (locationIndex != currentlyHighlightedMenuItemIndex) {
					//highlight menu item
					CGPoint highlightedCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:menuItem] withCircleRadius:menuItemsCenterRadius + highlightRadiusOffset];
					[self animateMenuItem:menuItem atIndex:locationIndex toPoint:highlightedCenter highlighted:YES];
				}
				currentlyHighlightedMenuItemIndex = locationIndex;
				currentlyHighlightedMenuItem = menuItem;
			} else {
				if (currentlyHighlightedMenuItem) {
					CGPoint originalCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] withCircleRadius:menuItemsCenterRadius];
					[self animateMenuItem:currentlyHighlightedMenuItem atIndex:currentlyHighlightedMenuItemIndex toPoint:originalCenter highlighted:NO];
				}
				currentlyHighlightedMenuItemIndex = NSNotFound;
			}
		} else {
			if (currentlyHighlightedMenuItem) {
				CGPoint originalCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] withCircleRadius:menuItemsCenterRadius];
				[self animateMenuItem:currentlyHighlightedMenuItem atIndex:currentlyHighlightedMenuItemIndex toPoint:originalCenter highlighted:NO];
			}
			currentlyHighlightedMenuItem = nil;
			currentlyHighlightedMenuItemIndex = NSNotFound;
		}
		
		startCircleView.center = gestureLocationInRootView;
	} else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		BOOL activateMenuItem = (currentlyHighlightedMenuItem && currentlyHighlightedMenuItemIndex != NSNotFound);
		
		if (activateMenuItem) {
			CGPoint originalCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] withCircleRadius:menuItemsCenterRadius];
			[self animateMenuItem:currentlyHighlightedMenuItem atIndex:currentlyHighlightedMenuItemIndex toPoint:originalCenter highlighted:NO];
			
			if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenu:didSelectItemAtIndex:)]) {
				[self.delegate contextualMenu:self didSelectItemAtIndex:currentlyHighlightedMenuItemIndex];
			}
			
			currentlyHighlightedMenuItem = nil;
			currentlyHighlightedMenuItemIndex = NSNotFound;
		}
		
		[self showMenuItems:NO completion:nil];
	} else {
		if (currentlyHighlightedMenuItem) {
			CGPoint originalCenter = [self calculateCenterForMenuItemAtIndex:[contextualMenuItems indexOfObject:currentlyHighlightedMenuItem] withCircleRadius:menuItemsCenterRadius];
			[self animateMenuItem:currentlyHighlightedMenuItem atIndex:currentlyHighlightedMenuItemIndex toPoint:originalCenter highlighted:NO];
		}
		currentlyHighlightedMenuItem = nil;
		currentlyHighlightedMenuItemIndex = NSNotFound;
		
		[self showMenuItems:NO completion:nil];
	}
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if (self.activateOption == kBAMContextualMenuActivateOptionTouchUp) {
		CGRect viewRect = self.containerView.frame;
		
		CGPoint touchLocation = point;
		CGPoint gestureLocationInRootView = [self.containerView convertPoint:point toView:rootView];
		
		startingLocation = CGPointMake((gestureLocationInRootView.x - touchLocation.x) + (viewRect.size.width / 2.0), (gestureLocationInRootView.y - touchLocation.y) + (viewRect.size.height / 2.0));
	}
	
	return [super hitTest:point withEvent:event];
}

- (void)tapActivated:(UIGestureRecognizer *)tapGesture
{
	startCircleView.center = startingLocation;
	
	[self layoutMenuItemsIfNeeded];
	
	if (!self.shouldActivateMenu) {
		return;
	}
	
	currentStatusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden]) ? 0.0 : [[UIApplication sharedApplication] statusBarFrame].size.height;
	
	[rootView addSubview:shadowView];
	
	[self showMenuItems:YES completion:nil];
}

- (void)shadowViewGestureActivated:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint touchLocation = [gestureRecognizer locationInView:rootView];
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		startingTouchIndex = [self indexAtPoint:touchLocation];
		shouldSelectMenuItem = (startingTouchIndex != NSNotFound);
		
		if (startingTouchIndex != NSNotFound) {
			startingTouchMenuRect = CGRectInset([[menuItemRectsInRootViewArray objectAtIndex:startingTouchIndex] CGRectValue], tapHighlightInset, tapHighlightInset);
			startTapMenuItem = [contextualMenuItems objectAtIndex:startingTouchIndex];
			
			[self animateMenuItem:startTapMenuItem atIndex:startingTouchIndex toPoint:startTapMenuItem.center highlighted:YES];
		}
	} else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		if (startingTouchIndex != NSNotFound) {
			if (shouldSelectMenuItem != CGRectContainsPoint(startingTouchMenuRect, touchLocation)) {
				shouldSelectMenuItem = CGRectContainsPoint(startingTouchMenuRect, touchLocation);
				[self animateMenuItem:startTapMenuItem atIndex:startingTouchIndex toPoint:startTapMenuItem.center highlighted:shouldSelectMenuItem];
			}
		}
	} else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		if (shouldSelectMenuItem) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenu:didSelectItemAtIndex:)] && startingTouchIndex != NSNotFound) {
				[self.delegate contextualMenu:self didSelectItemAtIndex:startingTouchIndex];
			}
			[self animateMenuItem:startTapMenuItem atIndex:startingTouchIndex toPoint:startTapMenuItem.center highlighted:NO];
			[self showMenuItems:NO completion:nil];
		} else {
			if (startingTouchIndex != NSNotFound && startTapMenuItem) {
				[self animateMenuItem:startTapMenuItem atIndex:startingTouchIndex toPoint:startTapMenuItem.center highlighted:NO];
			} else {
				[self showMenuItems:NO completion:nil];
			}
		}
	}
}

- (NSUInteger)indexAtPoint:(CGPoint)point
{
	NSInteger selectedIndex = NSNotFound;
	for (NSValue *value in menuItemRectsInRootViewArray) {
		CGRect menuRect = value.CGRectValue;
		
		if (CGRectContainsPoint(menuRect, point)) {
			selectedIndex = [menuItemRectsInRootViewArray indexOfObject:value];
			break;
		}
	}
	return selectedIndex;
}

#pragma mark Presentation/Dismissal Method
- (void)showMenuItems:(BOOL)show completion:(void (^)())completion
{
	_menuIsShowing = show;
	//totalCircle in this context means the circle from the starting location of the user's touch to the edge of the biggest menu item
	CGFloat totalCircleRectX = startingLocation.x - (circleViewWidthHeight / 2.0) - _menuItemDistancePadding - biggestMenuItemWidthHeight;
	CGFloat totalCircleRadius = startingLocation.x - totalCircleRectX;
	menuItemsCenterRadius = totalCircleRadius - (biggestMenuItemWidthHeight / 2.0);
	
	[menuItemRectsInRootViewArray removeAllObjects];
	
	if (show) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenuActivated:)]) {
			[self.delegate contextualMenuActivated:self];
		}
		//Calculate proper angle offset
		ZZScreenEdge screenCorner = (startingLocation.x < rootView.frame.size.width / 2.0) ? kZZScreenEdgeLeft : kZZScreenEdgeRight;
		
		if (startingLocation.y - totalCircleRadius - highlightRadiusOffset - titleLabelPadding - biggestTitleViewSize.height < currentStatusBarHeight) {
			//The highest possible y is past the top screen edge.
			screenCorner = screenCorner | kZZScreenEdgeTop;
		}
		[self calculateAngleOffsetForSide:screenCorner];
		
		NSInteger loopIndex = -1;
		for (UIView *menuItem in contextualMenuItems) {
			loopIndex++;
			
			menuItem.center = startingLocation;
			menuItem.alpha = 0.0;
			
			UIView *titleView = [contextualMenuTitleViews objectAtIndex:loopIndex];
			titleView.center = CGPointMake(menuItem.center.x, (titleView.frame.size.height / 2.0) + (menuItem.center.y - (menuItem.frame.size.height / 2.0)));
			
			UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:loopIndex];
			highlightedMenuItem.center = startingLocation;
			
			highlightedMenuItem.hidden = YES;
			menuItem.hidden = NO;
		}
		//Animations for presentation
		[UIView animateKeyframesWithDuration:0.3
									   delay:0.0
									 options:(UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewKeyframeAnimationOptionCalculationModeCubic)
								  animations:^{
									  [UIView addKeyframeWithRelativeStartTime:0.0
															  relativeDuration:1.0
																	animations:^{
																		shadowView.alpha = 1.0f;
																		[rootView bringSubviewToFront:shadowView];
																	}];
									  [UIView addKeyframeWithRelativeStartTime:0.0
															  relativeDuration:0.8
																	animations:^{
																		NSInteger index = -1;
																		for (UIView *menuItem in contextualMenuItems) {
																			index++;
																			
																			CGPoint menuItemCenter = [self calculateCenterForMenuItemAtIndex:index withCircleRadius:totalCircleRadius];
																			menuItem.center = menuItemCenter;
																			menuItem.alpha = 1.0;
																			
																			UIView *titleView = [contextualMenuTitleViews objectAtIndex:index];
																			titleView.center = CGPointMake(menuItem.center.x, (titleView.frame.size.height / 2.0) + (menuItem.center.y - (menuItem.frame.size.height / 2.0)));
																			
																			UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:index];
																			highlightedMenuItem.center = menuItem.center;
																		}
																	}];
									  [UIView addKeyframeWithRelativeStartTime:0.8
															  relativeDuration:0.2
																	animations:^{
																		NSInteger index = -1;
																		for (UIView *menuItem in contextualMenuItems) {
																			index++;
																			
																			CGPoint menuItemCenter = [self calculateCenterForMenuItemAtIndex:index withCircleRadius:menuItemsCenterRadius];
																			menuItem.center = menuItemCenter;
																			menuItem.alpha = 1.0;
																			
																			[menuItemRectsInRootViewArray addObject:[NSValue valueWithCGRect:menuItem.frame]];
																			
																			UIView *titleView = [contextualMenuTitleViews objectAtIndex:index];
																			titleView.center = CGPointMake(menuItem.center.x, (titleView.frame.size.height / 2.0) + (menuItem.center.y - (menuItem.frame.size.height / 2.0)));
																			
																			UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:index];
																			highlightedMenuItem.center = menuItem.center;
																		}
																	}];
								  }
								  completion:^(BOOL finished) {
									  if (completion) {
										  completion();
									  }
								  }];
	} else {
		if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenuDismissed:)]) {
			[self.delegate contextualMenuDismissed:self];
		}
		//Animations for dismissal
		[UIView animateKeyframesWithDuration:0.3
									   delay:0.0
									 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
								  animations:^{
									  [UIView addKeyframeWithRelativeStartTime:0.0f
															  relativeDuration:1.0f
																	animations:^{
																		shadowView.alpha = 0.0f;
																		
																		NSInteger index = -1;
																		for (UIView *menuItem in contextualMenuItems) {
																			index++;
																			menuItem.center = startingLocation;
																			menuItem.alpha = 0.0;
																			
																			UIView *titleView = [contextualMenuTitleViews objectAtIndex:index];
																			titleView.center = CGPointMake(menuItem.center.x, (titleView.frame.size.height / 2.0) + (menuItem.center.y - (menuItem.frame.size.height / 2.0)));
																			
																			UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:index];
																			highlightedMenuItem.center = menuItem.center;
																		}
																	}];
								  }
								  completion:^(BOOL finished) {
									  [shadowView removeFromSuperview];
									  if (completion) {
										  completion();
									  }
								  }];
	}
}

- (void)animateMenuItem:(UIView *)menuItem atIndex:(NSUInteger)index toPoint:(CGPoint)center highlighted:(BOOL)highlighted
{
	if (index == NSNotFound) {
		return;
	}
	menuItemIsAnimating = YES;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenu:didHighlightItemAtIndex:)] && highlighted) {
		[self.delegate contextualMenu:self didHighlightItemAtIndex:index];
	}
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(contextualMenu:didUnHighlightItemAtIndex:)] && !highlighted) {
		[self.delegate contextualMenu:self didUnHighlightItemAtIndex:index];
	}
	
	UIView *titleView = [contextualMenuTitleViews objectAtIndex:index];
	UIView *highlightedMenuItem = [highlightedMenuItems objectAtIndex:index];
	UIView *defaultSelectedBackgroundView;
	
	if (titleView) {
		[shadowView bringSubviewToFront:titleView];
	}
	
	BOOL shouldUseDefaultSelectedBackgroundView = (menuItem == highlightedMenuItem);
	
	if (menuItem && [menuItem isKindOfClass:[UIImageView class]]) {
		[(UIImageView *)menuItem setHighlighted:highlighted];
		if ([(UIImageView *)menuItem highlightedImage]) {
			shouldUseDefaultSelectedBackgroundView = NO;
		}
	}
	
	if (menuItem != highlightedMenuItem) {
		menuItem.hidden = highlighted;
		highlightedMenuItem.hidden = !highlighted;
	} else {
		if (shouldUseDefaultSelectedBackgroundView) {
			defaultSelectedBackgroundView = [defaultSelectedBackgroundViews objectAtIndex:index];
		}
	}
	
	CGFloat titleLabelCenterMultiplier = (highlighted) ? -1.0 : 1.0;
	CGFloat alpha = (highlighted) ? 1.0 : 0.0;
	CGFloat imageScaleGrow = 1.2;
	CGFloat imageScaleShrink = 0.8;
	
	[UIView animateKeyframesWithDuration:0.2
								   delay:0.0
								 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
							  animations:^{
								  defaultSelectedBackgroundView.alpha = alpha;
								  titleView.alpha = alpha;
								  [UIView addKeyframeWithRelativeStartTime:0.0
														  relativeDuration:1.0
																animations:^{
																	menuItem.center = center;
																	highlightedMenuItem.center = center;
																}];
								  [UIView addKeyframeWithRelativeStartTime:0.0
														  relativeDuration:0.7
																animations:^{
																	titleView.center = CGPointMake(center.x, (((titleView.frame.size.height / 2.0) + titleLabelPadding + 7.0) * titleLabelCenterMultiplier) + (center.y - (highlightedMenuItem.frame.size.height / 2.0)));
																}];
								  [UIView addKeyframeWithRelativeStartTime:0.7
														  relativeDuration:0.3
																animations:^{
																	titleView.center = CGPointMake(center.x, (((titleView.frame.size.height / 2.0) + titleLabelPadding) * titleLabelCenterMultiplier) + (center.y - (highlightedMenuItem.frame.size.height / 2.0)));
																}];
								  
								  //scale keyframes
								  if (highlighted) {
									  [UIView addKeyframeWithRelativeStartTime:0.0
															  relativeDuration:0.1
																	animations:^{
																		highlightedMenuItem.transform = CGAffineTransformScale(CGAffineTransformIdentity, imageScaleGrow, imageScaleGrow);
																	}];
									  [UIView addKeyframeWithRelativeStartTime:0.1
															  relativeDuration:0.5
																	animations:^{
																		highlightedMenuItem.transform = CGAffineTransformScale(CGAffineTransformIdentity, imageScaleShrink, imageScaleShrink);
																	}];
									  [UIView addKeyframeWithRelativeStartTime:0.6
															  relativeDuration:0.4
																	animations:^{
																		highlightedMenuItem.transform = CGAffineTransformIdentity;
																	}];
								  }
							  }
							  completion:^(BOOL finished) {
								  menuItemIsAnimating = NO;
							  }];
}

#pragma mark Menu Item Layout Methods

- (void)layoutMenuItemsIfNeeded
{
	if (!shouldRelayoutSubviews) {
		return;
	}
	shouldRelayoutSubviews = NO;
	
	if (!contextualMenuItems) {
		contextualMenuItems = [NSMutableArray array];
	}
	if (!highlightedMenuItems) {
		highlightedMenuItems = [NSMutableArray array];
	}
	if (!defaultSelectedBackgroundViews) {
		defaultSelectedBackgroundViews = [NSMutableArray array];
	}
	if (!contextualMenuTitleViews) {
		contextualMenuTitleViews = [NSMutableArray array];
	}
	if (!menuItemRectsInRootViewArray) {
		menuItemRectsInRootViewArray = [NSMutableArray array];
	}
	
	[contextualMenuItems removeAllObjects];
	[highlightedMenuItems removeAllObjects];
	[defaultSelectedBackgroundViews removeAllObjects];
	[contextualMenuTitleViews removeAllObjects];
	[menuItemRectsInRootViewArray removeAllObjects];
	
	for (UIView *subview in shadowView.subviews) {
		if (subview != startCircleView) {
			[subview removeFromSuperview];
		}
	}
	
	NSUInteger numberOfMenuItems = 0;
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfContextualMenuItems)]) {
		numberOfMenuItems = [self.dataSource numberOfContextualMenuItems];
	}
	
	totalAmountOfCirclesThatCanFit = defaultTotalAmountOfCirclesThatCanFit;
	
	if ([self.delegate respondsToSelector:@selector(menuItemDistancePadding)]) {
		_menuItemDistancePadding = [self.delegate menuItemDistancePadding];
	} else {
		_menuItemDistancePadding = 70;
	}
	
	if (totalAmountOfCirclesThatCanFit > 1) {
		angleIncrement = (180.0f / (totalAmountOfCirclesThatCanFit-1));
	} else {
		angleIncrement = 0;
	}
	defaultStartingAngle = 300;
	for (NSInteger index = 0; index < numberOfMenuItems; index++) {
		if (self.delegate) {
			UIView *menuItem;
			UIView *highlightedMenuItem;
			
			//Regular Menu Item
			if ([self.delegate respondsToSelector:@selector(contextualMenu:viewForMenuItemAtIndex:)]) {
				menuItem = [self.delegate contextualMenu:self viewForMenuItemAtIndex:index];
				
				if (!menuItem) {
					_shouldActivateMenu = NO;
					[NSException raise:@"contextualMenu:viewForMenuItemAtIndex: can NOT be nil or invalid." format:@"View returned at index %lu is invalid. (%@)", (unsigned long)index, menuItem];
				}
			} else {
				_shouldActivateMenu = NO;
				[NSException raise:@"BAMContextualMenu's delegate MUST implement contextualMenu:viewForMenuItemAtIndex:" format:nil];
			}
			
			//Highlighted Menu Item
			if ([self.delegate respondsToSelector:@selector(contextualMenu:viewForHighlightedMenuItemAtIndex:)]) {
				highlightedMenuItem = [self.delegate contextualMenu:self viewForHighlightedMenuItemAtIndex:index];
			}
			if (!highlightedMenuItem) {
				highlightedMenuItem = menuItem;
			}
			
			UIView *titleView;
			
			if ([self.delegate respondsToSelector:@selector(contextualMenu:titleViewForMenuItemAtIndex:)]) {
				titleView = [self.delegate contextualMenu:self titleViewForMenuItemAtIndex:index];
			}
			
			if (!titleView && [self.delegate respondsToSelector:@selector(contextualMenu:titleForMenuItemAtIndex:)]) {
				UILabel *titleLabel = [[UILabel alloc] init];
				titleLabel.text = [self.delegate contextualMenu:self titleForMenuItemAtIndex:index];
				titleLabel.textColor = [UIColor blackColor];
				titleLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.85];
				titleLabel.numberOfLines = 0;
				titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
				titleLabel.textAlignment = NSTextAlignmentCenter;
				
				UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:13.0];
				if ([self.delegate respondsToSelector:@selector(contextualMenu:fontForMenuItemTitleViewAtIndex:)]) {
					if ([self.delegate contextualMenu:self fontForMenuItemTitleViewAtIndex:index]) {
						font = [self.delegate contextualMenu:self fontForMenuItemTitleViewAtIndex:index];
					}
				}
				titleLabel.font = font;
				titleLabel.alpha = 0.0f;
				titleLabel.hidden = !stringIsValid(titleLabel.text);
				titleLabel.clipsToBounds = YES;
				
				[titleLabel sizeToFit];
				
				if (stringIsValid(titleLabel.text)) {
					CGFloat titleLabelHeight = titleLabel.frame.size.height + (topAndBottomTitleLabelPadding * 2.0);
					titleLabel.frame = CGRectMake(0.0, 0.0, titleLabel.frame.size.width + (titleLabelHeight * 0.8), titleLabel.frame.size.height + (topAndBottomTitleLabelPadding * 2.0));
					titleLabel.center = CGPointMake(startingLocation.x + (menuItem.frame.size.width / 2.0), startingLocation.y + titleLabel.frame.size.height / 2.0);
					titleLabel.layer.cornerRadius = titleLabel.frame.size.height / 2.0;
				} else {
					titleLabel.frame = CGRectMake(0.0, 0.0, biggestMenuItemWidthHeight, 1.0);
				}
				
				titleView = titleLabel;
			} else {
				titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, biggestMenuItemWidthHeight, 1.0)];
				titleView.backgroundColor = [UIColor clearColor];
			}
			
			biggestMenuItemWidthHeight = MAX(biggestMenuItemWidthHeight, MAX(menuItem.frame.size.width, menuItem.frame.size.height));
			biggestTitleViewSize = CGSizeMake(MAX(biggestTitleViewSize.width, titleView.frame.size.width), MAX(biggestTitleViewSize.height, titleView.frame.size.height));
			
			if (index == 0) {
				firstIndexTitleViewSize = titleView.frame.size;
			} else if (index == numberOfMenuItems - 1) {
				lastIndexTitleViewSize = titleView.frame.size;
			}
			
			UIView *defaultSelectedBackgroundView = [[UIView alloc] initWithFrame:menuItem.bounds];
			defaultSelectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
			defaultSelectedBackgroundView.alpha = 0.0;
			[menuItem addSubview:defaultSelectedBackgroundView];
			
			menuItem.center = startingLocation;
			highlightedMenuItem.center = startingLocation;
			menuItem.hidden = YES;
			highlightedMenuItem.hidden = YES;
			
			[contextualMenuItems addObject:menuItem];
			[defaultSelectedBackgroundViews addObject:defaultSelectedBackgroundView];
			[highlightedMenuItems addObject:highlightedMenuItem];
			[contextualMenuTitleViews addObject:titleView];
			
			if (menuItem != highlightedMenuItem) {
				[shadowView addSubview:highlightedMenuItem];
			}
			[shadowView addSubview:menuItem];
			[shadowView addSubview:titleView];
		} else {
			NSLog(@"%@ - Your delegate is nil. You must have a valid delegate object at all times! The Contextual Menu will not activate at this time.", self);
		}
	}
	
	_shouldActivateMenu = (contextualMenuItems.count > 0);
}

- (void)reloadDataAndRelayoutSubviews
{
	shouldRelayoutSubviews = YES;
	[self layoutMenuItemsIfNeeded];
}

#pragma mark Radial Calculation Convenience Methods

typedef enum ZZScreenEdge : NSUInteger {
	kZZScreenEdgeLeft		= 1 << 0,
	kZZScreenEdgeRight		= 1 << 1,
	kZZScreenEdgeTop		= 1 << 2
} ZZScreenEdge;

//MAGIC. DO NOT TOUCH LEST DRAGONS EAT YOU ALIVE
- (void)calculateAngleOffsetForSide:(ZZScreenEdge)screenEdge
{
	//If the user has touched too close to the edge of the screen, the menu item closest to the screen edge and it's label could bleed past it. We want to prevent this so we need to calculate an angle offset amount to apply to the starting angle of the first menu item.
	
	//First, we need to find the furthest point from the center of the user's starting location. The highlighted state is the furthest so let's make calculations based off of that.
	CGFloat circleRadius = menuItemsCenterRadius + highlightRadiusOffset;
	
	//This center point is where the menu item would have started at before the angle offset is applied.
	CGFloat startingAngle = defaultStartingAngle - 360.0;
	if (screenEdge & kZZScreenEdgeRight) {
		startingAngle += (((CGFloat)contextualMenuItems.count - 1) * angleIncrement);
	}
	CGPoint highlightedMenuCenter = [self circumferentialPointForViewWithRadius:circleRadius angle:startingAngle andCenterPoint:startingLocation];
	
	//how far from the y axis do we want the edge of the label to be?
	CGFloat screenEdgeOffsetForFinalLabelPosition = 10.0;
	
	//To determine the furthest point of the label in relation to the screen's edge, we need to first determine which label size to use based on which half of the screen we're on. Left half would be the labelsize of the label of the menu item at index 1. Right half would be the label of the menu item at the last index of the menu item array.
	//Calculation defaults are for left edge.
	CGSize sizeOfClosestLabelToEdge = firstIndexTitleViewSize;
	CGFloat maxWidthForFurthestX = MAX(sizeOfClosestLabelToEdge.width, biggestMenuItemWidthHeight);
	CGFloat labelXFurthestFromTheEdge = highlightedMenuCenter.x - (maxWidthForFurthestX / 2.0);
	BOOL calculateAngleOffset = (labelXFurthestFromTheEdge < screenEdgeOffsetForFinalLabelPosition);
	
	//Inverse calculations for cases where the touch is on the right half of the screen.
	if (screenEdge & kZZScreenEdgeRight) {
		sizeOfClosestLabelToEdge = lastIndexTitleViewSize;
		maxWidthForFurthestX = MAX(sizeOfClosestLabelToEdge.width, biggestMenuItemWidthHeight);
		labelXFurthestFromTheEdge = highlightedMenuCenter.x + (maxWidthForFurthestX / 2.0);
		calculateAngleOffset = (labelXFurthestFromTheEdge > rootView.frame.size.width - screenEdgeOffsetForFinalLabelPosition);
	}
	
	if (calculateAngleOffset) {
		//Since we want the label of the closest menu item to the screen edge to be flush with the screen edge, we can derive the x of where that menu item is supposed to be from that label. (NOTE: each menu item's label is centered with the menu item. So the center.x of the label is equal to the center.x of the menu item.) Once we know that X, we can use the paramteric equation to derive the angle of that final position of said menu item in relation to the origin.
		CGFloat finalCenterXOfMenuItemClosestToEdge = screenEdgeOffsetForFinalLabelPosition + (maxWidthForFurthestX / 2.0);
		if (screenEdge & kZZScreenEdgeRight) {
			finalCenterXOfMenuItemClosestToEdge = rootView.frame.size.width - (maxWidthForFurthestX / 2.0) - screenEdgeOffsetForFinalLabelPosition;
		}
		
		//Let's get our missing y. We could use an arcSine version of the paramteric equation, but our getAngleBetweenOrigin: method uses atan2 which will prevent us from getting NAN values here.
		CGFloat lengthOfMissingTriangleLeg = [self calculateMissingSideOfTriangleWithHypotenuse:circleRadius knownLegWidth:finalCenterXOfMenuItemClosestToEdge - startingLocation.x];
		
		CGFloat wantedCenterY = startingLocation.y - lengthOfMissingTriangleLeg;
		
		CGPoint wantedStartingMenuItemCenter = CGPointMake(finalCenterXOfMenuItemClosestToEdge, wantedCenterY);
		
		CGFloat finalAngleOfMenuItemClosestToEdge = [self getAngleBetweenOrigin:startingLocation andSecondPoint:wantedStartingMenuItemCenter relativeToYAxis:YES];
		
		//Subtract the startingAngle from the angle of the final menu item's position, and we have our angle offset!
		angleOffset = finalAngleOfMenuItemClosestToEdge - startingAngle;
	} else {
		angleOffset = 0.0f;
	}
	
	if (screenEdge & kZZScreenEdgeTop) {
		//We have a menu item crossing the top edge, so let's offset it instead by doing the same thing as above, but instead of making calculations based off of the x where we want the starting menu item to be, we use the y.
		//Parametric equation for y value on a circle's circumference is y = originY - (radius * cos(angle))
		//Solve for theta!
		//angle = acos((originY - y) / radius)
		
		CGFloat multiplier = 1.0;
		if (screenEdge & kZZScreenEdgeRight) {
			//Multiply by -1.0 to have the angle offset based on the fourth quadrant.
			multiplier = -1.0;
		}
		
		CGFloat wantedCenterYOfMenuItemClosestToTopEdge = MAX(screenEdgeOffsetForFinalLabelPosition, currentStatusBarHeight) + sizeOfClosestLabelToEdge.height + titleLabelPadding + (biggestMenuItemWidthHeight / 2.0);
		
		//Let's get our missing x. We could use an arcCosine version of the paramteric equation, but our getAngleBetweenOrigin: method uses atan2 which will prevent us from getting NAN values here.
		CGFloat lengthOfMissingTriangleLeg = [self calculateMissingSideOfTriangleWithHypotenuse:circleRadius knownLegWidth:startingLocation.y - wantedCenterYOfMenuItemClosestToTopEdge] * multiplier;
		
		CGFloat wantedCenterX = startingLocation.x + lengthOfMissingTriangleLeg;
		
		CGPoint wantedStartingMenuItemCenter = CGPointMake(wantedCenterX, wantedCenterYOfMenuItemClosestToTopEdge);
		
		CGFloat wantedAngleOfMenuItemClosestToTopEdge = [self getAngleBetweenOrigin:startingLocation andSecondPoint:wantedStartingMenuItemCenter relativeToYAxis:YES];
		
		angleOffset = wantedAngleOfMenuItemClosestToTopEdge - startingAngle;
	}
	
	angleOffset += [self rotationAngleOffset];
}

- (CGFloat)calculateMissingSideOfTriangleWithHypotenuse:(CGFloat)hypotenuse knownLegWidth:(CGFloat)legA
{
	//a^2 + b^2 = c^2 - solve for b
	//b = squareRoot(c^2 - a^2)
	
	//Let's ensure our hypotenuse is greater than our legA
	hypotenuse = MAX(ABS(legA), ABS(hypotenuse));
	legA = MIN(ABS(legA), ABS(hypotenuse));
	
	return sqrt(pow(hypotenuse, 2.0f) - pow(legA, 2.0f));
}

- (CGPoint)calculateCenterForMenuItemAtIndex:(NSUInteger)index withCircleRadius:(CGFloat)circleRadius
{
	CGPoint menuItemCenter = startingLocation;
	
	//Need an offset for the startingIndex for highlight logic
	CGFloat anglePercentage = (defaultStartingAngle / 360.0f);
	startingLocationIndexOffset = (NSInteger)roundf(anglePercentage * totalAmountOfCirclesThatCanFit);
	
	CGFloat startingAngle = defaultStartingAngle + ceil(index/2.0)*angleIncrement*pow(-1, index);//defaultStartingAngle - ((CGFloat)index * angleIncrement);
	menuItemCenter = [self circumferentialPointForViewWithRadius:circleRadius angle:startingAngle andCenterPoint:startingLocation];
	
	return menuItemCenter;
}

//Using the parametric equation, we can determine the point along the line of the circumference of a circle given it's radius and the angle of which to space out each point relative to the x axis.
- (CGPoint)circumferentialPointForViewWithRadius:(CGFloat)radius angle:(CGFloat)angle andCenterPoint:(CGPoint)centerPoint
{
	//Parametric Equation
	//angle is in radians
	//x = originX + (radius * sin(angle))
	//y = originY + (radius * cos(angle))
	
	CGFloat newX = centerPoint.x + (radius * sinf(degreesToRadians(angle)));
	CGFloat newY = centerPoint.y - (radius * cosf(degreesToRadians(angle))); //Make negative because y is flipped in the iOS coordinate system
	
	return CGPointMake(newX, newY);
}

//distance formula to calculate distance of point from origin. We leverage this to see if the user's touch is inside of the concentric circle that the menu items are inside of.
- (CGFloat)calculateDistanceWithPoint:(CGPoint)point fromOrigin:(CGPoint)origin
{
	CGFloat distanceX = point.x - origin.x;
	CGFloat distanceY = point.y - origin.y;
	
	return sqrt(pow(distanceX, 2.0) + pow(distanceY, 2.0));
}


// Determines the angle of a straight line drawn between firstPoint and secondPoint relative to the x axis in degrees. To get it in Radians, return the 'radians' instance variable.
- (CGFloat)getAngleBetweenOrigin:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint relativeToYAxis:(BOOL)relativeToYAxis
{
	CGFloat XDifference = secondPoint.x - firstPoint.x;
	CGFloat YDifference = secondPoint.y - firstPoint.y;
	
	CGFloat radians = atan2(YDifference, XDifference);
	CGFloat angles = radiansToDegrees(radians);
	
	if (relativeToYAxis) {
		//Because this formula returns the angle of the straight line between firstPoint and secondPoint relative to the X axis, where a horizontal line gives a value of 0 degrees and a vertical line gives a value of -90 degrees (because iOS has a flipped y coordinate system), we have to add 90 degrees to make the final output relative to the y axis.
		angles += 90.0f;
	}
	
	if (angles < 0.0f) {
		//After 270 degrees, angles jumps to -90 degrees. Adding 360 degrees to that will get us the correct angle from 270 to 360.
		angles += 360.0f;
	}
	
	return angles;
}

- (BOOL)sdkNeedsRotationOffsett
{
	BOOL isCompiledWithPreIOS8SDK = NSFoundationVersionNumber <= 1048.0;
	return ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 || isCompiledWithPreIOS8SDK);
}

- (CGFloat)rotationAngleOffset
{
	//Anything not on Portrait Orientation needs an additional offset due to strange behaviors with iPad rotation.
	if ([self sdkNeedsRotationOffsett] && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
		return 180.0;
	}
	return 0.0;
}

#pragma mark Tear Down Methods
+ (void)removeContextualMenuFromView:(UIView *)containingView
{
	BAMContextualMenu *menu = [BAMContextualMenu contextualMenuForView:containingView];
	if (menu) {
		[menu removeFromSuperview];
	}
	menu = nil;
}

- (void)dealloc
{
	if (longPressActivationGestureRecognizer) {
		[self.containerView removeGestureRecognizer:longPressActivationGestureRecognizer];
	}
	if (tapGestureRecognizer) {
		[self.containerView removeGestureRecognizer:tapGestureRecognizer];
	}
	if (shadowGestureRecognizer) {
		[shadowView removeGestureRecognizer:shadowGestureRecognizer];
	}
	
	shadowView = nil;
	contextualMenuItems = nil;
}

@end
