#import "IPARLoginScreenViewController.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARAccountAndCredits.h"
#import "IPARUtils.h"

@interface IPARLoginScreenViewController ()
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic, strong) NSMutableArray *linesStandardOutput;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@property (nonatomic) UILabel *underLabel;
@end

@implementation IPARLoginScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    [self setLoginButtons];
    [self.view addSubview:_emailTextField];
    [self.view addSubview:_passwordTextField];
    [self.view addSubview:_loginButton];
        // Create the text view
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(110, 100, 180, 130)];
    textView.text = @"";
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:35];
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;

    // Animate the text
    NSString *fullText = @"IPARanger";
    for (int i = 0; i < fullText.length; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            textView.text = [fullText substringToIndex:i+1];
        });
    }
    _underLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 105, 220, 130)];
	[_underLabel setNumberOfLines:4];
	_underLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
	[_underLabel setText:@"\nGUI Based Application for ipatool\n\n Created by 0xkuj"];
	[_underLabel setBackgroundColor:[UIColor clearColor]];
	_underLabel.textColor = [UIColor whiteColor];
	_underLabel.textAlignment = NSTextAlignmentCenter;
	_underLabel.alpha = 0;
		
    [self.view addSubview:_underLabel];
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(increaseAlpha)
                                   userInfo:nil
                                    repeats:NO];

    [self.view addSubview:textView];
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
    self.navigationController.navigationBarHidden = YES;
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    // UIColor *lightBlue = [UIColor colorWithRed:0.15 green:0.1 blue:0.65 alpha:1.0];
    // UIColor *lightPurple = [UIColor colorWithRed:0.5 green:0.4 blue:0.2 alpha:1.0];

    // CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    // gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[(id)[UIColor colorWithRed:0.13 green:0.35 blue:0.63 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:0.81 green:0.31 blue:0.35 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:0.95 green:0.64 blue:0.32 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:1.0 green:0.86 blue:0.54 alpha:1.0].CGColor,
                             (id)[UIColor colorWithRed:1.0 green:0.94 blue:0.85 alpha:1.0].CGColor];
    gradientLayer.startPoint = CGPointMake(0.5, 0.0);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = CGPointMake(130.5, 65.5);
    spinner.color = [UIColor whiteColor];
    [spinner startAnimating];
    [alert.view addSubview:spinner];
    [self presentViewController:alert animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
        self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];

        if ([self checkIfUserPassedAuthentication] == NO) {
            for (id obj in self.linesErrorOutput) {
                NSLog(@"omriku line error :%@", obj);
                if ([obj containsString:@"2FA"]) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self handle2FADialog];
                    }];
                } else if ([obj containsString:@"Missing value for"]) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Please fill both your Apple ID Email and Password" numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
                    }];
                } else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:obj numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
                    }];
                }
            }
        }
    });
}

- (void)handle2FADialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Continue with 2FA" message:@"Please enter 2FA you got from Apple" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *twoFAResponse = textField.text;
        [self handle2FALogic:twoFAResponse];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter your 2FA you got from Apple here";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handle2FALogic:(NSString *)twoFARes {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logging in with 2FA..."
                                                                message:@"\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = CGPointMake(130.5, 65.5);
    spinner.color = [UIColor whiteColor];
    [spinner startAnimating];
    [alert.view addSubview:spinner];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@%@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text, twoFARes];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
        self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];

        if ([self checkIfUserPassedAuthentication] == NO) {
            for (id obj in self.linesErrorOutput) {
                NSLog(@"omriku line error :%@", obj);
                if ([obj containsString:@"An unknown error has occurred"]) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Can't log you in\nCheck your Apple ID and Apple ID Password and try again" numberOfActions:1 buttonText:@"Try Again" alertBlock:nil presentOn:self];
                    }];
                } else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:obj numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
                    }];
                }
            }
        }
    });
}

- (BOOL)checkIfUserPassedAuthentication {
    for (id obj in self.linesStandardOutput) {
        NSLog(@"omriku line output :%@", obj);
        if ([obj containsString:@"Authenticated as"]) {
            [self authToFile];
            [self setTabNavigation];
            return YES;
        }
    }
    return NO;
}

- (void)authToFile {
    [IPARUtils loginToFile:self.emailTextField.text];
}

- (void)setTabNavigation {
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    // Create the first view controller
    IPARSearchViewController *firstViewController = [[IPARSearchViewController alloc] init];
    firstViewController.title = @"Search";
    firstViewController.tabBarItem.image = [UIImage systemImageNamed:@"magnifyingglass"];
    firstViewController.tabBarItem.title = @"Search";
    // Create the navigation controller for the first view controller
    UINavigationController *firstNavigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];

    // Create the second view controller
    IPARDownloadViewController *secondViewController = [[IPARDownloadViewController alloc] init];
    secondViewController.title = @"Download";
    secondViewController.tabBarItem.image = [UIImage systemImageNamed:@"square.stack.3d.up"];
    secondViewController.tabBarItem.title = @"Download";
    // Create the navigation controller for the second view controller
    UINavigationController *secondNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];

	IPARAccountAndCredits *thirdViewController = [[IPARAccountAndCredits alloc] init];
	thirdViewController.title = @"Account";
	thirdViewController.tabBarItem.image = [UIImage systemImageNamed:@"person.crop.circle"];
	thirdViewController.tabBarItem.title = @"Account";
    // Create the navigation controller for the second view controller
    UINavigationController *thirdNavigationController = [[UINavigationController alloc] initWithRootViewController:thirdViewController];
    // Add the navigation controllers to the tab bar controller
    tabBarController.viewControllers = @[firstNavigationController, secondNavigationController, thirdNavigationController];
    // Set the tab bar controller as the root view controller
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = tabBarController;
}
@end
