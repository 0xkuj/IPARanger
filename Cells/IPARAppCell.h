#import "../Extensions/IPARConstraintExtension.h"

@interface IPARAppCell : UITableViewCell
@property (nonatomic, retain) UIView *baseView;
@property (nonatomic, retain) UILabel *appName;
@property (nonatomic, retain) UILabel *appBundle;
@property (nonatomic, retain) UILabel *appVersion;
@property (nonatomic, retain) UIImageView *appImage;
@property (nonatomic, retain) UILabel *appFilename;
@property (nonatomic, retain) UILabel *appSize;
@end