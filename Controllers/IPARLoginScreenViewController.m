#import "IPARLoginScreenViewController.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARAccountAndCreditsController.h"
#import "../Utils/IPARUtils.h"
#import "../Extensions/IPARConstants.h"

@interface IPARLoginScreenViewController ()
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic) UIButton *eyeButton;
@property (nonatomic) NSDictionary *lastCommandResult;
@property (nonatomic) UILabel *underLabel;
@property (nonatomic) int welcomeMessageCounter;
@property (nonatomic) NSTimer *welcomeMessageTimer;
@end

@implementation IPARLoginScreenViewController
- (void)loadView {
    [super loadView];
    _lastCommandResult = [NSDictionary dictionary];
    self.welcomeMessageCounter = 10;
    self.welcomeMessageTimer = nil;
    self.navigationController.navigationBarHidden = YES;
    [self setLoginButtons];
    [self configureMainScreenGradient];
    [self setupTextAndAnimations];
    [self setupVersionLabel];
    [self setupGHLabel];
    [self setupXLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[IPARUtils getKeyFromFile:kFirstLaunchKey defaultValueIfNil:kUnknownValue] isEqualToString:kFirstLaunchDoneKey]) {
        [self showFirstTimeAlert];
    }
}

- (void)showFirstTimeAlert {
    if (self.welcomeMessageTimer != nil) {
        [self.welcomeMessageTimer invalidate];
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Welcome to IPA Ranger!"
                                                                             message:@"This app is an open source project I worked hard to maintain. Your account and password will be sent directly to Apple servers and will not be saved on your device.\n\nIf you have any concerns, please check out the source code below (and consider dropping a star there as well ;) )\n\nEnjoy!"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
     __weak typeof(self) weakSelf = self;
    UIAlertAction *githubAction = [UIAlertAction actionWithTitle:@"Checkout IPA Ranger Code"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [IPARUtils openGithub];
                                                            [weakSelf showFirstTimeAlert];
                                                        }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK (10...)"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [IPARUtils saveKeyToFile:kFirstLaunchKey withValue:kFirstLaunchDoneKey];
                                                     }];

    [alertController addAction:githubAction];
    [alertController addAction:okAction];
    okAction.enabled = NO;
    [self presentViewController:alertController animated:YES completion:^{
            self.welcomeMessageTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            self.welcomeMessageCounter--;
            if (self.welcomeMessageCounter > 0) {
                [okAction setValue:[NSString stringWithFormat:@"OK (%d...)", self.welcomeMessageCounter] forKey:@"title"];
            } else {
                [okAction setValue:@"OK" forKey:@"title"];
                okAction.enabled = YES;
                [self.welcomeMessageTimer invalidate];
            }
        }];
    }];
}

- (void)setupTextAndAnimations {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(110, 100, 180, 130)];
    textView.text = @"";
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:35];
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;
    NSString *fullText = @"IPA Ranger";
    for (int i = 0; i < fullText.length; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            textView.text = [fullText substringToIndex:i+1];
        });
    }

    [self setupUnderlabel];
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(increaseAlpha)
                                   userInfo:nil
                                    repeats:NO];

    [self.view addSubview:textView];
    [textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16].active = YES;
    [textView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
}

- (void)setupUnderlabel {
    self.underLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 105, 220, 130)];
	[self.underLabel setNumberOfLines:4];
	self.underLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
	[self.underLabel setText:@"\nGUI Based Application for ipatool\n\n Created by 0xkuj"];
	[self.underLabel setBackgroundColor:[UIColor clearColor]];
	self.underLabel.textColor = [UIColor whiteColor];
	self.underLabel.textAlignment = NSTextAlignmentCenter;
	self.underLabel.alpha = 0;
    [self.view addSubview:self.underLabel];
}

