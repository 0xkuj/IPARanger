#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARCountryTableViewController.h"
#import "IPARUtils.h"
#import "IPARAppCell.h"

#define APPS_SEARCH_INITIAL_LIMIT 12

@interface IPARSearchViewController ()
@property (nonatomic) UIButton *searchButton;
@property (nonatomic) NSMutableArray *searchResults;
@property (nonatomic) NSMutableArray *linesStandardOutput;
@property (nonatomic) NSMutableArray *linesErrorOutput;
@property (nonatomic) UILabel *noDataLabel;
@property (nonatomic) NSString *latestSearchTerm;
@property (nonatomic) NSInteger limitSearch;
@property (nonatomic, strong) IPARCountryTableViewController *countryTableViewController;
@property (nonatomic) UIBarButtonItem *countryButton;
@property (nonatomic) NSString *lastCountrySelected;
@end

@implementation IPARSearchViewController

//figure out best solution for countries. maybe in the menu, maybe in settings of account. its ugly af
- (void)loadView {
    [super loadView];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.rowHeight = 80;
    self.tableView.estimatedRowHeight = 100;
    // Create a label with the text you want to display
    _noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    _noDataLabel.numberOfLines = 2;
    _limitSearch = APPS_SEARCH_INITIAL_LIMIT;
    _noDataLabel.textColor = [UIColor grayColor];
    _noDataLabel.textAlignment = NSTextAlignmentCenter;

    // Set the label as the background view of the table view
    self.tableView.backgroundView = _noDataLabel;

    _searchResults = [NSMutableArray array];
    _linesStandardOutput = [NSMutableArray array];
    _linesErrorOutput = [NSMutableArray array];
    _latestSearchTerm = [NSString string];
    self.countryTableViewController = [[IPARCountryTableViewController alloc] initWithCaller:@"Search"];
    _lastCountrySelected = [NSString string];
    _lastCountrySelected = [IPARUtils getMostUpdatedSearchCountryFromFile] ? [IPARUtils getMostUpdatedSearchCountryFromFile] : @"US";
    _countryButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Search Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(countryButtonItemTapped:)];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    [_countryButton setTitleTextAttributes:attributes forState:UIControlStateNormal];                                                     
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
    self.navigationItem.leftBarButtonItem = _countryButton;
    [self _setUpNavigationBar];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
}

- (void)countryButtonItemTapped:(id)sender {
    [self presentViewController:self.countryTableViewController animated:YES completion:nil];
}

- (void)updateCountry {
    self.lastCountrySelected = [IPARUtils getMostUpdatedSearchCountryFromFile];
    self.countryButton.title = [NSString stringWithFormat:@"Search Appstore: %@", [IPARUtils emojiFlagForISOCountryCode:_lastCountrySelected]];
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
            [self logoutAction];
        }
	}];

    //if (@available(iOS 14, *)) {
        // UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.right"] style:UIBarButtonItemStylePlain target:self action:@selector(logoutAction)];
        // UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
        // self.navigationItem.rightBarButtonItems = @[logoutButton, lookupButton];
    //}
    UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *lookupButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[optionsButton, lookupButton];
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

