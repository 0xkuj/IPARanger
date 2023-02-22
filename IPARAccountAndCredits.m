#import "IPARAccountAndCredits.h"
// Define constants for padding between views
// static CGFloat const kVerticalPadding = 20.0;
// static CGFloat const kHorizontalPadding = 16.0;

@interface IPARAccountAndCredits ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *emailLabel;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UILabel *label3;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UILabel *headerLabel;
@end

@implementation IPARAccountAndCredits

- (void)loadView {
    [super loadView];
    
    // Initialize the header view
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(155,120 , 80, 80)];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:40.0];
    self.headerImageView.image = [UIImage systemImageNamed:@"person.crop.circle" withConfiguration:config];
    //self.headerImageView.center = headerView.center;
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, headerView.frame.size.height);
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
    [headerView.layer insertSublayer:gradientLayer atIndex:0];
    [self.view addSubview:headerView];
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height)];
    self.headerLabel.text = @"Header Text";
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.headerLabel];
    [self.view addSubview:self.headerImageView];
}
@end