- (void)setupGHLabel {
    UIButton *followMeGithub = [IPARUtils createButtonWithImageName:kGithubIcon title:@"Source Code" fontSize:16.0 selectorName:@"openGithub" frame:CGRectMake(0,0,150,50)];
    [self.view addSubview:followMeGithub];
    [NSLayoutConstraint activateConstraints:@[
        [followMeGithub.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [followMeGithub.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-110]
    ]];
}

- (void)setupXLabel {
    UIButton *followMeTwitter = [IPARUtils createButtonWithImageName:kTwitterIcon title:@"Need help?" fontSize:16.0 selectorName:@"openTW" frame:CGRectMake(0,0,150,50)];
    [self.view addSubview:followMeTwitter];
    [NSLayoutConstraint activateConstraints:@[
        [followMeTwitter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [followMeTwitter.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-60]
    ]];
}

- (void)setupVersionLabel {
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionLabel.text = kIPARangerVersion;
    versionLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:versionLabel];
    [NSLayoutConstraint activateConstraints:@[
        [versionLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [versionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
}

/* provides the animation */
- (void)increaseAlpha
{
	[UIView animateWithDuration:0.7 animations:^{
		self.underLabel.alpha = 1;
	}];
}	

- (void)setLoginButtons {
    self.emailTextField = [self setTextFieldsViewWithFrame:CGRectMake(40, 230, self.view.frame.size.width - 80, 45) title:@"Apple ID Email"];
    self.passwordTextField = [self setTextFieldsViewWithFrame:CGRectMake(40, 300, self.view.frame.size.width - 80, 45) title:@"Apple ID Password"];
    self.passwordTextField.secureTextEntry = YES;
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.loginButton = [self setLoginButtonPrefsWithFrame:CGRectMake(65, 420, self.view.frame.size.width - 130, 40) title:kLoginTitle];
    [self configureEyeButton];
    [self.view addSubview:self.emailTextField];
    [self.view addSubview:self.passwordTextField];
    [self.view addSubview:self.loginButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)configureMainScreenGradient {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:30/255.0 green:50/255.0 blue:80/255.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:50/255.0 green:85/255.0 blue:120/255.0 alpha:1.0].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)configureEyeButton {
    self.eyeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.eyeButton setImage:[UIImage systemImageNamed:kPasswordEyeButtonOpen] forState:UIControlStateNormal];
    [self.eyeButton addTarget:self action:@selector(togglePasswordVisibility:) forControlEvents:UIControlEventTouchUpInside];
    self.eyeButton.frame = CGRectMake(0, 0, 30, self.passwordTextField.frame.size.height);
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, self.passwordTextField.frame.size.height)];
    rightView.contentMode = UIViewContentModeRight;
    [rightView addSubview:self.eyeButton];
    self.passwordTextField.rightView = rightView;
    self.passwordTextField.rightViewMode = UITextFieldViewModeAlways;
}

- (void)togglePasswordVisibility:(UIButton *)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    NSString *imageName = self.passwordTextField.secureTextEntry ? kPasswordEyeButtonOpen : kPasswordEyeButtonClosed;
    [self.eyeButton setImage:[UIImage systemImageNamed:imageName] forState:UIControlStateNormal];
}

- (UIButton *)setLoginButtonPrefsWithFrame:(CGRect)frame title:(NSString *)title {
    UIButton* loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loginButton setTitle:title forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loginButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.1 blue:0.2 alpha:1.0];
    loginButton.layer.cornerRadius = 10;
    loginButton.layer.shadowColor = [UIColor blackColor].CGColor;
    loginButton.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    loginButton.layer.shadowOpacity = 1;
    loginButton.layer.shadowRadius = 20;
    loginButton.frame = frame;
    [loginButton addTarget:self action:@selector(handleLoginEmailPass) forControlEvents:UIControlEventTouchUpInside];
    return loginButton;
}

