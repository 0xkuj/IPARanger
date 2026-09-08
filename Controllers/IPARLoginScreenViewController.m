#import "IPARLoginScreenViewController.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARAccountAndCreditsController.h"
#import "../Utils/IPARUtils.h"
#import "../Extensions/IPARConstants.h"
#import "../Views/IPARDialog.h"

@interface IPARLoginScreenViewController ()
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic) UIButton *eyeButton;
@property (nonatomic) NSDictionary *lastCommandResult;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UILabel *titleLabel;
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
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[IPARUtils getKeyFromFile:kFirstLaunchKey defaultValueIfNil:kUnknownValue] isEqualToString:kFirstLaunchDoneKey]) {
        [self showFirstTimeAlert];
    }
}

#pragma mark - UI construction

- (void)buildUI {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 14.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];

    UIView *header = [self makeHeader];

    self.emailTextField = [self makeFieldWithPlaceholder:@"Apple ID email" iconSystemName:@"envelope.fill" secure:NO];
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailTextField.delegate = self;

    self.passwordTextField = [self makeFieldWithPlaceholder:@"Password" iconSystemName:@"lock.fill" secure:YES];
    self.passwordTextField.delegate = self;
    [self attachEyeToPasswordField];

    self.loginButton = [self makeLoginButton];
    UIButton *guestButton = [self makeGuestButton];

    UIView *footer = [self makeFooter];

    [stack addArrangedSubview:header];
    [stack addArrangedSubview:self.emailTextField];
    [stack addArrangedSubview:self.passwordTextField];
    [stack addArrangedSubview:self.loginButton];
    [stack addArrangedSubview:guestButton];
    [stack addArrangedSubview:footer];

    [stack setCustomSpacing:34 afterView:header];
    [stack setCustomSpacing:20 afterView:self.passwordTextField];
    [stack setCustomSpacing:10 afterView:self.loginButton];
    [stack setCustomSpacing:34 afterView:guestButton];

    UILayoutGuide *content = scrollView.contentLayoutGuide;
    UILayoutGuide *frame = scrollView.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:56],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-28],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [stack.widthAnchor constraintEqualToAnchor:frame.widthAnchor constant:-56],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [scrollView addGestureRecognizer:tap];

    [self startTitleTypewriter];
}

- (UIView *)makeHeader {
    UIStackView *header = [[UIStackView alloc] init];
    header.axis = UILayoutConstraintAxisVertical;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 14.0;

    // App icon in a rounded-square badge with a soft shadow.
    UIView *iconWrap = [[UIView alloc] init];
    iconWrap.translatesAutoresizingMaskIntoConstraints = NO;
    iconWrap.layer.shadowColor = [UIColor blackColor].CGColor;
    iconWrap.layer.shadowOpacity = 0.18;
    iconWrap.layer.shadowRadius = 14.0;
    iconWrap.layer.shadowOffset = CGSizeMake(0, 8);

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppIcon60x60"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFill;
    icon.layer.cornerRadius = 18.0;
    icon.layer.cornerCurve = kCACornerCurveContinuous;
    icon.clipsToBounds = YES;
    [iconWrap addSubview:icon];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = kIPARangerLoginSubtitle;
    subtitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.numberOfLines = 0;

    [header addArrangedSubview:iconWrap];
    [header addArrangedSubview:self.titleLabel];
    [header addArrangedSubview:subtitle];
    [header setCustomSpacing:18 afterView:iconWrap];
    [header setCustomSpacing:6 afterView:self.titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [iconWrap.widthAnchor constraintEqualToConstant:78],
        [iconWrap.heightAnchor constraintEqualToConstant:78],
        [icon.topAnchor constraintEqualToAnchor:iconWrap.topAnchor],
        [icon.bottomAnchor constraintEqualToAnchor:iconWrap.bottomAnchor],
        [icon.leadingAnchor constraintEqualToAnchor:iconWrap.leadingAnchor],
        [icon.trailingAnchor constraintEqualToAnchor:iconWrap.trailingAnchor],
    ]];
    return header;
}

- (void)startTitleTypewriter {
    NSString *fullText = @"IPA Ranger";
    self.titleLabel.text = @"";
    for (NSUInteger i = 0; i < fullText.length; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.07 * (i + 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.titleLabel.text = [fullText substringToIndex:i + 1];
        });
    }
}

