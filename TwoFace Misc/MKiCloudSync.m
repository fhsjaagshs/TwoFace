//
//  MKiCloudSync.m
//
//  Created by Mugunth Kumar on 11/20//11.
//  Modified by Alexsander Akers on 1/4/12.
//  
//  Copyright (C) 2011-2020 by Steinlogic
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MKiCloudSync.h"
#import "AppDelegate.h"

NSString *const MKiCloudSyncDidUpdateNotification = @"MKiCloudSyncDidUpdateNotification";

static BOOL _isSyncing;
static dispatch_queue_t _queue;

@interface MKiCloudSync ()

+ (BOOL) tryToStartSync;

+ (void) pullFromICloud;
+ (void) pushToICloud;

@end

@implementation MKiCloudSync

+ (BOOL) isSyncing
{
	__block BOOL isSyncing = NO;
	
	dispatch_sync(_queue, ^{
		isSyncing = _isSyncing;
	});

	return isSyncing;
}
+ (BOOL) start
{
	if ([NSUbiquitousKeyValueStore class] && [NSUbiquitousKeyValueStore defaultStore] && [self tryToStartSync])
	{
#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Will start sync");
#endif
		
		// Force push
		[MKiCloudSync pushToICloud];
		
		// Force pull
		[MKiCloudSync pullFromICloud];
		
		NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
		
		// Post notification
		[dnc postNotificationName: MKiCloudSyncDidUpdateNotification object: self];

		// Add self as observer
		[dnc addObserver: self selector: @selector(pullFromICloud) name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
		[dnc addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
		
#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Did start sync");
#endif		
		return YES;
	}
	
	return NO;
}
+ (BOOL) tryToStartSync
{
	__block BOOL didSucceed = NO;

	dispatch_sync(_queue, ^{
		if (!_isSyncing)
		{
			_isSyncing = YES;
			didSucceed = YES;
		}
	});

	return didSucceed;
}

+ (NSMutableSet *) ignoredKeys
{
	static NSMutableSet *ignoredKeys;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		ignoredKeys = [NSMutableSet new];
	});
	
	return ignoredKeys;
}

+ (void) cleanUbiquitousStore
{
	[self stop];
	
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	NSDictionary *dict = [store dictionaryRepresentation];
	
	NSMutableSet *keys = [NSMutableSet setWithArray: [dict allKeys]];
	[keys minusSet: [self ignoredKeys]];
	
	[keys enumerateObjectsUsingBlock: ^(NSString *key, BOOL *stop) {
		[store removeObjectForKey: key];
	}];
	[store synchronize];
	
#if MKiCloudSyncDebug
	NSLog(@"MKiCloudSync: Cleaned ubiquitous store");
#endif
}
+ (void) initialize
{
	if (self == [MKiCloudSync class])
	{
		_isSyncing = NO;
		_queue = dispatch_queue_create("com.mugunthkumar.MKiCloudSync", DISPATCH_QUEUE_SERIAL);
	}
}
+ (void) pullFromICloud
{
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	[dnc removeObserver: self name: NSUserDefaultsDidChangeNotification object: nil];
	
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
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *downloaded = [store dictionaryRepresentation];
    
    NSLog(@"downloaded: %@",downloaded);
    
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

    [finished enumerateKeysAndObjectsUsingBlock:^(id keyasdf, id objasdf, BOOL *stopasdf) {
        [[NSUserDefaults standardUserDefaults]setObject:objasdf forKey:keyasdf];
    }];
    
    [[NSUserDefaults standardUserDefaults]synchronize];
	
	[dnc addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
	[dnc postNotificationName: MKiCloudSyncDidUpdateNotification object: nil];
}
+ (void) pushToICloud {
    
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
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *downloaded = [store dictionaryRepresentation];
    
    NSLog(@"downloaded: %@",downloaded);
    
    
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
    
    [finished enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        if ([keysToSync containsObject:key]) {
            [store setObject:obj forKey:key];
        }
    }];
    [store synchronize];
    
    NSLog(@"In Cloud: %@",[store dictionaryRepresentation]);
	
#if MKiCloudSyncDebug
	NSLog(@"MKiCloudSync: Pushed to iCloud");
#endif
}
+ (void) stop
{
	dispatch_sync(_queue, ^{
		_isSyncing = NO;
		[[NSNotificationCenter defaultCenter]removeObserver:self];
		
#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Stopped syncing with iCloud");
#endif
	});
}

@end
