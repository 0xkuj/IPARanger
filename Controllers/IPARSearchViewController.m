#import "IPARSearchViewController.h"
#import "IPARCountryTableViewController_deprecated.h"
#import "../Utils/IPARUtils.h"
#import "../Cells/IPARAppCell.h"
#import "../Extensions/IPARConstants.h"

@interface IPARSearchViewController ()
@property (nonatomic) UIButton *searchButton;
@property (nonatomic) NSMutableArray *searchResults;
@property (nonatomic) NSMutableArray *linesStandardOutput;
@property (nonatomic) NSMutableArray *linesErrorOutput;
@property (nonatomic) NSDictionary *lastCommandResult;
@property (nonatomic) UILabel *noDataLabel;
@property (nonatomic) NSString *latestSearchTerm;
@property (nonatomic) NSInteger limitSearch;
@property (nonatomic, strong) IPARCountryTableViewController *countryTableViewController;
@property (nonatomic) UIBarButtonItem *countryButton;
@property (nonatomic) NSString *lastCountrySelected;
@end

@implementation IPARSearchViewController
- (instancetype)init {
    self = [super init];
    if (self) {
       	self.title = kSearchTitle;
		self.tabBarItem.image = [UIImage systemImageNamed:kTabbarSearchingSectionSystemImage];
		self.tabBarItem.title = kSearchTitle;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    _searchResults = [NSMutableArray array];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    _lastCommandResult = [NSDictionary dictionary];
    _latestSearchTerm = [NSString string];
    _limitSearch = APPS_SEARCH_INITIAL_LIMIT;
    [self setupTableviewProps];
    [self setupNoDataLabel];
    //[self setupCountryButton];
    [self _setUpNavigationBar];
}

- (void)setupTableviewProps {
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 80;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)setupNoDataLabel {
    self.noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    self.noDataLabel.numberOfLines = 2;
    self.noDataLabel.textColor = [UIColor grayColor];
    self.noDataLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = self.noDataLabel;
}

- (void)setupCountryButton {
    self.lastCountrySelected = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.countryButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Search in Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(countryButtonItemTapped:)];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];   
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal];                                                   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
    self.navigationItem.leftBarButtonItem = self.countryButton;
    self.countryTableViewController = [[IPARCountryTableViewController alloc] initWithCaller:kSearchTitle];
}

- (void)countryButtonItemTapped:(id)sender {
    [self presentViewController:self.countryTableViewController animated:YES completion:nil];
}

- (void)updateCountry {
    self.lastCountrySelected = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.countryButton.title = [NSString stringWithFormat:@"Search in Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateHighlighted];  
    [self.countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

- (void)_setUpNavigationBar
{
    UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:kTabbarSearchingSectionSystemImage] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[lookupButton];
}

- (void)searchButtonTapped:(id)sender {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        if ([textField.text isEqualToString:self.latestSearchTerm] == NO) {
            self.latestSearchTerm = textField.text;
            self.limitSearch = APPS_SEARCH_INITIAL_LIMIT;
        }
        
        if (self.latestSearchTerm == nil || [self.latestSearchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"App Name cannot be empty" hasTextfield:NO withTextfieldBlock:nil
             alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            return;
        }    
        [self runSearchCommand]; 
    };

    AlertTextFieldBlock textFieldBlock = ^(UITextField *textField) {
        textField.placeholder = @"e.g - Netflix";
    };

    [IPARUtils presentDialogWithTitle:kIPARangerSearchPromptHeadline message:@"Enter App Name" hasTextfield:YES withTextfieldBlock:textFieldBlock alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Search" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
}

- (void)runSearchCommand {
    UIAlertController *alert;
    if (self.limitSearch > APPS_SEARCH_INITIAL_LIMIT) {
        alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Fetching more results for '%@' from the Appstore", self.latestSearchTerm]
                                                                message:@"\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    } else {
        alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Searching for '%@' in the Appstore", self.latestSearchTerm]
                                                                message:@"\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    }

    [alert.view addSubview:[IPARUtils createActivitiyIndicatorWithPoint:CGPointMake(130.5, 110)]];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandToExecute = [NSString stringWithFormat:kSearchCommandPathTermLimitCountry, kIpatoolScriptPath, self.latestSearchTerm, self.limitSearch];
        self.lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil];
        if ([self.lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:self.lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }]; 
        } else if ([self.lastCommandResult[@"count"] intValue] == 0) {
           [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:[NSString stringWithFormat:@"Nothing was found when searching for %@", self.latestSearchTerm] hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:nil withConfirmText:@"OK" alertCancelBlock:nil withCancelText:nil presentOn:self];
            }]; 
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
                [self populateTableWithSearchResults];
            });
        }
    });
}

