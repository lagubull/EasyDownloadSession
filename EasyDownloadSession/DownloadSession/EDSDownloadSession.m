//
//  EDSDownloadSession.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Constant to indicate cancelled task.
 */
static NSInteger const kEDSCancelled = -999;

static EDSDownloadSession *downloadSession = nil;

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

/**
 Cancels a task.
 
 @param task - task to finalize.
 */
- (void)cancelTask:(EDSDownloadTaskInfo *)task;

/**
 Pauses a task.
 
 @param task - task to finalize.
 */
- (void)pauseTask:(EDSDownloadTaskInfo *)task;

/**
 Adds a downloading task to the stack.
 
 @param downloadId - identifies the download.
 @param request - request for a download.
 @param stackIdentifier - identifies the stack in which this download will be placed into.
 @param progress - to be executed when as the task progresses.
 @param success - to be executed when the task finishes succesfully.
 @param failure - to be executed when the task finishes with an error.
 @param completion - to be executed when the task finishes either with an error or a success.
 */
+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       request:(NSURLRequest *)request
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
                    completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion;

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

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      downloadSession = [[EDSDownloadSession alloc] init];
                      
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
                    completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    
    EDSDownloadTaskInfo *task = [[EDSDownloadTaskInfo alloc] initWithDownloadID:downloadId
                                                                        request:request
                                                                        session:[EDSDownloadSession sharedInstance].session
                                                                stackIdentifier:stackIdentifier
                                                                       progress:progress
                                                                        success:success
                                                                        failure:failure
                                                                     completion:completion];
    
    if (![[EDSDownloadSession sharedInstance] shouldCoalesceDownloadTask:task
                                                         stackIdentifier:stackIdentifier])
    {
        [[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier] push:task];
    }
    
    [EDSDownloadSession resumeDownloadsInStack:stackIdentifier];
}

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       request:(NSURLRequest *)request
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:request
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:nil
                                       failure:nil
                                    completion:completion];
}

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       request:(NSURLRequest *)request
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:request
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:success
                                       failure:failure
                                    completion:nil];
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

+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       fromURL:(NSURL *)url
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:[NSURLRequest requestWithURL:url]
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:nil
                                       failure:nil
                                    completion:completion];
}

#pragma mark - ForceDownload

+ (void)forceDownloadWithId:(NSString *)downloadId
                    request:(NSURLRequest *)request
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                 completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    [EDSDownloadSession pauseDownloadsInStack:stackIdentifier];
    
    NSInteger maxDownloads = ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads;
    
    ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads = 1;
    
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:request
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                    completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
     {
         ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads = maxDownloads;
         
         [EDSDownloadSession resumeDownloadsInStack:downloadTask.stackIdentifier];
         
         if (completion)
         {
             completion(downloadTask, responseData, error);
         }
     }];
}

