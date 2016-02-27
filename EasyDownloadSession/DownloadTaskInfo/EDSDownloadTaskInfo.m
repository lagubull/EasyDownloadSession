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

/**
 Merges success block of new task with self's.
 
 @param taskInfo - new task.
 */
- (void)coalesceSuccesWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

/**
 Merges failure block of new task with self's.
 
 @param taskInfo - new task.
 */
- (void)coalesceFailureWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

/**
 Merges progress block of new task with self's.
 
 @param taskInfo - new task.
 */
- (void)coalesceProgressWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

@end

@implementation EDSDownloadTaskInfo

#pragma mark - Init

- (instancetype)initWithDownloadID:(NSString *)downloadId
                               URL:(NSURL *)url
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask,NSError *error))failure
{
    self = [super init];
    
    if (self)
    {
        _task = [[EDSDownloadSession downloadSession] downloadTaskWithURL:url];
        _downloadId = downloadId;
        _url = url;
        _downloadProgress = @(0.0);
        _isDownloading = NO;
        _downloadComplete = NO;
        _success = success;
        _progress = progress;
        _failure = failure;
    }
    
    return self;
}


#pragma mark - Pause

- (void)pause
{
    self.isDownloading = NO;
    
    [self.task suspend];
    
    [self.task cancelByProducingResumeData:^(NSData * resumeData)
     {
         self.taskResumeData = [[NSData alloc] initWithData:resumeData];
     }];
}

#pragma mark - Resume

- (void)resume
{
    if (self.taskResumeData.length > 0)
    {
        EDSDebug(@"Resuming task - %@", self.downloadId);
        
        self.task = [[EDSDownloadSession downloadSession] downloadTaskWithResumeData:self.taskResumeData];
    }
    else
    {
        if (self.task.state == NSURLSessionTaskStateCompleted)
        {
            EDSDebug(@"Resuming task - %@", self.downloadId);
            
            //we cancelled this operation before it actually started
            self.task = [[EDSDownloadSession downloadSession] downloadTaskWithURL:self.url];
        }
        else
        {
            EDSDebug(@"Starting task - %@", self.downloadId);
        }
    }
    
    self.isDownloading = YES;
    
    [self.task resume];
}

#pragma mark - Progress

- (void)didUpdateProgress:(NSNumber *)newProgress
{
    self.downloadProgress = newProgress;
    
    if (self.progress)
    {
        self.progress(self);
    }
}

#pragma mark - Coalescing

- (BOOL)canCoalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    return [self.downloadId isEqualToString:taskInfo.downloadId];
}

- (void)coalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    [self coalesceSuccesWithTaskInfo:taskInfo];
    
    [self coalesceFailureWithTaskInfo:taskInfo];
    
    [self coalesceProgressWithTaskInfo:taskInfo];
}

- (void)coalesceSuccesWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^mySuccess)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location) = [_success copy];
    
    void (^theirSuccess)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location) = [taskInfo->_success copy];
    
    if (mySuccess != theirSuccess)
    {
        self.success = ^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location)
        {
            if (mySuccess)
            {
                mySuccess(downloadTask, responseData, location);
            }
            
            if (theirSuccess)
            {
                theirSuccess(downloadTask, responseData, location);
            }
        };
    }
}

- (void)coalesceFailureWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^myFailure)(EDSDownloadTaskInfo *downloadTask, NSError *error) = [_failure copy];
    
    void (^theirFailure)(EDSDownloadTaskInfo *downloadTask, NSError *error) = [taskInfo->_failure copy];
    
    if (myFailure != theirFailure)
    {
        self.failure = ^(EDSDownloadTaskInfo *downloadTask, NSError *error)
        {
            if (myFailure)
            {
                myFailure(downloadTask, error);
            }
            
            if (theirFailure)
            {
                theirFailure(downloadTask, error);
            }
        };
    }
}

- (void)coalesceProgressWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^myProgress)(EDSDownloadTaskInfo *downloadTask) = [_progress copy];
    
    void (^theirProgress)(EDSDownloadTaskInfo *downloadTask) = [taskInfo->_progress copy];
    
    if (myProgress != theirProgress)
    {
        self.progress = ^(EDSDownloadTaskInfo *downloadTask)
        {
            if (myProgress)
            {
                myProgress(downloadTask);
            }
            
            if (theirProgress)
            {
                theirProgress(downloadTask);
            }
        };
    }
}

- (void)releaseMemory
{
    self.downloadProgress = @(0.0);
    self.taskResumeData = nil;
}

@end
