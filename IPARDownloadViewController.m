#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARCountryTableViewController.h"
#import "IPARUtils.h"
#import "IPARAppDownloadedCell.h"
#import "IPARConstants.h"
#pragma clang diagnostic ignored "-Wimplicit-function-declaration"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

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
@implementation IPARDownloadViewController
- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"Download";
		self.tabBarItem.image = [UIImage systemImageNamed:@"square.stack.3d.up"];
		self.tabBarItem.title = @"Download";
    }
    return self;
}

- (void)loadView {
    [super loadView];
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
    _lastCountrySelected = [IPARUtils getKeyFromFile:@"AccountCountryDownload" defaultValueIfNil:@"US"];
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
    [alert.view addSubview:[IPARUtils createActivitiyIndicatorWithPoint:CGPointMake(130.5, 75)]];
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
    self.lastCountrySelected = [IPARUtils getKeyFromFile:@"AccountCountryDownload" defaultValueIfNil:@"US"];
    self.countryButton.title = [NSString stringWithFormat:@"Download Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];   
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal]; 
}

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
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(downloadButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[deleteAllButton, downloadButton];
}

- (void)deleteAllButtonTapped {
    if ([self.existingApps count] <= 0) {
        return;
    }

    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        int numOfObjectsToDelete = [[self.existingApps copy] count];
        for (int i=0; i<numOfObjectsToDelete; i++) {
            // Delete the file from the data source
            NSError *error;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, self.existingApps[indexPath.row][@"filename"]] error:&error];
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
    [IPARUtils presentDialogWithTitle:@"IPARanger\nDelete Files" message:confirmation hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:alertBlockConfirm withConfirmText:@"YES" alertCancelBlock:alertCancelBlock withCancelText:@"Cancel" presentOn:self];
}

- (AlertActionBlockWithTextField)getAlertBlockForLogout {  
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
         [IPARUtils accountDetailsToFile:@"" authName:@"" authenticated:@"NO"]; 
        IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init]; 
        // Step 1: Pop all view controllers from the navigation stack
        [self.navigationController popToRootViewControllerAnimated:NO];
        // Step 2: Remove the tabbarcontroller from the window's rootViewController
        [self.tabBarController.view removeFromSuperview];
        // Step 3: Instantiate your login screen view controller and set it as the new rootViewController of the window
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        window.rootViewController = navController;
    };
    return alertBlockConfirm;
}

- (void)populateTableWithExistingApps {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:kIPARangerDocumentsPath error:&error];
    if (error) {
        return;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.ipa'"];
    NSArray *ipaFiles = [files filteredArrayUsingPredicate:predicate];
    [self.existingApps removeAllObjects];;
    for (NSString *fileName in ipaFiles) {
        NSString *filePath = [kIPARangerDocumentsPath stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            continue;
        }
        long long fileSize = [attributes fileSize];
        NSString *humanReadableSize = [IPARUtils humanReadableSizeForBytes:fileSize];
        NSString *ipaFilePath = [NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, fileName];
        // Load the Info.plist file from the IPA file
        NSString *str = @"\"%s (%s)\\n\"";
        //if you skip this command you get 2 seconds constant loading time. if not, 4 seconds per 60 files. 
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"unzip -p '%@' Payload/*.app/Info.plist | grep -A1 -E '<key>CFBundle(Name|Identifier)</key>' | awk -F'[><]' '/<key>/ { key = $3 } /<string>/ { value = $3; printf(%@, value, key); }'", ipaFilePath, str]];
        NSString *appName = @"N/A";
        NSString *bundleName = @"N/A";
        if ([standardAndErrorOutputs[kstdOutput] count] > 2) {
            // sometimes info.plist contains CFBundleName first, and sometimes the opposite. thats why we are doing this
            if ([standardAndErrorOutputs[kstdOutput][0] containsString:@"CFBundleName"]) {
                appName = [self parseValueFromKey:standardAndErrorOutputs[kstdOutput][0]];
                bundleName = [self parseValueFromKey:standardAndErrorOutputs[kstdOutput][1]];
            } else {
                appName = [self parseValueFromKey:standardAndErrorOutputs[kstdOutput][1]];
                bundleName = [self parseValueFromKey:standardAndErrorOutputs[kstdOutput][0]];
            }
        }
        NSString *tempDir = [NSString stringWithFormat:@"%@tmp/%@/", kIPARangerDocumentsPath, bundleName];
        if ([fileManager fileExistsAtPath:tempDir] == NO) {
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        UIImage *appImage = [self getAppIconFromIPAFile:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, fileName] bundleId:bundleName tempDir:tempDir];
        if (appImage == nil) {
            appImage = [UIImage systemImageNamed:@"questionmark.diamond.fill"];
        }
        [self.existingApps addObject:@{@"filename": fileName, @"size": humanReadableSize, @"appname" : appName, @"appimage" : appImage}];
    }
}

