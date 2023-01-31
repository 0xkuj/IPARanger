#import "IPARLoginScreenViewController.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARUtils.h"

#define sha256verification @"22b9b697f865d25a702561e47a4748ade2675de6e26ad3a9ca2a607e66b0144b"

@interface IPARLoginScreenViewController ()
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic, strong) NSMutableArray *linesStandardOutput;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@end

@implementation IPARLoginScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    [self setLoginButtons];
    [self basicSanityChecks];
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
    [self.view addSubview:textView];

}

- (void)setLoginButtons {
    // Create email text field
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[(id)[[UIColor purpleColor] CGColor], (id)[[UIColor blueColor] CGColor]];
    [self.view.layer insertSublayer:gradientLayer atIndex:0];

    self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 230, self.view.frame.size.width - 80, 45)];
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0]};
    
    self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Apple ID Email" attributes:attributes];
    self.emailTextField.layer.shadowColor = [UIColor blackColor].CGColor;
    self.emailTextField.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.emailTextField.layer.shadowOpacity = 1;
    self.emailTextField.layer.shadowRadius = 20;
    self.emailTextField.layer.cornerRadius = 10;
    self.emailTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.font = [UIFont systemFontOfSize:14];
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.returnKeyType = UIReturnKeyDone;
    self.emailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.emailTextField.backgroundColor = [UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1.0];
    self.emailTextField.textColor = [UIColor blackColor];

    // Create password text field
    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 300, self.view.frame.size.width - 80, 40)];
    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Apple Account Password" attributes:attributes];
    self.passwordTextField.layer.shadowColor = [UIColor blackColor].CGColor;
    self.passwordTextField.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.passwordTextField.layer.shadowOpacity = 1;
    self.passwordTextField.layer.shadowRadius = 20;
    self.passwordTextField.layer.cornerRadius = 10;
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordTextField.font = [UIFont systemFontOfSize:14];
    self.passwordTextField.keyboardType = UIKeyboardTypeDefault;
    //self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.backgroundColor = [UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1.0];
    self.passwordTextField.textColor = [UIColor blackColor];

    // Create login button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.65 blue:0.0 alpha:1.0];
    self.loginButton.layer.cornerRadius = 10;
    self.loginButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.loginButton.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.loginButton.layer.shadowOpacity = 1;
    self.loginButton.layer.shadowRadius = 20;
    self.loginButton.frame = CGRectMake(65, 420, self.view.frame.size.width - 130, 40);
    [self.loginButton addTarget:self action:@selector(handleLoginEmailPass) forControlEvents:UIControlEventTouchUpInside];
    self.navigationController.navigationBarHidden = YES;
    // Set the delegate of your text field
    //self.passwordTextField.delegate = self;
    // Add a tap gesture recognizer to dismiss the keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];

   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

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
    [textField resignFirstResponder];
    return YES;
}

- (void)basicSanityChecks {
    NSString *s = [IPARUtils sha256ForFileAtPath:IPATOOL_SCRIPT_PATH];
    AlertActionBlock alertBlock = ^(void) {
        exit(0);
    };
    if (s == nil) {
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"ipatool file was not found inside resources directory!" numberOfActions:1 buttonText:@"Exit IPARanger" alertBlock:alertBlock presentOn:self];
    } else if (![s isEqualToString:sha256verification]) {
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Could not verify the integrity of files" numberOfActions:1 buttonText:@"Exit IPARanger" alertBlock:alertBlock presentOn:self];
    }
    NSLog(@"omriku ipatool binary was found. all good!");
}

- (void)handleLoginEmailPass {
    NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text];
    NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
    self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
    self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];

    if ([self checkIfUserPassedAuthentication] == NO) {
        for (id obj in self.linesErrorOutput) {
            NSLog(@"omriku line error :%@", obj);
            if ([obj containsString:@"2FA"]) {
                [self handle2FADialog];
            } else if ([obj containsString:@"Missing value for"]) {
                    [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Please fill both your Apple ID Email and Password" numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            } else {
                [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:obj numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            }
        }
    }
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
    NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@%@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text, twoFARes];
    NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
    self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
    self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];

    if ([self checkIfUserPassedAuthentication] == NO) {
        for (id obj in self.linesErrorOutput) {
            NSLog(@"omriku line error :%@", obj);
            if ([obj containsString:@"An unknown error has occurred"]) {
                [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Couldn't log you in\nSomething is wrong with your credentials.\nCheck your username and password and try again" numberOfActions:1 buttonText:@"Try Again" alertBlock:nil presentOn:self];
            } else {
                [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:obj numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            }
        }
    }
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
    // Add the navigation controllers to the tab bar controller
    tabBarController.viewControllers = @[firstNavigationController, secondNavigationController];    
    // Set the tab bar controller as the root view controller
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = tabBarController;
}
@end
