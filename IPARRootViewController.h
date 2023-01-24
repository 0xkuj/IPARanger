#import <UIKit/UIKit.h>

@interface NSTask : NSObject
@property (copy) NSArray * arguments; 
@property (retain) id standardOutput; 
@property (retain) id standardError; 
@property (readonly) int terminationStatus; 
-(void)waitUntilExit;
-(id)launchPath;
-(void)launch;
-(void)setLaunchPath:(id)arg1 ;
-(void)setStandardInput:(id)arg1 ;
@end

@interface IPARRootViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@end
