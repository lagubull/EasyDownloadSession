//
//  EDSFakeNSURLSessionTask.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "EDSFakeNSURLSessionTask.h"

@implementation EDSFakeNSURLSessionTask

@synthesize state = _state;

- (void)cancelByProducingResumeData:(void (^)(NSData * __nullable resumeData))completionHandler
{
    self.didInvokeCancelByProducingResumeDataInvoked = YES;
    
    self.pausedSavedData = [[NSData alloc] init];
    
    __weak typeof(self) weakSelf = self;
    
    if (completionHandler)
    {
        completionHandler = ^(NSData * __nullable resumeData)
        {
            weakSelf.pausedSavedData = resumeData;
            
            [weakSelf.pausedSavedDataExpectation fulfill];
            
            completionHandler(resumeData);
        };
        
        completionHandler(self.pausedSavedData);
    }
}

- (void)suspend
{
    self.didInvokeSuspend = YES;
}

-(void)resume
{
    self.didInvokeResume = YES;
}

- (void)setState:(NSURLSessionTaskState)state
{
    if (_state != state)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(state))];
        _state = state;
        [self didChangeValueForKey:NSStringFromSelector(@selector(state))];
    }
}

@end
