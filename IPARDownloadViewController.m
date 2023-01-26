#import "IPARDownloadViewController.h"
#import "IPARUtils.h"

@interface IPARDownloadViewController ()
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSMutableArray *searchResults;
@end

//IMPLEMENT SELECT COUNTRY!
@implementation IPARDownloadViewController
- (void)loadView {
    [super loadView];
    // _searchResults = [NSMutableArray array];
    // _linesStandardOutput = [NSMutableArray array];
    // _linesErrorOutput = [NSMutableArray array];
    //self.title = @"IPA Ranger - Download";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self _setUpNavigationBar2];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
    // self.viewControllers = @[navigationController];
    // navigationController.title = @"Search";
    // UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    // // Create the second view controller
    // IPARDownloadViewController *secondViewController = [[IPARDownloadViewController alloc] init];
    // secondViewController.title = @"Download";
    
    // // Add the view controllers to the tab bar controller
    // tabBarController.viewControllers = @[navigationController, secondViewController];

    // // Add the tab bar controller as the root view controller
    // UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
    // window.rootViewController = tabBarController;
}

- (void)_setUpNavigationBar2
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

	UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[optionsButton, downloadButton];
}

- (void)addButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Download" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *bundleToDownload = textField.text;
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ download --bundle-identifier %@ -o %@ --purchase -c US", IPATOOL_SCRIPT_PATH, bundleToDownload, IPARANGER_DOCUMENTS_LIBRARY];
        [self testing:commandToExecute];
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
    // NSLog(@"omriku counting rows.. %lu",self.searchResults.count);
    // if (self.searchResults.count > 0) {
    //     return self.searchResults.count;
    // }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

    //cell.textLabel.text = self.searchResults[indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//[self.searchResults removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

 -(void)testing:(NSString *)command {
//     NSLog(@"omriku in testing, command %@", command);
//     NSTask *task = [[NSTask alloc] init];
//     NSMutableArray *args = [NSMutableArray array];
//     [args addObject:@"-c"];
//     [args addObject:command];
//     [task setLaunchPath:@"/bin/sh"];
//     [task setArguments:args];
//     // Create a pipe for the task's standard output
//     NSPipe *pipe = [NSPipe pipe];
//     task.standardOutput = pipe;

//     [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
//     NSLog(@"omriku sigining to notif..");
//     // Register for notifications when new data is available to read
//     [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(receivedData:)
//                                                 name:NSFileHandleDataAvailableNotification
//                                             object:[pipe fileHandleForReading]];

//     // Start the task
//     [task launch];
 }

// - (void)receivedData:(NSNotification *)notification {
//     // Read the data from the pipe
//     NSData *data = [[notification object] availableData];

//     // Convert the data to a string
//     NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//     NSLog(@"omriku Output: %@", output);

//     // Check the percentage
//     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)%\\]" options:0 error:nil];
//     NSArray *matches = [regex matchesInString:output options:0 range:NSMakeRange(0, output.length)];
//     for (NSTextCheckingResult *match in matches) {
//         // Extract the percentage from the match
//         NSString *percentage = [output substringWithRange:[match rangeAtIndex:1]];
//         NSLog(@"omriku Percentage: %@%%", percentage);
//     }

//     // Register for notifications again
//     [[notification object] waitForDataInBackgroundAndNotify];
// }

@end
