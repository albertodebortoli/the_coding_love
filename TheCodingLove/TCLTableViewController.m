//
//  TCLTableViewController.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 30/12/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewController.h"

#import "TCLTableViewCellContentView.h"
#import "TCLEntry.h"

#import "AFNetworkReachabilityManager.h"
#import "TFHpple.h"
#import "UIImage+animatedGIF.h"

static NSString *const kTCLBaseURL = @"http://www.thecodinglove.com";

static NSString *const kTCLInternetConnectivityMissingErrorKey = @"TCLInternetConnectivityMissingErrorKey";
static NSString *const kTCLMissingNodeErrorKey = @"TCLMissingNodeErrorKey";

static NSInteger const kTCLInternetConnectivityMissingErrorCode = -1000;
static NSInteger const kTCLMissingNodeErrorCode = -1001;

@interface TCLTableViewController ()

@property (nonatomic, strong) NSMutableArray *entries;
@property (nonatomic, assign) NSUInteger counter;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation TCLTableViewController
{
    dispatch_queue_t _htmlFetcherWorkingQueue;
    dispatch_queue_t _dataFetcherWorkingQueue;
    dispatch_semaphore_t _semaphore;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"the_coding_love();", @"the_coding_love();");
    
    _htmlFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.html", NULL);
    _dataFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.data", NULL);
    _semaphore = dispatch_semaphore_create(1);
    
    self.entries = [NSMutableArray array];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    self.counter = 0;
    
    [self _loadNextPage];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[call] heightForRowAtIndexPath (%@)", indexPath);
    
    TCLEntry *entry = self.entries[indexPath.row];
    
    if (entry.size.height == 0 && entry.size.width == 0) {
        NSLog(@"[call] heightForRowAtIndexPath (calculating height...)");
        UIImage *image = [UIImage imageWithData:entry.data];
        entry.size = image.size;
    }
    else {
        NSLog(@"[call] heightForRowAtIndexPath (height previously cached...)");
    }
    
    // example: 100x20
    // resized: 100 : 20 = 320 : x
    // x = (320 * 20) / 100 = 64
    
    CGFloat x = (320.0 * entry.size.height) / entry.size.width;
    x += kTCLTableViewCellContentViewImagePadding;
    NSLog(@"[call] heightForRowAtIndexPath (height is %f)", x);
    
    return x;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.entries count] - 1) {
        [self _loadNextPage];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[call] cellForRow (%@)", indexPath);

    static NSString *cellReuseId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
    TCLTableViewCellContentView *customContentView = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseId];
        customContentView = [[NSBundle mainBundle] loadNibNamed:@"TCLTableViewCellContentView" owner:self options:nil][0];
        [cell.contentView addSubview:customContentView];
    }
    else {
        customContentView = cell.contentView.subviews[0];
    }
    
    TCLEntry *entry = self.entries[indexPath.row];
    
    dispatch_queue_t bkg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkg_queue, ^{
        UIImage *img = [UIImage animatedImageWithAnimatedGIFData:entry.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [customContentView setTitle:entry.title image:img];
        });
    });
    
    return cell;
}

#pragma mark - Actions

- (IBAction)loadMore:(id)sender
{
    [self _loadNextPage];
}

#pragma mark - Private Methods

- (void)_fetchInfoForPageAtIndex:(NSUInteger)index completion:(void (^)(NSArray *entries))completion failure:(void (^)(NSError *error))failure
{
    if ([self _checkReachability] == NO) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:kTCLInternetConnectivityMissingErrorKey
                                                 code:kTCLInternetConnectivityMissingErrorCode
                                             userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        return;
    }
    
    // 1. create the url and retrieve the data
    NSLog(@"[tcl] fetching HTML page (%i)", index);
    NSString *urlString = [NSString stringWithFormat:@"%@/page/%i", kTCLBaseURL, index];
    NSURL *tutorialsUrl = [NSURL URLWithString:urlString];
    NSData *htmlData = [NSData dataWithContentsOfURL:tutorialsUrl];
    NSLog(@"[tcl] fetched HTML page (%i)", index);

    // 2. create the parser and search using a XPath query
    TFHpple *tutorialsParser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *xpathQueryString1 = @"//div[@class='post']/h3/a";
    NSString *xpathQueryString2 = @"//div[@class='post']/div/p[@class='c1']/img";
    NSArray *nodes1 = [tutorialsParser searchWithXPathQuery:xpathQueryString1];
    NSArray *nodes2 = [tutorialsParser searchWithXPathQuery:xpathQueryString2];
    if ([nodes1 count] == 0 || [nodes2 count] == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:kTCLMissingNodeErrorKey
                                                 code:kTCLMissingNodeErrorCode
                                             userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        return;
    }
    
    // 3. create TCLEntry for each result
    NSMutableArray *entries = [NSMutableArray array];
    
    for (int i = 0; i < MIN([nodes1 count], [nodes2 count]); i++) {
        TCLEntry *entry = [[TCLEntry alloc] init];
        entry.title = [((TFHppleElement *)nodes1[i]) text];
        entry.url = ((TFHppleElement *)nodes2[i]).attributes[@"src"];
        
        [entries addObject:entry];
    }
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entries);
        });
    }
}

