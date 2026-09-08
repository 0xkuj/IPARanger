#import "IPARAccountAndCreditsController.h"
#import "IPARLoginScreenViewController.h"
#import "../Extensions/IPARConstants.h"
#import "../Utils/IPARUtils.h"
#import "../Views/IPARDialog.h"

@interface IPARAccountAndCredits ()
@end

@implementation IPARAccountAndCredits

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = kAccountTitle;
        self.tabBarItem.image = [UIImage systemImageNamed:kPersonIcon];
        self.tabBarItem.title = kAccountTitle;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 22.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];

    [stack addArrangedSubview:[self makeProfileHeader]];
    [stack addArrangedSubview:[self makeLogoutButton]];
    [stack addArrangedSubview:[self makeAboutCard]];
    [stack addArrangedSubview:[self makeLinksCard]];
    [stack addArrangedSubview:[self makeCreditsFooter]];

    UILayoutGuide *content = scrollView.contentLayoutGuide;
    UILayoutGuide *frame = scrollView.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-40],
        [stack.leadingAnchor constraintEqualToAnchor:frame.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:frame.trailingAnchor constant:-18],
    ]];
}

#pragma mark - Profile header

- (UIView *)makeProfileHeader {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12.0;

    // Avatar: a soft accent-tinted circle with a person glyph.
    UIView *avatar = [[UIView alloc] init];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.backgroundColor = [[IPARDialog accentColor] colorWithAlphaComponent:0.15];
    avatar.layer.cornerRadius = 44.0;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *glyph = [[UIImageView alloc] init];
    glyph.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:44 weight:UIImageSymbolWeightRegular];
    glyph.image = [UIImage systemImageNamed:@"person.fill" withConfiguration:cfg];
    glyph.tintColor = [IPARDialog accentColor];
    glyph.contentMode = UIViewContentModeScaleAspectFit;
    [avatar addSubview:glyph];

    BOOL guest = [IPARUtils isGuestMode];
    NSString *nameText = guest ? @"Not signed in" : [IPARUtils getKeyFromFile:kAccountNameKeyFromFile defaultValueIfNil:kUnknownValue];
    NSString *emailText = guest ? @"Sign in to search and download apps" : [IPARUtils getKeyFromFile:kAccountEmailKeyFromFile defaultValueIfNil:kUnknownValue];

    UILabel *name = [self labelWithText:nameText
                                   font:[UIFont systemFontOfSize:22 weight:UIFontWeightBold]
                                  color:[UIColor labelColor]];
    name.textAlignment = NSTextAlignmentCenter;

    UILabel *email = [self labelWithText:emailText
                                    font:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]
                                   color:[UIColor secondaryLabelColor]];
    email.textAlignment = NSTextAlignmentCenter;

    [stack addArrangedSubview:avatar];
    [stack addArrangedSubview:name];
    [stack addArrangedSubview:email];
    [stack setCustomSpacing:16 afterView:avatar];
    [stack setCustomSpacing:4 afterView:name];

    [NSLayoutConstraint activateConstraints:@[
        [avatar.widthAnchor constraintEqualToConstant:88],
        [avatar.heightAnchor constraintEqualToConstant:88],
        [glyph.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [glyph.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor],
        [glyph.widthAnchor constraintEqualToConstant:48],
        [glyph.heightAnchor constraintEqualToConstant:48],
    ]];
    return stack;
}

#pragma mark - Logout button

