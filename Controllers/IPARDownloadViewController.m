#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARCountryTableViewController_deprecated.h"
#import "IPARAppInfo.h"
#import "../Utils/IPARUtils.h"
#import "../Extensions/IPARConstants.h"
#import "../Cells/IPARAppCell.h"

#pragma clang diagnostic ignored "-Wimplicit-function-declaration"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wformat-extra-args"

@interface IPARDownloadViewController () 
@property (nonatomic, strong) NSMutableArray *existingApps;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) NSString *currentPrecentageDownload;
@property (nonatomic) UIViewController *downloadViewController;
@property (nonatomic) UIAlertController *downloadAlertController;
@property (nonatomic, strong) NSMutableArray *linesErrorOutput;
@property (nonatomic) NSString *lastBundleDownload;
@property (nonatomic) NSTimer *downloadTimer;
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
        self.title = kDownloadTitle;
		self.tabBarItem.image = [UIImage systemImageNamed:kTabbarDownloadingSectionSystemImage];
		self.tabBarItem.title = kDownloadTitle;
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
    _downloadAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    _countryTableViewController = [[IPARCountryTableViewController alloc] initWithCaller:@"Downloader"];
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    _downloadViewController = [[UIViewController alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL created = NO;
    BOOL isDirectory = NO;
    BOOL directoryExists = [fileManager fileExistsAtPath:kIPARangerDocumentsPath isDirectory:&isDirectory];
    NSError *error = nil;
    if ((directoryExists && isDirectory) == NO) {
        created = [fileManager createDirectoryAtPath:kIPARangerDocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [self setupTableviewPropsAndBackground];
    [self setupProgressViewCenter];
    //deprecated
    //[self setupCountryButton];
    [self setupDownloadAlertController];
    [self _setUpNavigationBar2];
    [self setupDownloadViewControllerStyle];
    [self refreshTableData];
}

- (void)setupDownloadAlertController {
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [IPARUtils cancelScript];
    }];
    [self.downloadAlertController addAction:cancelAction];
}

- (void)setupCountryButton {
    self.lastCountrySelected = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.countryButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Download Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(countryButtonItemTapped:)];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
    self.navigationItem.leftBarButtonItems = @[_countryButton];
}

- (void)setupProgressViewCenter {
    self.progressView.center = CGPointMake(self.downloadViewController.view.frame.size.width/2, self.downloadViewController.view.frame.size.height/2);
}

