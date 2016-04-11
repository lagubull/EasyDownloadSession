//
//  EDSFakeDownloadTaskInfo.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EDSFakeDownloadTaskInfo.h"

@implementation EDSFakeDownloadTaskInfo

- (void)releaseMemory
{
    self.callCounter++;
}

- (void)didFailWithError:(NSError *)error
{
    self.didInvokeDidFailWithError = YES;
}

@end
