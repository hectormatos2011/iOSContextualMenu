//
//  BAMContextualMenuOptionsViewController.m
//  Contextual Menu
//
//  Created by Hector on 4/18/14.
//  Copyright (c) 2014 CodeNinja. All rights reserved.
//

#import "BAMContextualMenuOptionsViewController.h"
#import "UIImage+ImageWithUIView.h"
#import "BAMOptionsButton.h"
#import <iOSContextualMenu/BAMContextualMenu.h>

#define contextualImageViewLeftRightMargin		50.0
#define contextualLabelTopMargin				100.0
#define imageWidthHeight						50.0

@interface BAMContextualMenuOptionsViewController () <BAMContextualMenuDataSource, BAMContextualMenuDelegate, UIGestureRecognizerDelegate>
{
	UILabel *actionLabel;
	UILabel *contextualMenuTitleLabel;
	UIImageView *contextualMenuImageView;

	NSMutableArray *menuItemImageArray;
	NSMutableArray *menuItemTitleArray;
	NSArray *totalImageArray;
	NSArray *totalTitleArray;

	BAMContextualMenu *contextualMenu;
}

@end

@implementation BAMContextualMenuOptionsViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	//Create our data sources
	totalImageArray = @[[UIImage imageNamed:@"facebookIcon"],
						[UIImage imageNamed:@"twitterIcon"],
						[UIImage imageNamed:@"vineIcon"],
						[UIImage imageNamed:@"githubIcon"],
						[UIImage imageNamed:@"googlePlusIcon"],
						[UIImage imageNamed:@"linkedInIcon"],
						[UIImage imageNamed:@"pinterestIcon"],
						[UIImage imageNamed:@"googleDriveIcon"]
						];

	totalTitleArray = @[@"Share on\nFacebook",
						@"Tweet",
						@"Post Vine",
						@"Fork Repo",
						@"Share on\nGoogle Plus",
						@"Send InMail",
						@"Pin it!",
						@"Upload to\nGoogle Drive"
						];

	menuItemImageArray = [NSMutableArray array];
	menuItemTitleArray = [NSMutableArray array];

	//Layout our title label and our contextual menu image view
	contextualMenuTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	contextualMenuTitleLabel.backgroundColor = [UIColor clearColor];
	contextualMenuTitleLabel.text = @"Contextual Menu";
	contextualMenuTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:25.0];
	contextualMenuTitleLabel.textColor = [UIColor whiteColor];
	contextualMenuTitleLabel.textAlignment = NSTextAlignmentCenter;
	contextualMenuTitleLabel.alpha = 0.0;

	[contextualMenuTitleLabel sizeToFit];
	contextualMenuTitleLabel.frame = CGRectMake(0.0, contextualLabelTopMargin, contextualMenuTitleLabel.frame.size.width, contextualMenuTitleLabel.frame.size.height);
	contextualMenuTitleLabel.center = CGPointMake(self.view.frame.size.width / 2.0, contextualMenuTitleLabel.center.y);

	//Since I want to apply a blur effect to the startup image, I'm going to add an image view with the proper launch image as it's background. Using [UIImage imageNamed:@"LaunchImage"] does not work in this case. These are the actual names for the 4 inch launch image and 3.5 inch launch image
	NSString *launchImageString;
	if  (isiPhone5) {
		launchImageString = @"LaunchImage-700-568h";
	} else {
		launchImageString = @"LaunchImage-700";
	}
	//Apply ablur to the image using Apple's blur image category
	UIImage *launchImage = [[UIImage imageNamed:launchImageString] applyBlurWithRadius:15.0 tintColor:[UIColor colorWithWhite:1.0 alpha:0.1] saturationDeltaFactor:1.5 maskImage:nil];

	UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:launchImage];
	backgroundImageView.frame = self.view.bounds;
	backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
	backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	//Layout image view that we apply our contextual menu too. We want a cool little animation so let's place it at the bottom of the screen at first, out of sight.
	UIImage *contextualMenuImage = [UIImage imageNamed:@"BrookeAbigailMatos"];
	CGFloat contextualMenuImageRatio = contextualMenuImage.size.height / contextualMenuImage.size.width;
	CGFloat contextualMenuImageViewWidth = self.view.frame.size.width - (contextualImageViewLeftRightMargin * 2.0);

	contextualMenuImageView = [[UIImageView alloc] initWithImage:contextualMenuImage];
	contextualMenuImageView.frame = CGRectMake(contextualImageViewLeftRightMargin, self.view.frame.size.height, contextualMenuImageViewWidth, contextualMenuImageViewWidth * contextualMenuImageRatio);
	contextualMenuImageView.layer.cornerRadius = 4.0;
	contextualMenuImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
	contextualMenuImageView.layer.borderWidth = 1.0;
	contextualMenuImageView.clipsToBounds = YES;

	//This action label will show our selection from our contextual menu. Let's place it where the image view will normally be.
	actionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	actionLabel.backgroundColor = [UIColor clearColor];
	actionLabel.text = @"Hi";
	actionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.0];
	actionLabel.textColor = [UIColor whiteColor];
	actionLabel.textAlignment = NSTextAlignmentCenter;
	actionLabel.alpha = 0.0;
	actionLabel.numberOfLines = 0;
	actionLabel.clipsToBounds = NO;

	[actionLabel sizeToFit];
	actionLabel.frame = CGRectMake(0.0, contextualMenuTitleLabel.frame.origin.y + contextualMenuTitleLabel.frame.size.height + 10.0 + contextualMenuImageView.frame.size.height + 10.0, self.view.frame.size.width, actionLabel.frame.size.height);
	actionLabel.center = CGPointMake(self.view.frame.size.width / 2.0, actionLabel.center.y);

	[self.view addSubview:backgroundImageView];
	[self.view addSubview:contextualMenuTitleLabel];
	[self.view addSubview:contextualMenuImageView];
	[self.view addSubview:actionLabel];

	//Convenience method to set up where the user can select options for the contextual menu's presentation.
	[self setupMenuOptions];

	//Add the contextual menu. the above is just laying out UI. This line is all you need to apply a contextual menu to a view. To actually do something with the menu and show stuff, you would have to implement it's delegate and data source methods.
	contextualMenu = [BAMContextualMenu addContextualMenuToView:contextualMenuImageView delegate:self dataSource:self activateOption:kBAMContextualMenuActivateOptionLongPress];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	//Kind of just threw this together. I'll switch over to UIDynamics soon enough. This animates the contextual image view in.
	[UIView animateKeyframesWithDuration:1.0
								   delay:0.0
								 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
							  animations:^{
								  contextualMenuTitleLabel.alpha = 1.0;
								  [UIView addKeyframeWithRelativeStartTime:0.0
														  relativeDuration:0.5
																animations:^{
																	contextualMenuImageView.frame = CGRectMake(contextualMenuImageView.frame.origin.x, contextualMenuTitleLabel.frame.origin.y + contextualMenuTitleLabel.frame.size.height - 20.0, contextualMenuImageView.frame.size.width, contextualMenuImageView.frame.size.height);
																	contextualMenuImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, degreesToRadians(-30.0));
																}];
								  [UIView addKeyframeWithRelativeStartTime:0.5
														  relativeDuration:0.2
																animations:^{
																	contextualMenuImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, degreesToRadians(30.0));
																}];
								  [UIView addKeyframeWithRelativeStartTime:0.7
														  relativeDuration:0.3
																animations:^{
																	contextualMenuImageView.transform = CGAffineTransformIdentity;
																	contextualMenuImageView.frame = CGRectMake(contextualMenuImageView.frame.origin.x, contextualMenuTitleLabel.frame.origin.y + contextualMenuTitleLabel.frame.size.height + 10.0, contextualMenuImageView.frame.size.width, contextualMenuImageView.frame.size.height);
																}];
							  }
							  completion:nil];
}