- (UIButton *)makeLogoutButton {
    BOOL guest = [IPARUtils isGuestMode];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    button.tintColor = [UIColor whiteColor];
    button.layer.cornerRadius = 14.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold];
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);

    if (guest) {
        [button setTitle:@"Sign In" forState:UIControlStateNormal];
        button.backgroundColor = [IPARDialog accentColor];
        [button setImage:[UIImage systemImageNamed:@"person.crop.circle.badge.plus" withConfiguration:cfg] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleSignIn) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [button setTitle:kLogoutTitle forState:UIControlStateNormal];
        button.backgroundColor = [IPARDialog destructiveColor];
        [button setImage:[UIImage systemImageNamed:kLogoutIcon withConfiguration:cfg] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    }

    [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [button.heightAnchor constraintEqualToConstant:52].active = YES;
    return button;
}

- (void)handleSignIn {
    [IPARUtils switchToLoginScreen];
}

#pragma mark - About card

- (UIView *)makeAboutCard {
    NSString *ipatool = [self valueFromVersionString:kipaToolVersion];
    NSString *ranger = [self valueFromVersionString:kIPARangerVersion];

    NSArray<UIView *> *rows = @[
        [self infoRowWithTitle:@"Last login" value:[self formattedLoginDate]],
        [self infoRowWithTitle:@"ipatool" value:ipatool],
        [self infoRowWithTitle:@"IPA Ranger" value:ranger],
    ];
    return [self cardWithRows:rows separatorInset:16];
}

#pragma mark - Links card

- (UIView *)makeLinksCard {
    NSArray<UIView *> *rows = @[
        [self linkRowWithImageNamed:kTwitterIcon title:@"Follow me on Twitter" action:@selector(openTwitter)],
        [self linkRowWithImageNamed:kPaypalIcon title:@"Buy me a coffee" action:@selector(openPaypal)],
        [self linkRowWithImageNamed:kGithubIcon title:@"Source code" action:@selector(openGithub)],
    ];
    return [self cardWithRows:rows separatorInset:56];
}

#pragma mark - Credits footer

- (UIView *)makeCreditsFooter {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 6.0;

    UILabel *createdBy = [self labelWithText:@"Created by 0xkuj"
                                        font:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]
                                       color:[UIColor secondaryLabelColor]];

    UILabel *thanksHeader = [self labelWithText:@"SPECIAL THANKS"
                                           font:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]
                                          color:[UIColor tertiaryLabelColor]];

    UILabel *majd = [self labelWithText:@"Majd Alfhaily — ipatool"
                                   font:[UIFont systemFontOfSize:13 weight:UIFontWeightRegular]
                                  color:[UIColor secondaryLabelColor]];

    UILabel *angel = [self labelWithText:@"angelXwind — appinst"
                                    font:[UIFont systemFontOfSize:13 weight:UIFontWeightRegular]
                                   color:[UIColor secondaryLabelColor]];

    [stack addArrangedSubview:createdBy];
    [stack addArrangedSubview:thanksHeader];
    [stack addArrangedSubview:majd];
    [stack addArrangedSubview:angel];
    [stack setCustomSpacing:18 afterView:createdBy];
    [stack setCustomSpacing:8 afterView:thanksHeader];
    return stack;
}

#pragma mark - Reusable builders

- (UIView *)cardWithRows:(NSArray<UIView *> *)rows separatorInset:(CGFloat)inset {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    card.layer.cornerRadius = 16.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 0.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    [rows enumerateObjectsUsingBlock:^(UIView *row, NSUInteger idx, BOOL *stop) {
        [stack addArrangedSubview:row];
        if (idx != rows.count - 1) {
            [stack addArrangedSubview:[self separatorWithLeadingInset:inset]];
        }
    }];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
    ]];
    return card;
}

- (UIView *)separatorWithLeadingInset:(CGFloat)inset {
    UIView *wrap = [[UIView alloc] init];
    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor separatorColor];
    [wrap addSubview:line];
    [NSLayoutConstraint activateConstraints:@[
        [line.heightAnchor constraintEqualToConstant:0.5],
        [line.topAnchor constraintEqualToAnchor:wrap.topAnchor],
        [line.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor],
        [line.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:inset],
        [line.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor],
    ]];
    return wrap;
}

- (UIView *)infoRowWithTitle:(NSString *)title value:(NSString *)value {
    UIView *row = [[UIView alloc] init];

    UILabel *titleLabel = [self labelWithText:title
                                         font:[UIFont systemFontOfSize:16 weight:UIFontWeightRegular]
                                        color:[UIColor secondaryLabelColor]];
    [titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UILabel *valueLabel = [self labelWithText:value
                                         font:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]
                                        color:[UIColor labelColor]];
    valueLabel.textAlignment = NSTextAlignmentRight;
    valueLabel.numberOfLines = 0;

    UIStackView *hstack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    hstack.axis = UILayoutConstraintAxisHorizontal;
    hstack.alignment = UIStackViewAlignmentCenter;
    hstack.spacing = 12.0;
    hstack.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:hstack];

    [NSLayoutConstraint activateConstraints:@[
        [hstack.topAnchor constraintEqualToAnchor:row.topAnchor constant:13],
        [hstack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-13],
        [hstack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [hstack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:48],
    ]];
    return row;
}

