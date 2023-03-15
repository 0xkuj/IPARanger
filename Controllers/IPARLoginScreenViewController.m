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
@property (nonatomic) NSMutableArray *linesStandardOutput;
@property (nonatomic) NSMutableArray *linesErrorOutput;
@property (nonatomic) UILabel *underLabel;
@end

@implementation IPARLoginScreenViewController

- (void)loadView {
    [super loadView];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    self.navigationController.navigationBarHidden = YES;
    [self setLoginButtons];
    [self configureMainScreenGradient];
    [self setupTextAndAnimations];
    [self setupVersionLabel];
}

- (void)setupTextAndAnimations {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(110, 100, 180, 130)];
    textView.text = @"";
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:35];
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;
    NSString *fullText = @"IPARanger";
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

- (void)setupVersionLabel {
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionLabel.text =  @"Version 1.4";
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
    self.loginButton = [self setLoginButtonPrefsWithFrame:CGRectMake(65, 420, self.view.frame.size.width - 130, 40) title:@"Login"];
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
    gradientLayer.colors = @[(id)[UIColor colorWithRed:13/255.0 green:23/255.0 blue:33/255.0 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:27/255.0 green:40/255.0 blue:56/255.0 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:40/255.0 green:57/255.0 blue:78/255.0 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:50/255.0 green:72/255.0 blue:98/255.0 alpha:1.0].CGColor];
    gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
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
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
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
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[kstdOutput];
        self.linesErrorOutput = standardAndErrorOutputs[kerrorOutput];

        if ([self checkIfUserPassedAuthentication] == NO) {
            [self analyzeErrorsOrContinueTo2FA];
        }
    });
}

- (void)analyzeErrorsOrContinueTo2FA {
    for (id obj in self.linesErrorOutput) {
        if ([obj containsString:@"2FA"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self handle2FADialog];
            }];
        } else if ([obj containsString:@"Missing value for"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"Please fill both your Apple ID Email and Password" hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:obj hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }];
        }
    }
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
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[kstdOutput];
        self.linesErrorOutput = standardAndErrorOutputs[kerrorOutput];

        if ([self checkIfUserPassedAuthentication] == NO) {
            for (id obj in self.linesErrorOutput) {
                if ([obj containsString:@"An unknown error has occurred"]) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"Can't log you in\nCheck your Apple ID and password and try again" hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
                    }];
                } else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:obj hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                    }];
                }
            }
        }
    });
}

- (BOOL)checkIfUserPassedAuthentication {
    for (id obj in self.linesStandardOutput) {
        if ([obj containsString:@"Authenticated as"]) {
            [self authToFile:obj];
            [self setTabNavigation];
            return YES;
        }
    }
    return NO;
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