- (void)setupMenuOptions
{
	//Setup of the scrollview to allow the user to see how the menu will look like with different menu items.
	CGFloat padding = 10.0;
	UIScrollView *optionsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - imageWidthHeight - padding, self.view.frame.size.width, imageWidthHeight)];
	optionsScrollView.showsHorizontalScrollIndicator = NO;

	UILabel *menuOptionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	menuOptionsLabel.backgroundColor = [UIColor clearColor];
	menuOptionsLabel.text = @"Visible Menu Items:";
	menuOptionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0];
	menuOptionsLabel.textColor = [UIColor whiteColor];
	menuOptionsLabel.textAlignment = NSTextAlignmentCenter;
	menuOptionsLabel.alpha = 1.0;

	[menuOptionsLabel sizeToFit];
	menuOptionsLabel.frame = CGRectMake(0.0, optionsScrollView.frame.origin.y - menuOptionsLabel.frame.size.height - padding, menuOptionsLabel.frame.size.width, menuOptionsLabel.frame.size.height);
	menuOptionsLabel.center = CGPointMake(self.view.frame.size.width / 2.0, menuOptionsLabel.center.y);

	CGFloat currentX = padding;
	for (int i = 0; i < totalImageArray.count; i++) {
		BAMOptionsButton *optionButton = [[BAMOptionsButton alloc] initWithFrame:CGRectMake(currentX, 0.0, imageWidthHeight, imageWidthHeight)];
		optionButton.index = i;
		[optionButton setBackgroundImage:[totalImageArray objectAtIndex:i] forState:UIControlStateNormal];
		[optionButton addTarget:self action:@selector(menuOptionsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

		[optionsScrollView addSubview:optionButton];

		if (i < 4) {
			[self menuOptionsButtonPressed:optionButton];
		}

		currentX += optionButton.frame.size.width + padding;
	}

	optionsScrollView.contentSize = CGSizeMake(currentX, imageWidthHeight);

	//Activate Option Segment Control View Layouts
	CGFloat segmentControlWidth = self.view.frame.size.width - contextualImageViewLeftRightMargin;

	UISegmentedControl *activateOptionSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Long Press", @"Tap to Activate"]];
	activateOptionSegmentControl.selectedSegmentIndex = 0;
	activateOptionSegmentControl.tintColor = [UIColor whiteColor];
	activateOptionSegmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[activateOptionSegmentControl addTarget:self action:@selector(segmentControlChanged:) forControlEvents:UIControlEventValueChanged];

	UILabel *activateOptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	activateOptionLabel.backgroundColor = [UIColor clearColor];
	activateOptionLabel.text = @"Activate Option:";
	activateOptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0];
	activateOptionLabel.textColor = [UIColor whiteColor];
	activateOptionLabel.textAlignment = NSTextAlignmentCenter;
	activateOptionLabel.alpha = 1.0;

	[activateOptionLabel sizeToFit];
	activateOptionLabel.frame = CGRectMake((segmentControlWidth - activateOptionLabel.frame.size.width) / 2.0, 0.0, activateOptionLabel.frame.size.width, activateOptionLabel.frame.size.height);

	activateOptionSegmentControl.frame = CGRectMake(0.0, activateOptionLabel.frame.origin.y + activateOptionLabel.frame.size.height + padding, segmentControlWidth, activateOptionSegmentControl.frame.size.height);

	CGFloat activateOptionViewHeight = activateOptionSegmentControl.frame.origin.y + activateOptionSegmentControl.frame.size.height + padding;
	UIView *activateOptionView = [[UIView alloc] initWithFrame:CGRectMake(0.0, menuOptionsLabel.frame.origin.y - (activateOptionViewHeight) - padding, activateOptionSegmentControl.frame.size.width, activateOptionViewHeight)];
	activateOptionView.backgroundColor = [UIColor clearColor];
	activateOptionView.center = CGPointMake(self.view.frame.size.width / 2.0, activateOptionView.center.y);

	[activateOptionView addSubview:activateOptionLabel];
	[activateOptionView addSubview:activateOptionSegmentControl];

	UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(activateOptionView.frame.origin.x / 2.0, activateOptionView.frame.origin.y + activateOptionView.frame.size.height, self.view.frame.size.width - activateOptionView.frame.origin.x, 1.0)];
	separatorView.backgroundColor = [UIColor whiteColor];

	//highlight outwards switch setup

	UILabel *highlightOutwardsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	highlightOutwardsLabel.backgroundColor = [UIColor clearColor];
	highlightOutwardsLabel.text = @"Animate Outwards on Highlight:";
	highlightOutwardsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0];
	highlightOutwardsLabel.textColor = [UIColor whiteColor];
	highlightOutwardsLabel.textAlignment = NSTextAlignmentLeft;
	highlightOutwardsLabel.alpha = 1.0;

	[highlightOutwardsLabel sizeToFit];

	UISwitch *highlightOutwardsSwitch = [[UISwitch alloc] init];
	[highlightOutwardsSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

	CGFloat highlightOutwardsViewHeight = MAX(highlightOutwardsSwitch.frame.size.height, highlightOutwardsLabel.frame.size.height);
	UIView *highlightOutwardsView = [[UIView alloc] initWithFrame:CGRectMake(padding, activateOptionView.frame.origin.y - highlightOutwardsViewHeight - padding - padding, self.view.frame.size.width - (padding * 2.0), highlightOutwardsViewHeight)];
	highlightOutwardsView.backgroundColor = [UIColor clearColor];

	highlightOutwardsSwitch.center = CGPointMake(highlightOutwardsView.frame.size.width - (highlightOutwardsSwitch.frame.size.width / 2.0), (highlightOutwardsView.frame.size.height / 2.0));
	highlightOutwardsLabel.center = CGPointMake(highlightOutwardsLabel.frame.size.width / 2.0, (highlightOutwardsView.frame.size.height / 2.0));

	UIView *outwardsSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(activateOptionView.frame.origin.x / 2.0, highlightOutwardsView.frame.origin.y + highlightOutwardsView.frame.size.height + padding, self.view.frame.size.width - activateOptionView.frame.origin.x, 1.0)];
	outwardsSeparatorView.backgroundColor = [UIColor whiteColor];

	[highlightOutwardsView addSubview:highlightOutwardsLabel];
	[highlightOutwardsView addSubview:highlightOutwardsSwitch];

	[self.view addSubview:highlightOutwardsView];
	[self.view addSubview:outwardsSeparatorView];
	[self.view addSubview:activateOptionView];
	[self.view addSubview:separatorView];
	[self.view addSubview:menuOptionsLabel];
	[self.view addSubview:optionsScrollView];
}

