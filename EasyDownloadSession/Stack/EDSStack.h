//
//  EDSStack.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 24/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDSDownloadTaskInfo;

/**
 Stack to store EDSDownloadTaskInfo objects.
 */
@interface EDSStack : NSObject

/**
 Number of items in the stack.
 */
@property (nonatomic, assign, readonly) NSInteger count;

/**
 Items in the stack.
 */
@property (nonatomic, strong, readonly) NSMutableArray *objectsArray;

/**
 Inserts in the stack.
 
 @param anObject - object to insert.
 */
- (void)push:(EDSDownloadTaskInfo *)anObject;

/**
 Retrieves from the stack.
 
 @return anObject - object to extracted.
 */
- (EDSDownloadTaskInfo *)pop;

/**
 Empties the stack.
 */
- (void)clear;

@end
