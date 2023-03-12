#import "IPARAccountAndCreditsController.h"
#import "IPARLoginScreenViewController.h"
#import "../Extensions/IPARConstants.h"
#import "../Utils/IPARUtils.h"

//those are the only one gets referenced later on
@interface IPARAccountAndCredits ()
@property (nonatomic) UILabel *searchCountryLabel;
@property (nonatomic) UILabel *downloadCountryLabel;
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

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scrollView];
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 800)]; // adjust height as needed
    [scrollView addSubview:contentView];
    scrollView.contentSize = contentView.frame.size;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(155,120 , 80, 80)];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:40.0];
    headerImageView.image = [UIImage systemImageNamed:@"person.crop.circle" withConfiguration:config];
    headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0,-100,self.view.frame.size.width, 900);
    gradientLayer.colors = @[(id)[UIColor colorWithRed:58/255.0 green:97/255.0 blue:156/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:19/255.0 green:39/255.0 blue:70/255.0 alpha:1.0].CGColor];
    gradientLayer.locations = @[@0.0, @1.0];
    gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [headerView.layer insertSublayer:gradientLayer atIndex:0];
    [contentView addSubview:headerView];
    [contentView addSubview:headerImageView];

    UILabel *accountNameLabel = [self createLabelWithText:[IPARUtils getKeyFromFile:kAccountNameKeyFromFile defaultValueIfNil:kUnknownValue] fontSize:17.0];
    [contentView addSubview:accountNameLabel];

    UILabel *emailLabel = [self createLabelWithText:[IPARUtils getKeyFromFile:kAccountEmailKeyFromFile defaultValueIfNil:kUnknownValue] fontSize:17.0];
    [contentView addSubview:emailLabel];

    UIButton *logoutButton = [self createButtonWithImageName:nil title:@"Logout" fontSize:24.0 selectorName:@"handleLogout" frame:CGRectMake(0,0,0,0)];
    [logoutButton.titleLabel setFont:[UIFont systemFontOfSize:24.0 weight:UIFontWeightBold]];
    [contentView addSubview:logoutButton];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd | HH:mm:ss"];
    NSDate *date = [IPARUtils getKeyFromFile:@"lastLoginDate" defaultValueIfNil:kUnknownValue];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    UILabel *lastLoginDate = [self createLabelWithText:[NSString stringWithFormat:@"Login Date: %@", formattedDate] fontSize:17.0];
    [contentView addSubview:lastLoginDate];

    NSString *searchCountry = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.searchCountryLabel = [self createLabelWithText:[NSString stringWithFormat:@"Search In Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:searchCountry], searchCountry] fontSize:17.0];
    [contentView addSubview:self.searchCountryLabel];

    NSString *downloadCountry = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.downloadCountryLabel = [self createLabelWithText:[NSString stringWithFormat:@"Download From Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:downloadCountry], downloadCountry] fontSize:17.0];
    [contentView addSubview:self.downloadCountryLabel];

    UILabel *createdByLabel = [self createLabelWithText:@"Created by 0xkuj" fontSize:24];
    [contentView addSubview:createdByLabel];

    UIButton *followMeTwitter = [self createButtonWithImageName:@"Twitter@2x.png" title:@"Follow Me On Twitter" fontSize:16.0 selectorName:@"openTW" frame:CGRectMake(0,0,150,50)];
    [contentView addSubview:followMeTwitter];

    UIButton *buyMeCoffeePP = [self createButtonWithImageName:@"donate@2x.png" title:@"Buy me a coffee" fontSize:16.0 selectorName:@"openPP" frame:CGRectMake(0,0,300,50)];
    //buyMeCoffeePP.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; 
    [contentView addSubview:buyMeCoffeePP];

    UIButton *followMeGithub = [self createButtonWithImageName:@"GitHub@2x.png" title:@"My GitHub" fontSize:16.0 selectorName:@"openGithub" frame:CGRectMake(0,0,150,50)];
    [contentView addSubview:followMeGithub];

    UILabel *credits = [self createLabelWithText:@"Special Thanks" fontSize:24.0];
    [contentView addSubview:credits];

    UILabel *majdLabel = [self createLabelWithText:@"Majd Alfhaily (ipatool)" fontSize:14.0];
    [contentView addSubview:majdLabel];

    UILabel *angelXwindLabel = [self createLabelWithText:@"angelXwind (appinst)" fontSize:14.0];
    [contentView addSubview:angelXwindLabel];


    [NSLayoutConstraint activateConstraints:@[
        [headerImageView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [headerImageView.topAnchor constraintEqualToAnchor:headerView.safeAreaLayoutGuide.topAnchor constant:16],
        [accountNameLabel.topAnchor constraintEqualToAnchor:headerImageView.bottomAnchor constant:16],
        [accountNameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [emailLabel.topAnchor constraintEqualToAnchor:accountNameLabel.bottomAnchor constant:8],
        [emailLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [logoutButton.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:24],
        [logoutButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [lastLoginDate.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:96],
        [lastLoginDate.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.searchCountryLabel.topAnchor constraintEqualToAnchor:lastLoginDate.bottomAnchor constant:16],
        [self.searchCountryLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.downloadCountryLabel.topAnchor constraintEqualToAnchor:self.searchCountryLabel.bottomAnchor constant:16],
        [self.downloadCountryLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [createdByLabel.topAnchor constraintEqualToAnchor:self.downloadCountryLabel.bottomAnchor constant:32],
        [createdByLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [followMeTwitter.topAnchor constraintEqualToAnchor:createdByLabel.bottomAnchor constant:16],
        [followMeTwitter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buyMeCoffeePP.topAnchor constraintEqualToAnchor:followMeTwitter.bottomAnchor constant:16],
        [buyMeCoffeePP.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [followMeGithub.topAnchor constraintEqualToAnchor:buyMeCoffeePP.bottomAnchor constant:16],
        [followMeGithub.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [credits.topAnchor constraintEqualToAnchor:buyMeCoffeePP.bottomAnchor constant:82],
        [credits.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [majdLabel.topAnchor constraintEqualToAnchor:credits.bottomAnchor constant:8],
        [majdLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [angelXwindLabel.topAnchor constraintEqualToAnchor:majdLabel.bottomAnchor constant:8],
        [angelXwindLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
}

- (UIButton *)createButtonWithImageName:(NSString *)imageName title:(NSString *)title fontSize:(CGFloat)fontSize selectorName:(NSString *)selectorName frame:(CGRect)frame {
    SEL selector = NSSelectorFromString(selectorName);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [button sizeToFit];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    return button;
}

-(UILabel *)createLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:fontSize];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (void)updateCountry {
    NSString *searchCountry = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.searchCountryLabel.text = [NSString stringWithFormat:@"Search In Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:searchCountry], searchCountry];
    NSString *downloadCountry = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
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

