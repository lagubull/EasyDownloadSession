//
//  EDSFakeSession.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EDSFakeSession.h"

#import "EDSFakeNSURLSessionTask.h"

@implementation EDSFakeSession

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
{
    self.didInvokeDownloadTaskWithResumeData = YES;
    
    return [[EDSFakeNSURLSessionTask alloc] init];
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request;
{
    self.didInvokeDownloadTaskWithRequest = YES;
    
    return [[EDSFakeNSURLSessionTask alloc] init];
}

@end
