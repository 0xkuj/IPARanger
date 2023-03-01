#import "IPARAccountAndCredits.h"
#import "IPARUtils.h"
#import "IPARLoginScreenViewController.h"
#import "IPARConstants.h"
// Define constants for padding between views
// static CGFloat const kVerticalPadding = 20.0;
// static CGFloat const kHorizontalPadding = 16.0;

@interface IPARAccountAndCredits ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *accountNameLabel;
@property (nonatomic, strong) UILabel *emailLabel;
@property (nonatomic, strong) UILabel *searchCountryLabel;
@property (nonatomic, strong) UILabel *downloadCountryLabel;
@property (nonatomic, strong) UILabel *creditsLabel;
@property (nonatomic, strong) UILabel *lastLoginDate;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIImageView *headerImageView;
@end

@implementation IPARAccountAndCredits
- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"Account";
		self.tabBarItem.image = [UIImage systemImageNamed:@"person.crop.circle"];
		self.tabBarItem.title = @"Account";
    }
    return self;
}

- (void)loadView {
    [super loadView];

    // Create a scroll view that fills the entire view controller's view
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scrollView];
    
    // Create your existing view with all the labels
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 800)]; // adjust height as needed
    [scrollView addSubview:contentView];
    
    // Add your labels to the content view
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    label1.text = @"Label 1";
    [contentView addSubview:label1];
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 50)];
    label2.text = @"Label 2";
    [contentView addSubview:label2];
    
    // Set the content size of the scroll view to the size of your content view
    scrollView.contentSize = contentView.frame.size;

    // Set the label as the background view of the table view
    //self.view.backgroundColor = [UIColor redColor];

    //Initialize the header view
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(155,120 , 80, 80)];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:40.0];
    self.headerImageView.image = [UIImage systemImageNamed:@"person.crop.circle" withConfiguration:config];
    self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    //self.headerImageView.center = headerView.center;
    // CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    // gradientLayer.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, headerView.frame.size.height);
    // UIColor *lightBlue = [UIColor colorWithRed:0.15 green:0.1 blue:0.65 alpha:1.0];
    // UIColor *lightPurple = [UIColor colorWithRed:0.5 green:0.4 blue:0.2 alpha:1.0];

    // CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    // gradientLayer.frame = self.view.bounds;
    // gradientLayer.colors = @[(id)[UIColor colorWithRed:13/255.0 green:23/255.0 blue:33/255.0 alpha:1.0].CGColor,
    //                          (id)[UIColor colorWithRed:27/255.0 green:40/255.0 blue:56/255.0 alpha:1.0].CGColor,
    //                          (id)[UIColor colorWithRed:40/255.0 green:57/255.0 blue:78/255.0 alpha:1.0].CGColor,
    //                          (id)[UIColor colorWithRed:50/255.0 green:72/255.0 blue:98/255.0 alpha:1.0].CGColor];
    // gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    // gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    // [headerView.layer insertSublayer:gradientLayer atIndex:0];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0,-100,self.view.frame.size.width, 900);
    gradientLayer.colors = @[(id)[UIColor colorWithRed:58/255.0 green:97/255.0 blue:156/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:19/255.0 green:39/255.0 blue:70/255.0 alpha:1.0].CGColor];
    gradientLayer.locations = @[@0.0, @1.0];
    gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [headerView.layer insertSublayer:gradientLayer atIndex:0];

    //headerView.backgroundColor =  UIColor.systemBackgroundColor;
    [contentView addSubview:headerView];
    [contentView addSubview:self.headerImageView];
    [self.headerImageView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor].active = YES;
    [self.headerImageView.topAnchor constraintEqualToAnchor:headerView.safeAreaLayoutGuide.topAnchor constant:16].active = YES;

    self.accountNameLabel = [[UILabel alloc] init];
    self.accountNameLabel.text = [IPARUtils getKeyFromFile:@"AccountName" defaultValueIfNil:@"N/A"];
    self.accountNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.accountNameLabel];
    [self.accountNameLabel.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor constant:16].active = YES;
    [self.accountNameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    self.emailLabel = [[UILabel alloc] init];
    self.emailLabel.text = [IPARUtils getKeyFromFile:@"AccountEmail" defaultValueIfNil:@"N/A"];
    self.emailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.emailLabel];
    [self.emailLabel.topAnchor constraintEqualToAnchor:self.accountNameLabel.bottomAnchor constant:8].active = YES;
    [self.emailLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    self.logoutButton = [[UIButton alloc] init];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    self.logoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.logoutButton.titleLabel setFont:[UIFont systemFontOfSize:24.0 weight:UIFontWeightBold]];
    [self.logoutButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.logoutButton addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.logoutButton];
    [self.logoutButton.topAnchor constraintEqualToAnchor:self.emailLabel.bottomAnchor constant:24].active = YES;
    [self.logoutButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    self.lastLoginDate = [[UILabel alloc] init];
    self.lastLoginDate.text = [NSString stringWithFormat:@"Login Date: %@", [IPARUtils getKeyFromFile:@"lastLoginDate" defaultValueIfNil:@"N/A"]];
    self.lastLoginDate.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.lastLoginDate];
    [self.lastLoginDate.topAnchor constraintEqualToAnchor:self.emailLabel.bottomAnchor constant:96].active = YES;
    [self.lastLoginDate.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;

    self.searchCountryLabel = [[UILabel alloc] init];
    NSString *searchCountry = [IPARUtils getKeyFromFile:@"AccountCountrySearch" defaultValueIfNil:@"US"];
    self.searchCountryLabel.text = [NSString stringWithFormat:@"Search In Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:searchCountry], searchCountry];
    self.searchCountryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.searchCountryLabel];
    [self.searchCountryLabel.topAnchor constraintEqualToAnchor:self.lastLoginDate.bottomAnchor constant:16].active = YES;
    [self.searchCountryLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
    
    self.downloadCountryLabel = [[UILabel alloc] init];
    NSString *downloadCountry = [IPARUtils getKeyFromFile:@"AccountCountryDownload" defaultValueIfNil:@"US"];
    self.downloadCountryLabel.text = [NSString stringWithFormat:@"Download From Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:downloadCountry], downloadCountry];
    self.downloadCountryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.downloadCountryLabel];
    [self.downloadCountryLabel.topAnchor constraintEqualToAnchor:self.searchCountryLabel.bottomAnchor constant:16].active = YES;
    [self.downloadCountryLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;


    UILabel *createdByLabel = [[UILabel alloc] init];
    createdByLabel.text = @"Created by 0xkuj";
    createdByLabel.font = [UIFont boldSystemFontOfSize:24];
    createdByLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:createdByLabel];
    [createdByLabel.topAnchor constraintEqualToAnchor:self.downloadCountryLabel.bottomAnchor constant:32].active = YES;
    [createdByLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UIButton *followMeTwitter = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    [followMeTwitter setTitle:@"Follow Me On Twitter" forState:UIControlStateNormal];
    [followMeTwitter setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    followMeTwitter.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [followMeTwitter sizeToFit]; // resize button to fit title
    [followMeTwitter setImage:[UIImage imageNamed:@"Twitter@2x.png"] forState:UIControlStateNormal];
    [followMeTwitter addTarget:self action:@selector(openTW) forControlEvents:UIControlEventTouchUpInside];
     followMeTwitter.translatesAutoresizingMaskIntoConstraints = NO;
    [followMeTwitter setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [followMeTwitter setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    [contentView addSubview:followMeTwitter];
    [followMeTwitter.topAnchor constraintEqualToAnchor:createdByLabel.bottomAnchor constant:16].active = YES;
    [followMeTwitter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UIButton *buyMeCoffeePP = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    [buyMeCoffeePP setTitle:@"Buy me a coffee" forState:UIControlStateNormal];
    [buyMeCoffeePP setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    buyMeCoffeePP.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [buyMeCoffeePP sizeToFit]; // resize button to fit title
    [buyMeCoffeePP setImage:[UIImage imageNamed:@"donate@2x.png"] forState:UIControlStateNormal];
    [buyMeCoffeePP addTarget:self action:@selector(openPP) forControlEvents:UIControlEventTouchUpInside];
    buyMeCoffeePP.translatesAutoresizingMaskIntoConstraints = NO;
    [buyMeCoffeePP setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [buyMeCoffeePP setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    buyMeCoffeePP.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; 
    [contentView addSubview:buyMeCoffeePP];
    [buyMeCoffeePP.topAnchor constraintEqualToAnchor:followMeTwitter.bottomAnchor constant:16].active = YES;
    [buyMeCoffeePP.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UIButton *followMeGithub = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    [followMeGithub setTitle:@"My GitHub" forState:UIControlStateNormal];
    [followMeGithub setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    followMeGithub.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [followMeGithub sizeToFit]; // resize button to fit title
    [followMeGithub setImage:[UIImage imageNamed:@"GitHub@2x.png"] forState:UIControlStateNormal];
    [followMeGithub addTarget:self action:@selector(openGithub) forControlEvents:UIControlEventTouchUpInside];
    followMeGithub.translatesAutoresizingMaskIntoConstraints = NO;
    [followMeGithub setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [followMeGithub setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    [contentView addSubview:followMeGithub];
    [followMeGithub.topAnchor constraintEqualToAnchor:buyMeCoffeePP.bottomAnchor constant:16].active = YES;
    [followMeGithub.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UILabel *credits = [[UILabel alloc] init];
    credits.text = @"Special Thanks";
    credits.font = [UIFont boldSystemFontOfSize:24];
    credits.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:credits];
    [credits.topAnchor constraintEqualToAnchor:buyMeCoffeePP.bottomAnchor constant:82].active = YES;
    [credits.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UILabel *majdLabel = [[UILabel alloc] init];
    majdLabel.text = @"Majd Alfhaily (ipatool)";
    majdLabel.font = [UIFont boldSystemFontOfSize:14.0];
    majdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:majdLabel];
    [majdLabel.topAnchor constraintEqualToAnchor:credits.bottomAnchor constant:8].active = YES;
    [majdLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    UILabel *angelXwindLabel = [[UILabel alloc] init];
    angelXwindLabel.text = @"angelXwind (appinst)";
    angelXwindLabel.font = [UIFont boldSystemFontOfSize:14.0];
    angelXwindLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:angelXwindLabel];
    [angelXwindLabel.topAnchor constraintEqualToAnchor:majdLabel.bottomAnchor constant:8].active = YES;
    [angelXwindLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
}

- (void)updateCountry {
    NSString *searchCountry = [IPARUtils getKeyFromFile:@"AccountCountrySearch" defaultValueIfNil:@"US"];
    self.searchCountryLabel.text = [NSString stringWithFormat:@"Search In Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:searchCountry], searchCountry];
    NSString *downloadCountry = [IPARUtils getKeyFromFile:@"AccountCountryDownload" defaultValueIfNil:@"US"];
    self.downloadCountryLabel.text = [NSString stringWithFormat:@"Download From Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:downloadCountry], downloadCountry];
}

- (void)handleLogout {
    NSDictionary *didLogoutOK = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"%@ auth revoke", kIpatoolScriptPath]];
    if ([didLogoutOK[kstdOutput][0] containsString:@"Revoked credentials for"] || [didLogoutOK[kerrorOutput][0] containsString:@"No credentials available to revoke"])
    {
        [self logoutAction];
    }
}

- (void)logoutAction {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init]; 
        // Step 1: Pop all view controllers from the navigation stack
        [self.navigationController popToRootViewControllerAnimated:NO];
        // Step 2: Remove the tabbarcontroller from the window's rootViewController
        [self.tabBarController.view removeFromSuperview];
        // Step 3: Instantiate your login screen view controller and set it as the new rootViewController of the window
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        window.rootViewController = navController;
        [IPARUtils accountDetailsToFile:@"" authName:@"" authenticated:@"NO"];  
    };
    [IPARUtils presentDialogWithTitle:@"IPARanger\nLogout" message:@"You are about to perform logout\nAre you sure?" hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Yes" alertCancelBlock:nil withCancelText:@"No" presentOn:self];
}

-(void)openTW {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.twitter.com/omrkujman"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

-(void)openPP {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.paypal.me/0xkuj"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

-(void)openGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://github.com/0xkuj"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

@end

