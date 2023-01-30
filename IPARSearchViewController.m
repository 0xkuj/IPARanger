#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARUtils.h"

@interface IPARSearchViewController ()
@property (nonatomic) UIButton *searchButton;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *linesStandardOutput;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@property (nonatomic) NSString *latestSearchTerm;
@end

@implementation IPARSearchViewController

- (void)loadView {
    [super loadView];
    _searchResults = [NSMutableArray array];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    _latestSearchTerm = [NSString string];
    //self.title = @"IPA Ranger - Search";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self _setUpNavigationBar];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
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
        // self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];
        NSDictionary *didLogoutOK = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"%@ auth revoke", IPATOOL_SCRIPT_PATH]];
        for (NSString *string in didLogoutOK[@"errorOutput"]) {
            NSLog(@"omriku print string: %@", string);
        }
        if ([didLogoutOK[@"standardOutput"][0] containsString:@"Revoked credentials for"] || [didLogoutOK[@"errorOutput"][0] containsString:@"No credentials available to revoke"])
        {
            AlertActionBlock alertBlock = ^(void) {
                NSLog(@"omriku logout ok!");
                IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init]; 
                // Step 1: Pop all view controllers from the navigation stack
                [self.navigationController popToRootViewControllerAnimated:NO];
                // Step 2: Remove the tabbarcontroller from the window's rootViewController
                [self.tabBarController.view removeFromSuperview];
                // Step 3: Instantiate your login screen view controller and set it as the new rootViewController of the window
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
                UIWindow *window = UIApplication.sharedApplication.delegate.window;
                window.rootViewController = navController;
                [IPARUtils logoutToFile];  
            };
            [IPARUtils presentMessageWithTitle:@"IPARanger\nLogout" message:@"You are about to perform logout\nAre you sure?" numberOfActions:2 buttonText:@"Yes" alertBlock:alertBlock presentOn:self];
        }
	}];

	UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[optionsButton, lookupButton];
}

- (void)searchButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Search" message:@"Enter App Name" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        self.latestSearchTerm = textField.text;
        if (self.latestSearchTerm == nil || [self.latestSearchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"App Name cannot be empty" numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
        }    
        [self runSearchCommand]; 
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"e.g Facebook";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)runSearchCommand {
    // Create and display a loading animation
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    loadingIndicator.center = self.view.center;
    [self.view addSubview:loadingIndicator];
    [loadingIndicator startAnimating];

    // Dispatch the command to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandToExecute = [NSString stringWithFormat:@"/Applications/IPARanger.app/ipatool/ipatool search %@ --limit 100", self.latestSearchTerm];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
        self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];
        
        // Once the command is finished, update the UI on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            // Remove the loading animation
            [loadingIndicator stopAnimating];
            [loadingIndicator removeFromSuperview];
            if ([self isErrorExists] == NO) {
                [self populateTableWithSearchResults];
            }
             // Update the UI with the results of the command
        });
    });
}

- (BOOL)isErrorExists {
    NSString *errorToShow = [NSString string];
    for (NSString *obj in self.linesErrorOutput) {
        if ([obj isEqualToString:@""] == NO) {
            if ([obj containsString:@"No results found"]) {
                errorToShow = [NSString stringWithFormat:@"No apps containing keyword: '%@' were found in the AppStore",self.latestSearchTerm];
            } else {
                errorToShow = obj;
            }
            [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorToShow numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            return YES;
        } 
    }
    return NO;
}
//try to think of a better algo to show search phrases..
- (void)populateTableWithSearchResults {
    [self.searchResults removeAllObjects];           
    for (id obj in self.linesStandardOutput) {
        NSLog(@"omriku line output :%@", obj);
        [self.searchResults addObject:obj];
    }
    [self.tableView reloadData];
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