- (void)setupTableviewPropsAndBackground {
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.rowHeight = 80;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.noDataLabel.numberOfLines = 2;
    self.noDataLabel.textColor = [UIColor grayColor];
    self.noDataLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = self.noDataLabel;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self populateTableWithExistingApps];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
    self.lastCountrySelected = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.countryButton.title = [NSString stringWithFormat:@"Download Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

- (void)setupDownloadViewControllerStyle {
    self.downloadViewController.view.backgroundColor = [UIColor blackColor];
    self.downloadViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.downloadViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
}

- (void)_setUpNavigationBar2 {
    UIBarButtonItem *deleteAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(deleteAllButtonTapped)];
    deleteAllButton.tintColor = [UIColor redColor];
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *attributes = @{NSFontAttributeName:font};
    [deleteAllButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [deleteAllButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:kDownloadSystemImage] style:UIBarButtonItemStylePlain target:self action:@selector(downloadButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[deleteAllButton, downloadButton];
    [self setupDownloadsMenu];
}

- (void)setupDownloadsMenu {
    UIAction *openInFilzaAction = [UIAction actionWithTitle:@"Open Download Folder in Filza" 
                                                      image:[UIImage systemImageNamed:kFolderIcon] 
                                                 identifier:nil 
                                                    handler:^(__kindof UIAction * _Nonnull action) {
        [self openInFilza:kIPARangerDocumentsPath];
    }];
    
    UIAction *deleteCacheAction = [UIAction actionWithTitle:@"Delete Cache Folder" 
                                                      image:[UIImage systemImageNamed:kTrashIcon] 
                                                 identifier:nil 
                                                    handler:^(__kindof UIAction * _Nonnull action) {
                                                        
        unsigned long long cacheFolderSize = [IPARUtils calculateFolderSize:kIPARangerCacheDirPath];
        NSString *folderSizeString = [IPARUtils humanReadableSizeForBytes:cacheFolderSize];
        AlertActionBlock alertBlockConfirm = ^(void) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                [fileManager removeItemAtPath:kIPARangerCacheDirPath error:nil];
        };
        
        [self dismissViewControllerAnimated:YES completion:^{
            [IPARUtils presentDialogWithTitle:kIPARangerWarningHeadline message:[NSString stringWithFormat:@"The cache folder contains cached information about your previously downloaded apps.\nYour downloaded app will still exists.\n\nCache folder size: %@\n\nAre you sure?", folderSizeString] hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"No" alertCancelBlock:alertBlockConfirm withCancelText:@"Yes" presentOn:self];
        }]; 
    }];
    
    deleteCacheAction.attributes = UIMenuElementAttributesDestructive;

    UIMenu *menu = [UIMenu menuWithTitle:@""
                                  image:nil
                             identifier:nil
                                options:UIMenuOptionsDisplayInline
                                children:@[openInFilzaAction, deleteCacheAction]];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:kMenuIcon] 
                                                                   menu:menu];
    
    self.navigationItem.leftBarButtonItem = menuButton;
}
- (void)deleteAllButtonTapped {
    if ([self.existingApps count] <= 0) {
        return;
    }

    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        int numOfObjectsToDelete = [[self.existingApps copy] count];
        for (int i=0; i<numOfObjectsToDelete; i++) {
            NSError *error;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, self.existingApps[indexPath.row][kFilenameIndex]] error:nil];
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

    NSString *confirmation = @"You are about to delete all downloaded IPAs\n\nThis operation cannot be undone\nAre you sure?";
    [IPARUtils presentDialogWithTitle:kIPARangerDeleteFilesHeadline message:confirmation hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:alertBlockConfirm withConfirmText:@"YES" alertCancelBlock:alertCancelBlock withCancelText:@"Cancel" presentOn:self];
}

- (AlertActionBlock)getAlertBlockForLogout {
    AlertActionBlock alertBlockConfirm = ^(void) {
        [IPARUtils accountDetailsToFile:@"" authName:@"" authenticated:@"NO"];
        IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.tabBarController.view removeFromSuperview];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        window.rootViewController = navController;
    };
    return alertBlockConfirm;
}

- (void)populateTableWithExistingApps {
    NSArray *ipaFiles = [self getIPAFilesFromDocumentsDirectory];
    [self.existingApps removeAllObjects];

    NSMutableDictionary *cachedData = [self loadAppCacheFromPath:kIPARangerAppsCacheDirPath];

    for (NSString *fileName in ipaFiles) {
        [self processIPAFile:fileName withCachedData:cachedData];
    }
    
    [cachedData writeToFile:kIPARangerAppsCacheDirPath atomically:YES];
}

- (NSArray *)getIPAFilesFromDocumentsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:kIPARangerDocumentsPath error:&error];
    
    if (error) {
        return @[];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:kPredicateIPAApps];
    return [files filteredArrayUsingPredicate:predicate];
}

- (NSMutableDictionary *)loadAppCacheFromPath:(NSString *)cachePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:cachePath]) {
        [fileManager createFileAtPath:cachePath contents:nil attributes:nil];
        return [NSMutableDictionary dictionary];
    } else {
        NSMutableDictionary *cache = [[NSMutableDictionary alloc] initWithContentsOfFile:cachePath];
        return cache ?: [NSMutableDictionary dictionary];
    }
}

- (void)processIPAFile:(NSString *)fileName withCachedData:(NSMutableDictionary *)cachedData {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [kIPARangerDocumentsPath stringByAppendingPathComponent:fileName];

    NSDictionary *cachedApp = cachedData[fileName];
    if (cachedApp) {
        [self addCachedAppToExistingApps:cachedApp];
        return;
    }
    
    NSError *error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
    if (error) {
        return;
    }
    
    NSDictionary *appData = [self extractAppDataFromIPAFile:fileName withAttributes:attributes];
    if (appData) {
        [self.existingApps addObject:appData];
        NSMutableDictionary *cachedAppData = [self createCachedAppDataFrom:appData];
        cachedData[fileName] = cachedAppData;
    }
}

