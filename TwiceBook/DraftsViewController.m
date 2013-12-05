//
//  DraftsViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/9/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "DraftsViewController.h"

@implementation DraftsViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-64) style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.backgroundColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:_theTableView.frame];
    bgView.backgroundColor = [UIColor clearColor];
    [_theTableView setBackgroundView:bgView];
    [self.view addSubview:_theTableView];
    [self.view bringSubviewToFront:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select a Draft"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    int count = [[Settings drafts]count];
    return (count == 0)?@"There are no saved drafts.":[NSString stringWithFormat:@"There %@ %d draft%@.",(count == 1)?@"is":@"are",count,(count == 1)?@"":@"s"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[Settings drafts]count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell_draftsvc";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
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

    NSDictionary *draft = [Settings drafts][indexPath.row];
    NSString *thumbnailImagePath = (NSString *)draft[@"thumbnailImagePath"];
    
    UIImage *image = [UIImage imageWithContentsOfFile:thumbnailImagePath.length?thumbnailImagePath:draft[@"imagePath"]];
    
    if (image) {
        cell.accessoryView.hidden = NO;
        [(UIImageView *)cell.accessoryView setImage:image];
    } else {
        cell.accessoryView.hidden = YES;
    }
    
    cell.textLabel.text = [[draft[@"time"]timeElapsedSinceCurrentDate]stringByAppendingString:@" ago"];
    cell.detailTextLabel.text = draft[@"text"];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *draftsArray = [Settings drafts];
    [draftsArray removeObjectAtIndex:indexPath.row];
    [draftsArray writeToFile:[Settings draftsPath] atomically:YES];
    
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationLeft];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"draft" object:[Settings drafts][indexPath.row]];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)startReloadLoop {
    if (!_theTableView.editing) {
        [_theTableView reloadData];
    }
    [self performSelector:@selector(startReloadLoop) withObject:nil afterDelay:10.0f];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startReloadLoop];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

@end
