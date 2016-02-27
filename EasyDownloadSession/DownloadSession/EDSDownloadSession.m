//
//  EDSDownloadSession.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EDSDownloadSession.h"

#import <UIKit/UIKit.h>

#import "EDSStack.h"
#import "EDSDownloadTaskInfo.h"


#ifdef DEBUG
#define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...)
#endif

/**
 Constant to indicate cancelled task.
 */
static NSInteger const kCancelled = -999;

@interface EDSDownloadSession () <NSURLSessionDownloadDelegate>

/**
 Stack to store the pending downloads.
 */
@property (nonatomic, strong) EDSStack *downloadStack;

/**
 Current download.
 */
@property (nonatomic, strong) EDSDownloadTaskInfo *inProgressDownload;

/**
 Current downloads.
 */
@property (nonatomic, strong) NSMutableDictionary *inProgressDownloadsDictionary;

/**
 Session Object.
 */
@property (nonatomic, strong) NSURLSession *session;

/**
 Tries to coales the operation.
 
 @param newTaskInfo - new task to coalesce.
 
 @result YES - If the taskInfo is coalescing, NO otherwise
 */
- (BOOL)shouldCoalesceDownloadTask:(EDSDownloadTaskInfo *)newTaskInfo;

@end

@implementation EDSDownloadSession

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"kEDSBackgroundEasyDownloadSessionConfigurationIdentifier"];
        
        [configuration setHTTPMaximumConnectionsPerHost:10];
        
        self.session = [NSURLSession sessionWithConfiguration:configuration
                                                     delegate:self
                                                delegateQueue:[NSOperationQueue mainQueue]];
        
        _downloadStack = [[EDSStack alloc] init];
        _inProgressDownloadsDictionary = [[NSMutableDictionary alloc] init];
        _maxDownloads = @(1);
    }
    
    return self;
}

+ (EDSDownloadSession *)downloadSession
{
    static EDSDownloadSession *downloadSession = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      downloadSession = [[self alloc] init];
                      
                      [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                                        object:nil
                                                                         queue:[NSOperationQueue mainQueue]
                                                                    usingBlock:^(NSNotification * __unused notification)
                       {
                           [downloadSession.downloadStack releaseMemory];
                       }];
                  });
    
    return downloadSession;
}

#pragma mark - ScheduleDownload

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       fromURL:(NSURL *)url
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask,NSError *error))failure
{
    EDSDownloadTaskInfo *task = [[EDSDownloadTaskInfo alloc] initWithDownloadID:downloadId
                                                                            URL:url
                                                                       progress:progress
                                                                        success:success
                                                                        failure:failure];
    
    if (![[EDSDownloadSession downloadSession] shouldCoalesceDownloadTask:task])
    {
        [[EDSDownloadSession downloadSession].downloadStack push:task];
    }
    
    [EDSDownloadSession resumeDownloads];
}

#pragma mark - ForceDownload

