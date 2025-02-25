#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IPARAppInfo : NSObject
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) UIImage *appIcon;
@end
