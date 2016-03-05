[![Build Status](https://travis-ci.org/lagubull/EasyDownloadSession.svg)](https://travis-ci.org/lagubull/EasyDownloadSession)
[![Version](https://img.shields.io/cocoapods/v/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![License](https://img.shields.io/cocoapods/l/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![Platform](https://img.shields.io/cocoapods/p/EasyDownloadSession.svg?style=flat)](http://cocoapods.org/pods/EasyDownloadSession)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/EasyDownloadSession.svg)](http://cocoapods.org/pods/EasyDownloadSession)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/lagubull/EasyDownloadSession)](http://clayallsopp.github.io/readme-score?url=https://github.com/lagubull/EasyDownloadSession)

EasyDownloadSession allows pausing and resuming downloads, giving the developer full control of the order of execution.

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

It can be configured to run as many concurrent operations as needed but the default behaviour is 1 running task. IMPORTANT: maximum number of downloads per host is 100.

There two ways of adding new downloads:

- scheduleDownloadWithId: It will add the task to a stack and will run whenever there is a free download slot.

- forceDownloadWithId: it will start the task immediately, pausing other download if necessary.

We can find a good example of the usage of this code in git@github.com:lagubull/SocialChallenge.git

Where we are using EasyDownload Session to add requests for downloading large images 
that will be afterwards processed and displayed in a tableview, therefore we use the stack
provided by this pod as we are more interested in newer requests that old ones.

####Schedule

We add the requests to the task respecting the current download task.

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

####Force Download

This will effectively pause all downloads start this one and then start any other download
that can up to maxDownloads.

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
####Concurrent Downloads

You can use the property maxDownloads to increase the number of concurrent downdloads.

```objc

    [EDSDownloadSession downloadSession].maxDownloads = @(4);
```

##Found an issue?

Please open a [new Issue here](https://github.com/lagubull/SimpleTableView/issues/new) if you run into a problem specific to EasyAlert, have a feature request, or want to share a comment.

Pull requests are encouraged and greatly appreciated! Please try to maintain consistency with the existing coding style. If you're considering taking on significant changes or additions to the project, please communicate in advance by opening a new Issue. This allows everyone to get onboard with upcoming changes, ensures that changes align with the project's design philosophy, and avoids duplicated work.

Thank you!
