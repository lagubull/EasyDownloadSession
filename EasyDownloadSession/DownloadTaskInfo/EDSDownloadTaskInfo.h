//
//  EDSDownloadTaskInfo.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "EasyDownloadSession.h"

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
@property (nonatomic, assign) CGFloat downloadProgress;

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
 Identifies the stack.
 */
@property (nonatomic, copy) NSString *stackIdentifier;

/**
 Creates a new DownloadTaskInfo object.
 
 @param downloadId - used to identify the task.
 @param request - request for a download.
 @param session - Session that will own the task.
 @param progress -  Block to be executed upon progress.
 @param success -  Block to be executed upon success.
 @param failure -  Block to be executed upon failure.
 @param completion - Block to be executed upon finishing.
 
 @return Instance of the class.
 */
- (instancetype)initWithDownloadID:(NSString *)downloadId
                           request:(NSURLRequest *)request
                           session:(NSURLSession *)session
                   stackIdentifier:(NSString *)stackIdentifier
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure
                        completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion;

/**
 Creates a new DownloadTaskInfo object.
 
 @param downloadId - used to identify the task.
 @param url - URL task will download from.
 @param session - Session that will own the task.
 @param progress -  Block to be executed upon progress.
 @param success -  Block to be executed upon success.
 @param failure -  Block to be executed upon faiilure.
 @param completion - Block to be executed upon finishing.
 
 @return Instance of the class.
 */
- (instancetype)initWithDownloadID:(NSString *)downloadId
                               URL:(NSURL *)url
                           session:(NSURLSession *)session
                   stackIdentifier:(NSString *)stackIdentifier
                          progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                           success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                           failure:(void (^)(EDSDownloadTaskInfo *downloadTask,NSError *error))failure
                        completion:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error))completion;

/**
 Stops the task and stores the progress.
 */
- (void)pause;

/**
 Starts the task.
 */
- (void)resume;

/**
 Notifies the task of its progress.
 
 @param newProgress - completion status.
 */
- (void)didUpdateProgress:(CGFloat)newProgress;

/**
 Notifies the task wwhen has finish succesfully.
 
 @param location - local path to the downloaded data.
 */
- (void)didSucceedWithLocation:(NSURL *)location;

/**
 Notifies the task when it is finished with error.
 
 @param error - completion status.
 */
- (void)didFailWithError:(NSError *)error;

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
