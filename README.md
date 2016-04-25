[![Build Status](https://travis-ci.org/lagubull/EasyDownloadSession.svg)](https://travis-ci.org/lagubull/EasyDownloadSession)
[![Version](https://img.shields.io/cocoapods/v/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![License](https://img.shields.io/cocoapods/l/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![Platform](https://img.shields.io/cocoapods/p/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/EasyDownloadSession.svg)](http://cocoapods.org/pods/EasyDownloadSession)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/lagubull/EasyDownloadSession)](http://clayallsopp.github.io/readme-score?url=https://github.com/lagubull/EasyDownloadSession)

EasyDownloadSession allows pausing and resuming downloads, giving the developer full control of the tasks execution.

##Installation via [Cocoapods](https://cocoapods.org/)

To integrate EasyDownloadSession into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'EasyDownloadSession'
```

Then, run the following command:

```bash
$ pod install
```

> CocoaPods 0.39.0+ is required to build EasyDownloadSession.

##Usage

EasyDownload Session is built on top of NSURLSession, contains a wrap around the session object that will take care of scheduling new download tasks for you.

It can be configured to run as many concurrent operations as needed but the default behaviour is 1 running task. It should be noted that this pod will help also for uploading but for conveniency we will refer to all transfers as downloads.

IMPORTANT: maximum number of downloads per host is 100. 

Cache has been disabled.

There are two ways of adding new downloads:

- scheduleDownloadWithId: It will add the task to a stack and will run whenever there is a free download slot.

- forceDownloadWithId: it will start the task immediately, pausing other download if necessary.

We can find a good example of the usage of this code in git@github.com:lagubull/SocialChallenge.git

Where we are using EasyDownload Session to add requests for downloading large images 
that will be afterwards processed and displayed in a tableview, therefore we use the stack
provided by this pod as we are more interested in newer requests than we are in old ones.

####Stacks

EasyDownloadSession can manage as many stacks as you may need, before scheduling any download you should create a stack and register it in the session.

```swift
		let mediaStack = Stack()
        
        DownloadSession.sharedInstance.registerStack(stack: mediaStack,
                                                     stackIdentifier:kJSCMediaDownloadStack)
```
####Schedule

We add the requests to the stack respecting the current download task.

After a download has finished successfully, A success block will be triggered. If the download finishes failure block will be triggered.
Additionally, the progress block will be called to notify the  progress of the task.

```swift
class func retrieveMediaForPost(post: JSCPost, retrievalRequired: ((postId: String) -> Void)?, success: ((result: AnyObject?, postId: String) -> Void)?, failure: ((error: NSError?, postId: String) -> Void)?) {
        
        let mySuccess = success
        let myFailure = failure
        
        if post.userAvatarRemoteURL != nil {
            
            let operation = JSCLocalImageAssetRetrievalOperation.init(postId: post.postId!)
            
            operation.onCompletion = { JSCOperationOnCompletionCallback in
                
                if let imageMedia = JSCOperationOnCompletionCallback {
                    
                    mySuccess?(result: imageMedia,
                               postId: post.postId!)
                }
                else {
                    
                    retrievalRequired?(postId: post.postId!)
                    
                    DownloadSession.scheduleDownloadWithId(post.postId!,
                                                           fromURL: NSURL.init(string: post.userAvatarRemoteURL!)!,
                                                           stackIdentifier: kJSCMediaDownloadStack,
                                                           progress: nil,
                                                           success: { (taskInfo: DownloadTaskInfo!, responseData: NSData?) -> Void in
                                                            
                                                            let storeOperation = JSCMediaStorageOperation.init(postId: post.postId!, data: responseData)
                                                            
                                                            storeOperation.onSuccess = { JSCOperationOnSuccessCallback in
                                                                
                                                                if let imageMedia = JSCOperationOnSuccessCallback {
                                                                    
                                                                    mySuccess?(result: imageMedia, postId: post.postId!)
                                                                }
                                                                else {
                                                                    
                                                                    myFailure?(error: nil, postId: post.postId!)
                                                                }
                                                            }
                                                            
                                                            storeOperation.onFailure = { JSCOperationOnFailureCallback in
                                                                
                                                                myFailure?(error: nil, postId: post.postId!)
                                                            }
                                                            
                                                            storeOperation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
                                                            
                                                            JSCOperationCoordinator.sharedInstance.addOperation(storeOperation)
                        },
                                                           failure: { (taskInfo, error) -> Void in
                                                            
                                                            myFailure?(error: error, postId: post.postId!)
                    })
                }
            }
            
            operation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
            
            JSCOperationCoordinator.sharedInstance.addOperation(operation)
        }
        else {
            
            myFailure?(error: nil,
                       postId: post.postId!)
        }
    }
```

```objc

#pragma mark - Retrieval

+ (void)retrieveMediaForPost:(JSCPost *)post
           retrievalRequired:(void (^)(NSString *postId))retrievalRequired
                     success:(void (^)(id result, NSString *postId))success
                     failure:(void (^)(NSError *error, NSString *postId))failure;
{
 [EDSDownloadSession scheduleDownloadWithId:post.postId
                         	        fromURL:[NSURL URLWithString:post.userAvatarRemoteURL]
									progress:nil
									 success:^(EDSDownloadTaskInfo *downloadTask,
									           NSData *responseData)
                 {
                     JSCMediaStorageOperation *storeOPeration =
                      [[JSCMediaStorageOperation alloc] initWithPostID:post.postId
                                                                  data:responseData];
                     
                     storeOPeration.onSuccess = ^(id result)
                     {
                         if (result)
                         {
                             if (success)
                             {
                                 success(result, post.postId);
                             }
                         }
                         else
                         {
                             if (failure)
                             {
                                 failure(nil, post.postId);
                             }
                         }
                     };
                     
                     storeOPeration.onFailure = ^(NSError *error)
                     {
                         if (failure)
                         {
                             failure(error, post.postId);
                         }
                     };
                     
                     storeOPeration.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier;
                     
                     [[JSCOperationCoordinator sharedInstance] addOperation:storeOPeration];
                 }
                                                   failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                 {
                     if (failure)
                     {
                         failure(error, post.postId);
                     }
                 }];
}
```

An alternative signature for a single completion block is available

```swift
  DownloadSession.scheduleDownloadWithId(post.postId!,
                                                           fromURL: NSURL.init(string: post.userAvatarRemoteURL!)!,
                                                           stackIdentifier: kJSCMediaDownloadStack,
                                                           progress: nil,
                                                           completion: { (taskInfo: DownloadTaskInfo!, responseData: NSData?, error: NSError?) -> Void in
                                                            
                                                            if error == nil {
                                                                
                                                                let storeOperation = JSCMediaStorageOperation.init(postId: post.postId!, data: responseData)
                                                                
                                                                storeOperation.onSuccess = { JSCOperationOnSuccessCallback in
                                                                    
                                                                    if let imageMedia = JSCOperationOnSuccessCallback {
                                                                        
                                                                        mySuccess?(result: imageMedia, postId: post.postId!)
                                                                    }
                                                                    else {
                                                                        
                                                                        myFailure?(error: nil, postId: post.postId!)
                                                                    }
                                                                }
                                                                
                                                                storeOperation.onFailure = { JSCOperationOnFailureCallback in
                                                                    
                                                                    myFailure?(error: nil, postId: post.postId!)
                                                                }
                                                                
                                                                storeOperation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
                                                                
                                                                JSCOperationCoordinator.sharedInstance.addOperation(storeOperation)
                                                            }
                                                            else {
                                                                
                                                                myFailure?(error: error, postId: post.postId!)
                                                            }
                    })
                }
            }
```

####Force Download

This will effectively pause all downloads start this one and then start any other download
that can up to maxDownloads.

After a download has finished successfully, A success block will be triggered. If the download finishes failure block will be triggered.

Additionally, the progress block will be called to notify the  progress of the task.

```swift
class func retrieveMediaForPost(post: JSCPost, retrievalRequired: ((postId: String) -> Void)?, success: ((result: AnyObject?, postId: String) -> Void)?, failure: ((error: NSError?, postId: String) -> Void)?) {
        
        let mySuccess = success
        let myFailure = failure
        
        if post.userAvatarRemoteURL != nil {
            
            let operation = JSCLocalImageAssetRetrievalOperation.init(postId: post.postId!)
            
            operation.onCompletion = { JSCOperationOnCompletionCallback in
                
                if let imageMedia = JSCOperationOnCompletionCallback {
                    
                    mySuccess?(result: imageMedia,
                               postId: post.postId!)
                }
                else {
                    
                    retrievalRequired?(postId: post.postId!)
                    
                    DownloadSession.forceDownloadWithId(post.postId!,
                                                        fromURL: NSURL.init(string: post.userAvatarRemoteURL!)!,
                                                        stackIdentifier: kJSCMediaDownloadStack,
                                                        progress: nil,
                                                        success: { (taskInfo: DownloadTaskInfo!, responseData: NSData?) -> Void in
                                                            
                                                            let storeOperation = JSCMediaStorageOperation.init(postId: post.postId!, data: responseData)
                                                            
                                                            storeOperation.onSuccess = { JSCOperationOnSuccessCallback in
                                                                
                                                                if let imageMedia = JSCOperationOnSuccessCallback {
                                                                    
                                                                    mySuccess?(result: imageMedia, postId: post.postId!)
                                                                }
                                                                else {
                                                                    
                                                                    myFailure?(error: nil, postId: post.postId!)
                                                                }
                                                            }
                                                            
                                                            storeOperation.onFailure = { JSCOperationOnFailureCallback in
                                                                
                                                                myFailure?(error: nil, postId: post.postId!)
                                                            }
                                                            
                                                            storeOperation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
                                                            
                                                            JSCOperationCoordinator.sharedInstance.addOperation(storeOperation)
                        },
                                                        failure: { (taskInfo, error) -> Void in
                                                            
                                                            myFailure?(error: error, postId: post.postId!)
                    })
                }
            }
            
            operation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
            
            JSCOperationCoordinator.sharedInstance.addOperation(operation)
        }
        else {
            
            myFailure?(error: nil,
                       postId: post.postId!)
        }
    }
```

```objc

#pragma mark - Retrieval

+ (void)retrieveMediaForPost:(JSCPost *)post
           retrievalRequired:(void (^)(NSString *postId))retrievalRequired
                     success:(void (^)(id result, NSString *postId))success
                     failure:(void (^)(NSError *error, NSString *postId))failure;
{
[EDSDownloadSession forceDownloadWithId:post.postId
                         	    fromURL:[NSURL URLWithString:post.userAvatarRemoteURL]
							   progress:nil
							    success:^(EDSDownloadTaskInfo *downloadTask,
									           NSData *responseData)
                 {
                     JSCMediaStorageOperation *storeOPeration =
                      [[JSCMediaStorageOperation alloc] initWithPostID:post.postId
                                                                  data:responseData];
                     
                     storeOPeration.onSuccess = ^(id result)
                     {
                         if (result)
                         {
                             if (success)
                             {
                                 success(result, post.postId);
                             }
                         }
                         else
                         {
                             if (failure)
                             {
                                 failure(nil, post.postId);
                             }
                         }
                     };
                     
                     storeOPeration.onFailure = ^(NSError *error)
                     {
                         if (failure)
                         {
                             failure(error, post.postId);
                         }
                     };
                     
                     storeOPeration.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier;
                     
                     [[JSCOperationCoordinator sharedInstance] addOperation:storeOPeration];
                 }
                                                   failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                 {
                     if (failure)
                     {
                         failure(error, post.postId);
                     }
                 }];
}
```

An alternative signature for a single completion block is available

```swift
DownloadSession.forceDownloadWithId(post.postId!,
                                                        fromURL: NSURL.init(string: post.userAvatarRemoteURL!)!,
                                                        stackIdentifier: kJSCMediaDownloadStack,
                                                        progress: nil,
                                                        completion: { (taskInfo: DownloadTaskInfo!, responseData: NSData?, error: NSError?) -> Void in
                                                            
                                                            if error == nil {
                                                                
                                                                let storeOperation = JSCMediaStorageOperation.init(postId: post.postId!, data: responseData)
                                                                
                                                                storeOperation.onSuccess = { JSCOperationOnSuccessCallback in
                                                                    
                                                                    if let imageMedia = JSCOperationOnSuccessCallback {
                                                                        
                                                                        mySuccess?(result: imageMedia, postId: post.postId!)
                                                                    }
                                                                    else {
                                                                        
                                                                        myFailure?(error: nil, postId: post.postId!)
                                                                    }
                                                                }
                                                                
                                                                storeOperation.onFailure = { JSCOperationOnFailureCallback in
                                                                    
                                                                    myFailure?(error: nil, postId: post.postId!)
                                                                }
                                                                
                                                                storeOperation.targetSchedulerIdentifier = kJSCLocalDataOperationSchedulerTypeIdentifier
                                                                
                                                                JSCOperationCoordinator.sharedInstance.addOperation(storeOperation)
                                                            }
                                                            else {
                                                                
                                                                myFailure?(error: error, postId: post.postId!)
                                                            }
                    })
                }
            }