- (UIButton *)linkRowWithImageNamed:(NSString *)imageName title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [icon.widthAnchor constraintEqualToConstant:26].active = YES;
    [icon.heightAnchor constraintEqualToConstant:26].active = YES;

    UILabel *titleLabel = [self labelWithText:title
                                         font:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium]
                                        color:[UIColor labelColor]];

    UIImageView *chevron = [[UIImageView alloc] init];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightSemibold];
    chevron.image = [UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg];
    chevron.tintColor = [UIColor tertiaryLabelColor];
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    [chevron setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *hstack = [[UIStackView alloc] initWithArrangedSubviews:@[icon, titleLabel, chevron]];
    hstack.axis = UILayoutConstraintAxisHorizontal;
    hstack.alignment = UIStackViewAlignmentCenter;
    hstack.spacing = 14.0;
    hstack.translatesAutoresizingMaskIntoConstraints = NO;
    hstack.userInteractionEnabled = NO; // let the button receive the tap
    [button addSubview:hstack];

    [NSLayoutConstraint activateConstraints:@[
        [hstack.topAnchor constraintEqualToAnchor:button.topAnchor constant:13],
        [hstack.bottomAnchor constraintEqualToAnchor:button.bottomAnchor constant:-13],
        [hstack.leadingAnchor constraintEqualToAnchor:button.leadingAnchor constant:16],
        [hstack.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-16],
        [button.heightAnchor constraintGreaterThanOrEqualToConstant:52],
    ]];

    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(rowDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(rowUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    return button;
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

#pragma mark - Highlight feedback

- (void)buttonDown:(UIButton *)sender { [UIView animateWithDuration:0.08 animations:^{ sender.alpha = 0.7; }]; }
- (void)buttonUp:(UIButton *)sender { [UIView animateWithDuration:0.18 animations:^{ sender.alpha = 1.0; }]; }
- (void)rowDown:(UIButton *)sender { sender.backgroundColor = [UIColor systemFillColor]; }
- (void)rowUp:(UIButton *)sender {
    [UIView animateWithDuration:0.2 animations:^{ sender.backgroundColor = [UIColor clearColor]; }];
}

#pragma mark - Link actions

- (void)openTwitter { [IPARUtils openTW]; }
- (void)openPaypal { [IPARUtils openPP]; }
- (void)openGithub { [IPARUtils openGithub]; }

#pragma mark - Helpers

- (NSString *)formattedLoginDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kDateFormatter];
    id date = [IPARUtils getKeyFromFile:kLastLoginDateKey defaultValueIfNil:kUnknownValue];
    if ([date isKindOfClass:[NSDate class]]) {
        return [formatter stringFromDate:date];
    }
    return kUnknownValue;
}

// "ipatool version: 2.5.0 (fork) (iOS)" -> "2.5.0 (fork) (iOS)"
- (NSString *)valueFromVersionString:(NSString *)versionString {
    NSRange range = [versionString rangeOfString:@": "];
    if (range.location != NSNotFound) {
        return [versionString substringFromIndex:range.location + range.length];
    }
    return versionString;
}

#pragma mark - Logout

- (void)handleLogout {
    __weak typeof(self) weakSelf = self;

    IPARDialog *dialog = [IPARDialog dialogWithTitle:@"Log out?"
                                             message:@"You’ll need to sign in with your Apple ID again to search and download apps."];

    [dialog addButtonWithTitle:@"Cancel" style:IPARDialogButtonStyleCancel handler:nil];
    [dialog addButtonWithTitle:@"Log Out" style:IPARDialogButtonStyleDestructive handler:^{
        [weakSelf performLogout];
    }];
    [dialog presentOn:self];
}

- (void)performLogout {
    IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.tabBarController.view removeFromSuperview];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = navController;

    NSString *commandToExecute = [NSString stringWithFormat:kLogoutCommand, kIpatoolScriptPath];
    NSDictionary *lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];
    if ([lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"Continue anyway" alertCancelBlock:nil withCancelText:nil presentOn:loginScreenVC];
    }
    [IPARUtils accountDetailsToFile:@"" authName:@"" authenticated:@"NO"];
}

@end
