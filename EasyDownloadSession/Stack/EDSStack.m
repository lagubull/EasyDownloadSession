//
//  EDSStack.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "EDSStack.h"

#import "EDSDownloadTaskInfo.h"

@interface EDSStack ()

/**
 Number of items in the stack.
 */
@property (nonatomic, assign, readwrite) NSUInteger count;

/**
 Items in the stack.
 */
@property (nonatomic, strong, readwrite) NSMutableArray *downloadsArray;

@end

@implementation EDSStack

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _downloadsArray = [[NSMutableArray alloc] init];
        _count = 0;
    }
    
    return self;
}

#pragma mark - Push

- (void)push:(EDSDownloadTaskInfo*)taskInfo
{
    [self.downloadsArray addObject:taskInfo];
    self.count = self.downloadsArray.count;
}

#pragma mark -  Pop

- (EDSDownloadTaskInfo *)pop
{
    EDSDownloadTaskInfo *taskInfo = nil;
    
    if (self.downloadsArray.count > 0)
    {
        taskInfo = [self.downloadsArray lastObject];
        
        [self.downloadsArray removeLastObject];
        self.count = self.downloadsArray.count;
    }
    
    return taskInfo;
}

#pragma mark - Clear

- (void)clear
{
    [self.downloadsArray removeAllObjects];
    self.count = 0;
}

#pragma mark - ReleaseMemory

- (void)releaseMemory
{
    @synchronized(self.downloadsArray)
    {
        for (EDSDownloadTaskInfo *download in self.downloadsArray)
        {
            [download releaseMemory];
        }
    }
}

#pragma mark - Dealloc

- (void)dealloc
{
    self.downloadsArray = nil;
}

@end