```

####Concurrent Downloads

You can use the property maxDownloads to increase the number of concurrent downloads.

```swift
	mediaStack.maxDownloads = 4
```

```objc
    [EDSDownloadSession downloadSession].maxDownloads = @(4);
```

####Pause

Pausing a download stops the task and stores the progress in memory so that it can be resumed later on.

All stacks may be paused at any time:

```swift
	DownloadSession.pauseDownloads()
```

Specific stacks may be stopped just as easily:

```swift
	DownloadSession.pauseDownloadsInStack(kJSCMediaDownloadStack)
```

####Resume

After a download has been manually paused, it can be resumed and it will continue from whenever it had been stopped.

To restart all downloads (within the stablished limits) you may call:

```swift
	DownloadSession.resumeDownloads()
```

To resume an specific stack, however:

```Swift
	DownloadSession.resumeDownloadsInStack(kJSCMediaDownloadStack)
```

####Cancel

All tasks may be cancelled at any time:

```swift
	DownloadSession.cancelDownloads()
```

Specific tasks may be stopped just as well:

```swift
	 DownloadSession.cancelDownload(post.postId!,
                                    stackIdentifier: kJSCMediaDownloadStack)
```

##Found an issue?

Please open a [new Issue here](https://github.com/lagubull/SimpleTableView/issues/new) if you run into a problem specific to EasyAlert, have a feature request, or want to share a comment.

Pull requests are encouraged and greatly appreciated! Please try to maintain consistency with the existing coding style. If you're considering taking on significant changes or additions to the project, please communicate in advance by opening a new Issue. This allows everyone to get onboard with upcoming changes, ensures that changes align with the project's design philosophy, and avoids duplicated work.

Thank you!
