//
//  EDSDownloadTaskInfo.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents a download task and its metadata.
 */
@interface EDSDownloadTaskInfo : NSObject

/**
 Identifies the object.
 */
@property (nonatomic, strong) NSString *downloadId;

/**
 Data already downloaded.
 */
@property (nonatomic, strong) NSData *taskResumeData;

/**
 Progress of the download.
 */
@property (nonatomic, assign) NSNumber *downloadProgress;

/**
 Indicates whethere the task is executing.
 */
@property (nonatomic, assign) BOOL isDownloading;

/**
 Indicates where the download has finished.
 */
@property (nonatomic, assign) BOOL downloadComplete;

/**
 The task itself.
 */
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

/**
 Identifies the object.
 */
@property (nonatomic, copy) NSString *taskIdentifier;

/**
 Block to be executed upon success.
 */
@property (nonatomic, copy) void (^success)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location);

/**
 Block to be executed upon error.
 */
@property (nonatomic, copy) void (^failure)(EDSDownloadTaskInfo *downloadTask, NSError *error);

/**
 Block to be executed upon progress.
 */
@property (nonatomic, copy) void (^progress)(EDSDownloadTaskInfo *downloadTask);

/**
 Path to be downloaded.
 */
@property (nonatomic, strong) NSURL *url;

/**
 Creates a new DownloadTaskInfo object.
 
 @param title - used to identify the task.
 @param url - URL task will download from.
 @param completionBlock -  Block to be executed upon finishing.
 
 @return Instance of the class.
 */
- (instancetype)initWithDownloadID:(NSString *)downloadId
                               URL:(NSURL *)url
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask,NSError *error))failure;

/**
 Stops the task and stores the progress.
 */
- (void)pause;

/**
 Starts the task.
 */
- (void)resume;

- (void)didUpdateProgress:(NSNumber *)newProgress;

/**
 Checks weather the taskInfo provided equals self.
 
 @param taskInfo - new task.
 */
- (BOOL)canCoalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

/**
 Merges a new task with self.
 
 @param taskInfo - new task.
 */
- (void)coalesceWithTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

/**
 Release the data of paused downloads.
 */
- (void)releaseMemory;

@end