- (void)populateTableWithSearchResults {
    [self.searchResults removeAllObjects];
    for (NSDictionary *dictForApp in self.lastCommandResult[@"apps"]) {
        NSMutableDictionary *appResultDict = [NSMutableDictionary dictionary];
        appResultDict = [dictForApp mutableCopy];
        [IPARUtils getAppIconFromApple:dictForApp[kAppBundleIndex] completion:^(UIImage * _Nullable appIcon) {
            if (appIcon) {
                appResultDict[kAppimageIndex] = appIcon;
            } else {
                appResultDict[kAppimageIndex] = [UIImage systemImageNamed:kUnknownSystemImage];
            }
            [self.searchResults addObject:appResultDict];
            [self.tableView reloadData];
        }];
    }        
    
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchResults.count > 0) {
        //fixing scrolling issue!!
        self.noDataLabel.text = @" \n  ";
        //adding one for show more button
        return self.searchResults.count+1;
    }
    self.noDataLabel.text = @"Nothing to show here.\nStart by clicking the search icon!";
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // this means we have valid search results i guess
    if (indexPath.row < [self.searchResults count]) {
        return [self createSearchTableCellIfNotReused:indexPath];
    } else {
        return [self createShowMoreLastCell:indexPath];
    }
}

- (UITableViewCell *)createSearchTableCellIfNotReused:(NSIndexPath *)indexPath {
    IPARAppCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kIPARCell];
    if (cell == nil) {
        cell = [[IPARAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIPARCell];
    }
    UIView *selectionView = [UIView new];
    selectionView.backgroundColor = UIColor.clearColor;
    [[UITableViewCell appearance] setSelectedBackgroundView:selectionView];
    cell.backgroundColor = UIColor.clearColor;
    //still crashing.. need to figure out why!
    cell.appName.text = self.searchResults[indexPath.row][kAppnameIndex];
    cell.appBundle.text = self.searchResults[indexPath.row][kAppBundleIndex];
    cell.appVersion.text = self.searchResults[indexPath.row][kAppVersionIndex];
    cell.appImage.image = self.searchResults[indexPath.row][kAppimageIndex];
    return cell;
}

- (UITableViewCell *)createShowMoreLastCell:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    cell.textLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
    cell.textLabel.text = kShowMoreButtonText;
    // Set Auto Layout constraints to center the text label in the cell
    cell.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    return cell;
}

#pragma mark - Table View Delegate
// copy the bundle upon cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [IPARUtils animateClickOnCell:cell];
    if (indexPath.row < [self.searchResults count]) {
        AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.searchResults[indexPath.row][kAppBundleIndex];
        };
        NSString *appSelected = [NSString stringWithFormat:@"App Selected %@",self.searchResults[indexPath.row][kAppnameIndex]];
        NSString *bundleSelected = [NSString stringWithFormat:@"Bundle ID: %@", self.searchResults[indexPath.row][kAppBundleIndex]];
        [IPARUtils presentDialogWithTitle:kIPARangerCopyHeadline message:[NSString stringWithFormat:@"%@\n\n%@", appSelected, bundleSelected]
         hasTextfield:NO withTextfieldBlock:nil alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Copy Bundle" alertCancelBlock:nil withCancelText:@"Cancel" presentOn:self];
    } else {
        self.limitSearch += APPS_SEARCH_INITIAL_LIMIT;
        [self runSearchCommand];
    }
}
@end