//
//  TCLTableViewController.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 30/12/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewController.h"

#import "TCLInfoViewController.h"
#import "TCLTableViewCell.h"
#import "TCLEntry.h"

#import "Reachability.h"
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
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation TCLTableViewController
{
    dispatch_queue_t _htmlFetcherWorkingQueue;
    dispatch_queue_t _dataFetcherWorkingQueue;
//    dispatch_semaphore_t _refreshSemaphore;
    dispatch_semaphore_t _loadNextSemaphore;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"the_coding_love();", @"the_coding_love();");
    
    _htmlFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.html", NULL);
    _dataFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.data", NULL);
//    _refreshSemaphore = dispatch_semaphore_create(1);
    _loadNextSemaphore = dispatch_semaphore_create(1);
    
    self.entries = [NSMutableArray array];
    self.counter = 0;
    
//    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
//    [refresh addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
//    self.refreshControl = refresh;
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    self.navigationItem.leftBarButtonItem = bbi;
    
    [self.activityIndicator startAnimating];
    
    [self _loadNextPageCompletion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCLEntry *entry = self.entries[indexPath.row];
    
    // example: 100x20
    // resized: 100 : 20 = 320 : x
    // x = (320 * 20) / 100 = 64
    
    CGFloat x = (320.0 * entry.size.height) / entry.size.width;
    x += kTCLTableViewCellContentViewImagePadding;
    
    return x;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.entries count] - 1) {
        [self _loadNextPageCompletion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellReuseId = @"cell";
    TCLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
    TCLTableViewCellContentView *customContentView = nil;
    
    if (!cell) {
        cell = [[TCLTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseId];
        customContentView = [[NSBundle mainBundle] loadNibNamed:@"TCLTableViewCellContentView" owner:self options:nil][0];
        [cell setCustomContentView:customContentView];
        [cell.contentView addSubview:customContentView];
    }
    else {
        customContentView = cell.contentView.subviews[0];
        [NSObject cancelPreviousPerformRequestsWithTarget:cell];
    }
    
    TCLEntry *entry = self.entries[indexPath.row];
    
    dispatch_queue_t bkg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkg_queue, ^{
        UIImage *img = [UIImage imageWithData:entry.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [customContentView setTitle:entry.title image:img];
            [cell performSelector:@selector(loadAnimatedGIF:) withObject:entry afterDelay:1.0f];
        });
    });
    
    return cell;
}

#pragma mark - Actions

- (void)showInfo
{
    TCLInfoViewController *infoViewController = [[TCLInfoViewController alloc] initWithNibName:@"TCLInfoViewController" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

//- (void)refreshView:(UIRefreshControl *)refresh
//{
//    self.counter = 0;
//    [self.entries removeAllObjects];
//    [self.tableView reloadData];
//    
//    [self _loadNextPageCompletion:nil];
//    
////    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
////    [formatter setDateFormat:@"MMM d, h:mm a"];
////    NSString *lastUpdated = [NSString stringWithFormat:@"Last updated on %@", [formatter stringFromDate:[NSDate date]]];
////    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
//    [refresh endRefreshing];
//}

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
    NSLog(@"[tcl] fetching HTML page (%lu)", (unsigned long)index);
    NSString *urlString = [NSString stringWithFormat:@"%@/page/%lu", kTCLBaseURL, (unsigned long)index];
    NSURL *tutorialsUrl = [NSURL URLWithString:urlString];
    NSError *error = nil;
    NSData *htmlData = [NSData dataWithContentsOfURL:tutorialsUrl options:kNilOptions error:&error];
    if (!htmlData) {
        // check error...
    }
    NSLog(@"[tcl] fetched HTML page (%lu) (size %lu)", (unsigned long)index, (unsigned long)htmlData.length);

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
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
    if (!data) {
        // check error...
    }
    
    UIImage *image = [UIImage imageWithData:data];
    
    entry.size = image.size;
    entry.data = data;
    
    NSLog(@"[tcl] fetched data (%@) (size %lu)", entry.url, (unsigned long)data.length);
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry);
        });
    }
}

