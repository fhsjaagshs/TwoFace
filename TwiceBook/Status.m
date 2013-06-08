//
//  Status.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Status.h"

@implementation Status

- (NSDictionary *)dictionaryValue {
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[_from dictionaryValue], [_to dictionaryValue], _identifier?_identifier:@"", _message?_message:@"", [NSString stringWithFormat:@"%f",_createdAt?[_createdAt timeIntervalSince1970]-1800:0], _type?_type:@"", _url?_url:@"", _subject?_subject:@"", _name?_name:@"", _thumbnailURL?_thumbnailURL:@"", _link?_link:@"", _pictureURL?_pictureURL:@"", _comments?_comments:@"", _actionsAvailable?_actionsAvailable:@"", _objectIdentifier?_objectIdentifier:@"", @"facebook", nil] forKeys:[NSArray arrayWithObjects:@"from", @"to", @"id", @"message", @"updated_time", @"type", @"url", @"subject", @"name", @"picture", @"link", @"embed_html_parsed", @"comments", @"actions_are_available", @"object_id", @"snn", nil]];
}

- (void)parseDictionary:(NSDictionary *)dict {
    self.from = [FacebookUser facebookUserWithDictionary:[dict objectForKey:@"from"]];
    self.to = [FacebookUser facebookUserWithDictionary:[[[dict objectForKey:@"to"]objectForKey:@"data"]firstObjectA]];
    self.identifier = [dict objectForKey:@"id"];
    self.message = [[dict objectForKey:@"message"]stringByTrimmingWhitespace];
    self.createdAt = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"updated_time"]floatValue]+1800];
    self.type = [dict objectForKey:@"type"];
    self.url = [dict objectForKey:@"url"];
    self.subject = [[dict objectForKey:@"subject"]stringByTrimmingWhitespace];
    self.thumbnailURL = [dict objectForKey:@"picture"];
    self.name = [[dict objectForKey:@"name"]stringByTrimmingWhitespace];
    self.link = [dict objectForKey:@"link"];
    self.pictureURL = [dict objectForKey:@"source"];
    
    NSString *htmlString = [dict objectForKey:@"embed_html"];
    
    if (htmlString.length > 0) {
        NSString *tempURL = nil;
        NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
        [theScanner scanUpToString:@"<iframe" intoString:nil];
        if (![theScanner isAtEnd]) {
            [theScanner scanUpToString:@"src" intoString:nil];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
            [theScanner scanUpToCharactersFromSet:charset intoString:nil];
            [theScanner scanCharactersFromSet:charset intoString:nil];
            [theScanner scanUpToCharactersFromSet:charset intoString:&tempURL];
            
            if (tempURL.length > 0) {
                self.link = tempURL;
            }
        }
    }
    
    if (_link.length == 0) {
        self.link = [dict objectForKey:@"embed_html_parsed"];
    }
    
    NSArray *actions = (NSArray *)[dict objectForKey:@"actions"];
    
    if (actions) {
        self.actionsAvailable = (actions.count > 0)?@"yes":@"no";
    } else {
        self.actionsAvailable = [dict objectForKey:@"actions_are_available"];
    }
    
    self.objectIdentifier = [dict objectForKey:@"object_id"];
    
    if (_message.length == 0) {
        NSString *story = [dict objectForKey:@"story"];
        NSString *description = [dict objectForKey:@"description"];
        
        if (description.length > 0) {
            self.message = description;
        } else if (story.length > 0) {
            self.message = story;
        }
    }
    
    if ([_type isEqualToString:@"link"]) {
        _message = [dict objectForKey:@"story"];
    }
    
    self.message = [_message stringByTrimmingWhitespace];
    
    self.comments = [NSMutableArray arrayWithArray:[dict objectForKey:@"comments"]];
    
    /*
     NSMutableDictionary *restructured = [[NSMutableDictionary alloc]init];
     
     NSString *toID = [[[[post objectForKey:@"to"]objectForKey:@"data"]firstObjectA]objectForKey:@"id"];
     NSString *toName = [[[[post objectForKey:@"to"]objectForKey:@"data"]firstObjectA]objectForKey:@"name"];
     NSString *objectID = [post objectForKey:@"object_id"];
     NSString *imageIcon = [post objectForKey:@"icon"];
     NSString *fromName = [[post objectForKey:@"from"]objectForKey:@"name"];
     NSString *fromID = [[post objectForKey:@"from"]objectForKey:@"id"];
     NSString *message = [[post objectForKey:@"message"]stringByTrimmingWhitespace];
     NSString *type = [post objectForKey:@"type"];
     NSString *imageURL = [post objectForKey:@"picture"];
     NSString *link = [post objectForKey:@"link"];
     NSString *linkName = [post objectForKey:@"name"];
     NSString *linkCaption = [post objectForKey:@"caption"];
     NSString *linkDescription = [post objectForKey:@"description"];
     NSString *actionsAvailable = ([(NSArray *)[post objectForKey:@"actions"]count] > 0)?@"yes":@"no";
     NSString *postID = [post objectForKey:@"id"];
     NSDate *created_time = [NSDate dateWithTimeIntervalSince1970:[[post objectForKey:@"updated_time"]floatValue]+1800];
     
     [restructured setValue:toID forKey:@"to_id"];
     [restructured setValue:toName forKey:@"to_name"];
     [restructured setValue:objectID forKey:@"object_id"];
     [restructured setValue:imageIcon forKey:@"icon"];
     [restructured setValue:postID forKey:@"id"];
     [restructured setValue:type forKey:@"type"];
     [restructured setValue:created_time forKey:@"poster_created_time"];
     [restructured setValue:fromName forKey:@"poster_name"];
     [restructured setValue:fromID forKey:@"poster_id"];
     [restructured setValue:message forKey:@"message"];
     [restructured setValue:imageURL forKey:@"image_url"];
     [restructured setValue:link forKey:@"link"];
     [restructured setValue:linkName forKey:@"link_name"];
     [restructured setValue:linkCaption forKey:@"link_caption"];
     [restructured setValue:linkDescription forKey:@"link_description"];
     [restructured setValue:actionsAvailable forKey:@"actions_available"];
     */
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self parseDictionary:dict];
    }
    return self;
}

+ (Status *)statusWithDictionary:(NSDictionary *)dict {
    return [[[self class]alloc]initWithDictionary:dict];
}

@end
