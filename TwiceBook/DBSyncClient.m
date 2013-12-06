//
//  DBSyncClient.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DBSyncClient.h"

@implementation DBSyncClient

- (void)checkForSyncingFile {
    NSString *path = [[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
}

- (void)mainSyncStep:(NSString *)rev {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *susPath = [[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"];
    
    NSMutableDictionary *cloudData = [NSMutableDictionary dictionaryWithContentsOfFile:susPath];
    
    if (cloudData.allKeys.count == 0) {
        cloudData = [NSMutableDictionary dictionary];
    }
    
    id fdc = cloudData[kSelectedFriendsDictionaryKey];
    id autc = cloudData[kAddedUsernamesListKey];
    id utc = cloudData[kSelectedUsernamesListKey];
    id ddc = cloudData[@"deleted_dict_facebook"];
    id dac = cloudData[@"deleted_array_twitter"];

    id fdl = [defaults objectForKey:kSelectedFriendsDictionaryKey];
    id autl = [defaults objectForKey:kAddedUsernamesListKey];
    id utl = [defaults objectForKey:kSelectedUsernamesListKey];
    
    
    //
    // Facebook Selected Friends
    //
    
    NSMutableDictionary *remoteFriendsDict = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary *)fdc];
    NSMutableDictionary *localFriendsDict = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary *)fdl];
    NSMutableDictionary *cloudDeletionDict = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary *)ddc]; // from sync-before-this-sync
    
    NSMutableDictionary *deleteDict = [Settings dropboxDeletedFacebookDictionary];
    
    [localFriendsDict removeObjectsForKeys:cloudDeletionDict.allKeys];
    [remoteFriendsDict removeObjectsForKeys:cloudDeletionDict.allKeys];
    
    [localFriendsDict removeObjectsForKeys:deleteDict.allKeys];
    [remoteFriendsDict removeObjectsForKeys:deleteDict.allKeys];
    
    /*for (id key in cloudDeletionDict.allKeys) {
        [localFriendsDict removeObjectForKey:key];
        if ([remoteFriendsDict.allKeys containsObject:key]) {
            [remoteFriendsDict removeObjectForKey:key];
        }
    }
    
    for (id key in deleteDict.allKeys) {
        [remoteFriendsDict removeObjectForKey:key];
        if ([localFriendsDict.allKeys containsObject:key]) {
            [localFriendsDict removeObjectForKey:key];
        }
    }*/
    
    [cloudDeletionDict removeAllObjects];
    [cloudDeletionDict addEntriesFromDictionary:deleteDict];
    
    cloudData[@"deleted_dict_facebook"] = cloudDeletionDict;
    
    [deleteDict removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:deleteDict forKey:kDBSyncDeletedFBDictKey];
    
    NSMutableDictionary *combinedDict = [NSMutableDictionary dictionary];
    [combinedDict addEntriesFromDictionary:remoteFriendsDict];
    [combinedDict addEntriesFromDictionary:localFriendsDict];
    
    cloudData[kSelectedFriendsDictionaryKey] = combinedDict;
    [defaults setObject:combinedDict forKey:kSelectedFriendsDictionaryKey];
    
    //
    // Twitter Added Users
    //
    
    NSMutableArray *combinedArray = [NSMutableArray array];
    NSMutableArray *autcA = [NSMutableArray arrayWithArray:(NSMutableArray *)autc];
    NSMutableArray *autlA = [NSMutableArray arrayWithArray:(NSMutableArray *)autl];
    
    NSMutableArray *deleteArray = [Settings dropboxDeletedTwitterArray];
    
    NSMutableArray *cloudDeleteArray = [NSMutableArray arrayWithArray:(NSMutableArray *)dac];
    
    [autc removeObjectsInArray:deleteArray];
    
    /*for (id obj in deleteArray) {
        if ([autcA containsObject:obj]) {
            [autcA removeObject:obj];
        }
    }*/
    
    [autlA removeObjectsInArray:cloudDeleteArray];
    
    /*for (id obj in cloudDeleteArray) {
        if ([autlA containsObject:obj]) {
            [autlA removeObject:obj];
        }
    }*/
    
    [combinedArray addObjectsFromArray:autcA];
    [combinedArray addObjectsFromArray:autlA];
    
    NSMutableArray *finalArray = [NSMutableArray array];
    
    for (id obj in combinedArray) {
        if (![finalArray containsObject:obj]) {
            [finalArray addObject:obj];
        }
    }
    
    cloudData[kAddedUsernamesListKey] = finalArray;
    [defaults setObject:finalArray forKey:kAddedUsernamesListKey];
    
    //
    // Twitter Selected Users
    //
    
    NSMutableArray *combinedArrayF = [NSMutableArray array];
    
    NSMutableArray *selectedUsersTCloud = [NSMutableArray arrayWithArray:(NSMutableArray *)utc];
    NSMutableArray *selectedUsersTLocal = [NSMutableArray arrayWithArray:(NSMutableArray *)utl];
    
    [selectedUsersTCloud removeObjectsInArray:deleteArray];
    
    /*for (id obj in deleteArray) {
        if ([selectedUsersTCloud containsObject:obj]) {
            [selectedUsersTCloud removeObject:obj];
        }
    }*/
    
    [selectedUsersTLocal removeObjectsInArray:cloudDeleteArray];
    
    /*for (id obj in cloudDeleteArray) {
        if ([selectedUsersTLocal containsObject:obj]) {
            [selectedUsersTLocal removeObject:obj];
        }
    }*/
    
    [cloudDeleteArray removeAllObjects];
    [cloudDeleteArray addObjectsFromArray:deleteArray];
    cloudData[@"deleted_array_twitter"] = cloudDeleteArray;
    
    //[deleteArray removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:[NSMutableArray array] forKey:kDBSyncDeletedTArrayKey];
    
    [combinedArrayF addObjectsFromArray:selectedUsersTCloud];
    [combinedArrayF addObjectsFromArray:selectedUsersTLocal];
    
    /*NSMutableArray *finalArrayF = [NSMutableArray array];
    
    for (id obj in combinedArrayF) {
        if (![finalArrayF containsObject:obj]) {
            [finalArrayF addObject:obj];
        }
    }*/
    
    cloudData[@"usernames_twitter"] = combinedArrayF;
    [defaults setObject:combinedArrayF forKey:@"usernames_twitter"];
    
    [defaults synchronize];
    [cloudData writeToFile:susPath atomically:YES];
    
    [DroppinBadassBlocks uploadFile:@"selectedUsernameSync.plist" toPath:@"/" withParentRev:rev fromPath:susPath withBlock:^(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) {
        [Settings.appDelegate hideHUD];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (error) {
            qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
        } else {
            [[NSUserDefaults standardUserDefaults]setObject:[NSDate date] forKey:@"lastSyncedDateKey"];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"lastSynced" object:nil];
        }
    } andProgressBlock:nil];
}