- (void)switchChanged:(UISwitch *)optionsSwitch
{
	contextualMenu.shouldHighlightOutwards = optionsSwitch.isOn;
}

- (void)segmentControlChanged:(UISegmentedControl *)segmentedControl
{
	contextualMenu.activateOption = segmentedControl.selectedSegmentIndex;
}

- (void)menuOptionsButtonPressed:(BAMOptionsButton *)optionsButton
{
	BOOL selectOption = !optionsButton.optionSelected;
	[optionsButton selectOption:selectOption];

	if (optionsButton.optionSelected) {
		if (optionsButton.index < menuItemImageArray.count) {
			[menuItemImageArray insertObject:[totalImageArray objectAtIndex:optionsButton.index] atIndex:optionsButton.index];
			[menuItemTitleArray insertObject:[totalTitleArray objectAtIndex:optionsButton.index] atIndex:optionsButton.index];
		} else {
			[menuItemImageArray addObject:[totalImageArray objectAtIndex:optionsButton.index]];
			[menuItemTitleArray addObject:[totalTitleArray objectAtIndex:optionsButton.index]];
		}
	} else {
		if (optionsButton.index < menuItemImageArray.count) {
			[menuItemImageArray removeObjectAtIndex:optionsButton.index];
			[menuItemTitleArray removeObjectAtIndex:optionsButton.index];
		} else {
			[menuItemImageArray removeLastObject];
			[menuItemTitleArray removeLastObject];
		}
	}

	[contextualMenu reloadDataAndRelayoutSubviews];
}

