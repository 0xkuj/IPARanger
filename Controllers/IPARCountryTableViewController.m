#import "IPARCountryTableViewController.h"
#import "../Utils/IPARUtils.h"
#import "../Extensions/IPARConstants.h"

@interface IPARCountryTableViewController ()
@property (nonatomic) NSArray *sortedCountries;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) NSArray *filteredCountries;
@property (nonatomic) NSMutableDictionary* codesKeysEmojisValues;
@property (nonatomic) NSString* viewControllerCaller;
@property (nonatomic) NSLocale *USLocale;
@end

@implementation IPARCountryTableViewController
- (instancetype)initWithCaller:(NSString *)caller {
    self = [super init];
    if (self) {
        // we need this to avoid different locales as countries are different in parsing
        _USLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        _viewControllerCaller = [NSString string];
        _viewControllerCaller = caller;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _codesKeysEmojisValues = [NSMutableDictionary dictionary];

    NSMutableArray *countries = [NSMutableArray arrayWithCapacity:[[NSLocale ISOCountryCodes] count]];
    for (NSString *countryCode in  [NSLocale ISOCountryCodes])
    {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode forKey:NSLocaleCountryCode]];
        NSString *country = [self.USLocale displayNameForKey:NSLocaleIdentifier value:identifier];
        //stupid country unknown flag fuck cocos
        if ([country containsString:@"Cocos"]) {
            continue;
        }
        [countries addObject:country];
        _codesKeysEmojisValues[countryCode] = [IPARUtils emojiFlagForISOCountryCode:countryCode];
    }

    _sortedCountries = [countries sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    _filteredCountries = _sortedCountries;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Select The Country Of Your Account";
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (NSString *)localeForFullCountryName:(NSString *)fullCountryName {
    NSString *locales = @"";
    for (NSString *localeCode in [NSLocale ISOCountryCodes]) {
        NSString *countryName = [self.USLocale displayNameForKey:NSLocaleCountryCode value:localeCode];
        if ([[fullCountryName lowercaseString] isEqualToString:[countryName lowercaseString]]) {
            return localeCode;
        }
    }
    return locales;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    if (searchText.length == 0) {
        self.filteredCountries = self.sortedCountries;
    } else {
        self.filteredCountries = [self.sortedCountries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText]];
    }
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredCountries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CountryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSString *countryCode = [self localeForFullCountryName:self.filteredCountries[indexPath.row]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@ [%@]", self.codesKeysEmojisValues[countryCode], self.filteredCountries[indexPath.row], countryCode];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     NSString *countryCode = [self localeForFullCountryName:self.filteredCountries[indexPath.row]];
     if ([self.viewControllerCaller isEqualToString:@"Downloader"]) {
        [IPARUtils saveKeyToFile:kCountryDownloadKeyFromFile withValue:countryCode];
     } else if ([self.viewControllerCaller isEqualToString:@"Search"]) {
        [IPARUtils saveKeyToFile:kCountrySearchKeyFromFile withValue:countryCode];
     }
    
     self.searchController.searchBar.text = nil;
     //wtf is this shit? one is releasing the search the other the table?!?!
	 [self dismissViewControllerAnimated:YES completion:nil];
     [self dismissViewControllerAnimated:YES completion:nil];
}
@end