#import "IPARAppCell.h"

@implementation IPARAppCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.baseView = [[UIView alloc] init];
        self.baseView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        self.baseView.clipsToBounds = YES;
        self.baseView.layer.cornerRadius = 12;
        self.baseView.layer.cornerCurve = kCACornerCurveContinuous;
        [self addSubview:self.baseView];
        [self.baseView top:self.topAnchor padding:12];
        [self.baseView leading:self.leadingAnchor padding:20];
        [self.baseView trailing:self.trailingAnchor padding:-20];
        [self.baseView bottom:self.bottomAnchor padding:-5];
        
        self.appImage = [[UIImageView alloc] init];
        self.appImage.contentMode = UIViewContentModeScaleAspectFill;
        self.appImage.layer.cornerRadius = 20;
        self.appImage.clipsToBounds = YES;
        [self.baseView addSubview:self.appImage];
        [self.appImage size:CGSizeMake(40, 40)];
        [self.appImage y:self.baseView.centerYAnchor padding:0];
        [self.appImage leading:self.baseView.leadingAnchor padding:10];
        
        self.appName = [[UILabel alloc] init];
        self.appName.textColor = UIColor.labelColor;
        self.appName.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        self.appName.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appName];
        
        [self.appName top:self.appImage.topAnchor padding:-6.5];
        [self.appName leading:self.appImage.trailingAnchor padding:15];
        //Fit appname to the size of the cell
        self.appName.translatesAutoresizingMaskIntoConstraints = NO;
        [self.baseView addConstraints:@[
            [self.baseView.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.appName.trailingAnchor constant:10],
            [self.baseView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.appName.bottomAnchor constant:10]
        ]];
        self.appName.adjustsFontSizeToFitWidth = YES;
        self.appName.minimumScaleFactor = 0.3; // Or any other value between 0 and      
        
        self.appBundle = [[UILabel alloc] init];
        self.appBundle.textColor = UIColor.tertiaryLabelColor;
        self.appBundle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.appBundle.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appBundle];
        
        [self.appBundle top:self.appName.bottomAnchor padding:1];
        [self.appBundle leading:self.appImage.trailingAnchor padding:15];
        //Fit bundle to the size of the cell
        self.appBundle.translatesAutoresizingMaskIntoConstraints = NO;
        [self.baseView addConstraints:@[
            [self.baseView.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.appBundle.trailingAnchor constant:10],
            [self.baseView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.appBundle.bottomAnchor constant:10]
        ]];
        self.appBundle.adjustsFontSizeToFitWidth = YES;
        self.appBundle.minimumScaleFactor = 0.3; // Or any other value between 0 an
        // [self.appBundle trailing:self.timeLabel.leadingAnchor padding:-10];
        
        self.appVersion = [[UILabel alloc] init];
        self.appVersion.textColor = UIColor.tertiaryLabelColor;
        self.appVersion.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.appVersion.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appVersion];
        
        [self.appVersion top:self.appBundle.bottomAnchor padding:0];
        [self.appVersion leading:self.appImage.trailingAnchor padding:15];
        // [self.appVersion trailing:self.timeLabel.leadingAnchor padding:-10];      
    }
    
    return self;
}


-(void)prepareForReuse {
    [super prepareForReuse];
    //self.iconImage.image = nil;
    self.appName.text = nil;
    self.appBundle.text = nil;
    self.appVersion.text = nil;
}

@end