- (NSString *)parseValueFromKey:(NSString *)CFKey{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+?)\\s*\\(" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:CFKey options:0 range:NSMakeRange(0, [CFKey length])];
    NSString *result = [CFKey substringWithRange:[match rangeAtIndex:1]];
    return result;
}

- (void)downloadButtonTapped:(id)sender {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        self.lastBundleDownload = textField.text;
        if (self.lastBundleDownload == nil || [self.lastBundleDownload stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:@"Bundle ID cannot be empty" hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
        }
        [self showDownloadDialog];
        self.currentPrecentageDownload = 0;
        [self.progressView setProgress:0.0f];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(receivedData:)
                                            name:NSFileHandleDataAvailableNotification
                                            object:nil];
        
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ download --bundle-identifier %@ -o %@ --purchase -c %@", kIpatoolScriptPath, self.lastBundleDownload, kIPARangerDocumentsPath, self.lastCountrySelected];
        //here we dont deal with errors since 'download' keyword throws notification
        [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
    };

    AlertActionBlockWithTextField alertBlockTextfield = ^(UITextField *textField) {
        textField.placeholder = @"e.g com.facebook.Facebook";
    };

    [IPARUtils presentDialogWithTitle:@"IPARanger - Download" message:@"Enter App Bundle ID" hasTextfield:YES withTextfieldBlock:alertBlockTextfield
                    alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Download" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];

}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        __block NSDictionary *standardAndErrorOutputs = [NSDictionary dictionary];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger\nInstallation\n"
                                                                    message:[NSString stringWithFormat:@"\n\n\nInstalling Application '%@'", appName]
                                                                preferredStyle:UIAlertControllerStyleAlert];
                                                                
        [alert.view addSubview:[IPARUtils createActivitiyIndicatorWithPoint:CGPointMake(130.5, 95)]];
        [self presentViewController:alert animated:YES completion:nil]; 
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"%@ %@%@", kAppinstScriptPath, kIPARangerDocumentsPath, ipaFilePath]];
            //Successfully installed
            for (NSString *obj in standardAndErrorOutputs[kstdOutput]) {
                if ([obj containsString:@"Successfully installed"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self dismissViewControllerAnimated:YES completion:^{
                            [IPARUtils presentDialogWithTitle:@"IPARanger\nSuccess!" message:[NSString stringWithFormat:@"Successfully installed '%@'!", appName] hasTextfield:NO withTextfieldBlock:nil
                                alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                        }];
                        return;
                    });
                } 
            }   
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:[NSString stringWithFormat:@"Error occurred while trying to install '%@'", appName] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                }];
            });
        });
    };

    NSString *confirmation = [NSString stringWithFormat:@"You are about to install App: %@\n\nAre you sure?", appName];
    [IPARUtils presentDialogWithTitle:@"IPARanger\nInstall Application" message:confirmation hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Yes, Continue" alertCancelBlock:nil withCancelText:nil presentOn:self];
}

