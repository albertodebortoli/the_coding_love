//
//  TCLTableViewController.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 30/12/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewController.h"

#import "TFHpple.h"
#import "UIImage+animatedGIF.h"

#import "TCLTableViewCellContentView.h"
#import "TCLEntry.h"

static NSString *const kTCLBaseURL = @"http://www.thecodinglove.com";

@interface TCLTableViewController ()

@property (nonatomic, strong) NSMutableArray *entries;
@property (nonatomic, assign) NSUInteger counter;

- (IBAction)loadMore:(id)sender;

@end

@implementation TCLTableViewController
{
    dispatch_queue_t _htmlFetcherWorkingQueue;
    dispatch_queue_t _dataFetcherWorkingQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _htmlFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.html", NULL);
    _dataFetcherWorkingQueue = dispatch_queue_create("com.albertodebortoli.thecodinglove.fetcher.data", NULL);
    self.entries = [NSMutableArray array];
    
    self.counter = 0;
    
    [self _loadNextPage];
}

- (void)fetchInfoForPageAtIndex:(NSUInteger)index completion:(void (^)(NSArray *entries))completion
{
    dispatch_async(_htmlFetcherWorkingQueue, ^{
        // 1. create the url and retrieve the data
        NSString *urlString = [NSString stringWithFormat:@"%@/page/%i", kTCLBaseURL, index];
        NSURL *tutorialsUrl = [NSURL URLWithString:urlString];
        NSData *htmlData = [NSData dataWithContentsOfURL:tutorialsUrl];
        
        // 2. create the parser and search using a XPath query
        TFHpple *tutorialsParser = [TFHpple hppleWithHTMLData:htmlData];
//        NSString *xpathQueryString = @"//div[@class='post']";
        NSString *xpathQueryString = @"//div[@class='post']/div/p[@class='c1']/img";
        NSArray *nodes = [tutorialsParser searchWithXPathQuery:xpathQueryString];
//        NSArray *nodes2 = [tutorialsParser searchWithXPathQuery:xpathQueryString2];
        NSLog(@"[tcl] fetched HTML page (%i)", index);
        
        // 3. create TCLEntry for each result
        NSMutableArray *entries = [NSMutableArray array];
        for (TFHppleElement *element in nodes) {
            TCLEntry *entry = [[TCLEntry alloc] init];
            entry.title = @"fake title";
            entry.author = @"fake author";
            entry.url = element.attributes[@"src"];
            
            [entries addObject:entry];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entries);
        });
    });
}

- (void)fetchDataForEntry:(TCLEntry *)entry completion:(void (^)(TCLEntry *populatedEntry))completion
{
    dispatch_async(_dataFetcherWorkingQueue, ^{
        NSURL *url = [NSURL URLWithString:entry.url];
        NSData *data = [NSData dataWithContentsOfURL:url];
        entry.data = data;
        NSLog(@"[tcl] fetched data (%@)", entry.url);

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry);
        });
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[call] heightForRowAtIndexPath (%@)", indexPath);
    
    TCLEntry *entry = self.entries[indexPath.row];
    
    // TODO: it does not work like that, this method is called once per reload, the caching should be during the fetch
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
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else {
        customContentView = cell.contentView.subviews[0];
    }
    
    TCLEntry *entry = self.entries[indexPath.row];
    
    dispatch_queue_t bkg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkg_queue, ^{
        UIImage *img = [UIImage animatedImageWithAnimatedGIFData:entry.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [customContentView setTitle:entry.title image:img author:entry.author];
        });
    });
    
    return cell;
}

- (void)_loadNextPage
{
    self.counter++;
    
    [self fetchInfoForPageAtIndex:self.counter completion:^(NSArray *entries) {
        for (TCLEntry *entry in entries) {
            [self fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
                [self.entries addObject:populatedEntry];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.entries count] - 1 inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
        }
    }];
}

- (IBAction)loadMore:(id)sender
{
    [self _loadNextPage];
}

@end
