#import "IPARDialog.h"

typedef NS_ENUM(NSInteger, IPARDialogMode) {
    IPARDialogModeNormal = 0,
    IPARDialogModeSpinner,
    IPARDialogModeProgress,
};

@interface IPARDialog ()
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, assign) IPARDialogMode mode;

@property (nonatomic, copy) void (^textFieldConfig)(UITextField *);
@property (nonatomic, strong, readwrite) UITextField *textField;

@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *buttonStyles;
@property (nonatomic, strong) NSMutableArray *buttonHandlers; // block or NSNull

@property (nonatomic, strong) UIView *backdrop;
@property (nonatomic, strong) UIView *card;              // shadow host
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) NSLayoutConstraint *cardCenterY;
@property (nonatomic, strong) NSLayoutConstraint *cardWidth;

@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;
@property (nonatomic, strong) NSLayoutConstraint *progressFillWidth;
@property (nonatomic, strong) UILabel *percentLabel;
@end

@implementation IPARDialog

#pragma mark - Palette

+ (UIColor *)accentColor {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        if (tc.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.36 green:0.58 blue:1.00 alpha:1.0];
        }
        return [UIColor colorWithRed:0.13 green:0.40 blue:0.90 alpha:1.0];
    }];
}

+ (UIColor *)destructiveColor {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        if (tc.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:1.00 green:0.35 blue:0.37 alpha:1.0];
        }
        return [UIColor colorWithRed:0.86 green:0.22 blue:0.24 alpha:1.0];
    }];
}

#pragma mark - Construction

+ (instancetype)dialogWithTitle:(NSString *)title message:(NSString *)message {
    IPARDialog *dialog = [[self alloc] init];
    dialog.titleText = title;
    dialog.messageText = message;
    dialog.buttons = [NSMutableArray array];
    dialog.buttonStyles = [NSMutableArray array];
    dialog.buttonHandlers = [NSMutableArray array];
    return dialog;
}

- (void)addTextFieldWithConfiguration:(void (^)(UITextField *))configuration {
    self.textFieldConfig = configuration;
}

- (UIButton *)addButtonWithTitle:(NSString *)title
                           style:(IPARDialogButtonStyle)style
                         handler:(void (^)(void))handler {
    NSUInteger index = self.buttons.count;
    [self.buttonStyles addObject:@(style)];
    [self.buttonHandlers addObject:handler ? [handler copy] : (id)[NSNull null]];
    UIButton *button = [self makeButtonWithTitle:(title ?: @"") style:style index:index];
    [self.buttons addObject:button];
    return button; // real button, so callers can disable it / update its title
}

- (void)showSpinner { self.mode = IPARDialogModeSpinner; }
- (void)showProgress { self.mode = IPARDialogModeProgress; }

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    [self buildBackdrop];
    [self buildCard];
    [self populateContent];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildBackdrop {
    self.backdrop = [[UIView alloc] init];
    self.backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    self.backdrop.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    [self.view addSubview:self.backdrop];
    [NSLayoutConstraint activateConstraints:@[
        [self.backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)buildCard {
    // Shadow host (does not clip) wrapping a clipped blur card.
    self.card = [[UIView alloc] init];
    self.card.translatesAutoresizingMaskIntoConstraints = NO;
    self.card.backgroundColor = [UIColor clearColor];
    self.card.layer.shadowColor = [UIColor blackColor].CGColor;
    self.card.layer.shadowOpacity = 0.22;
    self.card.layer.shadowRadius = 26.0;
    self.card.layer.shadowOffset = CGSizeMake(0, 12);
    [self.view addSubview:self.card];

    UIVisualEffectView *blur = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterial]];
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    blur.layer.cornerRadius = 22.0;
    blur.layer.cornerCurve = kCACornerCurveContinuous;
    blur.clipsToBounds = YES;
    blur.layer.borderWidth = 0.5;
    blur.layer.borderColor = [[UIColor separatorColor] colorWithAlphaComponent:0.35].CGColor;
    [self.card addSubview:blur];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.spacing = 14.0;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [blur.contentView addSubview:self.contentStack];

    self.cardCenterY = [self.card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
    self.cardWidth = [self.card.widthAnchor constraintEqualToConstant:300.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        self.cardCenterY,
        self.cardWidth,

        [blur.topAnchor constraintEqualToAnchor:self.card.topAnchor],
        [blur.bottomAnchor constraintEqualToAnchor:self.card.bottomAnchor],
        [blur.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor],
        [blur.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor],

        [self.contentStack.topAnchor constraintEqualToAnchor:blur.contentView.topAnchor constant:22],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:blur.contentView.bottomAnchor constant:-20],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:blur.contentView.leadingAnchor constant:20],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:blur.contentView.trailingAnchor constant:-20],
    ]];
}

