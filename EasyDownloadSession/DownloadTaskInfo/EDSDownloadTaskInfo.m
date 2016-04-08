//
//  EDSDownloadTaskInfo.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

@interface EDSDownloadTaskInfo ()

/**
 Block to be executed upon success.
 */
@property (nonatomic, copy) void (^success)(EDSDownloadTaskInfo *downloadTask, NSData *responseData);

/**
 Block to be executed upon error.
 */
@property (nonatomic, copy) void (^failure)(EDSDownloadTaskInfo *downloadTask, NSError *error);

/**
 Block to be executed upon progress.
 */
@property (nonatomic, copy) void (^progress)(EDSDownloadTaskInfo *downloadTask);

/**
 Block to be executed upon finishing.
 */
@property (nonatomic, copy) void (^completion)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error);

/**
 Internal callback queue to make sure callbacks execute on same queue task is created on.
 */
@property (nonatomic, strong) NSOperationQueue *callbackQueue;

/**
 Session that will own the task.
 */
@property (nonatomic, strong) NSURLSession *session;

/**
 Request for a download.
 */
@property (nonatomic, strong) NSURLRequest *request;

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

/**
 Merges completion block of new task with self's.
 
 @param taskInfo - new task.
 */
- (void)coalesceCompletionWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

@end

@implementation EDSDownloadTaskInfo

#pragma mark - Init

- (instancetype)initWithDownloadID:(NSString *)downloadId
                           request:(NSURLRequest *)request
                           session:(NSURLSession *)session
                   stackIdentifier:(NSString *)stackIdentifier
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
                        completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    self = [super init];
    
    if (self)
    {
        _task = [session downloadTaskWithRequest:request];
        _session = session;
        _downloadId = downloadId;
        _request = request;
        _stackIdentifier = stackIdentifier;
        _downloadProgress = 0.0;
        _isDownloading = NO;
        _downloadComplete = NO;
        _success = success;
        _progress = progress;
        _failure = failure;
        _completion = completion;
        _callbackQueue = [NSOperationQueue currentQueue];
    }
    
    return self;
}

- (instancetype)initWithDownloadID:(NSString *)downloadId
                               URL:(NSURL *)url
                           session:(NSURLSession *)session
                   stackIdentifier:(NSString *)stackIdentifier
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
                        completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion
{
    return [self initWithDownloadID:downloadId
                            request:[NSURLRequest requestWithURL:url]
                            session:session
                    stackIdentifier:stackIdentifier
                           progress:progress
                            success:success
                            failure:failure
                         completion:completion];
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
        
        self.task = [self.session downloadTaskWithResumeData:self.taskResumeData];
    }
    else
    {
        if (self.task.state == NSURLSessionTaskStateCompleted)
        {
            EDSDebug(@"Resuming task - %@", self.downloadId);
            
            //we cancelled this operation before it actually started
            self.task = [self.session downloadTaskWithRequest:self.request];
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

- (void)didUpdateProgress:(CGFloat)newProgress
{
    self.downloadProgress = newProgress;
    
    if (self.progress)
    {
        [self.callbackQueue addOperationWithBlock:^
         {
             self.progress(self);
         }];
    }
}

#pragma mark - Success

- (void)didSucceedWithLocation:(NSURL *)location
{
    NSData *data = [NSData dataWithContentsOfFile:[location path]];
    
    if (self.success)
    {
        if (data.length > 0)
        {
            [self.callbackQueue addOperationWithBlock:^
             {
                 self.success(self, data);
             }];
        }
        else
        {
            [self didFailWithError:nil];
        }
    }
    else if (self.completion)
    {
        [self.callbackQueue addOperationWithBlock:^
         {
             self.completion(self, data, nil);
         }];
    }
}

#pragma mark - Failure

- (void)didFailWithError:(NSError *)error
{
    if (self.failure)
    {
        [self.callbackQueue addOperationWithBlock:^
         {
             self.failure(self, error);
         }];
    }
    else if (self.completion)
    {
        [self.callbackQueue addOperationWithBlock:^
         {
             self.completion(self, nil, error);
         }];
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
    
    [self coalesceCompletionWithTaskInfo:taskInfo];
}

- (void)coalesceSuccesWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^mySuccess)(EDSDownloadTaskInfo *downloadTask, NSData *responseData) = [_success copy];
    
    void (^theirSuccess)(EDSDownloadTaskInfo *downloadTask, NSData *responseData) = [taskInfo->_success copy];
    
    if (mySuccess ||
        theirSuccess)
    {
        self.success = ^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
        {
            if (mySuccess)
            {
                mySuccess(downloadTask, responseData);
            }
            
            if (theirSuccess)
            {
                theirSuccess(downloadTask, responseData);
            }
        };
    }
}

- (void)coalesceFailureWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^myFailure)(EDSDownloadTaskInfo *downloadTask, NSError *error) = [_failure copy];
    
    void (^theirFailure)(EDSDownloadTaskInfo *downloadTask, NSError *error) = [taskInfo->_failure copy];
    
    if (myFailure ||
        theirFailure)
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
    
    if (myProgress ||
        theirProgress)
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

- (void)coalesceCompletionWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    void (^myCompletion)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error) = [_completion copy];
    
    void (^theirCompletion)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error ) = [taskInfo->_completion copy];
    
    if (myCompletion ||
        theirCompletion)
    {
        self.completion = ^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
        {
            if (myCompletion)
            {
                myCompletion(downloadTask, responseData, error);
            }
            
            if (theirCompletion)
            {
                theirCompletion(downloadTask, responseData, error);
            }
        };
    }
}

#pragma mark - IsEqual

- (BOOL)isEqual:(id)object
{
    BOOL equals = NO;
    
    if ([object isKindOfClass:self.class])
    {
        if ([((EDSDownloadTaskInfo *)object).downloadId isEqualToString:self.downloadId])
        {
            equals = YES;
        }
    }
    
    return equals;
}

#pragma mark - ReleaseMemory

- (void)releaseMemory
{
    self.downloadProgress = 0.0;
    self.taskResumeData = nil;
}

@end
