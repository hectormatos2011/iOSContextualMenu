# iOSContextualMenu
Here lies an easy and awesome way to create contextual menus in iOS. Do you want to access a quick and beautiful popup menu by tapping on a sprite for your game? Do you want to do what Pinterest did and have a contextual menu popup in your UICollectionView by long pressing on a cell?

Well, you've come to the right place. Hopefully this will help my fellow iOS Developers create beautiful UX for their applications quickly and easily!

![Alt text](/Assets/fullCircle.png)&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;![Alt text](/Assets/facebookHighlight.png)&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;![Alt text](/Assets/twitterHighlight.png)

## Installation

iOSContextualMenu is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "iOSContextualMenu"

## Getting Started
To run the example project; clone the repo, and run `pod install` from the Example directory first. A full blown example is included there. If you don't want to do that, then read ahead!

##Overview
The iOSContextualMenu uses a similar dataSource/delegate paradigm like UITableView, UICollectionView, UIPickerView, etc.

To implement in your code, follow these steps (This code in these steps is for putting a contextual menu in every cell of a UICollectionView. In this example, I'm adding the contextual menu code inside of my own UICollectionViewCell subclass. Feel free to add a contextual menu to any UIView or a subclass of UIView if this isn't what you want. The following example will also work for UITableView and it's UITableViewCell subclasses.): 

#### Step 1
In your interface declaration, make sure to make your object comply to BAMContextualMenuDelegate and BAMContextualMenuDataSource

```objectivec
@interface BAMCollectionViewCell () <BAMContextualMenuDelegate, BAMContextualMenuDataSource>

@end
```

#### Step 2
After creating your UIView, add this line to add a contextual menu to it. NOTE: the contextual menu will NOT activate unless the long press was within the bounds of that view.
```objectivec
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[BAMContextualMenu addContextualMenuToView:self.contentView delegate:self dataSource:self activateOption:kBAMContextualMenuActivateOption];
	}
	return self;
}
```

#### Step 3
Now implement the contextual menu's dataSource methods like you would for any UITableView, UICollectionView, or UIPickerView

Data Source:
NOTE: numberOfContextualMenuItems is required. Failure to implement this will result in your contextual menu not showing up at all.

```objectivec
- (NSUInteger)numberOfContextualMenuItems
{
	return 3;
}
```

#### Step 4
After implementing your data source, we'll implement our delegate methods

NOTE: The only required delegate method to implement is contextualMenu:viewForMenuItemAtIndex:. You absolutely have to supply a UIView in this method. Failure to do so will result in a raised exception.

Also, feel free to return any UIView you want. One nice thing about BAMContextualMenu is that when you return a UIImageView instance, the contextual menu will call setHighlighted: for you. This enables you to supply just one UIImageView instance in contextualMenu:viewForMenuItemAtIndex: that has a highlightedImage and a regular image, and on highlight, the imageView will swap out it's originalImage for it's highlighted one.

```objectivec
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu viewForMenuItemAtIndex:(NSUInteger)index
{
	UIImage *menuItemImage = [self imageForMenuItemAtIndex:index];
	UIImage *highlightedMenuItemImage = [self highlightedImageForMenuItemAtIndex:index];

	UIImageView *menuItemImageView = [[UIImageView alloc] initWithImage:menuItemImage highlightedImage:highlightedMenuItemImage];
	return menuItemImageView;
}
```

####Optional Delegate Methods for Further Customization
This is optional, but if you wanted to use a separate view for each menu item's highlighted state, you can use contextualMenu:viewForHighlightedMenuItemAtIndex:. 

```objectivec
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu viewForHighlightedMenuItemAtIndex:(NSUInteger)index
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];
	view.backgroundColor = [UIColor redColor];
	return view;
}
```

Just like a UIPickerView, you could also associate a title with each menu item. Also optional, but implementing contextualMenu:titleForMenuItemAtIndex: will place a label that pops up above and centered to the menu item when it's highlighted. The label is a slightly transparent white rounded rect label with black text inside. Returning an empty string or a nil NSString object will prevent a title label from showing at the menu item's index.

```objectivec
- (NSString *)contextualMenu:(BAMContextualMenu *)contextualMenu titleForMenuItemAtIndex:(NSUInteger)index
{
	NSString *title;

	if (index == facebookMenuItemIndex) {
		title = @"Share on Facebook";
	} else if (index == googlePlusMenuItemIndex) {
		title = @"Share on Google+";
	} else if (index == pinterestMenuItemIndex) {
		title = NSLocalizedString(@"Pin It!", nil);
	}

	return title;
}
```

If you like the way the title label looks and you simply want to change the font, you could use contextualMenu:fontForMenuItemTitleViewAtIndex:.

```objectivec
- (UIFont *)contextualMenu:(BAMContextualMenu *)contextualMenu fontForMenuItemTitleViewAtIndex:(NSUInteger)index
{
	return [UIFont boldSystemFontOfSize:19.0];
}
```

For even further customization, you could use your own view for the menu item's title view by implementing contextualMenu:titleViewForMenuItemAtIndex:.

```objectivec
- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu titleViewForMenuItemAtIndex:(NSUInteger)index
{
	//Create a custom view here
	return yourCustomView;
}
```

For some cases, a developer would want to add a contextual menu to a moving sprite in their game to access options for it (Ex. Defend, Attack, Run Away)
In cases like this, you would probably want to pause your game to allow the user to select an option without affecting gameplay. To do this, you can implement the delegate methods contextualMenuActivated: and contextualMenuDismissed:

```objectivec
- (void)contextualMenuActivated:(BAMContextualMenu *)contextualMenu
{
	//Pause your game here.
}

- (void)contextualMenuDismissed:(BAMContextualMenu *)contextualMenu
{
	//Unpause your game here.
}
```


Also, if you have need for this sort of thing, you can remove the contextualMenu at any time by calling removeContextualMenuFromView:.

```objectivec
[BAMContextualMenu removeContextualMenuFromView:self.contentView];
```

## Requirements

Currently, the minimum iOS requirement is iOS7 for this class to work. I am working on a version that will work for earlier versions as well. Coming Soon!

## Author

Hector Matos, hectormatos2011@gmail.com

## License

iOSContextualMenu is available under the MIT license. See the LICENSE file for more info.

