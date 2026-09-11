#import "IPARVersionPickerViewController.h"
#import "../Views/IPARDialog.h"

@interface IPARVersionPickerViewController () <UISearchResultsUpdating>
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, strong) NSArray *versions;         // full history, newest first
@property (nonatomic, strong) NSArray *filteredVersions; // current search result
@property (nonatomic, copy) IPARVersionPickerCompletion completion;
@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation IPARVersionPickerViewController

- (instancetype)initWithAppName:(NSString *)appName
                       versions:(NSArray *)versions
                     completion:(IPARVersionPickerCompletion)completion {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _appName = [appName copy];
        _versions = versions ?: @[];
        _filteredVersions = _versions;
        _completion = [completion copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select Version";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self action:@selector(cancelTapped)];
    if (self.navigationController) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search versions";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isSearching {
    return self.searchController.isActive &&
           self.searchController.searchBar.text.length > 0;
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = [searchController.searchBar.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (query.length == 0) {
        self.filteredVersions = self.versions;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *version, NSDictionary *bindings) {
            NSString *v = [NSString stringWithFormat:@"%@", version[@"bundle_version"] ?: @""];
            return [v localizedCaseInsensitiveContainsString:query];
        }];
        self.filteredVersions = [self.versions filteredArrayUsingPredicate:predicate];
    }
    [self.tableView reloadData];
}

#pragma mark - Table data

// Section 0: "Latest version" (hidden while searching). Section 1: the history.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self isSearching] ? 1 : 2;
}

- (BOOL)isVersionSection:(NSInteger)section {
    return [self isSearching] ? section == 0 : section == 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isVersionSection:section]) {
        return self.filteredVersions.count;
    }
    return 1; // Latest
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isVersionSection:section]) {
        NSUInteger count = self.filteredVersions.count;
        return [NSString stringWithFormat:@"%lu version%@ available",
                (unsigned long)count, count == 1 ? @"" : @"s"];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseID = @"VersionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (![self isVersionSection:indexPath.section]) {
        cell.textLabel.text = @"Latest version";
        cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        cell.textLabel.textColor = [IPARDialog accentColor];
        cell.detailTextLabel.text = @"The current App Store release";
        cell.imageView.image = [UIImage systemImageNamed:@"arrow.down.circle.fill"];
        cell.imageView.tintColor = [IPARDialog accentColor];
        return cell;
    }

    NSDictionary *version = self.filteredVersions[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", version[@"bundle_version"] ?: @"Unknown version"];
    cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    cell.textLabel.textColor = [UIColor labelColor];
    cell.detailTextLabel.text = [self detailForVersion:version];
    cell.imageView.image = nil;
    return cell;
}

- (NSString *)detailForVersion:(NSDictionary *)version {
    NSMutableArray *parts = [NSMutableArray array];
    NSString *createdAt = [NSString stringWithFormat:@"%@", version[@"created_at"] ?: @""];
    if (createdAt.length >= 10) {
        [parts addObject:[createdAt substringToIndex:10]]; // YYYY-MM-DD
    }
    NSString *externalID = [NSString stringWithFormat:@"%@", version[@"external_identifier"] ?: @""];
    if (externalID.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"ID %@", externalID]];
    }
    return [parts componentsJoinedByString:@"  ·  "];
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *externalVersionID = @"";
    if ([self isVersionSection:indexPath.section]) {
        NSDictionary *version = self.filteredVersions[indexPath.row];
        externalVersionID = [NSString stringWithFormat:@"%@", version[@"external_identifier"] ?: @""];
    }
    // "Latest version" keeps externalVersionID empty -> plain download of the
    // current App Store release (the standard path).

    IPARVersionPickerCompletion completion = self.completion;
    [self dismissViewControllerAnimated:YES completion:^{
        if (completion) {
            completion(externalVersionID);
        }
    }];
}

@end
