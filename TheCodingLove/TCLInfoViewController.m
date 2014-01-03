//
//  TCLInfoViewController.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 03/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "TCLInfoViewController.h"

@interface TCLInfoViewController ()

@property (nonatomic, weak) IBOutlet UITextView *creditsTextView;

@end

@implementation TCLInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Credits", @"Credits");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    
    self.creditsTextView.text = @"simple third-party reader for the_coding_love(); that shows GIFs when they are ready to be shown \n http://thecodinglove.com\n\nAuthor: Alberto De Bortoli \n http://albertodebortoli.com\nhttp://github.com/albertodebortoli\nhttp://twitter.com/albertodebo";
}

- (IBAction)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