- (void)searchButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Search" message:@"Enter App Name" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        if ([textField.text isEqualToString:self.latestSearchTerm] == NO) {
            self.latestSearchTerm = textField.text;
            self.limitSearch = APPS_SEARCH_INITIAL_LIMIT;
        }
        
        if (self.latestSearchTerm == nil || [self.latestSearchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"App Name cannot be empty" numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            return;
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
    UIAlertController *alert;
    if (self.limitSearch > APPS_SEARCH_INITIAL_LIMIT) {
        alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Fetching more results for '%@' from the Appstore", self.latestSearchTerm]
                                                                message:@"\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    } else {
        alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Searching for '%@' in the Appstore", self.latestSearchTerm]
                                                                message:[NSString stringWithFormat:@"Country Selected: %@\n\n\n\n", [IPARUtils emojiFlagForISOCountryCode:self.lastCountrySelected]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    }

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = CGPointMake(130.5, 125);
    spinner.color = [UIColor whiteColor];
    [spinner startAnimating];
    [alert.view addSubview:spinner];
    [self presentViewController:alert animated:YES completion:nil];

    // Dispatch the command to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandToExecute = [NSString stringWithFormat:@"/Applications/IPARanger.app/ipatool/ipatool search '%@' --limit %ld -c %@", self.latestSearchTerm, self.limitSearch, self.lastCountrySelected];
        NSDictionary *standardAndErrorOutputs = [IPARUtils setupTaskAndPipesWithCommand:commandToExecute];
        self.linesStandardOutput = standardAndErrorOutputs[@"standardOutput"];
        self.linesErrorOutput = standardAndErrorOutputs[@"errorOutput"];
    
        // Remove the loading animation
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self isErrorExists] == NO) {
            // Once the command is finished, update the UI on the main queue
                [self populateTableWithSearchResults];
            
        }
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
            [self dismissViewControllerAnimated:YES completion:^{
                [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:errorToShow numberOfActions:1 buttonText:@"OK" alertBlock:nil presentOn:self];
            }];
            return YES;
        } 
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
}
//try to think of a better algo to show search phrases..
- (void)populateTableWithSearchResults {
    [self.searchResults removeAllObjects];           
    for (NSString *obj in self.linesStandardOutput) {
        NSLog(@"omriku line output :%@", obj);
        if (![obj containsString:@"==>"] && obj.length > 0 /*&& [obj.lowercaseString containsString:self.latestSearchTerm]*/) {
            [self.searchResults addObject:obj];
        } 
    }

    [self parseSearchResults];
    [self.tableView reloadData];
}

- (void)parseSearchResults {
    NSArray *parsedAppBundle = [NSArray array];
    NSArray *parsedAppName = [NSArray array];
    NSArray *parsedAppVersion = [NSArray array];
    parsedAppBundle = [self stambundle:self.searchResults];
    parsedAppName = [self stamapps:self.searchResults];
    parsedAppVersion = [self stamversion:self.searchResults];

    for (int i=0; i<[[self.searchResults copy] count]; i++) {
        if (i < [parsedAppName count] && i < [parsedAppVersion count] && i < [parsedAppBundle count]) {
            NSMutableDictionary *dictForApp = [NSMutableDictionary dictionary];
            dictForApp[@"appName"] = parsedAppName[i];
            dictForApp[@"appBundle"] = parsedAppBundle[i];
            dictForApp[@"appVersion"] = parsedAppVersion[i];
            dictForApp[@"appImage"] = [self getAppIconFromApple:parsedAppBundle[i]];
            self.searchResults[i] = dictForApp;
        }
    }
}

- (UIImage *)getAppIconFromApple:(NSString *)bundleId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/lookup?bundleId=%@", bundleId]];
    NSData *data = [NSData dataWithContentsOfURL:url];

    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSArray *results = json[@"results"];
        
        if (results.count > 0) {
            NSDictionary *appInfo = results[0];
            NSString *iconUrlString = appInfo[@"artworkUrl100"];
            NSURL *iconUrl = [NSURL URLWithString:iconUrlString];
            NSData *iconData = [NSData dataWithContentsOfURL:iconUrl];
            UIImage *iconImage = [UIImage imageWithData:iconData];
            NSLog(@"omriku returning image: %@ for bundle: %@", iconImage, bundleId);
            return iconImage;
            // Use the icon image in your list
        }
    }
    NSLog(@"omriku returns nil FOR BUNDLE: %@", bundleId);
    return nil;
}
//bundle - works well! need to see if that is hitting performace. dont really care for 1-2 more seconds!
- (NSArray *)stambundle:(NSArray *)strings {
    NSError *error = nil;
    NSMutableArray *retval = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@":\\s*(\\S+)\\s*\\(" options:0 error:&error];

    for (NSString *string in strings) {
        NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
        if (match) {
            NSRange range = [match rangeAtIndex:1];
            [retval addObject:[string substringWithRange:range]];
            //NSString *bundleIdentifier = [string substringWithRange:range];
            //NSLog(@"omriku bundle: %@", bundleIdentifier);
        }
    }
    return retval;
}