+ (void)forceDownloadWithId:(NSString *)downloadId
                    request:(NSURLRequest *)request
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
{
    [EDSDownloadSession pauseDownloadsInStack:stackIdentifier];
    
    NSInteger maxDownloads = ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads;
    
    ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads = 1;
    
    [EDSDownloadSession scheduleDownloadWithId:downloadId
                                       request:request
                               stackIdentifier:stackIdentifier
                                      progress:progress
                                       success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
     {
         ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads = maxDownloads;
         
         [EDSDownloadSession resumeDownloadsInStack:downloadTask.stackIdentifier];
         
         if (success)
         {
             success(downloadTask, responseData);
         }
     }
                                       failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
     {
         ((EDSStack *)[EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier]).maxDownloads = maxDownloads;
         
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
                 completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    
    [EDSDownloadSession forceDownloadWithId:downloadId
                                    request:[NSURLRequest requestWithURL:url]
                            stackIdentifier:stackIdentifier
                                   progress:progress
                                 completion:completion];
    
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
        [taskInProgress didUpdateProgress:(double)totalBytesWritten / (double)totalBytesExpectedToWrite];
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

+ (void)cancelDownload:(NSString *)downloadId
       stackIdentifier:(NSString *)stackIdentifier
{
    EDSDownloadTaskInfo * task = [[EDSDownloadSession sharedInstance] taskInfoWithIdentfier:downloadId
                                                                            stackIdentifier:stackIdentifier];
    
    [[EDSDownloadSession sharedInstance] cancelTask:task];
}

+ (void)cancelDownloads
{
    @synchronized([EDSDownloadSession sharedInstance].inProgressDownloadsDictionary)
    {
        for (EDSDownloadTaskInfo *task in [EDSDownloadSession sharedInstance].inProgressDownloadsDictionary)
        {
            [[EDSDownloadSession sharedInstance] cancelTask:task];
        }
    }
    
    for (EDSStack *stack in [[EDSDownloadSession sharedInstance].stackTableDictionary allValues])
    {
        [stack clear];
    }
}

- (void)cancelTask:(EDSDownloadTaskInfo *)task
{
    [task.task cancel];
    
    [[EDSDownloadSession sharedInstance] finalizeTask:task];
}

#pragma mark - Resume

+ (void)resumeDownloads
{
    for (NSString *downloadStackIdentifier in [[EDSDownloadSession sharedInstance].stackTableDictionary allKeys])
    {
        [EDSDownloadSession resumeDownloadsInStack:downloadStackIdentifier];
    }
}

+ (void)resumeDownloadsInStack:(NSString *)downloadStackIdentifier
{
    EDSDownloadTaskInfo *downloadTaskInfo = nil;
    
    EDSStack *downloadStack = [EDSDownloadSession sharedInstance].stackTableDictionary[downloadStackIdentifier];
    
    @synchronized (downloadStack)
    {
        while ([downloadStack canPopTask])
        {
            downloadTaskInfo = [downloadStack pop];
            
            if (downloadTaskInfo)
            {
                if (downloadTaskInfo &&
                    !downloadTaskInfo.isDownloading)
                {
                    [downloadTaskInfo resume];
                    
                    [[EDSDownloadSession sharedInstance].delegate didResumeDownload:downloadTaskInfo];
                }
                
                [[EDSDownloadSession sharedInstance].inProgressDownloadsDictionary setObject:downloadTaskInfo
                                                                                      forKey:@(downloadTaskInfo.task.taskIdentifier)];
            }
        }
    }
}

#pragma mark - Pause

+ (void)pauseDownloadsInStack:(NSString *)stackIndetifier;
{
    for (EDSDownloadTaskInfo *taskInfo in [[EDSDownloadSession sharedInstance].inProgressDownloadsDictionary allValues])
    {
        if ([taskInfo.stackIdentifier isEqualToString:stackIndetifier])
        {
            [[EDSDownloadSession sharedInstance] pauseTask:taskInfo];
        }
    }
}

+ (void)pauseDownloads
{
    for (EDSDownloadTaskInfo *taskInfo in [[EDSDownloadSession sharedInstance].inProgressDownloadsDictionary allValues])
    {
        [[EDSDownloadSession sharedInstance] pauseTask:taskInfo];
    }
}

- (void)pauseTask:(EDSDownloadTaskInfo *)task
{
    EDSDebug(@"Pausing task - %@", task.downloadId);
    
    [task pause];
    
    EDSStack *downloadStack = [EDSDownloadSession sharedInstance].stackTableDictionary[task.stackIdentifier];
    
    @synchronized (downloadStack)
    {
        [downloadStack push:task];
        
        [[EDSDownloadSession sharedInstance] finalizeTask:task];
    }
}

#pragma mark - Coalescing

- (BOOL)shouldCoalesceDownloadTask:(EDSDownloadTaskInfo *)newTaskInfo
                   stackIdentifier:(NSString *)stackIdentifier
{
    BOOL didCoalesce = NO;
    
    for (EDSDownloadTaskInfo *taskInfo in [self.inProgressDownloadsDictionary allValues])
    {
        if ([taskInfo canCoalesceWithTaskInfo:newTaskInfo])
        {
            [taskInfo coalesceWithTaskInfo:newTaskInfo];
            
            didCoalesce = YES;
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
    if ([self.inProgressDownloadsDictionary objectForKey:@(task.task.taskIdentifier)])
    {
        [self.inProgressDownloadsDictionary removeObjectForKey:@(task.task.taskIdentifier)];
        
        ((EDSStack *)self.stackTableDictionary[task.stackIdentifier]).currentDownloads = (((EDSStack *)self.stackTableDictionary[task.stackIdentifier]).currentDownloads - 1);
    }
}

#pragma mark - TaskWithIdentifier

- (EDSDownloadTaskInfo *)taskInfoWithIdentfier:(NSString *)downloadId
                               stackIdentifier:(NSString *)stackIdentifier
{
    EDSDownloadTaskInfo *resultingTask = nil;
    
    EDSDownloadTaskInfo *soughtAfterTask = [[EDSDownloadTaskInfo alloc] init];
    
    soughtAfterTask.downloadId = downloadId;
    
    NSUInteger indexOfTask = [self.inProgressDownloadsDictionary.allValues indexOfObject:soughtAfterTask];
    
    if (indexOfTask == NSNotFound)
    {
        EDSStack *stack = [EDSDownloadSession sharedInstance].stackTableDictionary[stackIdentifier];
        
        indexOfTask = [stack.downloadsArray indexOfObject:soughtAfterTask];
    }
    else
    {
        if (indexOfTask != NSNotFound)
        {
            resultingTask = [self.inProgressDownloadsDictionary.allValues objectAtIndex:indexOfTask];
        }
    }
    
    return resultingTask;
}

@end
