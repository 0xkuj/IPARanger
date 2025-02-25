#import <UIKit/UIKit.h>

@interface IPARCountryTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating>
- (instancetype)initWithCaller:(NSString *)caller;
@end