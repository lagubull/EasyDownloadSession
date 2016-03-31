//
//  EDSStack.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EasyDownloadSession.h"

/**
 Stack to store EDSDownloadTaskInfo objects.
 */
@interface EDSStack : NSObject

/**
 Number of items in the stack.
 */
@property (nonatomic, assign, readonly) NSUInteger count;

/**
 Items in the stack.
 */
@property (nonatomic, strong, readonly) NSMutableArray *downloadsArray;

/**
 Maximum number of concurrent downloads.
 
 1 by default.
 */
@property (nonatomic, strong) NSNumber *maxDownloads;

/**
 Number of downloads that were started off this stack and have not finished yet.
 */
@property (nonatomic, strong) NSNumber *currentDownloads;

/**
 Inserts in the stack.
 
 @param anObject - object to insert.
 */
- (void)push:(EDSDownloadTaskInfo *)anObject;

/**
 Checks wethere a task can be started from the stack.
 
 @return YES - A task can be started, NO - there are no tasks to start or the maximum running tasks operations has been reached.
 */
- (BOOL)canPopTask;

/**
 Retrieves from the stack.
 
 @return anObject - object to extracted.
 */
- (EDSDownloadTaskInfo *)pop;

/**
 Empties the stack.
 */
- (void)clear;

/**
 Removes the task from the stack.
 
 @param taskInfo - task to remove.
 */
- (void)removeTaskInfo:(EDSDownloadTaskInfo *)taskInfo;

/**
 Release the data of paused downloads.
 */
- (void)releaseMemory;

@end
