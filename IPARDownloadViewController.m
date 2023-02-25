#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARCountryTableViewController.h"
#import "IPARUtils.h"
#import "IPARAppDownloadedCell.h"
#import <libarchive/archive.h>
#import <libarchive/archive_entry.h>
#pragma clang diagnostic ignored "-Wimplicit-function-declaration"

@interface IPARDownloadViewController ()
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
@property (nonatomic) UILabel *noDataLabel;
@property (nonatomic) BOOL isRefreshing;
@end

//improve download progress bar, its ugly.
//bundle casuing crash if many apps. check why!!
@implementation IPARDownloadViewController
- (void)loadView {
    [super loadView];
    //size_t read = archive_read_data(_archive, buf, size);
    _isRefreshing = NO;
    _existingApps = [NSMutableArray array];
    _currentPrecentageDownload = [NSString string];
    _lastBundleDownload = [NSString string];
    _linesErrorOutput = [NSMutableArray array];
    _lastCountrySelected = [NSString string];
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.rowHeight = 80;
    self.tableView.estimatedRowHeight = 100;
    // Create a label with the text you want to display
    _noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    _noDataLabel.numberOfLines = 2;
    _noDataLabel.textColor = [UIColor grayColor];
    _noDataLabel.textAlignment = NSTextAlignmentCenter;
    // Set the label as the background view of the table view
    self.tableView.backgroundView = _noDataLabel;
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.center = CGPointMake(_downloadViewController.view.frame.size.width/2, _downloadViewController.view.frame.size.height/2);
    _lastCountrySelected = [IPARUtils getMostUpdatedDownloadCountryFromFile] ? [IPARUtils getMostUpdatedDownloadCountryFromFile] : @"US";
    _countryButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Download Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(countryButtonItemTapped:)];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [_countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];   
    [_countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
    _downloadAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self stopScriptAndRemoveObserver];
    }];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self.downloadAlertController addAction:cancelAction];
     self.navigationItem.leftBarButtonItems = @[_countryButton];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self _setUpNavigationBar2];
    [self setupDownloadViewControllerStyle];
    [self refreshTableData];
    self.countryTableViewController = [[IPARCountryTableViewController alloc] initWithCaller:@"Downloader"];
}

- (void)handleRefresh:(UIRefreshControl *)refreshControl {
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
    [self refreshTableData];
    [refreshControl endRefreshing];
    self.isRefreshing = NO;
}

- (void)refreshTableData {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Loading Downloaded Apps.."
                                                                message:@"\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = CGPointMake(130.5, 75);
    spinner.color = [UIColor grayColor];
    [spinner startAnimating];
    [alert.view addSubview:spinner];
    [self presentViewController:alert animated:YES completion:nil];

    //Dispatch the command to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self populateTableWithExistingApps];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.tableView reloadData];
            });
        });
    });
}

- (void)countryButtonItemTapped:(id)sender {
    [self presentViewController:self.countryTableViewController animated:YES completion:nil];
}

- (void)updateCountry {
    self.lastCountrySelected = [IPARUtils getMostUpdatedDownloadCountryFromFile];
    self.countryButton.title = [NSString stringWithFormat:@"Download Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];   
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal]; 
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
    UIBarButtonItem *deleteAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(deleteAllButtonTapped)];
    deleteAllButton.tintColor = [UIColor redColor];      
    UIFont *font = [UIFont systemFontOfSize:12.0]; // adjust this value as needed
    NSDictionary *attributes = @{NSFontAttributeName:font};
    [deleteAllButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [deleteAllButton setTitleTextAttributes:attributes forState:UIControlStateNormal];                                                      
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[deleteAllButton, downloadButton];
}

- (void)deleteAllButtonTapped {
    if ([self.existingApps count] <= 0) {
        return;
    }

    AlertActionBlock alertConfirmationBlock = ^(void) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        int numOfObjectsToDelete = [[self.existingApps copy] count];
        for (int i=0; i<numOfObjectsToDelete; i++) {
            // Delete the file from the data source
            NSError *error;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, self.existingApps[indexPath.row][@"filename"]] error:&error];
            if (success == NO) {
                NSLog(@"Error deleting file: %@", error);
            } 
            [self.existingApps removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    };

    AlertActionBlock alertCancelBlock = ^(void) {
        if (self.tableView.editing) {
            [self.tableView setEditing:NO animated:YES];
            [self.tableView reloadData];
        }
    };

    NSString *confirmation = @"You are about to all downloaded IPAs\n\nThis operation cannot be undone\nAre you sure?";
    [IPARUtils presentMessageWithTitle:@"IPARanger\nDelete Files" message:confirmation numberOfActions:2 buttonText:@"YES" alertConfirmationBlock:alertConfirmationBlock alertCancelBlock:alertCancelBlock presentOn:self];
}