+ (void)forceDownloadWithId:(NSString *)downloadId
                    fromURL:(NSURL *)url
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask,NSError *error))failure
{
    [EDSDownloadSession pauseDownloads];
    
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       fromURL:url
                                      progress:progress
                                       success:success
                                       failure:failure];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    EDSDownloadTaskInfo *taskInProgress = [self.inProgressDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    
    if (taskInProgress)
    {
        if (taskInProgress.success)
        {
            NSData * data  = [NSData dataWithContentsOfFile:[location path]];
            
            taskInProgress.success(self.inProgressDownload, data, location);
        }
        
        [self.inProgressDownloadsDictionary removeObjectForKey:@(downloadTask.taskIdentifier)];
        
        [EDSDownloadSession resumeDownloads];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    EDSDownloadTaskInfo *taskInProgress = [self.inProgressDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    
    if (taskInProgress)
    {
        [taskInProgress didUpdateProgress:[NSNumber numberWithDouble:(double)totalBytesWritten / (double)totalBytesExpectedToWrite]];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error &&
        error.code != kCancelled)
    {
        EDSDownloadTaskInfo *taskInProgress = [self.inProgressDownloadsDictionary objectForKey:@(task.taskIdentifier)];
        
        if (taskInProgress &&
            taskInProgress.failure)
        {
            taskInProgress.failure(self.inProgressDownload, error);
        }
        
        //  Handle error
        NSLog(@"task: %@ Error: %@", taskInProgress.downloadId, error);
        
        [self.inProgressDownloadsDictionary removeObjectForKey:@(task.taskIdentifier)];
        
        [EDSDownloadSession resumeDownloads];
    }
}

#pragma mark - Cancel

+ (void)cancelDownloads
{
    [[EDSDownloadSession downloadSession].inProgressDownload.task cancel];
    [EDSDownloadSession downloadSession].inProgressDownload = nil;
    [[EDSDownloadSession downloadSession].downloadStack clear];
}

#pragma mark - Resume

+ (void)resumeDownloads
{
    EDSDownloadTaskInfo *downloadTaskInfo = nil;
    
    if ([EDSDownloadSession downloadSession].inProgressDownloadsDictionary.count < [EDSDownloadSession downloadSession].maxDownloads.integerValue)
    {
        downloadTaskInfo = [[EDSDownloadSession downloadSession].downloadStack pop];
        
        if (downloadTaskInfo)
        {
            [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary setObject:downloadTaskInfo
                                                                                   forKey:@(downloadTaskInfo.task.taskIdentifier)];
        }
    }
    
    if (downloadTaskInfo &&
        !downloadTaskInfo.isDownloading)
    {
        [downloadTaskInfo resume];
        
        [[EDSDownloadSession downloadSession].delegate didResumeDownload:[EDSDownloadSession downloadSession].inProgressDownload];
    }
}

#pragma mark - Pause

+ (void)pauseDownloads
{
    if ([EDSDownloadSession downloadSession].inProgressDownloadsDictionary.count > 0)
    {
        for (EDSDownloadTaskInfo *taskInfo in [EDSDownloadSession downloadSession].inProgressDownloadsDictionary)
        {
            DLog(@"Pausing task - %@", taskInfo.downloadId);
            
            [taskInfo pause];
            
            [[EDSDownloadSession downloadSession].downloadStack push:[EDSDownloadSession downloadSession].inProgressDownload];
            
            [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary removeObjectForKey:@(taskInfo.task.taskIdentifier)];
        }
    }
}

#pragma mark - NSURLSessionDownloadTask

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url
{
    return [[EDSDownloadSession downloadSession].session downloadTaskWithURL:url];
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
{
    return [[EDSDownloadSession downloadSession].session downloadTaskWithResumeData:resumeData];
}

#pragma mark - Coalescing

- (BOOL)shouldCoalesceDownloadTask:(EDSDownloadTaskInfo *)newTaskInfo
{
    BOOL didCoalesce = NO;
    
    if ([EDSDownloadSession downloadSession].inProgressDownloadsDictionary.count > 0)
    {
        for (EDSDownloadTaskInfo *taskInfo in [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary allValues])
        {
            if ([taskInfo canCoalesceWithTaskInfo:newTaskInfo])
            {
                [taskInfo coalesceWithTaskInfo:newTaskInfo];
                
                didCoalesce = YES;
            }
        }
    }
    
    if (!didCoalesce)
    {
        for (EDSDownloadTaskInfo *taskInfo in self.downloadStack.downloadsArray)
        {
            BOOL canAskToCoalesce = [taskInfo isKindOfClass:[EDSDownloadTaskInfo class]];
            
            if (canAskToCoalesce &&
                [taskInfo canCoalesceWithTaskInfo:newTaskInfo])
            {
                [taskInfo coalesceWithTaskInfo:newTaskInfo];
                
                didCoalesce = YES;
                
                break;
            }
        }
    }
    
    return didCoalesce;
}

@end
