#import "IPARRootViewController.h"

@interface IPARRootViewController ()
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSMutableArray *searchResults;
@end

@implementation IPARRootViewController

- (void)loadView {
	[super loadView];

	_objects = [NSMutableArray array];
  _searchResults = [NSMutableArray array];
	self.title = @"IPA Ranger";
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
  [self _setUpNavigationBar];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  // Create a navigation controller and set self as the root view controller
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
  UITabBarController *tabBarController = [[UITabBarController alloc] init];
  
  // Create the second view controller
  UIViewController *secondViewController = [[UIViewController alloc] init];
  secondViewController.title = @"Account";

  // Add the view controllers to the tab bar controller
  tabBarController.viewControllers = @[navigationController, secondViewController];

  // Add the tab bar controller as the root view controller
  UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
  window.rootViewController = tabBarController;
}

- (void)_setUpNavigationBar
{
	UIAction *accountAction = [UIAction actionWithTitle:@"Account" image:[UIImage systemImageNamed:@"person.crop.circle"] identifier:@"IPARangerAccount" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIAction *creditsAction = [UIAction actionWithTitle:@"Credits" image:[UIImage systemImageNamed:@"info.circle.fill"] identifier:@"IPARangerCredits" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIAction *logoutAction = [UIAction actionWithTitle:@"Logout" image:[UIImage systemImageNamed:@"arrow.right"] identifier:@"IPARangerLogout" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIMenu* installMenu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
  UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:installMenu];
  UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
  UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
	self.navigationItem.rightBarButtonItems = @[optionsButton, downloadButton, lookupButton];

}

-(void)searchButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *searchTerm = textField.text;
		    //need to create directory as such.. -.-
        NSLog(@"omriku calling cmd! %@",[self CMD2:[NSString stringWithFormat:@"/Applications/IPARanger.app/ipatool/ipatool search %@ --limit 100", searchTerm]]);
        //[_objects insertObject:[NSDate date] atIndex:0];
        //[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"e.g Facebook";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addButtonTapped:(id)sender {
	//not saving in your directory. need to investigate..
	//this works. you need to create a good directory for this, think where.
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *text = textField.text;
		//need to create directory as such.. -.-
        NSLog(@"omriku calling cmd! %@",[self CMD2:[NSString stringWithFormat:@"/Applications/IPARanger.app/ipatool/ipatool download --bundle-identifier %@ -o /var/mobile/Library/Preferences/IPARanger/ --purchase -c US", text]]);
		//[_objects insertObject:[NSDate date] atIndex:0];
		//[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"e.g com.facebook.Facebook";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSLog(@"omriku counting rows.. %lu",self.searchResults.count);
  if (self.searchResults.count > 0) {
    return self.searchResults.count;
  }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	//NSDate *date = _objects[indexPath.row];
	//cell.textLabel.text = date.description;
  cell.textLabel.text = self.searchResults[indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.searchResults removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString *)CMD2:(NSString *)CMD {
   NSTask *task = [[NSTask alloc] init];
   NSMutableArray *args = [NSMutableArray array];
   [args addObject:@"-c"];
   [args addObject:CMD];
   [task setLaunchPath:@"/bin/sh"];
   [task setArguments:args];
   NSPipe *outputPipe = [NSPipe pipe];
   NSPipe *errorPipe = [NSPipe pipe];
   [task setStandardError:errorPipe];
   [task setStandardOutput:outputPipe];
   [task launch];
   NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
   NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

   NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
   NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

   NSLog(@"omriku reading outputstring.. command: %@ %@",task.launchPath, [task.arguments componentsJoinedByString:@" "]);
   NSArray *linesOutput = [outputString componentsSeparatedByCharactersInSet:
										[NSCharacterSet newlineCharacterSet]];

   NSArray *linesError = [errorOutput componentsSeparatedByCharactersInSet:
										[NSCharacterSet newlineCharacterSet]];

   [self.searchResults removeAllObjects];           
   for (id obj in linesOutput) {
      NSLog(@"omriku line output :%@", obj);
      if ([obj containsString:@"Authenticated as"]) {
        return @"Success";
      }
      if ([CMD containsString:@"search"]) {
        NSLog(@"omriku adding object.. %@", obj);
        [self.searchResults addObject:obj];
      }
   }

   NSLog(@"omriku before reloading data.. ");
   for (id obj in self.searchResults) {
    NSLog(@"omriku array place: %@", obj);
   }
    [self.tableView reloadData];

   for (id obj in linesError) {
      NSLog(@"omriku line error :%@", obj);
      if ([obj containsString:@"2FA"]) {
        return @"2FA";
      }
   }

   //returns one line, this is shit basically..
   return outputString;
}
@end

//regex and stuff..
/*
NSString *string = @"77. Dots: A Game About Connecting: com.nerdyoctopus.dots (2.4.7).";

// Use regular expressions to extract the bundle identifier
NSRegularExpression *bundleIdRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<=:\\s)[a-zA-Z0-9.]+(?=\\s\\()" options:0 error:NULL];
NSTextCheckingResult *bundleIdMatch = [bundleIdRegex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
NSString *bundleId = [string substringWithRange:bundleIdMatch.range];

// Use regular expressions to remove the number at the beginning of the string
NSRegularExpression *numberRegex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9.]+(?=\\s)" options:0 error:NULL];
NSString *cleanString = [numberRegex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@""];

NSLog(@"Bundle Identifier: %@", bundleId);
NSLog(@"Clean String: %@", cleanString);
*/