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

#import "TCLTableViewCell.h"
#import "TCLEntry.h"

static NSString *const kTCLBaseURL = @"http://www.thecodinglove.com";

@interface TCLTableViewController ()

@property (nonatomic, strong) NSMutableArray *entries;

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
    
    [self fetchInfoForPageAtIndex:1 completion:^(NSArray *entries) {
        for (TCLEntry *entry in entries) {
            [self fetchDataForEntry:entry completion:^(TCLEntry *populatedEntry) {
                [self.entries addObject:populatedEntry];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.entries count] - 1 inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
        }
    }];
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
        NSString *xpathQueryString = @"//div[@class='post']/div/p[@class='c1']/img";
        NSArray *nodes = [tutorialsParser searchWithXPathQuery:xpathQueryString];
        
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry);
        });
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCLEntry *entry = self.entries[indexPath.row];
    
    if (entry.size.height == 0 && entry.size.width == 0) {
        UIImage *image = [UIImage imageWithData:entry.data];
        entry.size = image.size;
    }
    
    // example: 100x20
    // resized: 100 : 20 = 320 : x
    // x = (320 * 20) / 100 = 64
    
    return (320.0 * entry.size.height) / entry.size.width;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellReuseId = @"cell";
    TCLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
    
    if (!cell) {
        cell = [[TCLTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseId];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    TCLEntry *entry = self.entries[indexPath.row];
    cell.entryImageView.image = [UIImage animatedImageWithAnimatedGIFData:entry.data];
    
    return cell;
}

@end