- (NSArray *)retrieveBundlesInTmpFolder {
    NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@tmp/", kIPARangerDocumentsPath]];
    NSMutableArray *bundles = [NSMutableArray array];
    for (NSString *bundle in standardAndErrorOutputs[kstdOutput]) {
        if ([bundle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
            [bundles addObject:bundle];
        }   
    }
    return bundles;
}

- (UIImage *)getAppIconFromIPAFile:(NSString *)ipaFilePath bundleId:(NSString *)bundleName tempDir:(NSString *)tempDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@Info.plist",tempDir]] == NO) {
        [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:@"Info.plist"];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@Payload/", tempDir]];
        NSString *appFolder = standardAndErrorOutputs[kstdOutput][0];
        [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"mv %@Payload/%@/Info.plist %@", tempDir, appFolder, tempDir]];
    } 

    NSString *infoPlistPath = [tempDir stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *iconFileName = infoPlist[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"][0];

    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@%@@2x.png", tempDir, iconFileName]] == NO) {
        [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:[NSString stringWithFormat:@"%@@2x.png", iconFileName]];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:[NSString stringWithFormat:@"ls %@Payload/", tempDir]];
        NSString *appFolder = standardAndErrorOutputs[kstdOutput][0];
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
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        // Delete the file from the data source
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, pathToFile] error:&error];
        if (success == NO) {
            NSLog(@"Error deleting file: %@", error);
        } 
        [self.existingApps removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };

    AlertActionBlock alertBlockCancel = ^(void) {
        if (self.tableView.editing) {
            [self.tableView setEditing:NO animated:YES];
            [self.tableView reloadData];
        }
    };

    NSString *confirmation = [NSString stringWithFormat:@"You are about to delete file: %@\n\nAre you sure?", self.existingApps[indexPath.row][@"filename"]];
    [IPARUtils presentDialogWithTitle:@"IPARanger\nDelete File" message:confirmation hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"YES" alertCancelBlock:alertBlockCancel withCancelText:@"Cancel" presentOn:self];
}

- (void)shareFile:(NSString *)pathToFile {
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, pathToFile]];
    NSArray *activityItems = @[fileURL];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)openInFilza:(NSString *)pathToFile {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"filza://%@%@", kIPARangerDocumentsPath, pathToFile]];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

- (void)renameFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, path];
    NSString *currentFileName = [fullPath lastPathComponent];
    NSString *currentDirectoryPath = [fullPath stringByDeletingLastPathComponent];
    
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSString *newFileName = textField.text;
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
    };

    AlertTextFieldBlock alertBlockTextfield = ^(UITextField *textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.text = currentFileName;
    };

    [IPARUtils presentDialogWithTitle:@"IPARanger\nRename File\n\nDont forget to add '.ipa' at the end of your file" message:nil hasTextfield:YES withTextfieldBlock:alertBlockTextfield
                alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Rename" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
}

- (void)receivedData:(NSNotification *)notification {
    NSData *data = [[notification object] availableData];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
   
    if ([output containsString:@"Error"]) {
        [self.downloadAlertController dismissViewControllerAnimated:YES completion:^{
             [self showErrorDialog:output];
        }];
        [self stopScriptAndRemoveObserver];
        return;
    }

    [self analyzePercentage:output];
    [[notification object] waitForDataInBackgroundAndNotify];
}

- (void)analyzePercentage:(NSString *)output {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)%\\]" options:0 error:nil];
    NSArray *matches = [regex matchesInString:output options:0 range:NSMakeRange(0, output.length)];
    for (NSTextCheckingResult *match in matches) {
        NSString *percentage = [output substringWithRange:[match rangeAtIndex:1]];
        self.currentPrecentageDownload = percentage;
        [self performSelectorOnMainThread:@selector(updateProgressBar) withObject:nil waitUntilDone:NO];
        if ([percentage containsString:@"100"]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.downloadAlertController dismissViewControllerAnimated:YES completion:nil];
                [self refreshTableData];
            });
        }
    }
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
        [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:errorForDialog hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:[self getAlertBlockForLogout] withConfirmText:@"Logout" alertCancelBlock:nil withCancelText:nil presentOn:self];
        return;
    } else if ([errorMessage.lowercaseString rangeOfString:cantFindApp.lowercaseString].location != NSNotFound)
    {
        errorForDialog = [NSString stringWithFormat:@"Could not find app with bundleID: %@", self.lastBundleDownload];
    } else {
        errorForDialog = errorMessage;
    }
    [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:errorForDialog hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
}        


- (void)updateProgressBar {
    [self.progressView setProgress:[self.currentPrecentageDownload floatValue]/100];
}

- (void)stopScriptAndRemoveObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
    [IPARUtils cancelScript];
}
@end