- (UITextField *)makeFieldWithPlaceholder:(NSString *)placeholder iconSystemName:(NSString *)iconName secure:(BOOL)secure {
    UITextField *field = [[UITextField alloc] init];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.font = [UIFont systemFontOfSize:16];
    field.textColor = [UIColor labelColor];
    field.backgroundColor = [UIColor tertiarySystemFillColor];
    field.layer.cornerRadius = 12.0;
    field.layer.cornerCurve = kCACornerCurveContinuous;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.returnKeyType = UIReturnKeyDone;
    field.secureTextEntry = secure;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
        attributes:@{NSForegroundColorAttributeName: [UIColor secondaryLabelColor]}];

    // Leading icon.
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightRegular];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName withConfiguration:cfg]];
    icon.tintColor = [UIColor tertiaryLabelColor];
    icon.contentMode = UIViewContentModeCenter;
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 42, 54)];
    icon.frame = CGRectMake(14, 0, 22, 54);
    [leftView addSubview:icon];
    field.leftView = leftView;
    field.leftViewMode = UITextFieldViewModeAlways;

    [field.heightAnchor constraintEqualToConstant:54].active = YES;
    return field;
}

- (void)attachEyeToPasswordField {
    self.eyeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.eyeButton setImage:[UIImage systemImageNamed:kPasswordEyeButtonOpen] forState:UIControlStateNormal];
    self.eyeButton.tintColor = [UIColor tertiaryLabelColor];
    [self.eyeButton addTarget:self action:@selector(togglePasswordVisibility:) forControlEvents:UIControlEventTouchUpInside];
    self.eyeButton.frame = CGRectMake(0, 0, 30, 54);
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 54)];
    [rightView addSubview:self.eyeButton];
    self.passwordTextField.rightView = rightView;
    self.passwordTextField.rightViewMode = UITextFieldViewModeAlways;
}