- (UITextField *)setTextFieldsViewWithFrame:(CGRect)frame title:(NSString *)title {
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0]};
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    textField.layer.shadowColor = [UIColor blackColor].CGColor;
    textField.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    textField.layer.shadowOpacity = 1;
    textField.layer.shadowRadius = 20;
    textField.layer.cornerRadius = 10;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.font = [UIFont systemFontOfSize:14];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.returnKeyType = UIReturnKeyDone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.backgroundColor = [UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1.0];
    textField.textColor = [UIColor blackColor];

    return textField;
}

// Implement the dismissKeyboard method
- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    CGRect newFrame = self.view.frame;

    newFrame.origin.y = -20;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = newFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect newFrame = self.view.frame;
    newFrame.origin.y = 0;

    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = newFrame;
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        [self handleLoginEmailPass];
        return YES;
    }
    [textField resignFirstResponder];
    return NO;
}

- (void)handleLoginEmailPass {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logging in..."
                                                                message:@"\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert.view addSubview:[IPARUtils createActivitiyIndicatorWithPoint:CGPointMake(130.5, 65.5)]];
    [self presentViewController:alert animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSString *commandToExecute = [NSString stringWithFormat:kLoginCommandPathAccountPassword, kIpatoolScriptPath, self.emailTextField.text, self.passwordTextField.text];
        self.lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];
        if ([self.lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:self.lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }]; 
        } else if ([self.lastCommandResult[kJsonResponseContent] containsString:@"2FA"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self handle2FADialog];
            }];
        } else if ([self.lastCommandResult[kJsonKeySuccess] boolValue] == YES) {
            [self userAuthenticated];
        }
    });
}

- (void)userAuthenticated {
    [self authToFile:self.lastCommandResult[@"name"]];
    [self setTabNavigation];
}

- (void)handle2FADialog {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSString *twoFAResponse = textField.text;
        [self handle2FALogic:twoFAResponse];
    };

    AlertTextFieldBlock alertBlockTextfield = ^(UITextField *textField) {
            textField.placeholder = textField.text;
    };

    [IPARUtils presentDialogWithTitle:@"Continue with 2FA" message:@"Please enter the 2FA you got from Apple" hasTextfield:YES withTextfieldBlock:alertBlockTextfield
                    alertConfirmationBlock:alertBlockConfirm withConfirmText:@"OK" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
}

- (void)handle2FALogic:(NSString *)twoFARes {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logging in with 2FA..."
                                                                message:@"\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert.view addSubview:[IPARUtils createActivitiyIndicatorWithPoint:CGPointMake(130.5, 65.5)]];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSString *commandToExecute = [NSString stringWithFormat:kLoginCommandPathAccountPassword2FA, kIpatoolScriptPath, self.emailTextField.text, self.passwordTextField.text, twoFARes];
        self.lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];
        if ([self.lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError] || twoFARes == nil || twoFARes.length == 0) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:self.lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }]; 
        } else if ([self.lastCommandResult[kJsonKeySuccess] boolValue] == YES) {
            [self userAuthenticated];
        }
    });
}

- (void)authToFile:(NSString *)authNameFromOutput {
    [IPARUtils accountDetailsToFile:self.emailTextField.text authName:authNameFromOutput authenticated:@"YES"];
}

- (void)setTabNavigation {
    IPARSearchViewController *searchVC = [[IPARSearchViewController alloc] init];
    UINavigationController *searchNC = [[UINavigationController alloc] initWithRootViewController:searchVC];    

    IPARDownloadViewController *downloadVC = [[IPARDownloadViewController alloc] init];
    UINavigationController *downloadNC = [[UINavigationController alloc] initWithRootViewController:downloadVC];    

    IPARAccountAndCredits *accountVC = [[IPARAccountAndCredits alloc] init];
    UINavigationController *accountNC = [[UINavigationController alloc] initWithRootViewController:accountVC]; 

    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[searchNC, downloadNC, accountNC];

    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = tabBarController;
}
@end
