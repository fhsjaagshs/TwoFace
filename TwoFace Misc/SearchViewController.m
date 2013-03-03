//
//  SearchViewController.m
//  Node
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchViewController.h"
#import "SBJson.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)lookupTerm:(NSString *)term {
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    NSString *embarkURL = [NSString stringWithFormat:@"https://api.twitter.com/1/users/lookup.json?screen_name=%@&include_entities=true",term];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:embarkURL]];
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSArray *statuses = [parser objectWithString:json_string error:nil];
    for (NSDictionary *status in statuses)
    {
        NSLog(@"Status of statuses: %@",status);
      //  NSLog(@"%@ - %@", [status objectForKey:@"text"], [[status objectForKey:@"user"] objectForKey:@"screen_name"]);
    }
    NSLog(@"%@",statuses);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