- (void)populateContent {
    if (self.titleText.length) {
        [self.contentStack addArrangedSubview:[self makeTitleLabel]];
    }

    if (self.mode == IPARDialogModeSpinner) {
        UIActivityIndicatorView *spinner =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        spinner.color = [UIColor labelColor];
        [spinner startAnimating];
        // Wrap so the (fixed-size) spinner stays centered within the full-width row.
        UIView *row = [[UIView alloc] init];
        [row addSubview:spinner];
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [spinner.centerXAnchor constraintEqualToAnchor:row.centerXAnchor],
            [spinner.topAnchor constraintEqualToAnchor:row.topAnchor constant:6],
            [spinner.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-2],
        ]];
        [self.contentStack addArrangedSubview:row];
    }

    if (self.messageText.length) {
        [self.contentStack addArrangedSubview:[self makeMessageLabel]];
    }

    if (self.mode == IPARDialogModeProgress) {
        [self.contentStack addArrangedSubview:[self makeProgressView]];
    }

    if (self.textFieldConfig) {
        [self.contentStack addArrangedSubview:[self makeTextField]];
    }

    UIView *buttons = [self makeButtonsView];
    if (buttons) {
        // A little more breathing room above the buttons (only if something precedes).
        UIView *last = self.contentStack.arrangedSubviews.lastObject;
        if (last) {
            [self.contentStack setCustomSpacing:20 afterView:last];
        }
        [self.contentStack addArrangedSubview:buttons];
    }
}

#pragma mark - Content builders

- (UILabel *)makeTitleLabel {
    UILabel *label = [[UILabel alloc] init];
    UIFont *base = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    label.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:base];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor labelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.text = self.titleText;
    return label;
}

- (UILabel *)makeMessageLabel {
    UILabel *label = [[UILabel alloc] init];
    UIFont *base = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:base];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor secondaryLabelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.text = self.messageText;
    return label;
}

- (UITextField *)makeTextField {
    UITextField *field = [[UITextField alloc] init];
    field.font = [UIFont systemFontOfSize:16];
    field.textColor = [UIColor labelColor];
    field.backgroundColor = [UIColor tertiarySystemFillColor];
    field.layer.cornerRadius = 10.0;
    field.layer.cornerCurve = kCACornerCurveContinuous;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    field.leftView = pad;
    field.leftViewMode = UITextFieldViewModeAlways;
    [field.heightAnchor constraintEqualToConstant:46].active = YES;
    if (self.textFieldConfig) {
        self.textFieldConfig(field);
    }
    self.textField = field;
    return field;
}

