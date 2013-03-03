//
//  DraftsViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/9/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "DraftsViewController.h"

@implementation DraftsViewController

@synthesize theTableView;

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-64) style:UITableViewStyleGrouped];
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;
    self.theTableView.backgroundColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:self.theTableView.frame];
    bgView.backgroundColor = [UIColor clearColor];
    [self.theTableView setBackgroundView:bgView];
    [self.view addSubview:self.theTableView];
    [self.view bringSubviewToFront:self.theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select a Draft"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    
    [self startReloadLoop];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    int count = [kDraftsArray count];
    return (count == 0)?@"There are no saved drafts.":[NSString stringWithFormat:@"There %@ %d draft%@.",(count == 1)?@"is":@"are",count,(count == 1)?@"":@"s"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [kDraftsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell_draftsvc";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
        imageView.layer.cornerRadius = 4;
        imageView.layer.masksToBounds = YES;
        imageView.layer.borderColor = [UIColor blackColor].CGColor;
        imageView.layer.borderWidth = 1;
        imageView.layer.cornerRadius = 5;
        imageView.clipsToBounds = YES;
        cell.accessoryView = imageView;
    }

    NSDictionary *draft = [kDraftsArray objectAtIndex:indexPath.row];
    NSString *thumbnailImagePath = (NSString *)[draft objectForKey:@"thumbnailImagePath"];
    
    UIImage *image = nil;
    
    if (thumbnailImagePath) {
        image = [UIImage imageWithContentsOfFile:thumbnailImagePath];
    } else {
        image = [UIImage imageWithContentsOfFile:[draft objectForKey:@"imagePath"]];
    }
    
    if (image != nil) {
        cell.accessoryView.hidden = NO;
        [(UIImageView *)cell.accessoryView setImage:image];
    } else {
        cell.accessoryView.hidden = YES;
    }
    
    cell.textLabel.text = [[[draft objectForKey:@"time"]timeElapsedSinceCurrentDate]stringByAppendingString:@" ago"];
    cell.detailTextLabel.text = [draft objectForKey:@"text"];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([kDraftsArray count] > 0);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *draftsArray = kDraftsArray;
    [draftsArray removeObjectAtIndex:indexPath.row];
    [draftsArray writeToFile:kDraftsPath atomically:YES];
    
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil] withRowAnimation:UITableViewRowAnimationLeft];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"draft" object:[kDraftsArray objectAtIndex:indexPath.row]];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)startReloadLoop {
    if (!self.theTableView.editing) {
        [self.theTableView reloadData];
    }
    [self performSelector:@selector(startReloadLoop) withObject:nil afterDelay:10.0f];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