- (void)addCachedAppToExistingApps:(NSDictionary *)cachedApp {
    NSData *imageData = cachedApp[kAppimageIndex];
    UIImage *appImage = [UIImage imageWithData:imageData];
    
    NSMutableDictionary *mutableApp = [cachedApp mutableCopy];
    mutableApp[kAppimageIndex] = appImage;
    [self.existingApps addObject:mutableApp];
}

- (NSDictionary *)extractAppDataFromIPAFile:(NSString *)fileName withAttributes:(NSDictionary *)attributes {
    long long fileSize = [attributes fileSize];
    NSString *humanReadableSize = [IPARUtils humanReadableSizeForBytes:fileSize];
    
    NSString *ipaFilePath = [NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, fileName];
    
    IPARAppInfo *appInfo = [self extractAppInfoFromIPA:ipaFilePath toTempFolder:kIPARangerCacheDirTempPath];
    if (!appInfo) {
        return nil;
    }
    
    UIImage *appImage = appInfo.appIcon ?: [UIImage systemImageNamed:kUnknownSystemImage];
    return @{
        kFilenameIndex: fileName,
        kSizeIndex: humanReadableSize,
        kAppnameIndex: appInfo.appName,
        kAppimageIndex: appImage
    };
}

- (NSMutableDictionary *)createCachedAppDataFrom:(NSDictionary *)appData {
    UIImage *appImage = appData[kAppimageIndex];
    NSData *imageData = UIImagePNGRepresentation(appImage);
    
    NSMutableDictionary *cachedAppData = [appData mutableCopy];
    cachedAppData[kAppimageIndex] = imageData;
    
    return cachedAppData;
}

- (IPARAppInfo *)extractAppInfoFromIPA:(NSString *)ipaFilePath toTempFolder:(NSString *)tempDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [self extractInfoPlistFromIPA:ipaFilePath toFolder:tempDir];
    NSString *folderNameInsidePayload = [self getFolderNameInsidePayload:[NSString stringWithFormat:@"%@/Payload/", tempDir]];
    
    if (!folderNameInsidePayload) {
        [fileManager removeItemAtPath:tempDir error:nil];
        return nil;
    }
    
    NSString *infoPlistPath = [NSString stringWithFormat:@"%@/Payload/%@/%@", tempDir, folderNameInsidePayload, kInfoFile];
    
    NSDictionary *stdOutput = [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathPlutil 
                                                                      arg1:kKeyForPlutil 
                                                                      arg2:kKeyToExtractPlutilBundleId 
                                                                      arg3:infoPlistPath];
    NSString *bundleID = stdOutput[kstdOutput][0] ?: kUnknownValue;
    
    NSString *appName = [self extractAppNameFromPlist:infoPlistPath];
    
    NSString *cacheDir = [NSString stringWithFormat:@"%@%@/", kIPARangerCacheDirPath, bundleID];
    [self createDirectoryIfNeeded:cacheDir];
    
    [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathMv arg1:infoPlistPath arg2:cacheDir arg3:nil];
    
    UIImage *appIcon = [self getAppIconFromIPAFile:ipaFilePath 
                                appNameInsidePayload:folderNameInsidePayload 
                                            tempDir:cacheDir];
    
    [fileManager removeItemAtPath:tempDir error:nil];
    
    IPARAppInfo *appInfo = [[IPARAppInfo alloc] init];
    appInfo.bundleID = bundleID;
    appInfo.appName = appName;
    appInfo.appIcon = appIcon;
    
    return appInfo;
}

- (NSString *)extractAppNameFromPlist:(NSString *)infoPlistPath {
    // Try to extract display name first
    NSDictionary *stdOutput = [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathPlutil arg1:kKeyForPlutil arg2:kKeyToExtractPlutilBundleName arg3:infoPlistPath];
    NSString *appName = stdOutput[kstdOutput][0];
    
    // If display name is empty, try bundle name
    if (!appName || [appName isEqualToString:@""]) {
        stdOutput = [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathPlutil arg1:kKeyForPlutil arg2:kCFBundleKeyPlist arg3:infoPlistPath];
        appName = stdOutput[kstdOutput][0];
    }
    
    return appName ?: kUnknownValue;
}