- (void)_fetchDataForEntry:(TCLEntry *)entry completion:(void (^)(TCLEntry *populatedEntry))completion failure:(void (^)(NSError *error))failure
{
    if ([self _checkReachability] == NO) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:kTCLInternetConnectivityMissingErrorKey
                                                 code:kTCLInternetConnectivityMissingErrorCode
                                             userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        return;
    }
    
    NSLog(@"[tcl] fetching image data (%@)", entry.url);
    NSURL *url = [NSURL URLWithString:entry.url];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    
    entry.size = image.size;
    entry.data = data;
    
    NSLog(@"[tcl] fetched data (%@)", entry.url);
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry);
        });
    }
}

- (void)_refresh
{
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull * NSEC_PER_SEC);
    long result = dispatch_semaphore_wait(_semaphore, time);
    
    if (result == 0) {
        
        [self.activityIndicator startAnimating];
        
        void (^terminationBlock)(void) = ^{
            [self.activityIndicator stopAnimating];
            dispatch_semaphore_signal(_semaphore);
        };
        
        
        void (^networkFailureBlock)(void) = ^{
            [self.activityIndicator stopAnimating];
            dispatch_semaphore_signal(_semaphore);
            [self _showNetworkConnectivityErrorAlert];
        };
        
        dispatch_async(_htmlFetcherWorkingQueue, ^{
            [self _fetchInfoForPageAtIndex:1 completion:^(NSArray *entries) {
                NSEnumerator *enumerator = [entries reverseObjectEnumerator];
                
                TCLEntry *entry = nil;
                while (entry = [enumerator nextObject]) {
                    if ([self.entries containsObject:entry] == NO) {
                        dispatch_async(_dataFetcherWorkingQueue, ^{
                            [self _fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
                                [self.entries insertObject:populatedEntry atIndex:0];
                                
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                
                                if ([entry isEqual:[entries lastObject]]) {
                                    terminationBlock();
                                }
                            } failure:^(NSError *error) {
                                switch (error.code) {
                                    case kTCLInternetConnectivityMissingErrorCode:
                                        networkFailureBlock();
                                        break;
                                    case kTCLMissingNodeErrorCode:
                                        [self _showTumblrScrapingErrorAlert];
                                        break;
                                    default:
                                        break;
                                }
                            }];
                        });
                    }
                }
            } failure:^(NSError *error) {
                networkFailureBlock();
            }];
        });
    }
}

- (void)_loadNextPage
{
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull * NSEC_PER_SEC);
    long result = dispatch_semaphore_wait(_semaphore, time);
    
    if (result == 0) {
        
        self.counter++;
        
        [self.activityIndicator startAnimating];
        
        void (^terminationBlock)(void) = ^{
            [self.activityIndicator stopAnimating];
            dispatch_semaphore_signal(_semaphore);
        };
        
        
        void (^networkFailureBlock)(void) = ^{
            [self.activityIndicator stopAnimating];
            dispatch_semaphore_signal(_semaphore);
            [self _showNetworkConnectivityErrorAlert];
        };
        
        dispatch_async(_htmlFetcherWorkingQueue, ^{
            [self _fetchInfoForPageAtIndex:self.counter completion:^(NSArray *entries) {
                NSEnumerator *enumerator = [entries objectEnumerator];
                
                TCLEntry *entry = nil;
                while (entry = [enumerator nextObject]) {
                    dispatch_async(_dataFetcherWorkingQueue, ^{
                        [self _fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
                            [self.entries addObject:populatedEntry];
                            
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.entries count] - 1 inSection:0];
                            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                            
                            if ([entry isEqual:[entries lastObject]]) {
                                terminationBlock();
                            }
                        } failure:^(NSError *error) {
                            switch (error.code) {
                                case kTCLInternetConnectivityMissingErrorCode:
                                    networkFailureBlock();
                                    break;
                                case kTCLMissingNodeErrorCode:
                                    [self _showTumblrScrapingErrorAlert];
                                    break;
                                default:
                                    break;
                            }
                        }];
                    });
                };
            } failure:^(NSError *error) {
                networkFailureBlock();
            }];
        });
    }
}

- (BOOL)_checkReachability
{
    return YES;
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

- (void)_showNetworkConnectivityErrorAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network error", @"Network error")
                                                    message:NSLocalizedString(@"Connectivity is missing.", @"Connectivity is missing.")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)_showTumblrScrapingErrorAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Scraping error", @"Scraping error")
                                                    message:NSLocalizedString(@"Tumblr format seems to be changed. Update or wait for an update.", @"Tumblr format seems to be changed. Update or wait for an update.")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                          otherButtonTitles:nil];
    [alert show];
}

@end
