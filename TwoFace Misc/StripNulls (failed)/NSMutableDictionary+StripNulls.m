//
//  NSMutableDictionary+StripNulls.m
//  TwoFace
//
//  Created by Nathaniel Symer on 9/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSMutableDictionary+StripNulls.h"

@implementation NSMutableDictionary (StripNulls)

/*- (NSDictionary *) dictionaryByReplacingNullsWithStrings {
    NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary:self];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for (NSString *key in self) {
        const id object = [self objectForKey: key];
        
        if (object == nul) {
            [replaced setObject: blank forKey: key];
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            [replaced setObject:[object dictionaryByReplacingNullsWithStrings] forKey:key];
            for (NSString *key in [replaced objectForKey:key]) {
                
                const id object = [[replaced objectForKey:key] objectForKey: key];
                
                if (object == nul) {
                    [replaced setObject: blank forKey: key];
                } else if ([object isKindOfClass:[NSDictionary class]]) {
                    [replaced setObject:[object dictionaryByReplacingNullsWithStrings] forKey:key];
                }
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:replaced];
}*/

// probably the simplest
- (void)removeNullValues3 {
    
    NSString *dictString = [[self description]stringByReplacingOccurrencesOfString:@"\"<null>\"" withString:@"\"\""];
    
    NSData *data = [dictString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError* error;
    NSPropertyListFormat plistFormat;
    NSDictionary *temp = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&plistFormat error:&error];
    NSLog(@"temp: %@",temp);
}

// simpler - enumerate, then modify
- (void)removeNullValues2 {
    
    NSMutableDictionary *theDict = [self mutableCopy];
    
    NSMutableArray *keyPaths = [NSMutableDictionary traverseDictionary:self];
    
    NSLog(@"keyPaths: %@",keyPaths);
    
    for (NSString *key in keyPaths) {
        id obj = [theDict objectForKey:key];
        
        if ([obj isKindOfClass:[NSNull class]]) { // top-level NSNull's
            [theDict setObject:@"FUCKERASDF" forKey:key];
            //[theDict removeObjectForKey:key];
        }
        
        if ([obj isKindOfClass:[NSArray class]]) { // top-level NSArray's
            
            obj = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)obj]; // our main bitch
            
            [obj removeObjectIdenticalTo:[NSNull null]]; // Remove all top level null's
            
            for (id topLevelObj in [obj mutableCopy]) { // dict.path.array
                
                for (id objz in [topLevelObj mutableCopy]) {
                    if ([objz isKindOfClass:[NSArray class]]) {
                        [objz removeObjectIdenticalTo:[NSNull null]];
                    }
                    for (id objx in [objz mutableCopy]) {
                        if ([objx isKindOfClass:[NSArray class]]) {
                            [objx removeObjectIdenticalTo:[NSNull null]];
                        }
                    }
                }
                
                if ([topLevelObj isKindOfClass:[NSArray class]]) {
                    int index = [obj indexOfObject:topLevelObj];
                    [topLevelObj removeObjectIdenticalTo:[NSNull null]];
                    [obj replaceObjectAtIndex:index withObject:topLevelObj];
                }
            }
            
            
            /*for (id topLevelObj in [obj mutableCopy]) { // objects in the "obj" array
                
                if ([topLevelObj isKindOfClass:[NSArray class]]) { // [dict.path.array objectAtIndex:x];
                    [topLevelObj removeObjectIdenticalTo:[NSNull null]];
                    
                }
                
            }*/
        }
    }
    /*
    [theDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setObject:obj forKey:key];
    }];*/
    //NSLog(@"theDict: %@",theDict);
}

// Long and difficult - modify while enumerating
- (void)removeNullValues {
    NSMutableDictionary *theDict = [self mutableCopy];

    NSMutableArray *keys = [NSMutableArray arrayWithArray:[theDict allKeys]];
    
    NSString *currentKeyPath = @"";
    
    for (int i = 0; i < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
        NSLog(@"key: %@",key);
        
        id obj = [theDict valueForKeyPath:key];
        if ([obj isKindOfClass:[NSArray class]]) {
            
            obj = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)obj]; // our main bitch
            
            for (id secondLevelObj in [obj mutableCopy]) {
                if ([secondLevelObj isKindOfClass:[NSNull class]]) {
                    [obj replaceObjectAtIndex:[obj indexOfObject:secondLevelObj] withObject:@"FUCKERASDF"];
                }
            }
            
        } else {
            currentKeyPath = key;
        }

        if ([obj isKindOfClass:[NSNull class]]) {
            NSMutableDictionary *target = theDict;
            NSString *keyPath = @"";
            NSMutableArray *components = [NSMutableArray arrayWithArray:[key componentsSeparatedByString:@"."]];
            [components removeObjectAtIndex:components.count-1];
            for (NSString *keyy in components) {
                target = [target objectForKey:keyy];
                keyPath = [keyPath stringByAppendingFormat:@"%@.",keyy];
            }
            
            NSString *lastKey = [[key componentsSeparatedByString:@"."]lastObject];
            
            if (keyPath.length > 0) {
                
                NSString *lastChar = [keyPath substringFromIndex:1];
                BOOL lastCharIsDot = [lastChar isEqualToString:@"."];
                
                if (lastCharIsDot) {
                    keyPath = [keyPath substringToIndex:keyPath.length-1];
                }
                
               // [target removeObjectForKey:[target.allKeys objectAtIndex:[target.allValues indexOfObject:obj]]];
                [target setObject:@"FUCKASDF" forKey:lastKey];
                [theDict setValue:target forKeyPath:keyPath];
            } else {
                [theDict setObject:@"FUCKASDF" forKey:lastKey];
                //[self removeObjectForKey:[target.allKeys objectAtIndex:[target.allValues indexOfObject:obj]]];
            }
        }
        
        // do an action here...
        
        if (([obj isKindOfClass:[NSDictionary class]]) || ([obj isKindOfClass:[NSNumber class]] && (NSNumber *)obj == 0)) {
            NSMutableDictionary *dicty = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)obj];
            for (int i = 0; i < dicty.allKeys.count; i++) {
                NSString *key = [dicty.allKeys objectAtIndex:i];
                
                NSString *string = [currentKeyPath stringByAppendingFormat:@".%@",key];
                [keys addObject:string];
            }
        }
    }
    NSLog(@"%@",theDict);
}

+ (NSMutableArray *)traverseDictionary:(NSDictionary *)aDictionary {
    
    NSMutableDictionary *theDict = [aDictionary mutableCopy];
    
    NSMutableArray *keys = [NSMutableArray arrayWithArray:[aDictionary allKeys]];
    
    NSString *currentKeyPath = @"";
    
    for (int i = 0; i < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
      //  NSLog(@"key: %@",key);
        
        currentKeyPath = key;
        
        id obj = [theDict valueForKeyPath:key];
        
        // do an action here...
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *dicty = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)obj];
            for (int i = 0; i < dicty.allKeys.count; i++) {
                NSString *key = [dicty.allKeys objectAtIndex:i];

                NSString *string = [currentKeyPath stringByAppendingFormat:@".%@",key];
                [keys addObject:string];
            }
        }
    }
    return keys;
}

@end
