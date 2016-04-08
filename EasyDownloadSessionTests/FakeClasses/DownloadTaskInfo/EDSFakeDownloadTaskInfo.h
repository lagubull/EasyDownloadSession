//
//  EDSFakeDownloadTaskInfo.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EasyDownloadSession.h"

@interface EDSFakeDownloadTaskInfo : EDSDownloadTaskInfo

@property (nonatomic, assign) NSUInteger callCounter;

@property (nonatomic, assign) BOOL didInvokeDidFailWithError;

- (void)releaseMemory;

- (void)didFailWithError:(NSError *)error;

@end