- (void)logoutAction {
    [IPARUtils presentMessageWithTitle:@"IPARanger\nLogout" message:@"You are about to perform logout\nAre you sure?" numberOfActions:2 buttonText:@"Yes" alertConfirmationBlock:[self getAlertBlockForLogout] alertCancelBlock:nil presentOn:self];
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
    //maybe for later usage.
    //NSArray *bundlesThatExists = [self retrieveBundlesInTmpFolder];
    for (NSString *fileName in ipaFiles) {
        NSLog(@"omriku checking file: %@", fileName);
        NSString *filePath = [IPARANGER_DOCUMENTS_LIBRARY stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"omriku Error getting attributes of file at path: %@", filePath);
            continue;
        }
        long long fileSize = [attributes fileSize];
        NSString *humanReadableSize = [IPARUtils humanReadableSizeForBytes:fileSize];
        NSString *ipaFilePath = [NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, fileName];
        // Load the Info.plist file from the IPA file
        NSString *str = @"\"%s (%s)\\n\"";
        //if you skip this command you get 2 seconds constant loading time. if not, 4 seconds per 60 files. 
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"unzip -p '%@' Payload/*.app/Info.plist | grep -A1 -E '<key>CFBundle(Name|Identifier)</key>' | awk -F'[><]' '/<key>/ { key = $3 } /<string>/ { value = $3; printf(%@, value, key); }'", ipaFilePath, str]];
        NSString *appName = [NSString string];
        NSString *bundleName = [NSString string];
        if ([standardAndErrorOutputs[@"standardOutput"][0] containsString:@"CFBundleName"]) {
            appName = [self parseValueFromKey:standardAndErrorOutputs[@"standardOutput"][0]];
            bundleName = [self parseValueFromKey:standardAndErrorOutputs[@"standardOutput"][1]];
        } else {
            appName = [self parseValueFromKey:standardAndErrorOutputs[@"standardOutput"][1]];
            bundleName = [self parseValueFromKey:standardAndErrorOutputs[@"standardOutput"][0]];
        }
        NSLog(@"omriku bundle? %@, appname: %@", bundleName, appName);
        //need to do that with the command from ealier.. think how you combine those two..
        // Check if the directory already exists
        NSString *tempDir = [NSString stringWithFormat:@"%@tmp/%@/", IPARANGER_DOCUMENTS_LIBRARY, bundleName];
        if ([fileManager fileExistsAtPath:tempDir] == NO) {
            // Create the directory if it doesn't exist
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        UIImage *appImage = [self getAppIconFromIPAFile:[NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, fileName] bundleId:bundleName tempDir:tempDir];
        if (appImage == nil) {
            appImage = [UIImage systemImageNamed:@"questionmark.diamond.fill"];
        }
        [self.existingApps addObject:@{@"filename": fileName, @"size": humanReadableSize, @"appname" : appName, @"appimage" : appImage}];
    }
}

- (NSString *)parseValueFromKey:(NSString *)CFKey{
    NSLog(@"omriku parsing value from: %@", CFKey);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+?)\\s*\\(" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:CFKey options:0 range:NSMakeRange(0, [CFKey length])];
    NSString *result = [CFKey substringWithRange:[match rangeAtIndex:1]];
    return result;
}