- (UIButton *)makeLoginButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:kLoginTitle forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    button.backgroundColor = [IPARDialog accentColor];
    button.layer.cornerRadius = 14.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    [button addTarget:self action:@selector(handleLoginEmailPass) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(loginButtonDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(loginButtonUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [button.heightAnchor constraintEqualToConstant:52].active = YES;
    return button;
}

- (void)loginButtonDown:(UIButton *)sender { [UIView animateWithDuration:0.08 animations:^{ sender.alpha = 0.7; }]; }
- (void)loginButtonUp:(UIButton *)sender { [UIView animateWithDuration:0.18 animations:^{ sender.alpha = 1.0; }]; }

- (UIButton *)makeGuestButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"Browse downloaded apps" forState:UIControlStateNormal];
    [button setTitleColor:[IPARDialog accentColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [button addTarget:self action:@selector(enterGuestMode) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(loginButtonDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(loginButtonUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    return button;
}

- (void)enterGuestMode {
    [IPARUtils setGuestMode:YES];
    [self setTabNavigation];
}

- (UIView *)makeFooter {
    UIStackView *footer = [[UIStackView alloc] init];
    footer.axis = UILayoutConstraintAxisVertical;
    footer.alignment = UIStackViewAlignmentCenter;
    footer.spacing = 12.0;

    UIStackView *links = [[UIStackView alloc] init];
    links.axis = UILayoutConstraintAxisHorizontal;
    links.alignment = UIStackViewAlignmentCenter;
    links.spacing = 22.0;
    [links addArrangedSubview:[self linkButtonWithImageNamed:kTwitterIcon title:@"Need help?" action:@selector(openTwitter)]];
    [links addArrangedSubview:[self linkButtonWithImageNamed:kGithubIcon title:@"Source code" action:@selector(openGithubLink)]];

    UILabel *createdBy = [[UILabel alloc] init];
    createdBy.text = @"Created by 0xkuj";
    createdBy.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    createdBy.textColor = [UIColor secondaryLabelColor];

    UILabel *version = [[UILabel alloc] init];
    version.text = kIPARangerVersion;
    version.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    version.textColor = [UIColor tertiaryLabelColor];
    version.textAlignment = NSTextAlignmentCenter;
    version.numberOfLines = 0;

    [footer addArrangedSubview:links];
    [footer addArrangedSubview:createdBy];
    [footer addArrangedSubview:version];
    [footer setCustomSpacing:18 afterView:links];
    return footer;
}

- (UIButton *)linkButtonWithImageNamed:(NSString *)imageName title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [icon.widthAnchor constraintEqualToConstant:18].active = YES;
    [icon.heightAnchor constraintEqualToConstant:18].active = YES;

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textColor = [IPARDialog accentColor];

    UIStackView *hstack = [[UIStackView alloc] initWithArrangedSubviews:@[icon, label]];
    hstack.axis = UILayoutConstraintAxisHorizontal;
    hstack.alignment = UIStackViewAlignmentCenter;
    hstack.spacing = 7.0;
    hstack.translatesAutoresizingMaskIntoConstraints = NO;
    hstack.userInteractionEnabled = NO;
    [button addSubview:hstack];

    [NSLayoutConstraint activateConstraints:@[
        [hstack.topAnchor constraintEqualToAnchor:button.topAnchor constant:6],
        [hstack.bottomAnchor constraintEqualToAnchor:button.bottomAnchor constant:-6],
        [hstack.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [hstack.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
    ]];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)openTwitter { [IPARUtils openTW]; }
- (void)openGithubLink { [IPARUtils openGithub]; }

#pragma mark - Password visibility

- (void)togglePasswordVisibility:(UIButton *)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    NSString *imageName = self.passwordTextField.secureTextEntry ? kPasswordEyeButtonOpen : kPasswordEyeButtonClosed;
    [self.eyeButton setImage:[UIImage systemImageNamed:imageName] forState:UIControlStateNormal];
}

#pragma mark - Keyboard

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect kbInView = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = CGRectGetMaxY(self.scrollView.frame) - CGRectGetMinY(kbInView);
    if (overlap < 0) { overlap = 0; }

    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom = overlap;
    self.scrollView.contentInset = insets;
    UIEdgeInsets indicator = self.scrollView.verticalScrollIndicatorInsets;
    indicator.bottom = overlap;
    self.scrollView.verticalScrollIndicatorInsets = indicator;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.verticalScrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGRect rect = [self.scrollView convertRect:textField.bounds fromView:textField];
    [self.scrollView scrollRectToVisible:CGRectInset(rect, 0, -80) animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        [self handleLoginEmailPass];
        return YES;
    }
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Welcome

- (void)showFirstTimeAlert {
    if (self.welcomeMessageTimer != nil) {
        [self.welcomeMessageTimer invalidate];
    }
    __weak typeof(self) weakSelf = self;

    IPARDialog *dialog = [IPARDialog dialogWithTitle:@"Welcome to IPA Ranger!"
                                             message:@"This is an open source project I worked hard to maintain. Your Apple ID and password are sent directly to Apple’s servers and are never saved on your device.\n\nIf you have any concerns, check out the source code below (and maybe drop a star ;) ).\n\nEnjoy!"];

    [dialog addButtonWithTitle:@"Check out the code" style:IPARDialogButtonStyleCancel handler:^{
        [IPARUtils openGithub];
        [weakSelf showFirstTimeAlert];
    }];

    UIButton *okButton = [dialog addButtonWithTitle:@"OK (10…)" style:IPARDialogButtonStylePrimary handler:^{
        [IPARUtils saveKeyToFile:kFirstLaunchKey withValue:kFirstLaunchDoneKey];
    }];
    okButton.enabled = NO;
    okButton.alpha = 0.45;

    [dialog presentOn:self];

    self.welcomeMessageTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        weakSelf.welcomeMessageCounter--;
        if (weakSelf.welcomeMessageCounter > 0) {
            [okButton setTitle:[NSString stringWithFormat:@"OK (%d…)", weakSelf.welcomeMessageCounter] forState:UIControlStateNormal];
        } else {
            [okButton setTitle:@"OK" forState:UIControlStateNormal];
            okButton.enabled = YES;
            okButton.alpha = 1.0;
            [weakSelf.welcomeMessageTimer invalidate];
        }
    }];
}

#pragma mark - Login

- (void)handleLoginEmailPass {
    [IPARUtils presentLoadingDialogWithMessage:@"Logging in…\nThe first login may take a minute." on:self];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSString *commandToExecute = [NSString stringWithFormat:kLoginCommandPathAccountPassword, kIpatoolScriptPath, self.emailTextField.text, self.passwordTextField.text];
        self.lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];

        NSString *message = self.lastCommandResult[kJsonResponseContent]; // "message"
        NSString *errorText = self.lastCommandResult[kJsonLevelError];    // "error"
        // ipatool signals "2FA required" in the "message" key (level info); check
        // the "error" key too so a future/alternate format still routes to 2FA.
        BOOL requires2FA = ([message containsString:@"2FA"] || [errorText containsString:@"2FA"]);

        if (requires2FA) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self handle2FADialog];
            }];
        } else if ([self.lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:errorText hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }];
        } else if ([self.lastCommandResult[kJsonKeySuccess] boolValue] == YES) {
            [self userAuthenticated];
        } else {
            // Unexpected result: surface it instead of leaving the spinner running forever.
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *fallback = errorText.length ? errorText : (message.length ? message : @"Login failed: unexpected response");
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:fallback hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }];
        }
    });
}

- (void)userAuthenticated {
    [IPARUtils setGuestMode:NO];
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
    [IPARUtils presentLoadingDialogWithMessage:@"Verifying your 2FA code…" on:self];

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
        } else {
            // Unexpected result: surface it instead of leaving the spinner running forever.
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *errorText = self.lastCommandResult[kJsonLevelError];
                NSString *message = self.lastCommandResult[kJsonResponseContent];
                NSString *fallback = errorText.length ? errorText : (message.length ? message : @"2FA login failed: unexpected response");
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:fallback hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"Try Again" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }];
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
