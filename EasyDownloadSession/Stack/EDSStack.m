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
@property (nonatomic, assign, readwrite) NSInteger count;

/**
 Items in the stack.
 */
@property (nonatomic, strong, readwrite) NSMutableArray *objectsArray;

@end

@implementation EDSStack

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _objectsArray = [[NSMutableArray alloc] init];
        _count = 0;
    }
    
    return self;
}

#pragma mark - Push

- (void)push:(EDSDownloadTaskInfo*)taskInfo
{
    [self.objectsArray addObject:taskInfo];
    self.count = self.objectsArray.count;
}

#pragma mark -  Pop

- (EDSDownloadTaskInfo *)pop
{
    EDSDownloadTaskInfo *taskInfo = nil;
    
    if (self.objectsArray.count > 0)
    {
        taskInfo = [self.objectsArray lastObject];
        
        [self.objectsArray removeLastObject];
        self.count = self.objectsArray.count;
    }
    
    return taskInfo;
}

#pragma mark - Clear

- (void)clear
{
    [self.objectsArray removeAllObjects];
    self.count = 0;
}

#pragma mark - Dealloc

- (void)dealloc
{
    self.objectsArray = nil;
}

@end