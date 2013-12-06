//
//  DroppingBadassBlocks.m
//  DroppingBadassBlocks
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DroppinBadassBlocks.h"
#import <DropboxSDK/DBRestClient.h>

@interface DroppinBadassBlocks () <DBRestClientDelegate>

@property (nonatomic, copy) id uploadBlock;
@property (nonatomic, copy) id uploadProgressBlock;
@property (nonatomic, copy) id deltaBlock;
@property (nonatomic, copy) id linkBlock;
@property (nonatomic, copy) id downloadBlock;
@property (nonatomic, copy) id downloadProgressBlock;
@property (nonatomic, copy) id metadataBlock;
@property (nonatomic, copy) id accountInfoBlock;
@property (nonatomic, copy) id streamableURLBlock;
@property (nonatomic, copy) id deletionBlock;

@end

@implementation DroppinBadassBlocks

+ (DroppinBadassBlocks *)sharedInstance {
    static DroppinBadassBlocks *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[DroppinBadassBlocks alloc]initWithSession:[DBSession sharedSession]];
        shared.delegate = shared;
    });
    
    return shared;
}

//
// Uploading
//

+ (void)uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev fromPath:(NSString *)sourcePath withBlock:(void(^)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(CGFloat progress, NSString *destPath, NSString *scrPath))pBlock {
    [[DroppinBadassBlocks sharedInstance]setUploadBlock:block];
    [[DroppinBadassBlocks sharedInstance]setUploadProgressBlock:pBlock];
    [[DroppinBadassBlocks sharedInstance]uploadFile:filename toPath:path withParentRev:parentRev fromPath:sourcePath];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    void(^block)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]uploadBlock];
    block(destPath, srcPath, metadata, nil);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    void(^block)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]uploadBlock];
    block(nil, nil, nil, error);
}

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    void(^block)(CGFloat progress, NSString *destPath, NSString *scrPath) = [[DroppinBadassBlocks sharedInstance]uploadProgressBlock];
    block(progress, destPath, srcPath);
}

//
// Delta
//

+ (void)loadDelta:(NSString *)cursor withCompletionHandler:(void(^)(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setDeltaBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadDelta:cursor];
}

- (void)restClient:(DBRestClient *)client loadedDeltaEntries:(NSArray *)entries reset:(BOOL)shouldReset cursor:(NSString *)cursor hasMore:(BOOL)hasMore {
    void(^block)(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error) = [[DroppinBadassBlocks sharedInstance]deltaBlock];
    block(entries, cursor, hasMore, shouldReset, nil);
}

- (void)restClient:(DBRestClient *)client loadDeltaFailedWithError:(NSError *)error {
    void(^block)(NSArray *entries, NSString *cursor, NSError *error) = [[DroppinBadassBlocks sharedInstance]deltaBlock];
    block(nil, nil, error);
}

//
// Links
//

+ (void)loadStreamableURLForFile:(NSString *)path andCompletionBlock:(void(^)(NSURL *url, NSString *path, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setStreamableURLBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadStreamableURLForFile:path];
}

+ (void)loadSharableLinkForFile:(NSString *)path andCompletionBlock:(void(^)(NSString *link, NSString *path, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setLinkBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadSharableLinkForFile:path shortUrl:YES];
}

- (void)restClient:(DBRestClient *)restClient loadedStreamableURL:(NSURL *)url forFile:(NSString *)path {
    void(^block)(NSURL *url, NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]streamableURLBlock];
    block(url, path, nil);
}

- (void)restClient:(DBRestClient *)restClient loadStreamableURLFailedWithError:(NSError *)error {
    void(^block)(NSURL *url, NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]streamableURLBlock];
    block(nil, nil, error);
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    void(^block)(NSString *link, NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]linkBlock];
    block(link, path, nil);
}

- (void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error {
    void(^block)(NSString *link, NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]linkBlock];
    block(nil, nil, error);
}

//
// File Downloading
//

+ (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(float progress))progBlock {
    [[DroppinBadassBlocks sharedInstance]setDownloadBlock:block];
    [[DroppinBadassBlocks sharedInstance]setDownloadProgressBlock:progBlock];
    [[DroppinBadassBlocks sharedInstance]loadFile:path intoPath:destinationPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    void(^block)(DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]downloadBlock];
    block(metadata, nil);
}

- (void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath {
    void(^block)(float progress) = [[DroppinBadassBlocks sharedInstance]downloadProgressBlock];
    block(progress);
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    void(^block)(DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]downloadBlock];
    block(nil, error);
}

//
// Metadata
//

+ (void)loadMetadata:(NSString *)path withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setMetadataBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadMetadata:path];
}

- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setMetadataBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadMetadata:path atRev:rev];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    void(^metadataBlock)(DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]metadataBlock];
    metadataBlock(metadata, nil);
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError *)error {
    void(^metadataBlock)(DBMetadata *metadata, NSError *error) = [[DroppinBadassBlocks sharedInstance]metadataBlock];
    metadataBlock(nil, error);
}

//
// Delete Files
//

+ (void)deletePath:(NSString *)path completionHandler:(void(^)(NSString *path, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setDeletionBlock:block];
    [[DroppinBadassBlocks sharedInstance]deletePath:path];
}

- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
    void(^deletionBlock)(NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]deletionBlock];
    deletionBlock(path,nil);
}

- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
    void(^deletionBlock)(NSString *path, NSError *error) = [[DroppinBadassBlocks sharedInstance]deletionBlock];
    deletionBlock(nil,error);
}

/*+ (void)loadMetadata:(NSString *)path withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setMetadataBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadMetadata:path];
}*/

//
// Account Info Loading
//

+ (void)loadAccountInfoWithCompletionBlock:(void(^)(DBAccountInfo *info, NSError *error))block {
    [[DroppinBadassBlocks sharedInstance]setAccountInfoBlock:block];
    [[DroppinBadassBlocks sharedInstance]loadAccountInfo];
}

- (void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    void(^block)(DBAccountInfo *, NSError *) = [[DroppinBadassBlocks sharedInstance]accountInfoBlock];
    block(info, nil);
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error {
    void(^block)(DBAccountInfo *, NSError *) = [[DroppinBadassBlocks sharedInstance]accountInfoBlock];
    block(nil, error);
}

//
// Cancellation
//

/*+ (BOOL)cancelShareableLinkLoadWithDropboxPath:(NSString *)dbPath {
    return [[DroppinBadassBlocks sharedInstance]cancelSharableLinkLoadWithDropboxPath:dbPath];
}

+ (BOOL)cancelDownloadWithDropboxPath:(NSString *)dbPath {
    return [[DroppinBadassBlocks sharedInstance]cancelDownloadWithDropboxPath:dbPath];
}

+ (BOOL)cancelUploadWithDropboxPath:(NSString *)dbPath {
    return [[DroppinBadassBlocks sharedInstance]cancelUploadWithDropboxPath:dbPath];
}

+ (int)cancelAllDownloads {
    return [[DroppinBadassBlocks sharedInstance]cancelAllDownloads];
}

+ (int)cancelAllMiscRequests {
    return [[DroppinBadassBlocks sharedInstance]cancelAllMiscRequests];
}*/

+ (int)cancel {
    float requestCount = [[DroppinBadassBlocks sharedInstance]requestCount];
    [[DroppinBadassBlocks sharedInstance]cancelAllRequests];
    return requestCount;
}
            
@end