- (void)dropboxSync {
    [Settings.appDelegate showHUDWithTitle:@"Syncing..."];
    NSString *susPath = [[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"];
    
    [DroppinBadassBlocks loadMetadata:@"/" withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        if (error) {
            [Settings.appDelegate hideHUD];
            [[NSFileManager defaultManager]removeItemAtPath:susPath error:nil];
            qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        } else {
            NSMutableArray *filenames = [NSMutableArray array];
            
            NSString *savedRev = nil;
            
            for (DBMetadata *item in metadata.contents) {
                NSString *theFileName = item.filename;
                [filenames addObject:theFileName];
                if ([theFileName isEqualToString:@"selectedUsernameSync.plist"]) {
                    savedRev = item.rev;
                    break;
                }
            }
            
            [[NSFileManager defaultManager]removeItemAtPath:susPath error:nil];
            [[NSFileManager defaultManager]createFileAtPath:susPath contents:nil attributes:nil];
            
            if ([filenames containsObject:@"selectedUsernameSync.plist"]) {
                [DroppinBadassBlocks loadFile:@"/selectedUsernameSync.plist" intoPath:susPath withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
                    if (error) {
                        [Settings.appDelegate hideHUD];
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
                    } else {
                        [self mainSyncStep:savedRev];
                    }
                } andProgressBlock:nil];
            } else {
                [self mainSyncStep:savedRev];
            }
        }
    }];
}

- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [Settings.appDelegate hideHUD];
}

- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [Settings.appDelegate hideHUD];
    if (error.code != 404) {
        [[NSFileManager defaultManager]removeItemAtPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"] error:nil];
        qAlert(@"Error Resetting Dropbox Sync", @"TwoFace failed to delete the data stored on Dropbox.");
    }
}

- (void)resetDropboxSync {
    [Settings.appDelegate showHUDWithTitle:@"Resetting Sync..."];
    [[NSUserDefaults standardUserDefaults]setObject:[[NSMutableArray alloc]init] forKey:kDBSyncDeletedTArrayKey];
    [[NSUserDefaults standardUserDefaults]setObject:[[NSMutableDictionary alloc]init] forKey:kDBSyncDeletedFBDictKey];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastSyncedDateKey"];
   // [self.restClient deletePath:@"/selectedUsernameSync.plist"];
}

@end
