//
//  EDSDownloadTaskInfo.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EDSDownloadTaskInfo.h"

#import "EDSDownloadSession.h"

@interface EDSDownloadTaskInfo ()

@end

@implementation EDSDownloadTaskInfo

#pragma mark - Init

- (instancetype)initWithDownloadID:(NSString *)downloadId
                               URL:(NSURL *)url
                   completionBlock:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error))completionHandler
{
    self = [super init];
    
    if (self)
    {
        _task = [[EDSDownloadSession downloadSession] downloadTaskWithURL:url];
        _downloadId = downloadId;
        _url = url;
        _downloadProgress = 0.0;
        _isDownloading = NO;
        _downloadComplete = NO;
        _completionHandler = completionHandler;
    }
    
    return self;
}


#pragma mark - Pause

- (void)pause
{
    self.isDownloading = NO;
    
    [self.task suspend];
    
    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData)
     {
         self.taskResumeData = [[NSData alloc] initWithData:resumeData];
     }];
}

#pragma mark - Resume

- (void)resume
{
    if (self.taskResumeData.length > 0)
    {
        NSLog(@"Resuming task - %@", self.downloadId);
        
        self.task = [[EDSDownloadSession downloadSession] downloadTaskWithResumeData:self.taskResumeData];
    }
    else
    {
        if (self.task.state == NSURLSessionTaskStateCompleted)
        {
            NSLog(@"Resuming task - %@", self.downloadId);
            
            //we cancelled this operation before it actually started
            self.task = [[EDSDownloadSession downloadSession] downloadTaskWithURL:self.url];
        }
        else
        {
            NSLog(@"Starting task - %@", self.downloadId);
        }
    }
    
    self.isDownloading = YES;
    
    [self.task resume];
}

#pragma mark - Coalescing

- (BOOL)canCoalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    return [self.downloadId isEqualToString:taskInfo.downloadId];
}

- (void)coalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    // Success coalescing
    void (^myCompletionHandler)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error) = [_completionHandler copy];
    void (^theirCompletionHandler)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error) = [taskInfo->_completionHandler copy];
    
    if (myCompletionHandler != theirCompletionHandler)
    {
        self.completionHandler = ^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error)
        {
            if (myCompletionHandler)
            {
                myCompletionHandler(downloadTask, responseData, location, error);
            }
            
            if (theirCompletionHandler)
            {
                theirCompletionHandler(downloadTask, responseData, location, error);
            }
        };
    }
}

@end
