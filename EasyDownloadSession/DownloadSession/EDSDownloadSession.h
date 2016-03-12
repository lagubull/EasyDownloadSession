//
//  EDSDownloadSession.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDSDownloadTaskInfo;
@class EDSStack;

/**
 Protocol to indicate the status of the downloads.
 */
@protocol EDSDownloadSessionDelegate <NSObject>

/**
 Notifies the delegate a download has been resumed.
 
 @param downloadTaskInfo - metadata on the resumed download.
 */
- (void)didResumeDownload:(EDSDownloadTaskInfo *)downloadTaskInfo;

@end

/**
 Defines a session with custom methods to download.
 */
@interface EDSDownloadSession : NSObject

/**
 Delegate for the DownloadSessionDelegate class.
 */
@property (nonatomic, weak) id<EDSDownloadSessionDelegate>delegate;

/**
 Registers the stack in the session.
 
 @param stackIdentifier - identifies the stack.
 */
- (void)registerStack:(EDSStack *)stack
      stackIdentifier:(NSString *)stackIdentifier;

/**
 Stop and remove all the pending downloads without executing the completion block.
 */
+ (void)cancelDownloads;

/**
 Resume or starts the next pending downloads in every stack if there is capacity in each stack.
 */
+ (void)resumeDownloads;

/**
 Resume or starts the next pending downloads if there is capacity in an specific stack.
 
 @param stackIndetifier - Identifier of the stack for the download.
 */
+ (void)resumeDownloadsInStack:(NSString *)downloadStackIdentifier;

/**
 Stop the current downloads in every stack and save them back in the queue.
 */
+ (void)pauseDownloads;

/**
 Stop the current downloads and save them back in the queue for an specific stack.
 
 @param stackIndetifier - Identifier of the stack for the download.
 */
+ (void)pauseDownloadsInStack:(NSString *)stackIndetifier;

/**
 Creates an instance od DownloadSession
 
 @return Session - instance of self.
 */
+ (instancetype)sharedInstance;

/**
 Adds a downloading task to the stack.
 
 @param downloadId - identifies the download.
 @param URL - path to download.
 @param stackIdentifier - identifies the stack in which this download will be placed into.
 @param progress - to be executed when as the task progresses.
 @param success - to be executed when the task finishes succesfully.
 @param failure - to be executed when the task finishes with an error.
 */
+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       fromURL:(NSURL *)url
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure;

/**
 Adds a downloading task to the stack.
 
 @param downloadId - identifies the download.
 @param request - request for a download.
 @param stackIdentifier - identifies the stack in which this download will be placed into.
 @param progress - to be executed when as the task progresses.
 @param success - to be executed when the task finishes succesfully.
 @param failure - to be executed when the task finishes with an error.
 */
+ (void)scheduleDownloadWithId:(NSString *)downloadId
                       request:(NSURLRequest *)request
               stackIdentifier:(NSString *)stackIdentifier
                      progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                       success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                       failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure;

/**
 Stops the current download and adds it to the stack, the it begins executing this new download.
 
 @param downloadId - identifies the download.
 @param URL - path to download.
 @param stackIdentifier - identifies the stack in which this download will be placed into.
 @param progress - to be executed when as the task progresses.
 @param success - to be executed when the task finishes succesfully.
 @param failure - to be executed when the task finishes with an error.
 */
+ (void)forceDownloadWithId:(NSString *)downloadId
                    fromURL:(NSURL *)url
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure;


/**
 Stops the current download and adds it to the stack, the it begins executing this new download.
 
 @param downloadId - identifies the download.
 @param request - request for a download.
 @param stackIdentifier - identifies the stack in which this download will be placed into.
 @param progress - to be executed when as the task progresses.
 @param success - to be executed when the task finishes succesfully.
 @param failure - to be executed when the task finishes with an error.
 */
+ (void)forceDownloadWithId:(NSString *)downloadId
                    request:(NSURLRequest *)request
            stackIdentifier:(NSString *)stackIdentifier
                   progress:(void (^)(EDSDownloadTaskInfo *downloadTask))progress
                    success:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData))success
                    failure:(void (^)(EDSDownloadTaskInfo *downloadTask, NSError *error))failure;
@end
