//
//  FHSiCloudSync.m
//  TwoFace
//
//  Created by Nate Symer on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FHSiCloudSync.h"
#import "AppDelegate.h"

static BOOL _isSyncing;

@implementation FHSiCloudSync

+ (void)resetUbiquitousStore {	
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
    NSMutableArray *keysToSync = [[NSMutableArray alloc]init];
    
    [keysToSync addObject:@"FBSelectedFriendsDict"];
    [keysToSync addObject:@"addedUsernames_twitter"];
    [keysToSync addObject:@"usernames_twitter"];
    [keysToSync addObject:@"FBExpirationDateKey"];
    [keysToSync addObject:@"FBAccessTokenKey"];
    [keysToSync addObject:@"ada"];
    
    for (id key in keysToSync) {
        [store removeObjectForKey:key];
    }
                                
	[store synchronize];
    
	NSLog(@"FHSiCloudSync: Cleaned ubiquitous store");
}

+ (void)syncWithDelegate:(id)delegate {
    [NSThread detachNewThreadSelector:@selector(syncTaskWithDelegate:) toTarget:self withObject:delegate]; 
}

+ (void)sync {
    [NSThread detachNewThreadSelector:@selector(syncTaskWithDelegate:) toTarget:self withObject:nil];
}

+ (void)syncTaskWithDelegate:(id)delegate {
    if ([NSUbiquitousKeyValueStore class] && [NSUbiquitousKeyValueStore defaultStore] && !_isSyncing) {
        _isSyncing = YES;
        
        NSMutableArray *keysToSync = [[NSMutableArray alloc]init];
        
        BOOL syncUsernames = kiCloudSyncUsernames;
        BOOL syncLoginSessions = kiCloudSyncLoginSession;
        
        if (syncUsernames) {
            [keysToSync addObject:@"FBSelectedFriendsDict"];
            [keysToSync addObject:@"addedUsernames_twitter"];
            [keysToSync addObject:@"usernames_twitter"];
        }
        
        if (syncLoginSessions) {
            [keysToSync addObject:@"FBExpirationDateKey"];
            [keysToSync addObject:@"ada"];
            [keysToSync addObject:@"FBAccessTokenKey"];
        }
        
        printf("//\n//Next Sync\n//\n");
        
		NSLog(@"FHSiCloudSync: Will start sync");
    
		NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
		NSDictionary *downloaded = [store dictionaryRepresentation];
        
        NSLog(@"downloaded: %@",downloaded);
        
		NSLog(@"FHSiCloudSync: Did Finish downloading");
        
        NSLog(@"FHSiCloudSync: Will start combining step");
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *udDict = [userDefaults dictionaryRepresentation];
        
        NSMutableDictionary *finished = [[NSMutableDictionary alloc]init];
        
		[udDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			
            if (![keysToSync containsObject:key]) {
                return;
            }
            
            NSLog(@"Key: %@",key);
            
            id objInUdDict = [udDict objectForKey:key]; // local
            id objInDownloaded = [downloaded objectForKey:key]; // remote

            if (objInUdDict == objInDownloaded) {
                NSLog(@"same");
                [finished setObject:obj forKey:key];
            } else { 
                BOOL isDict = ([objInUdDict isKindOfClass:[NSDictionary class]] && [objInDownloaded isKindOfClass:[NSDictionary class]]);
                BOOL isArray = ([objInUdDict isKindOfClass:[NSArray class]] && [objInDownloaded isKindOfClass:[NSArray class]]);
                
                NSLog(@"isDict: %i, isArray: %i",isDict, isArray);
                
                if (isDict) {
                    // if they are dictionaries
                    
                    NSDictionary *oiud = (NSDictionary *)objInUdDict;
                    NSDictionary *oid = (NSDictionary *)objInDownloaded;
                    
                    NSLog(@"oiud: %@",oiud);
                    NSLog(@"oid: %@",oid);
                    
                    
                    NSMutableDictionary *combinedDict = [[NSMutableDictionary alloc]init];
                    [combinedDict addEntriesFromDictionary:oiud];
                    [combinedDict addEntriesFromDictionary:oid];
                    
                    /*[oiud enumerateKeysAndObjectsUsingBlock:^(id keyq, id objq, BOOL *stopq) {
                        [combinedDict setObject:objq forKey:keyq];
                        NSLog(@"obj: %@",objq);
                    }];
                    
                    [oid enumerateKeysAndObjectsUsingBlock:^(id keyqa, id objqa, BOOL *stopqa) {
                        [combinedDict setObject:objqa forKey:keyqa];
                        NSLog(@"obj: %@",objqa);
                    }];*/
                    
                    NSLog(@"combinedDict: %@",combinedDict);

                    NSMutableDictionary *deleteDict = kiCloudSyncDeletedFBDict;
                    [combinedDict removeObjectsForKeys:deleteDict.allKeys];
                    [deleteDict removeAllObjects];
                    [[NSUserDefaults standardUserDefaults]setObject:deleteDict forKey:kiCloudSyncDeletedFBKey];

                    
                    [finished setObject:combinedDict forKey:key];
                    
                } else if (isArray) {
                    // if they are arrays
                    
                    NSLog(@"isArray");
                    
                    NSMutableArray *combinedArray = [[NSMutableArray alloc]init];
                    
                    NSMutableArray *oiuda = (NSMutableArray *)objInUdDict;
                    NSMutableArray *oida = (NSMutableArray *)objInDownloaded;
                    
                    [combinedArray addObjectsFromArray:oiuda];
                    [combinedArray addObjectsFromArray:oida];
                    
                    NSArray *intermediateArray = [[NSSet setWithArray:combinedArray]allObjects];
                    
                    NSMutableArray *finalArray = [[NSMutableArray alloc]initWithArray:intermediateArray];
                    
                    NSMutableArray *deleteArray = kiCloudSyncDeletedTArray;
                    
                    for (id obj in finalArray) {
                        if ([deleteArray containsObject:obj]) {
                            [finalArray removeObject:obj];
                        }
                    }
                    
                    [deleteArray removeAllObjects];
                    [[NSUserDefaults standardUserDefaults]setObject:deleteArray forKey:kiCloudSyncDeletedTKey];
                    
                    [finished setObject:finalArray forKey:key];
                } else {
                    [finished setObject:obj forKey:key];
                }
            }
            
		}];
        
        NSLog(@"FHSiCloudSync: Did finish combining step");
        
        /*NSLog(@"FHSiCloudSync: Checking if the downloaded dict is in line with iCloud");
        
        NSUbiquitousKeyValueStore *storeCheck = [NSUbiquitousKeyValueStore defaultStore];
		NSDictionary *downloadedCheck = [storeCheck dictionaryRepresentation];
        
        if (![downloaded isEqualToDictionary:downloadedCheck]) {
            NSLog(@"FHSiCloudSync: Downloaded dict has changed. Starting over.");
            _isSyncing = NO;
            [self sync];
            return;
        }
        
        NSLog(@"FHSiCloudSync: Downloaded dict was sane");*/
        
        NSLog(@"FHSiCloudSync: Starting Uploading step");
        
        [finished enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
            if ([keysToSync containsObject:key]) {
                [store setObject:obj forKey:key];
            }
        }];
        [store synchronize];
        
        NSLog(@"In Cloud: %@",[store dictionaryRepresentation]);
        
        NSLog(@"FHSiCloudSync: Finished Uploading Step");
        
        NSLog(@"FHSiCloudSync: Modifying local data");
        
        [finished enumerateKeysAndObjectsUsingBlock:^(id keyasdf, id objasdf, BOOL *stopasdf) {
            [[NSUserDefaults standardUserDefaults]setObject:objasdf forKey:keyasdf];
        }];
        
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        NSLog(@"FHSiCloudSync: Done modifing local data");
        
        NSLog(@"FHSiCloudSync: Finished Sync");
        _isSyncing = NO;
        if ([delegate respondsToSelector:@selector(syncingDidFinish)]) {
            [delegate syncingDidFinish];
        }
	}
}

@end
