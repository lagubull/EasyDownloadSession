//
//  EDSDownloadSession.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDSDownloadTaskInfo;

/**
 Protocol to indicate the status of the downloads.
 */
@protocol EDSDownloadSessionDelegate <NSObject>

/**
 Notifies the delegate a download has been resumed.
 
 @param downloadTaskInfo - metadata on the resumed download.
 */
- (void)didResumeDownload:(EDSDownloadTaskInfo *)downloadTaskInfo;

/**
 Notifies the delegate a download has progressed.
 
 @param downloadTaskInfo - metadata on the download.
 */
- (void)didUpdateProgress:(EDSDownloadTaskInfo *)downloadTaskInfo;

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
 Maximum number of concurrent downloads.
 
 1 by default.
 */
@property (nonatomic, strong) NSNumber *maxDownloads;

/**
 Stop and remove all the pending downloads without executing the completion block.
 */
+ (void)cancelDownloads;

/**
 Resume or starts the next pending download if it is not already executing.
 */
+ (void)resumeDownloads;

/**
 Stop the current downlad and saves it back in the queue without triggering a new download.
 */
+ (void)pauseDownloads;

/**
 Creates an instance od DownloadSession
 
 @return Session - instance of self.
 */
+ (EDSDownloadSession *)downloadSession;

/**
 Adds a downloading task to the stack.
 
 @param URL - path to download.
 @param completionBlock - to be executed when the task finishes.
 */
+ (void)scheduleDownloadWithID:(NSString *)downloadID
                       fromURL:(NSURL *)url
               completionBlock:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error))completionHandler;

/**
 Stops the current download and adds it to the stack, the it begins executing this new download.
 
 @param URL - path to download.
 @param completionBlock - to be executed when the task finishes.
 */
+ (void)forceDownloadWithID:(NSString *)downloadID
                    fromURL:(NSURL *)url
            completionBlock:(void (^)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSURL *location, NSError *error))completionHandler;

/**
 Creates a download task to download the contents of the given URL.
 
 @param URL - path to download.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url;

/*
 * data task convenience methods.  These methods create tasks that
 * bypass the normal delegate calls for response and data delivery,
 * and provide a simple cancelable asynchronous interface to receiving
 * data.  Errors will be returned in the NSURLErrorDomain,
 * see <Foundation/NSURLError.h>.  The delegate, if any, will still be
 * called for authentication challenges.
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

/**
 Creates a download task with the resume data.  If the download cannot be successfully resumed, URLSession:task:didCompleteWithError: will be called.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData;

@end