- (void)createDirectoryIfNeeded:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directoryPath]) {
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)getFolderNameInsidePayload:(NSString *)payloadPath {
    NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathLs arg1:[NSString stringWithFormat:@"%@", payloadPath] arg2:nil arg3:nil];
    return standardAndErrorOutputs[kstdOutput][0];
}

- (void)downloadButtonTapped:(id)sender {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        self.lastBundleDownload = textField.text;
        if (self.lastBundleDownload == nil || [self.lastBundleDownload stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"Bundle ID cannot be empty" hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
        }
        [self showDownloadDialog];
        self.currentPrecentageDownload = 0;
        [self.progressView setProgress:0.0f];
        NSString *commandToExecute = [NSString stringWithFormat:kDownloadCommandBundleOutputpathCountry, kIpatoolScriptPath, self.lastBundleDownload, kIPARangerDocumentsPath, kDownloadProgressFileOutput];
        NSDictionary *lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];
        // this means we had errors trying to run download..
        if ([lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }]; 
        } else {
            // download should start, remove the progress file if needed
            [[NSFileManager defaultManager] removeItemAtPath:kDownloadProgressFileOutput error:nil];
            [self startMonitoringDownloadProgress];
        }
    };

    AlertActionBlockWithTextField alertBlockTextfield = ^(UITextField *textField) {
        textField.placeholder = @"e.g com.facebook.Facebook";
    };

    [IPARUtils presentDialogWithTitle:kIPARangerDownloadPromptHeadline message:@"Enter App Bundle ID" hasTextfield:YES withTextfieldBlock:alertBlockTextfield
                    alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Download" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];

}

- (void)startMonitoringDownloadProgress {
    if (self.downloadTimer) {
        [self.downloadTimer invalidate];
        self.downloadTimer = nil;
    }
    
    self.downloadTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self
                                                        selector:@selector(checkDownloadProgress)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)checkDownloadProgress {
    NSString *fileContents = [NSString stringWithContentsOfFile:kDownloadProgressFileOutput encoding:NSUTF8StringEncoding error:nil];
    NSRange jsonStart = [fileContents rangeOfString:@"{"];
    if (jsonStart.location != NSNotFound) {
        NSString *jsonString = [fileContents substringFromIndex:jsonStart.location];

        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (!jsonError && [jsonDict isKindOfClass:[NSDictionary class]]) {
            NSString *level = jsonDict[kJsonLevel];
            BOOL success = [jsonDict[kJsonKeySuccess] boolValue];

            dispatch_async(dispatch_get_main_queue(), ^{
                if ([level isEqualToString:kJsonLevelError]) {
                    if ([jsonDict[kJsonLevelError] containsString:@"open zip"]) {
                        [self dismissViewControllerAnimated:YES completion:^{
                            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:[NSString stringWithFormat:@"App with same name already exists in %@", kIPARangerDocumentsPath] hasTextfield:NO withTextfieldBlock:nil 
                                alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                        }]; 
                    } else if ([jsonDict[kJsonLevelError] containsString:@"password token is expired"]) {
                        [self dismissViewControllerAnimated:YES completion:^{
                            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:jsonDict[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                                        alertConfirmationBlock:nil withConfirmText:nil alertCancelBlock:[self getAlertBlockForLogout] withCancelText:@"Logout" presentOn:self];
                        }]; 
                    } else {
                        [self dismissViewControllerAnimated:YES completion:^{
                            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:jsonDict[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil 
                                alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                        }]; 
                    }
                } else if ([level isEqualToString:@"info"] && success) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        AlertActionBlock alertBlockConfirm = ^(void) {
                            [self refreshTableData];
                        };
                        [IPARUtils presentDialogWithTitle:kIPARangerSuccessMessage message:@"The download finished successfully!" hasTextfield:NO withTextfieldBlock:nil
                                alertConfirmationBlock:nil withConfirmText:nil alertCancelBlock:alertBlockConfirm withCancelText:@"OK" presentOn:self];
                    }]; 
                }
            });

            [self.downloadTimer invalidate];
            self.downloadTimer = nil;
            return;
        }
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"downloading\\s+(\\d+)%" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, fileContents.length)];
    if (matches.count > 0) {
        NSTextCheckingResult *lastMatch = matches.lastObject;
        NSRange percentageRange = [lastMatch rangeAtIndex:1];
        NSString *percentage = [fileContents substringWithRange:percentageRange];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentPrecentageDownload = percentage;
            [self.progressView setProgress:[percentage floatValue] / 100];
        });
    }
}