- (UIView *)makeProgressView {
    UIView *container = [[UIView alloc] init];

    self.progressTrack = [[UIView alloc] init];
    self.progressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressTrack.backgroundColor = [UIColor tertiarySystemFillColor];
    self.progressTrack.layer.cornerRadius = 5.0;
    self.progressTrack.clipsToBounds = YES;
    [container addSubview:self.progressTrack];

    self.progressFill = [[UIView alloc] init];
    self.progressFill.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressFill.backgroundColor = [IPARDialog accentColor];
    self.progressFill.layer.cornerRadius = 5.0;
    [self.progressTrack addSubview:self.progressFill];

    self.percentLabel = [[UILabel alloc] init];
    self.percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.percentLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold];
    self.percentLabel.textColor = [UIColor secondaryLabelColor];
    self.percentLabel.textAlignment = NSTextAlignmentCenter;
    self.percentLabel.text = @"0%";
    [container addSubview:self.percentLabel];

    self.progressFillWidth = [self.progressFill.widthAnchor constraintEqualToAnchor:self.progressTrack.widthAnchor multiplier:0.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.progressTrack.topAnchor constraintEqualToAnchor:container.topAnchor constant:2],
        [self.progressTrack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [self.progressTrack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [self.progressTrack.heightAnchor constraintEqualToConstant:10],

        [self.progressFill.leadingAnchor constraintEqualToAnchor:self.progressTrack.leadingAnchor],
        [self.progressFill.topAnchor constraintEqualToAnchor:self.progressTrack.topAnchor],
        [self.progressFill.bottomAnchor constraintEqualToAnchor:self.progressTrack.bottomAnchor],
        self.progressFillWidth,

        [self.percentLabel.topAnchor constraintEqualToAnchor:self.progressTrack.bottomAnchor constant:10],
        [self.percentLabel.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [self.percentLabel.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    return container;
}

- (UIView *)makeButtonsView {
    if (self.buttons.count == 0) {
        return nil;
    }

    NSArray<UIButton *> *buttons = self.buttons;

    // Two short buttons sit side-by-side (cancel left, action right); otherwise
    // stack vertically (primary/destructive on top, cancel at the bottom).
    BOOL horizontal = (buttons.count == 2);
    for (UIButton *b in buttons) {
        if ([b titleForState:UIControlStateNormal].length > 14) { horizontal = NO; break; }
    }

    NSArray<UIButton *> *ordered = buttons;
    if (horizontal) {
        ordered = [buttons sortedArrayUsingComparator:^NSComparisonResult(UIButton *a, UIButton *b) {
            BOOL aCancel = (a.tag < self.buttonStyles.count) && ([self.buttonStyles[a.tag] integerValue] == IPARDialogButtonStyleCancel);
            BOOL bCancel = (b.tag < self.buttonStyles.count) && ([self.buttonStyles[b.tag] integerValue] == IPARDialogButtonStyleCancel);
            if (aCancel == bCancel) return NSOrderedSame;
            return aCancel ? NSOrderedAscending : NSOrderedDescending; // cancel first (left)
        }];
    } else {
        ordered = [buttons sortedArrayUsingComparator:^NSComparisonResult(UIButton *a, UIButton *b) {
            BOOL aCancel = (a.tag < self.buttonStyles.count) && ([self.buttonStyles[a.tag] integerValue] == IPARDialogButtonStyleCancel);
            BOOL bCancel = (b.tag < self.buttonStyles.count) && ([self.buttonStyles[b.tag] integerValue] == IPARDialogButtonStyleCancel);
            if (aCancel == bCancel) return NSOrderedSame;
            return aCancel ? NSOrderedDescending : NSOrderedAscending; // cancel last (bottom)
        }];
    }

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:ordered];
    stack.axis = horizontal ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.spacing = 10.0;
    return stack;
}

- (UIButton *)makeButtonWithTitle:(NSString *)title style:(IPARDialogButtonStyle)style index:(NSUInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = (NSInteger)index;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.titleLabel.font = [[UIFontMetrics defaultMetrics]
        scaledFontForFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
    button.titleLabel.numberOfLines = 1;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.75;
    button.layer.cornerRadius = 13.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;

    switch (style) {
        case IPARDialogButtonStylePrimary:
            button.backgroundColor = [IPARDialog accentColor];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case IPARDialogButtonStyleDestructive:
            button.backgroundColor = [IPARDialog destructiveColor];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case IPARDialogButtonStyleCancel:
        default:
            button.backgroundColor = [UIColor tertiarySystemFillColor];
            [button setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
            break;
    }

    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    return button;
}

#pragma mark - Button interaction

- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.08 animations:^{ sender.alpha = 0.6; }];
}

- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.18 animations:^{ sender.alpha = 1.0; }];
}

- (void)buttonTapped:(UIButton *)sender {
    id stored = (sender.tag < (NSInteger)self.buttonHandlers.count) ? self.buttonHandlers[sender.tag] : [NSNull null];
    void (^handler)(void) = [stored isKindOfClass:NSClassFromString(@"NSNull")] ? nil : stored;

    [self.textField resignFirstResponder];
    // Dismiss first, then run the handler — matching UIAlertController semantics,
    // so a handler that presents another dialog isn't blocked by this one.
    [self dismissViewControllerAnimated:YES completion:^{
        if (handler) { handler(); }
    }];
}

#pragma mark - Progress

- (void)setProgress:(float)progress {
    float p = MAX(0.0f, MIN(1.0f, progress));
    if (self.progressFillWidth) { self.progressFillWidth.active = NO; }
    self.progressFillWidth = [self.progressFill.widthAnchor
        constraintEqualToAnchor:self.progressTrack.widthAnchor multiplier:p];
    self.progressFillWidth.active = YES;
    self.percentLabel.text = [NSString stringWithFormat:@"%d%%", (int)roundf(p * 100.0f)];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ [self.view layoutIfNeeded]; } completion:nil];
}

#pragma mark - Layout / sizing

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat available = CGRectGetWidth(self.view.bounds) - 48.0;
    self.cardWidth.constant = MIN(320.0, MAX(240.0, available));
}

#pragma mark - Presentation + animation

- (void)presentOn:(UIViewController *)presenter {
    if (!presenter) { return; }
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [presenter presentViewController:self animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.textField) {
        [self.textField becomeFirstResponder];
    }
}

#pragma mark - Keyboard

- (void)keyboardWillChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect kbInView = [self.view convertRect:endFrame fromView:nil];
    CGFloat cardBottom = CGRectGetMaxY(self.card.frame);
    CGFloat overlap = cardBottom - (CGRectGetMinY(kbInView) - 16.0);
    CGFloat shift = overlap > 0 ? -overlap : 0;

    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.cardCenterY.constant = shift;
    [UIView animateWithDuration:MAX(duration, 0.2) animations:^{ [self.view layoutIfNeeded]; }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.cardCenterY.constant = 0;
    [UIView animateWithDuration:MAX(duration, 0.2) animations:^{ [self.view layoutIfNeeded]; }];
}

@end