#pragma mark Contextual Menu Data Source

- (NSUInteger)numberOfContextualMenuItems
{
	return menuItemImageArray.count;
}

#pragma mark Contextual Menu Delegate

- (UIView *)contextualMenu:(BAMContextualMenu *)contextualMenu viewForMenuItemAtIndex:(NSUInteger)index
{
	UIImage *menuItemImage = [menuItemImageArray objectAtIndex:index];
	UIImageView *menuItemImageView = [[UIImageView alloc] initWithImage:menuItemImage];
	menuItemImageView.backgroundColor = [UIColor whiteColor];
	menuItemImageView.layer.cornerRadius = menuItemImage.size.height / 2.0;
	menuItemImageView.clipsToBounds = YES;

	return menuItemImageView;
}

- (void)contextualMenu:(BAMContextualMenu *)contextualMenu didSelectItemAtIndex:(NSUInteger)index
{
	actionLabel.text = [menuItemTitleArray objectAtIndex:index];

	[actionLabel sizeToFit];
	actionLabel.frame = CGRectMake(0.0, contextualMenuTitleLabel.frame.origin.y + contextualMenuTitleLabel.frame.size.height + 10.0 + contextualMenuImageView.frame.size.height + 10.0, self.view.frame.size.width, actionLabel.frame.size.height);
	actionLabel.center = CGPointMake(self.view.frame.size.width / 2.0, actionLabel.center.y);

	[UIView animateWithDuration:1.0
						  delay:0.0
						options:UIViewAnimationOptionAutoreverse
					 animations:^{
						 actionLabel.alpha = 1.0;
					 }
					 completion:^(BOOL finished) {
						 actionLabel.alpha = 0.0;
					 }];
}

- (NSString *)contextualMenu:(BAMContextualMenu *)contextualMenu titleForMenuItemAtIndex:(NSUInteger)index
{
	return [menuItemTitleArray objectAtIndex:index];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
