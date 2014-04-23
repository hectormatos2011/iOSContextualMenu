//
//  HMContextualMenuItem.h
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

#import <UIKit/UIKit.h>

typedef enum HMContextualMenuActivateOption : NSUInteger {
	kBAMContextualMenuActivateOptionLongPress = 0,
	kBAMContextualMenuActivateOptionTouchUp = 1,
} BAMContextualMenuActivateOption;

@protocol BAMContextualMenuDelegate, BAMContextualMenuDataSource;

@interface BAMContextualMenu : UIView

@property (nonatomic) BOOL menuIsShowing; //Flag to turn off the ability to activate the popup menu. Defaults to YES but will be NO if menuItems array is nil or empty.
@property (nonatomic) BOOL shouldActivateMenu; //Flag to turn off the ability to activate the popup menu. Defaults to YES but will be NO if menuItems array is nil or empty.
@property (nonatomic) BOOL shouldHighlightOutwards; //Defaults to YES. This flag determines whether or not the menu item will animate outwards on highlight. Or just stay in place.

@property (nonatomic) CGFloat menuItemDistancePadding; //Distance of each menuItem from the edge of the startingCircle (the thing that indicates your touch)

@property (nonatomic) BAMContextualMenuActivateOption activateOption; //User can set this to switch between ways to activate the menu later on.

//This will tear down all subviews will calling all implemented data source and delegate methods.
- (void)reloadDataAndRelayoutSubviews;

/**
 Adds Contextual Menu
 @param containingView		View that the contextual menu bases most of it's stuff on. Unless the long press is inside of the containingView's bounds, the menu will not activate.
 @param activateOption		An option you can pass to control whether the menu is presented on a long press or by tapping on it. Long pressing will cause the menu to dismiss when the user lifts their finger, while the tap gesture keeps the menu up until the user either taps on a menu item or
 **/
+ (BAMContextualMenu *)addContextualMenuToView:(UIView *)containingView delegate:(id <BAMContextualMenuDelegate>)delegate dataSource:(id <BAMContextualMenuDataSource>)dataSource activateOption:(BAMContextualMenuActivateOption)activateOption;

//Removes the contextual menu from containing view as a subview. This is in case you have need for that sort of thing. You would use this in the prepareForReuse method of your UITableViewCell or UICollectionViewReusableView subclass. Failure to do so could result in a objc_msgSend crash due to the longPressGestureRecognizer being added to the view
+ (void)removeContextualMenuFromView:(UIView *)containingView;

@end

@protocol BAMContextualMenuDelegate <NSObject>

//fires on touch up. From there you can perform whatever action needed for that menu item.
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu viewForMenuItemAtIndex:(NSUInteger)index;

@optional
//You would use this delegate method to pause a game or take action when contextual menu overlays your entire screen. For example, If my iOS game implemented this contextual menu by tapping on a character in motion, I would probably pause the game while it's up to give the user time to make a selection on the menu. This is one such example, feel free to use it in any way you would need it.
- (void)contextualMenuActivated:(BAMContextualMenu *)contextualMenu;
//This method could be used to undo any action taken in contextualMenuActivated:.
- (void)contextualMenuDismissed:(BAMContextualMenu *)contextualMenu;

- (void)contextualMenu:(BAMContextualMenu *)contextualMenu didSelectItemAtIndex:(NSUInteger)index;
- (void)contextualMenu:(BAMContextualMenu *)contextualMenu didHighlightItemAtIndex:(NSUInteger)index;
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu viewForHighlightedMenuItemAtIndex:(NSUInteger)index;
- (NSString *)contextualMenu:(BAMContextualMenu *)contextualMenu titleForMenuItemAtIndex:(NSUInteger)index;
- (UIFont *)contextualMenu:(BAMContextualMenu *)contextualMenu fontForMenuItemTitleViewAtIndex:(NSUInteger)index;
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu titleViewForMenuItemAtIndex:(NSUInteger)index;

@end

@protocol BAMContextualMenuDataSource <NSObject>

- (NSUInteger)numberOfContextualMenuItems;

@optional

@end