- (void)addButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Download" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        self.lastBundleDownload = textField.text;
        if (self.lastBundleDownload == nil || [self.lastBundleDownload stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Bundle ID cannot be empty" numberOfActions:1 buttonText:@"OK" alertConfirmationBlock:nil alertCancelBlock:nil presentOn:self];
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
    NSLog(@"omriku counting rows.. %lu",self.existingApps.count);
    if (self.existingApps.count > 0) {
        //fixing scrolling issue!!
        self.noDataLabel.text = @" \n  ";
        //adding one for show more button
        return self.existingApps.count;
    }
    self.noDataLabel.text = @"Nothing to show here.\nStart by clicking the download icon!";
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IPARAppDownloadedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IPARAppDownloadedCell"];
        
    if (cell == nil) {
        cell = [[IPARAppDownloadedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IPARAppDownloadedCell"];
    }
    if (indexPath.row < self.existingApps.count) {
        UIView *selectionView = [UIView new];
        selectionView.backgroundColor = UIColor.clearColor;
        [[UITableViewCell appearance] setSelectedBackgroundView:selectionView];
        cell.backgroundColor = UIColor.clearColor;
        cell.appName.text = self.existingApps[indexPath.row][@"appname"];
        cell.appFilename.text = self.existingApps[indexPath.row][@"filename"];
        cell.appSize.text = [NSString stringWithFormat:@"%@", self.existingApps[indexPath.row][@"size"]];
        cell.appImage.image = self.existingApps[indexPath.row][@"appimage"];         
    }

    return cell;
	// static NSString *CellIdentifier = @"Cell";
	// UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	// if (!cell) {
	// 	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	// }

    cell.textLabel.text = [NSString stringWithFormat:@"appname: %@ size: %@", self.existingApps[indexPath.row][@"filename"], self.existingApps[indexPath.row][@"size"]]; 
	return cell;
}

// - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
// 	//[self.searchResults removeObjectAtIndex:indexPath.row];
// 	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
// }

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Create actions
    UIAlertAction *openInFilzaAction = [UIAlertAction actionWithTitle:@"Open in Filza" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       [self openInFilza:self.existingApps[indexPath.row][@"filename"]];
    }];
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareFile:self.existingApps[indexPath.row][@"filename"]];
        
    }];
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self renameFileAtPath:self.existingApps[indexPath.row][@"filename"]];
        
    }];
    UIAlertAction *installApplicationAction = [UIAlertAction actionWithTitle:@"Install Application" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self installApplication:self.existingApps[indexPath.row][@"filename"] appName:self.existingApps[indexPath.row][@"appname"]];
    }];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteFile:self.existingApps[indexPath.row][@"filename"] index:indexPath];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    // Add actions to alert
    [alert addAction:installApplicationAction];
    [alert addAction:openInFilzaAction];
    [alert addAction:renameAction];
    [alert addAction:shareAction];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    // Present alert
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)installApplication:(NSString *)ipaFilePath appName:(NSString *)appName {
    AlertActionBlock alertConfirmationBlock = ^(void) { 
        __block NSDictionary *standardAndErrorOutputs = [NSDictionary dictionary];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger\nInstallation\n"
                                                                    message:[NSString stringWithFormat:@"\n\n\nInstalling Application '%@'", appName]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        spinner.center = CGPointMake(130.5, 95);
        spinner.color = [UIColor grayColor];
        [spinner startAnimating];
        [alert.view addSubview:spinner];
        [self presentViewController:alert animated:YES completion:nil]; 
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"%@ %@%@", APPINST_SCRIPT_PATH, IPARANGER_DOCUMENTS_LIBRARY, ipaFilePath]];
            //Successfully installed
            for (NSString *obj in standardAndErrorOutputs[@"standardOutput"]) {
                if ([obj containsString:@"Successfully installed"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self dismissViewControllerAnimated:YES completion:^{
                            [IPARUtils presentMessageWithTitle:@"IPARanger\nSuccess!" message:[NSString stringWithFormat:@"Successfully installed '%@'!", appName] numberOfActions:1 buttonText:@"OK" alertConfirmationBlock:nil alertCancelBlock:nil presentOn:self];
                        }];
                        return;
                    });
                } 
            }   
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                    [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:[NSString stringWithFormat:@"Error occurred while trying to install '%@'", appName] numberOfActions:1 buttonText:@"OK" alertConfirmationBlock:nil alertCancelBlock:nil presentOn:self];
                }];
            });
        });
    };

    NSString *confirmation = [NSString stringWithFormat:@"You are about to install App: %@\n\nAre you sure?", appName];
    [IPARUtils presentMessageWithTitle:@"IPARanger\nInstall Application" message:confirmation numberOfActions:2 buttonText:@"Yes, Continue" alertConfirmationBlock:alertConfirmationBlock alertCancelBlock:nil presentOn:self];
}

- (NSArray *)retrieveBundlesInTmpFolder {
    NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@tmp/", IPARANGER_DOCUMENTS_LIBRARY]];
    NSMutableArray *bundles = [NSMutableArray array];
    for (NSString *bundle in standardAndErrorOutputs[@"standardOutput"]) {
        if ([bundle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
            NSLog(@"omriku adding bundle %@", bundle);
            [bundles addObject:bundle];
        }   
    }
    return bundles;
}

- (UIImage *)getAppIconFromIPAFile:(NSString *)ipaFilePath bundleId:(NSString *)bundleName tempDir:(NSString *)tempDir {
    // Check if the file exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@Info.plist",tempDir]]) {
        NSLog(@"omriku file already exist.. %@", [NSString stringWithFormat:@"%@Info.plist",tempDir]);
    } else {
        [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:@"Info.plist"];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@Payload/", tempDir]];
        NSString *appFolder = standardAndErrorOutputs[@"standardOutput"][0];
        [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"mv %@Payload/%@/Info.plist %@", tempDir, appFolder, tempDir]];
    }
    
    // Read the Info.plist file to get the name of the icon file
    NSString *infoPlistPath = [tempDir stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *iconFileName = infoPlist[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"][0];

    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@%@@2x.png", tempDir, iconFileName]]) {
        NSLog(@"omriku file already exist.. %@", [NSString stringWithFormat:@"%@%@@2x.png", tempDir, iconFileName]);
    } else {
        [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:[NSString stringWithFormat:@"%@@2x.png", iconFileName]];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@Payload/", tempDir]];
        NSString *appFolder = standardAndErrorOutputs[@"standardOutput"][0];
        [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"mv %@Payload/%@/%@@2x.png %@", tempDir, appFolder, iconFileName, tempDir]];
    }

    // Read the icon file and create a UIImage
    NSString *iconFilePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", iconFileName]];
    NSData *iconData = [NSData dataWithContentsOfFile:iconFilePath];
    UIImage *iconImage = [UIImage imageWithData:iconData];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Payload", tempDir] error:nil];
    
    return iconImage;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self deleteFile:self.existingApps[indexPath.row][@"filename"] index:indexPath];
    }];
    
    UIImage *shareImage = [UIImage systemImageNamed:@"square.and.arrow.up"];
    UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {        // Share the file using a UIActivityViewController
        [self shareFile:self.existingApps[indexPath.row][@"filename"]];
    }];
    shareAction.image = shareImage;
    shareAction.backgroundColor = [UIColor blueColor];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, shareAction]];
    return config;
}