//appname - works well! need to see if that is hitting performace. dont really care for 1-2 more seconds!
- (NSArray *)stamapps:(NSArray *)strings {
    NSError *error = nil;
    NSMutableArray *retval = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+\\.\\s*([^:-]+)" options:0 error:&error];

    for (NSString *string in strings) {
        NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
        if (match) {
            NSRange range = [match rangeAtIndex:1];
            [retval addObject:[string substringWithRange:range]];
            //NSString *bundleIdentifier = [string substringWithRange:range];
            //NSLog(@"omriku appname: %@", bundleIdentifier);
        }
    }
    return retval;
}

- (NSArray *)stamversion:(NSArray *)strings {
    NSString *pattern = @"\\((.*?)\\)[^\\(]*$";
    NSMutableArray *retval = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];

    for (NSString *string in strings) {
        NSRange range = [regex rangeOfFirstMatchInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length])];
        if (range.location != NSNotFound) {
            NSString *version = [string substringWithRange:range];
            //remove parenthesis..
            [retval addObject:[version substringWithRange:NSMakeRange(1, [version length] - 3)]];
            //NSLog(@"omriku Version for %@ is %@", string, [version substringWithRange:NSMakeRange(1, [version length] - 3)]);
        }
    }
    return retval;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"omriku counting rows.. %lu",self.searchResults.count);
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


	// static NSString *CellIdentifier = @"Cell";
	// UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	// if (!cell) {
	// 	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	// }
    // cell.textLabel.text = self.searchResults[indexPath.row];
    NSLog(@"omriku cell: %lu", indexPath.row);
    if (indexPath.row < [self.searchResults count]) {
        IPARAppCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IPARAppCell"];
        
        if (cell == nil) {
            cell = [[IPARAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IPARAppCell"];
        }
        UIView *selectionView = [UIView new];
        selectionView.backgroundColor = UIColor.clearColor;
        [[UITableViewCell appearance] setSelectedBackgroundView:selectionView];
        cell.backgroundColor = UIColor.clearColor;
        //still crashing.. need to figure out why!
        cell.appName.text = self.searchResults[indexPath.row][@"appName"];
        cell.appBundle.text = self.searchResults[indexPath.row][@"appBundle"];
        cell.appVersion.text = self.searchResults[indexPath.row][@"appVersion"];
        cell.appImage.image = self.searchResults[indexPath.row][@"appImage"];
        return cell;
    } else {
        static NSString *CellIdentifier = @"Cell";
	    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	    if (!cell) {
		    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	    }

       cell.textLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
       cell.textLabel.text = @"Show More Results";
        // Set Auto Layout constraints to center the text label in the cell
       cell.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
       [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
       [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        return cell;
    }
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//[tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < [self.searchResults count]) {
        AlertActionBlock alertBlock = ^(void) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.searchResults[indexPath.row][@"appBundle"];
        };

        [IPARUtils presentMessageWithTitle:@"IPARanger\nCopy Bundle" message:[NSString stringWithFormat:@"App selected: %@\n\nBundle ID: %@",self.searchResults[indexPath.row][@"appName"], self.searchResults[indexPath.row][@"appBundle"]] numberOfActions:2 buttonText:@"Copy Bundle" alertBlock:alertBlock presentOn:self];
    } else {
        self.limitSearch += APPS_SEARCH_INITIAL_LIMIT;
        [self runSearchCommand];
        NSLog(@"omriku show more!");
    }
}
@end