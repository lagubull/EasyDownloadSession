//
//  EDSFakeNSURLSessionTask.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCTestExpectation;

@interface EDSFakeNSURLSessionTask : NSURLSessionDownloadTask

@property (nonatomic, assign) BOOL didInvokeSuspend;

@property (nonatomic, assign) BOOL didInvokeResume;

@property (nonatomic, assign) BOOL didInvokeCancelByProducingResumeDataInvoked;

@property (nonatomic, strong) NSData *pausedSavedData;

@property (nonatomic, strong) XCTestExpectation *pausedSavedDataExpectation;

- (void)setState:(NSURLSessionTaskState)state;

@end
