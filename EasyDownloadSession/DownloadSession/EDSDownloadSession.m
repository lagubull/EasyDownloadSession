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

/**
 Constant to indicate cancelled task.
 */
static NSInteger const kEDSCancelled = -999;

@interface EDSDownloadSession () <NSURLSessionDownloadDelegate>

/**
 Background Session Object.
 */
@property (nonatomic, strong) NSURLSession *backgroundSession;

/**
 Current downloads.
 */
@property (nonatomic, strong) NSMutableDictionary *inProgressDownloadsDictionary;

/**
 Default Session Object.
 */
@property (nonatomic, strong) NSURLSession *defaultSession;

/**
 Mutable Dictionary of stacks.
 */
@property (nonatomic, strong) NSMutableDictionary *mutableStackTableDictionary;

/**
 Tries to coales the operation.
 
 @param newTaskInfo - new task to coalesce.
 
 @result YES - If the taskInfo is coalescing, NO otherwise.
 */
- (BOOL)shouldCoalesceDownloadTask:(EDSDownloadTaskInfo *)newTaskInfo
                   stackIdentifier:(NSString *)stackIdentifier;

/**
 Auxiliar session Object either background or default.
 */
- (NSURLSession *)session;

/**
 Dictionary of stacks.
 */
- (NSDictionary *)stackTableDictionary;

/**
 Convenience method called when a task finishes executing for any reason.
 
 @param task - task to finalize.
 */
- (void)finalizeTask:(EDSDownloadTaskInfo *)task;

@end

@implementation EDSDownloadSession

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSURLSessionConfiguration *backgrounfConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"kEDSBackgroundEasyDownloadSessionConfigurationIdentifier"];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        [backgrounfConfiguration setHTTPMaximumConnectionsPerHost:100];
        
        [configuration setHTTPMaximumConnectionsPerHost:100];
        
        self.defaultSession = [NSURLSession sessionWithConfiguration:configuration
                                                            delegate:self
                                                       delegateQueue:[NSOperationQueue mainQueue]];
        
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgrounfConfiguration
                                                               delegate:self
                                                          delegateQueue:[NSOperationQueue mainQueue]];
        
        _mutableStackTableDictionary = [[NSMutableDictionary alloc] init];
        _inProgressDownloadsDictionary = [[NSMutableDictionary alloc] init];
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
                           for (EDSStack *stack in [downloadSession.stackTableDictionary allValues])
                           {
                               [stack releaseMemory];
                           }
                       }];
                  });
    
    return downloadSession;
}

#pragma mark - StackTableDictionary

- (NSDictionary *)stackTableDictionary
{
    return [self.mutableStackTableDictionary copy];
}

#pragma mark - Register

- (void)registerStack:(EDSStack *)stack
      stackIdentifier:(NSString *)stackIdentifier
{
    self.mutableStackTableDictionary[stackIdentifier] = stack;
}

#pragma mark - Session

- (NSURLSession *)session
{
    return _defaultSession;
}

#pragma mark - ScheduleDownload

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       request:(NSURLRequest *)request
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    EDSDownloadTaskInfo *task = [[EDSDownloadTaskInfo alloc] initWithDownloadID:downloadId
                                                                        request:request
                                                                        session:[EDSDownloadSession downloadSession].session
                                                                stackIdentifier:stackIdentifier
                                                                       progress:progress
                                                                        success:success
                                                                        failure:failure];
    
    if (![[EDSDownloadSession downloadSession] shouldCoalesceDownloadTask:task
                                                          stackIdentifier:stackIdentifier])
    {
        [[EDSDownloadSession downloadSession].stackTableDictionary[stackIdentifier] push:task];
    }
    
    [EDSDownloadSession resumeDownloadsInStack:stackIdentifier];
}

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       fromURL:(NSURL *)url
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:[NSURLRequest requestWithURL:url]
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:success
                                       failure:failure];
}

#pragma mark - ForceDownload

