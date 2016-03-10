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
        _maxDownloads = @(0);
        _currentDownloads = @(0);
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

- (BOOL)canPopTask
{
    BOOL canPopTask = NO;
    
    if (self.maxDownloads.integerValue == 0 ||
        (self.currentDownloads.integerValue < self.maxDownloads.integerValue &&
         self.count > 0))
    {
        canPopTask = YES;
    }
    
    return canPopTask;
}

- (EDSDownloadTaskInfo *)pop
{
    EDSDownloadTaskInfo *taskInfo = nil;
    
    if (self.downloadsArray.count > 0)
    {
        taskInfo = [self.downloadsArray lastObject];
        
        [self.downloadsArray removeLastObject];
        self.count = self.downloadsArray.count;
        self.currentDownloads = @(self.currentDownloads.integerValue + 1);
    }
    
    return taskInfo;
}

#pragma mark - Clear

- (void)clear
{
    [self.downloadsArray removeAllObjects];
    self.count = 0;
}

#pragma mark - RemoveTaskInfo

- (void)removeTaskInfo:(EDSDownloadTaskInfo *)taskInfo
{
    [self.downloadsArray removeObject:taskInfo];
    self.count = self.count - 1;
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