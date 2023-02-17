#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARCountryTableViewController.h"
#import "IPARUtils.h"

@interface IPARDownloadViewController ()
@property (nonatomic, strong) NSMutableArray *appsBeingDownloaded;
@property (nonatomic, strong) NSMutableArray *existingApps;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) NSString *currentPrecentageDownload;
@property (nonatomic) UIViewController *downloadViewController;
@property (nonatomic) UIAlertController *downloadAlertController;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@property (nonatomic) NSString *lastBundleDownload;
@property (nonatomic, strong) IPARCountryTableViewController *countryTableViewController;
@property (nonatomic) UIBarButtonItem *countryButton;
@property (nonatomic) NSString *lastCountrySelected;
@end

int pid;

//IMPLEMENT SELECT COUNTRY!
@implementation IPARDownloadViewController
- (void)loadView {
    [super loadView];
    _appsBeingDownloaded = [NSMutableArray array];
    _existingApps = [NSMutableArray array];
    _currentPrecentageDownload = [NSString string];
    _lastBundleDownload = [NSString string];
    _linesErrorOutput = [NSMutableArray array];
    _lastCountrySelected = [NSString string];
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.center = CGPointMake(_downloadViewController.view.frame.size.width/2, _downloadViewController.view.frame.size.height/2);
    _lastCountrySelected = [IPARUtils getMostUpdatedDownloadCountryFromFile] ? [IPARUtils getMostUpdatedDownloadCountryFromFile] : @"US";
    _countryButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"CN: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(barButtonItemTapped:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
    _downloadAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self stopScriptAndRemoveObserver];
    }];
    [self.downloadAlertController addAction:cancelAction];
     self.navigationItem.leftBarButtonItems = @[self.editButtonItem, _countryButton];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self _setUpNavigationBar2];
    [self setupDownloadViewControllerStyle];
    [self populateTableWithExistingApps];
    self.countryTableViewController = [[IPARCountryTableViewController alloc] initWithCaller:@"Downloader"];
}

- (void)barButtonItemTapped:(id)sender {
    [self presentViewController:self.countryTableViewController animated:YES completion:nil];
}

- (void)updateCountry {
    self.lastCountrySelected = [IPARUtils getMostUpdatedDownloadCountryFromFile];
    self.countryButton.title = [NSString stringWithFormat:@"CN: %@", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]];
}

// I THINK ALERT CONTROLLER WILL BE THE BEST OPTION HERE. LESS BUGS.!
- (void)setupDownloadViewControllerStyle {
    self.downloadViewController = [[UIViewController alloc] init];
    self.downloadViewController.view.backgroundColor = [UIColor blackColor];//[UIColor colorWithWhite:0 alpha:0.5];
    self.downloadViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.downloadViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
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
        // self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];
        NSDictionary *didLogoutOK = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"%@ auth revoke", IPATOOL_SCRIPT_PATH]];
        if ([didLogoutOK[@"standardOutput"][0] containsString:@"Revoked credentials for"] || [didLogoutOK[@"errorOutput"][0] containsString:@"No credentials available to revoke"])
        {
            [self logoutAction];
        }
	}];

    // if (@available(iOS 14, *)) {
    //     UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.right"] style:UIBarButtonItemStylePlain target:self action:@selector(logoutAction)];
    //     UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    //     self.navigationItem.rightBarButtonItems = @[logoutButton, downloadButton];
    //}
    UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[optionsButton, downloadButton];
}

- (void)logoutAction {
    [IPARUtils presentMessageWithTitle:@"IPARanger\nLogout" message:@"You are about to perform logout\nAre you sure?" numberOfActions:2 buttonText:@"Yes" alertBlock:[self getAlertBlockForLogout] presentOn:self];
}

- (AlertActionBlock)getAlertBlockForLogout {  
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
    return alertBlock;
}
- (void)populateTableWithExistingApps {
    NSLog(@"omriku will try to read directory content.. ");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    // Get an array of all files and directories in the specified directory
    NSArray *files = [fileManager contentsOfDirectoryAtPath:IPARANGER_DOCUMENTS_LIBRARY error:&error];
    if (error) {
        NSLog(@"omriku Error getting contents of directory: %@", error);
        return;
    }

    // Filter the array to only include "ipa" files
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.ipa'"];
    NSArray *ipaFiles = [files filteredArrayUsingPredicate:predicate];

    // Get the size of each "ipa" file
    [self.existingApps removeAllObjects];
    NSMutableArray *ipaFileInfos = [NSMutableArray array];
    for (NSString *fileName in ipaFiles) {
        NSLog(@"omriku checking file: %@", fileName);
        NSString *filePath = [IPARANGER_DOCUMENTS_LIBRARY stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"omriku Error getting attributes of file at path: %@", filePath);
            continue;
        }
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        [self.existingApps addObject:@{@"name": fileName, @"size": fileSize}];
    }
    [self.tableView reloadData];
    // Now you can use the `ipaFileInfos` array to populate your table view.
}

- (void)addButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Download" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        self.lastBundleDownload = textField.text;
        if (self.lastBundleDownload == nil || [self.lastBundleDownload stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Bundle ID cannot be empty" numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
        }
        //[self presentViewController:self.downloadViewController animated:YES completion:nil];
        [self showDownloadDialog];
        self.currentPrecentageDownload = 0;
        [self.progressView setProgress:0.0f];
        NSLog(@"omriku sigining notif..");
        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(receivedData:)
                                              name:NSFileHandleDataAvailableNotification
                                              object:nil];
        
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ download --bundle-identifier %@ -o %@ --purchase -c %@", IPATOOL_SCRIPT_PATH, self.lastBundleDownload, IPARANGER_DOCUMENTS_LIBRARY, self.lastCountrySelected];
        //here we dont deal with errors since 'download' keyword throws notification
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
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
    return self.existingApps.count + self.appsBeingDownloaded.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

    cell.textLabel.text = [NSString stringWithFormat:@"appname: %@ size: %@", self.existingApps[indexPath.row][@"name"], self.existingApps[indexPath.row][@"size"]]; 
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