//- (void)_refreshCompletion:(void(^)(void))completion
//{
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull * NSEC_PER_SEC);
//    long result = dispatch_semaphore_wait(_refreshSemaphore, time);
//    
//    if (result == 0) {
//        
//        void (^terminationBlock)(void) = ^{
//            dispatch_semaphore_signal(_refreshSemaphore);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (completion) {
//                    completion();
//                }
//            });
//        };
//        
//        void (^networkFailureBlock)(void) = ^{
//            dispatch_semaphore_signal(_refreshSemaphore);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self _showNetworkConnectivityErrorAlert];
//                if (completion) {
//                    completion();
//                }
//            });
//        };
//        
//        void (^scrapingErrorBlock)(void) = ^{
//            dispatch_semaphore_signal(_refreshSemaphore);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self _showTumblrScrapingErrorAlert];
//                if (completion) {
//                    completion();
//                }
//            });
//        };
//        
//        dispatch_async(_htmlFetcherWorkingQueue, ^{
//            [self _fetchInfoForPageAtIndex:1 completion:^(NSArray *entries) {
//                
//                // TODO: now it's just for page #1
//                NSMutableArray *newEntries = [entries mutableCopy];
//                [newEntries removeObjectsInArray:self.entries];
//                
//                if ([newEntries count] == 0) {
//                    terminationBlock();
//                    return;
//                }
//                
//                NSEnumerator *enumerator = [newEntries reverseObjectEnumerator];
//                
//                TCLEntry *entry = nil;
//                while (entry = [enumerator nextObject]) {
//                    dispatch_async(_dataFetcherWorkingQueue, ^{
//                        [self _fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
//                            [self.entries insertObject:populatedEntry atIndex:0];
//                            
//                            if ([entry isEqual:[newEntries firstObject]]) {
//                                terminationBlock();
//                            }
//
//                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//                            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//                            
//                        } failure:^(NSError *error) {
//                            switch (error.code) {
//                                case kTCLInternetConnectivityMissingErrorCode:
//                                    networkFailureBlock();
//                                    break;
//                                default:
//                                    terminationBlock();
//                                    break;
//                            }
//                        }];
//                    });
//                }
//            } failure:^(NSError *error) {
//                switch (error.code) {
//                    case kTCLInternetConnectivityMissingErrorCode:
//                        networkFailureBlock();
//                        break;
//                    case kTCLMissingNodeErrorCode:
//                        scrapingErrorBlock();
//                        break;
//                    default:
//                        terminationBlock();
//                        break;
//                }
//            }];
//        });
//    }
//}

- (void)_loadNextPageCompletion:(void(^)(void))completion
{
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull * NSEC_PER_SEC);
    long result = dispatch_semaphore_wait(_loadNextSemaphore, time);
    
    if (result == 0) {
        
        self.counter++;
        
        void (^terminationBlock)(void) = ^{
            dispatch_semaphore_signal(_loadNextSemaphore);
        };
        
        
        void (^networkFailureBlock)(void) = ^{
            dispatch_semaphore_signal(_loadNextSemaphore);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _showNetworkConnectivityErrorAlert];
            });
        };
        
        void (^scrapingErrorBlock)(void) = ^{
            dispatch_semaphore_signal(_loadNextSemaphore);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _showTumblrScrapingErrorAlert];
                if (completion) {
                    completion();
                }
            });
        };
        
        dispatch_async(_htmlFetcherWorkingQueue, ^{
            [self _fetchInfoForPageAtIndex:self.counter completion:^(NSArray *entries) {
                for (TCLEntry *entry in entries) {
                    dispatch_async(_dataFetcherWorkingQueue, ^{
                        [self _fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
                            [self.entries addObject:populatedEntry];
                            
                            if ([entry isEqual:[entries lastObject]]) {
                                terminationBlock();
                            }
                        
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.entries count] - 1 inSection:0];
                            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                        } failure:^(NSError *error) {
                            switch (error.code) {
                                case kTCLInternetConnectivityMissingErrorCode:
                                    networkFailureBlock();
                                    break;
                                default:
                                    terminationBlock();
                                    break;
                            }
                        }];
                    });
                };
            } failure:^(NSError *error) {
                switch (error.code) {
                    case kTCLInternetConnectivityMissingErrorCode:
                        networkFailureBlock();
                        break;
                    case kTCLMissingNodeErrorCode:
                        scrapingErrorBlock();
                        break;
                    default:
                        terminationBlock();
                        break;
                }
            }];
        });
    }
}

- (BOOL)_checkReachability
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    return (reach.currentReachabilityStatus != NotReachable);
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