#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.existingApps.count > 0) {
        self.noDataLabel.text = @" \n  ";
        return self.existingApps.count;
    }
    self.noDataLabel.text = @"Nothing to show here.\nStart by clicking the download icon!";
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IPARAppCell *cell = [tableView dequeueReusableCellWithIdentifier:kIPARCell];

    if (cell == nil) {
        cell = [[IPARAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIPARCell];
    }
    if (indexPath.row < self.existingApps.count) {
        UIView *selectionView = [UIView new];
        selectionView.backgroundColor = UIColor.clearColor;
        [[UITableViewCell appearance] setSelectedBackgroundView:selectionView];
        cell.backgroundColor = UIColor.clearColor;
        cell.appName.text = self.existingApps[indexPath.row][kAppnameIndex];
        cell.appFilename.text = self.existingApps[indexPath.row][kFilenameIndex];
        cell.appSize.text = [NSString stringWithFormat:@"%@", self.existingApps[indexPath.row][kSizeIndex]];
        cell.appImage.image = self.existingApps[indexPath.row][kAppimageIndex];
    }

    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
   [IPARUtils animateClickOnCell:cell];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    // Create actions
    UIAlertAction *openInFilzaAction = [UIAlertAction actionWithTitle:@"Open in Filza" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       [self openInFilza:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, self.existingApps[indexPath.row][kFilenameIndex]]];
    }];
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareFile:self.existingApps[indexPath.row][kFilenameIndex]];

    }];
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self renameFileAtPath:self.existingApps[indexPath.row][kFilenameIndex]];

    }];
    UIAlertAction *installApplicationAction = [UIAlertAction actionWithTitle:@"Install Application" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self installApplication:self.existingApps[indexPath.row][kFilenameIndex] appName:self.existingApps[indexPath.row][kAppnameIndex]];
    }];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteFile:self.existingApps[indexPath.row][kFilenameIndex] index:indexPath];
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)installApplication:(NSString *)ipaFilePath appName:(NSString *)appName {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        __block NSDictionary *standardAndErrorOutputs = [NSDictionary dictionary];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:kIPARangerInstallationHeadline
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
                            [IPARUtils presentDialogWithTitle:kIPARangerSuccessMessage message:[NSString stringWithFormat:@"Successfully installed '%@'!", appName] hasTextfield:NO withTextfieldBlock:nil
                                alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                        }];
                        return;
                    });
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:[NSString stringWithFormat:@"Error occurred while trying to install '%@'", appName] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                }];
            });
        });
    };

    NSString *confirmation = [NSString stringWithFormat:@"You are about to install App: %@\n\nAre you sure?", appName];
    [IPARUtils presentDialogWithTitle:@"IPARanger\nInstall Application" message:confirmation hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Yes, Continue" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
}

- (void)extractInfoPlistFromIPA:(NSString *)ipaFilePath toFolder:(NSString*)tempDir {
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:kInfoFile];
}

