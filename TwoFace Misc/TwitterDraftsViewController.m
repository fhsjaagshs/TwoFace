//
//  TwitterDraftsViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "TwitterDraftsViewController.h"

@implementation TwitterDraftsViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *draftsArray = kTwitterDraftsArray;
    
    if (draftsArray.count == 0) {
        return 44;
    }
    
    NSDictionary *draft = [draftsArray objectAtIndex:indexPath.row];
    NSString *text = [draft objectForKey:@"text"];
    
    if (text.length == 0 || text == nil) {
        return 44;
    }
    
    CGSize labelSize = [text sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:17] constrainedToSize:CGSizeMake(280, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    CGFloat labelHeight = labelSize.height;
    
    return 44-21+labelHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int count = [kTwitterDraftsArray count];
    
    if (count == 0) {
        count = 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell7";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    int row = indexPath.row;
    
    NSMutableArray *draftsArray = kTwitterDraftsArray;
    
    if (draftsArray.count == 0) {
        cell.textLabel.text = @"No Drafts";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    
    NSDictionary *draft = [kTwitterDraftsArray objectAtIndex:row];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[draft objectForKey:@"imagePath"]];
    
    cell.textLabel.text = [draft objectForKey:@"text"];
    
    if (cell.textLabel.text.length == 0) {
        cell.textLabel.text = @"No Text";
    }
    
    if (image != nil) {
        cell.detailTextLabel.text = @"Image";
    } else {
        cell.detailTextLabel.text = @"";
    }

    cell.textLabel.numberOfLines = ([self tableView:tableView heightForRowAtIndexPath:indexPath]/17)-1;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *draftsArray = kTwitterDraftsArray;
    
    if (draftsArray.count == 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *draftsArray = kTwitterDraftsArray;
    [[NSFileManager defaultManager]removeItemAtPath:[[draftsArray objectAtIndex:indexPath.row]objectForKey:@"imagePath"] error:nil];
    [draftsArray removeObjectAtIndex:indexPath.row];
    [draftsArray writeToFile:kTwitterDraftsPath atomically:YES];
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *draftsArray = kTwitterDraftsArray;
    
    if (draftsArray.count == 0) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int row = indexPath.row;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"twitter_draft" object:[draftsArray objectAtIndex:row]];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