//==> ❌  [Error] The country provided does not match with the account you are using. Supply a valid country using the "--country" flag
//==> ❌  [Error] Token expired. Login again using the "auth" command.
//==> ❌  [Error] Could not find ap
- (void)receivedData:(NSNotification *)notification {
    static int downloadInProgress = 0;
    // Read the data from the pipe
    NSData *data = [[notification object] availableData];

    // Convert the data to a string
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"omriku Output: %@", output);
   
    if ([output containsString:@"Error"]) {
        //[self.downloadAlertController dismissViewControllerAnimated:YES completion:nil];
        [self.downloadAlertController dismissViewControllerAnimated:YES completion:^{
        // code to be executed after the alert controller is dismissed
             [self showErrorDialog:output];
        }];
        [self stopScriptAndRemoveObserver];
        return;
    }

    // Check the percentage
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)%\\]" options:0 error:nil];
    NSArray *matches = [regex matchesInString:output options:0 range:NSMakeRange(0, output.length)];
    for (NSTextCheckingResult *match in matches) {
        // Extract the percentage from the match
        NSString *percentage = [output substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"omriku Percentage: %@%%", percentage);
        self.currentPrecentageDownload = percentage;
        [self performSelectorOnMainThread:@selector(updateProgressBar) withObject:nil waitUntilDone:NO];
        if ([percentage containsString:@"100"]) {
            NSLog(@"omriku have 100!");
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self populateTableWithExistingApps];
                //[self.downloadViewController dismissViewControllerAnimated:YES completion:nil];
                [self.downloadAlertController dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }

    // Register for notifications again
    [[notification object] waitForDataInBackgroundAndNotify];
}


- (void)showDownloadDialog {
    // Create a UIAlertController with a custom view
    self.downloadAlertController.title = @"IPARanger\nDownloading..";
    self.downloadAlertController.message = [NSString stringWithFormat:@"Downloading requested bundle: %@\n\n", self.lastBundleDownload];
    self.progressView.frame = CGRectMake(15, 120, 230, 5);
    [self.downloadAlertController.view addSubview:self.progressView];
    [self presentViewController:self.downloadAlertController animated:YES completion:nil];
}

- (void)showErrorDialog:(NSString *)errorMessage {
    //this is where you should handle errors!
    // Create a UIAlertController with a custom view
    NSString *token = @"token";
    NSString *login = @"login";
    NSString *authentication = @"authentication";
    NSString *cantFindApp = @"could not find app";

    NSString *errorForDialog = [NSString string];
    if ([errorMessage containsString:@"Country"] || [errorMessage containsString:@"country"]) {
        errorForDialog = @"Mismatch Country Code\nMake sure the country code you supplied matches the country your account is linked to";
    } else if ([errorMessage.lowercaseString rangeOfString:token.lowercaseString].location != NSNotFound ||
               [errorMessage.lowercaseString rangeOfString:login.lowercaseString].location != NSNotFound || 
               [errorMessage.lowercaseString rangeOfString:authentication.lowercaseString].location != NSNotFound) {
        errorForDialog = @"There was an issue with your token\nPlease logout and then login again with your account and try again";
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorForDialog numberOfActions:1 buttonText:@"Logout" alertBlock:[self getAlertBlockForLogout] presentOn:self];
        return;
    } else if ([errorMessage.lowercaseString rangeOfString:cantFindApp.lowercaseString].location != NSNotFound)
    {
        errorForDialog = [NSString stringWithFormat:@"Could not find app with bundleID: %@", self.lastBundleDownload];
    } else {
        errorForDialog = errorMessage;
    }

    [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorForDialog numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
}        


- (void)updateProgressBar {
    NSLog(@"omriku updateing progress bar with.. %f", [self.currentPrecentageDownload floatValue]/100);
    [self.progressView setProgress:[self.currentPrecentageDownload floatValue]/100];
}

- (void)stopScriptAndRemoveObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
    [IPARUtils cancelScript];
}
@end

// - (void)showDownloadDialog {
//     // UIView *overlayView = [[UIView alloc] initWithFrame:self.tableView.frame];
//     // overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
//     // overlayView.userInteractionEnabled = NO;
//     // [newViewController.view addSubview:overlayView];
//     //this will force me to see the whole page (presetnviewcontroller)
//     //this will work but will let me keep pressing buttons.
//    //[self.view addSubview:self.downloadViewController.view];
//     //consider - customized alert controller? but it will disable your tabs.. not sure you want to do this.
//     // Create the progress view
//     // UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
//     // progressView.center = 
//     UIAlertController *downloadAlert = [UIAlertController alertControllerWithTitle:@"Downloading..." message:nil preferredStyle:UIAlertControllerStyleAlert];
//     UILabel *percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 110, 40, 20)];
//     percentageLabel.text = @"blablabla";
//     [downloadAlert.view addSubview:percentageLabel];
    
//     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//         // Handle cancel action here
//     }];
//     [downloadAlert addAction:cancelAction];
//     [downloadAlert.view addSubview:self.progressView];

//     [self presentViewController:downloadAlert animated:YES completion:nil];
// }