- (UIImage *)getAppIconFromIPAFile:(NSString *)ipaFilePath appNameInsidePayload:(NSString *)appName tempDir:(NSString *)tempDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *infoPlistPath = [tempDir stringByAppendingPathComponent:kInfoFile];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *iconFileName = kIconFile;
    if (infoPlist[kCFBundleIconsKeyPlist]){
      iconFileName = infoPlist[kCFBundleIconsKeyPlist][kCFBundlePrimaryIconKeyPlist][kCFBundleIconFilesKeyPlist][0];
    }else if (infoPlist[kCFBundleIconFilesKeyPlist]){
      iconFileName = infoPlist[kCFBundleIconFilesKeyPlist][0];
    }

    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@%@@2x.png", tempDir, iconFileName]] == NO) {
        [IPARUtils setupUnzipTask:ipaFilePath directoryPath:tempDir file:[NSString stringWithFormat:@"%@@2x.png", iconFileName]];
        NSString *moveFromDir = [NSString stringWithFormat:@"%@/Payload/%@/%@@2x.png", tempDir, appName, iconFileName];
        [IPARUtils setupTaskAndPipesWithCommandposix:kLaunchPathMv arg1:moveFromDir arg2:tempDir arg3:nil];
    }

    NSString *iconFilePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", iconFileName]];
    NSData *iconData = [NSData dataWithContentsOfFile:iconFilePath];
    UIImage *iconImage = [UIImage imageWithData:iconData];
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/Payload", tempDir] error:nil];

    return iconImage;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self deleteFile:self.existingApps[indexPath.row][kFilenameIndex] index:indexPath];
    }];

    UIImage *shareImage = [UIImage systemImageNamed:kShareSystemImage];
    UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {        // Share the file using a UIActivityViewController
        [self shareFile:self.existingApps[indexPath.row][kFilenameIndex]];
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

    NSString *confirmation = [NSString stringWithFormat:@"You are about to delete file: %@\n\nAre you sure?", self.existingApps[indexPath.row][kFilenameIndex]];
    [IPARUtils presentDialogWithTitle:kIPARangerDeleteFileHeadline message:confirmation hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"YES" alertCancelBlock:alertBlockCancel withCancelText:@"Cancel" presentOn:self];
}

- (void)shareFile:(NSString *)pathToFile {
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, pathToFile]];
    NSArray *activityItems = @[fileURL];

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityVC];
        [popoverController presentPopoverFromRect:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/4, 0, 0) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

- (void)openInFilza:(NSString *)pathToFile {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kFilzaScheme, pathToFile]];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

- (void)renameFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [NSString stringWithFormat:@"%@%@", kIPARangerDocumentsPath, path];
    NSString *currentFileName = [fullPath lastPathComponent];
    NSString *currentDirectoryPath = [fullPath stringByDeletingLastPathComponent];

    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSString *newFileName = textField.text;
        //change filename only if different from old one
        if ([newFileName isEqualToString:currentFileName] == NO) {
            AlertActionBlockWithTextField alertBlockWarningConfirm = ^(UITextField *textField) {
                NSString *newFilePath = [currentDirectoryPath stringByAppendingPathComponent:newFileName];
                NSError *error = nil;
                BOOL success = [fileManager moveItemAtPath:fullPath toPath:newFilePath error:&error];
                if (success) {
                    [self refreshTableData];
                } else {
                    NSLog(@"Error renaming file: %@", error);
                    [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"There was an error trying to rename your file\nCheck your filename and try again" hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
                }
            };

            if ([newFileName hasSuffix:@".ipa"] == NO) {
                [IPARUtils presentDialogWithTitle:kIPARangerWarningHeadline message:@"Your IPA file does not end with '.ipa' extension.\nDo you wish to continue?" hasTextfield:NO withTextfieldBlock:nil
                    alertConfirmationBlock:alertBlockWarningConfirm withConfirmText:@"Yes" alertCancelBlock:nil withCancelText:@"No" presentOn:self];
            } else {
                alertBlockWarningConfirm(nil);
            }
        }
    };

    AlertTextFieldBlock alertBlockTextfield = ^(UITextField *textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.text = currentFileName;
    };

    [IPARUtils presentDialogWithTitle:[NSString stringWithFormat:@"%@\n\nDont forget to add '.ipa' at the end of your file", kIPARangerRenameFileHeadline] message:nil hasTextfield:YES withTextfieldBlock:alertBlockTextfield
                alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Rename" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
}

- (void)showDownloadDialog {
    self.downloadAlertController.title = kIPARangerDownloadingMessage;
    self.downloadAlertController.message = [NSString stringWithFormat:@"Downloading requested bundle: %@\n\n", self.lastBundleDownload];
    self.progressView.frame = CGRectMake(15, 120, 230, 5);
    [self.downloadAlertController.view addSubview:self.progressView];
    [self presentViewController:self.downloadAlertController animated:YES completion:nil];
}

- (void)updateProgressBar {
    [self.progressView setProgress:[self.currentPrecentageDownload floatValue]/100];
}
@end