+ (void)forceDownloadWithId:(NSString *)downloadId
                    request:(NSURLRequest *)request
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    [EDSDownloadSession pauseDownloadsInStack:stackIdentifier];
    
    NSNumber *maxDownloads = ((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[stackIdentifier]).maxDownloads;
    
    ((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[stackIdentifier]).maxDownloads = @(1);
    
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:request
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
     {
         ((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[stackIdentifier]).maxDownloads = maxDownloads;
         
         [EDSDownloadSession resumeDownloadsInStack:downloadTask.stackIdentifier];
         
         if (success)
         {
             success(downloadTask, responseData);
         }
     }
                                       failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
     {
         ((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[stackIdentifier]).maxDownloads = maxDownloads;
         
         [EDSDownloadSession resumeDownloadsInStack:downloadTask.stackIdentifier];
         
         if (failure)
         {
             failure(downloadTask, error);
         }
     }];
}

+ (void)forceDownloadWithId:(NSString *)downloadId
                    fromURL:(NSURL *)url
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    [EDSDownloadSession forceDownloadWithId:downloadId
                                    request:[NSURLRequest requestWithURL:url]
                            stackIdentifier:stackIdentifier
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
        [taskInProgress didSucceedWithLocation:location];
        
        [self finalizeTask:taskInProgress];
        
        [EDSDownloadSession resumeDownloadsInStack:taskInProgress.stackIdentifier];
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
        error.code != kEDSCancelled)
    {
        EDSDownloadTaskInfo *taskInProgress = [self.inProgressDownloadsDictionary objectForKey:@(task.taskIdentifier)];
        
        [taskInProgress didFailWithError:(NSError *)error];
        
        //  Handle error
        NSLog(@"task: %@ Error: %@", taskInProgress.downloadId, error);
        
        [self finalizeTask:taskInProgress];
        
        [EDSDownloadSession resumeDownloadsInStack:taskInProgress.stackIdentifier];
    }
}

#pragma mark - Cancel

+ (void)cancelDownloads
{
    @synchronized([EDSDownloadSession downloadSession].inProgressDownloadsDictionary)
    {
        for (EDSDownloadTaskInfo *task in [EDSDownloadSession downloadSession].inProgressDownloadsDictionary)
        {
            [task.task cancel];
            
            [[EDSDownloadSession downloadSession] finalizeTask:task];
        }
    }
    
    for (EDSStack *stack in [[EDSDownloadSession downloadSession].stackTableDictionary allValues])
    {
        [stack clear];
    }
}

#pragma mark - Resume

+ (void)resumeDownloads
{
    for (NSString *downloadStackIdentifier in [[EDSDownloadSession downloadSession].stackTableDictionary allKeys])
    {
        [EDSDownloadSession resumeDownloadsInStack:downloadStackIdentifier];
    }
}

+ (void)resumeDownloadsInStack:(NSString *)downloadStackIdentifier
{
    EDSDownloadTaskInfo *downloadTaskInfo = nil;
    
    EDSStack *downloadStack = [EDSDownloadSession downloadSession].stackTableDictionary[downloadStackIdentifier];
    
    while ([downloadStack canPopTask])
    {
        downloadTaskInfo = [downloadStack pop];
        
        if (downloadTaskInfo)
        {
            if (downloadTaskInfo &&
                !downloadTaskInfo.isDownloading)
            {
                [downloadTaskInfo resume];
                
                [[EDSDownloadSession downloadSession].delegate didResumeDownload:downloadTaskInfo];
            }
            
            [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary setObject:downloadTaskInfo
                                                                                   forKey:@(downloadTaskInfo.task.taskIdentifier)];
        }
    }
}

#pragma mark - Pause

+ (void)pauseDownloadsInStack:(NSString *)stackIndetifier;
{
    if ([EDSDownloadSession downloadSession].inProgressDownloadsDictionary.count > 0)
    {
        for (EDSDownloadTaskInfo *taskInfo in [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary allValues])
        {
            if ([taskInfo.stackIdentifier isEqualToString:stackIndetifier])
            {
                EDSDebug(@"Pausing task - %@", taskInfo.downloadId);
                
                [taskInfo pause];
                
                [((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[taskInfo.stackIdentifier]) push:taskInfo];
                
                [[EDSDownloadSession downloadSession] finalizeTask:taskInfo];
            }
        }
    }
}

+ (void)pauseDownloads
{
    if ([EDSDownloadSession downloadSession].inProgressDownloadsDictionary.count > 0)
    {
        for (EDSDownloadTaskInfo *taskInfo in [[EDSDownloadSession downloadSession].inProgressDownloadsDictionary allValues])
        {
            EDSDebug(@"Pausing task - %@", taskInfo.downloadId);
            
            [taskInfo pause];
            
            [((EDSStack *)[EDSDownloadSession downloadSession].stackTableDictionary[taskInfo.stackIdentifier]) push:taskInfo];
            
            [[EDSDownloadSession downloadSession] finalizeTask:taskInfo];
        }
    }
}

#pragma mark - Coalescing

- (BOOL)shouldCoalesceDownloadTask:(EDSDownloadTaskInfo *)newTaskInfo
                   stackIdentifier:(NSString *)stackIdentifier
{
    BOOL didCoalesce = NO;
    
    if (self.inProgressDownloadsDictionary.count > 0)
    {
        for (EDSDownloadTaskInfo *taskInfo in [self.inProgressDownloadsDictionary allValues])
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
        for (EDSDownloadTaskInfo *taskInfo in ((EDSStack *)self.stackTableDictionary[stackIdentifier]).downloadsArray)
        {
            BOOL canAskToCoalesce = [taskInfo isKindOfClass:[EDSDownloadTaskInfo class]];
            
            if (canAskToCoalesce &&
                [newTaskInfo canCoalesceWithTaskInfo:taskInfo])
            {
                [newTaskInfo coalesceWithTaskInfo:taskInfo];
                
                [((EDSStack *)self.stackTableDictionary[stackIdentifier]) removeTaskInfo:taskInfo];
                
                break;
            }
        }
    }
    
    return didCoalesce;
}

#pragma mark - Finalize

- (void)finalizeTask:(EDSDownloadTaskInfo *)task
{
    [self.inProgressDownloadsDictionary removeObjectForKey:@(task.task.taskIdentifier)];
    
    ((EDSStack *)self.stackTableDictionary[task.stackIdentifier]).currentDownloads = @(((EDSStack *)self.stackTableDictionary[task.stackIdentifier]).currentDownloads.integerValue - 1);
}

@end