- (void)deleteFile:(NSString *)pathToFile index:(NSIndexPath *)indexPath {
    AlertActionBlock alertConfirmationBlock = ^(void) {
        // Delete the file from the data source
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, pathToFile] error:&error];
        if (success == NO) {
            NSLog(@"Error deleting file: %@", error);
        } 
        [self.existingApps removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };

    AlertActionBlock alertCancelBlock = ^(void) {
        if (self.tableView.editing) {
            [self.tableView setEditing:NO animated:YES];
            [self.tableView reloadData];
        }
    };

    NSString *confirmation = [NSString stringWithFormat:@"You are about to delete file: %@\n\nAre you sure?", self.existingApps[indexPath.row][@"filename"]];
    [IPARUtils presentMessageWithTitle:@"IPARanger\nDelete File" message:confirmation numberOfActions:2 buttonText:@"YES" alertConfirmationBlock:alertConfirmationBlock alertCancelBlock:alertCancelBlock presentOn:self];
}

- (void)shareFile:(NSString *)pathToFile {
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, pathToFile]];
    NSArray *activityItems = @[fileURL];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)openInFilza:(NSString *)pathToFile {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"filza://%@%@", IPARANGER_DOCUMENTS_LIBRARY, pathToFile]];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

- (void)renameFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Get the current file name and path
    NSString *fullPath = [NSString stringWithFormat:@"%@%@", IPARANGER_DOCUMENTS_LIBRARY, path];
    NSString *currentFileName = [fullPath lastPathComponent];
    NSString *currentDirectoryPath = [fullPath stringByDeletingLastPathComponent];
    
    // Create an alert controller with a text field for the new file name
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger\nRename File\n\nDont forget to add '.ipa' at the end of your file" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.text = currentFileName;
    }];
    
    // Add rename and cancel actions
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newFileName = alert.textFields.firstObject.text;
        if (![newFileName isEqualToString:currentFileName]) {
            NSString *newFilePath = [currentDirectoryPath stringByAppendingPathComponent:newFileName];
            NSError *error = nil;
            BOOL success = [fileManager moveItemAtPath:fullPath toPath:newFilePath error:&error];
            if (success) {
                NSLog(@"File renamed successfully.");
                [self refreshTableData];
            } else {
                NSLog(@"Error renaming file: %@", error);
            }
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    // Add actions to alert and present it
    [alert addAction:renameAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.downloadAlertController dismissViewControllerAnimated:YES completion:nil];
                [self refreshTableData];
                //[self.downloadViewController dismissViewControllerAnimated:YES completion:nil];
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
        errorForDialog = @"Mismatch Country Code\nMake sure the 'Download Appstore' country you provided matches the country your account is linked to";
    } else if ([errorMessage.lowercaseString rangeOfString:token.lowercaseString].location != NSNotFound ||
               [errorMessage.lowercaseString rangeOfString:login.lowercaseString].location != NSNotFound || 
               [errorMessage.lowercaseString rangeOfString:authentication.lowercaseString].location != NSNotFound) {
        errorForDialog = @"There was an issue with your token\nPlease logout and then login again with your account and try again";
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorForDialog numberOfActions:1 buttonText:@"Logout" alertConfirmationBlock:[self getAlertBlockForLogout] alertCancelBlock:nil presentOn:self];
        return;
    } else if ([errorMessage.lowercaseString rangeOfString:cantFindApp.lowercaseString].location != NSNotFound)
    {
        errorForDialog = [NSString stringWithFormat:@"Could not find app with bundleID: %@", self.lastBundleDownload];
    } else {
        errorForDialog = errorMessage;
    }

    [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorForDialog numberOfActions:1 buttonText:@"OK" alertConfirmationBlock:nil alertCancelBlock:nil presentOn:self];
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