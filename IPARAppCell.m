#import "IPARAppCell.h"

@implementation IPARAppCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.baseView = [[UIView alloc] init];
        self.baseView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        self.baseView.clipsToBounds = true;
        self.baseView.layer.cornerRadius = 12;
        self.baseView.layer.cornerCurve = kCACornerCurveContinuous;
        [self addSubview:self.baseView];
        [self.baseView top:self.topAnchor padding:5];
        [self.baseView leading:self.leadingAnchor padding:20];
        [self.baseView trailing:self.trailingAnchor padding:-20];
        [self.baseView bottom:self.bottomAnchor padding:-5];
        
        self.appImage = [[UIImageView alloc] init];
        self.appImage.clipsToBounds = true;
        self.appImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.baseView addSubview:self.appImage];
        [self.appImage size:CGSizeMake(70, 70)];
        [self.appImage y:self.baseView.centerYAnchor padding:0];
        [self.appImage leading:self.baseView.leadingAnchor padding:10];
        
        // self.timeLabel = [[UILabel alloc] init];
        // self.timeLabel.textAlignment = NSTextAlignmentCenter;
        // self.timeLabel.font = [UIFont systemFontOfSize:12];
        // self.timeLabel.backgroundColor = [UIColor.systemOrangeColor colorWithAlphaComponent:0.4];
        // self.timeLabel.textColor = UIColor.orangeColor;
        // self.timeLabel.layer.cornerRadius = 5;
        // self.timeLabel.layer.cornerCurve = kCACornerCurveContinuous;
        // self.timeLabel.clipsToBounds = YES;
        // [self.baseView addSubview:self.timeLabel];
        // [self.timeLabel size:CGSizeMake(60, 20)];
        // [self.timeLabel top:self.baseView.topAnchor padding:8];
        // [self.timeLabel trailing:self.baseView.trailingAnchor padding:-8];
        
        self.appName = [[UILabel alloc] init];
        self.appName.textColor = UIColor.labelColor;
        self.appName.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        self.appName.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appName];
        
        [self.appName top:self.appImage.topAnchor padding:-3];
        [self.appName leading:self.appImage.trailingAnchor padding:15];
        //[self.appName trailing:self.timeLabel.leadingAnchor padding:-10];
        
        
        self.appBundle = [[UILabel alloc] init];
        self.appBundle.textColor = UIColor.tertiaryLabelColor;
        self.appBundle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.appBundle.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appBundle];
        
        [self.appBundle top:self.appName.bottomAnchor padding:2];
        [self.appBundle leading:self.appImage.trailingAnchor padding:15];
        // [self.appBundle trailing:self.timeLabel.leadingAnchor padding:-10];
        
        
        self.appVersion = [[UILabel alloc] init];
        self.appVersion.textColor = UIColor.tertiaryLabelColor;
        self.appVersion.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.appVersion.textAlignment = NSTextAlignmentLeft;
        [self.baseView addSubview:self.appVersion];
        
        [self.appVersion top:self.appBundle.bottomAnchor padding:2];
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