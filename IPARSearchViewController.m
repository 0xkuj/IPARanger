#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARUtils.h"

@interface IPARSearchViewController ()
@property (nonatomic) UIButton *searchButton;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *linesStandardOutput;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@end

@implementation IPARSearchViewController

- (void)loadView {
    [super loadView];
    _searchResults = [NSMutableArray array];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    //self.title = @"IPA Ranger - Search";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self _setUpNavigationBar];
    //[self setSearchButton];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Create a navigation controller and set self as the root view controller
    // UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
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

	UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
    //UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    //self.navigationItem.rightBarButtonItems = @[optionsButton, downloadButton, lookupButton];
    self.navigationItem.rightBarButtonItems = @[optionsButton, lookupButton];
}

// - (void)setSearchButton {
//     self.searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
//     self.searchButton.backgroundColor = [UIColor redColor];
//     [self.searchButton setTitle:@"Tap me to search!" forState:UIControlStateNormal];
//     [self.searchButton addTarget:self  action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//     //searchButton.translatesAutoresizingMaskIntoConstraints = NO;
//     [self.searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
// }

- (void)searchButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Search" message:@"Enter App Name" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *searchTerm = textField.text;
        [self runSearchCommand:searchTerm]; 
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"e.g Facebook";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)runSearchCommand:(NSString *)searchTerm {
    // Create and display a loading animation
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    loadingIndicator.center = self.view.center;
    [self.view addSubview:loadingIndicator];
    [loadingIndicator startAnimating];

    // Dispatch the command to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Execute the command here
        // ...
        NSString *commandToExecute = [NSString stringWithFormat:@"/Applications/IPARanger.app/ipatool/ipatool search %@ --limit 100", searchTerm];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
        self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];
        
        // Once the command is finished, update the UI on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            // Remove the loading animation
            [loadingIndicator stopAnimating];
            [loadingIndicator removeFromSuperview];
            [self populateTableWithSearchResults];
            // Update the UI with the results of the command
            // ...
        });
    });
}

//try to think of a better algo to show search phrases..
- (void)populateTableWithSearchResults {
    [self.searchResults removeAllObjects];           
    for (id obj in self.linesStandardOutput) {
        NSLog(@"omriku line output :%@", obj);
        [self.searchResults addObject:obj];
    }
    for (id obj in self.linesErrorOutput) {
        NSLog(@"omriku error output :%@", obj);
        [self.searchResults addObject:obj];
    }
    [self.tableView reloadData];
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
        //could not find app..
        UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ download --bundle-identifier %@ -o %@ --purchase -c US",IPATOOL_SCRIPT_PATH, text, IPARANGER_DOCUMENTS_LIBRARY];
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

-(void)testing:(NSString *)command {
    NSLog(@"omriku in testing, command %@", command);
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:command];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    // Create a pipe for the task's standard output
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    NSLog(@"omriku sigining to notif..");
    // Register for notifications when new data is available to read
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(receivedData:)
                                                name:NSFileHandleDataAvailableNotification
                                            object:[pipe fileHandleForReading]];

    // Start the task
    [task launch];
}

- (void)receivedData:(NSNotification *)notification {
    // Read the data from the pipe
    NSData *data = [[notification object] availableData];

    // Convert the data to a string
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"omriku Output: %@", output);

    // Check the percentage
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)%\\]" options:0 error:nil];
    NSArray *matches = [regex matchesInString:output options:0 range:NSMakeRange(0, output.length)];
    for (NSTextCheckingResult *match in matches) {
        // Extract the percentage from the match
        NSString *percentage = [output substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"omriku Percentage: %@%%", percentage);
    }

    // Register for notifications again
    [[notification object] waitForDataInBackgroundAndNotify];
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