#import <UIKit/UIKit.h>

// Called with the chosen version's external identifier, or an empty string for
// "Latest version". Not called if the user cancels.
typedef void (^IPARVersionPickerCompletion)(NSString *externalVersionID);

@interface IPARVersionPickerViewController : UITableViewController
// versions: array of dictionaries with keys bundle_version, external_identifier,
// created_at (as returned by the version-history endpoint), newest first.
- (instancetype)initWithAppName:(NSString *)appName
                       versions:(NSArray *)versions
                     completion:(IPARVersionPickerCompletion)completion;
@end
