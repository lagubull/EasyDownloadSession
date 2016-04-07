//
//  EDSStackTests.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 06/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "EasyDownloadSession.h"

@interface FakeDownloadTaskInfo : EDSDownloadTaskInfo

@property (nonatomic, assign) NSUInteger callCounter;

- (void)releaseMemory;

@end

@implementation FakeDownloadTaskInfo

- (void)releaseMemory
{
    self.callCounter++;
}

@end

@interface EDSStackTests : XCTestCase

@property (nonatomic, strong) EDSStack *stack;
@property (nonatomic, strong) EDSDownloadTaskInfo *insertedTask;
@property (nonatomic, strong) NSString *insertedTaskId;

@end

@implementation EDSStackTests

#pragma mark - TestLyfeCycle

- (void)setUp
{
    [super setUp];
    
    self.stack = [[EDSStack alloc] init];
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                   URL:nil
                                                               session:nil
                                                       stackIdentifier:nil
                                                              progress:nil
                                                               success:nil
                                                               failure:nil
                                                            completion:nil];
}
- (void)tearDown
{
    [self.stack clear];
    
    self.stack = nil;
    
    [super tearDown];
}

#pragma mark - Push

- (void)test_push_shouldAddItem
{
    [self.stack push:self.insertedTask];
    
    XCTAssertEqual(self.stack.downloadsArray[0], self.insertedTask, @"Item was not inserted in stack");
}

- (void)test_push_countShouldMatchItemNumbers
{
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.stack push:self.insertedTask];
    }
    
    XCTAssertEqual(self.stack.downloadsArray.count, self.stack.count, @"Item count %@ does not match %@ items in the stack", @(self.stack.downloadsArray.count), @(self.stack.count));
}

#pragma mark - CanPop

- (void)test_canPopTask_ShouldReturnYes
{
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.stack push:self.insertedTask];
    }
    
    BOOL canPopTask = [self.stack canPopTask];
    
    XCTAssertTrue(canPopTask, @"canPopTask should return YES");
}

- (void)test_canPopTask_ShouldReturnNO_EmptyStack
{
    BOOL canPopTask = [self.stack canPopTask];
    
    XCTAssertFalse(canPopTask, @"canPopTask should return NO)");
}

- (void)test_canPopTask_ShouldReturnNO_LimitReached_EmptyStack
{
    self.stack.maxDownloads = 1;
    
    self.stack.currentDownloads = 1;
    
    BOOL canPopTask = [self.stack canPopTask];
    
    XCTAssertFalse(canPopTask, @"canPopTask should return NO)");
}

- (void)test_canPopTask_ShouldReturnNO_LimitReached
{
    self.stack.maxDownloads = 1;
    
    self.stack.currentDownloads = 1;
    
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.stack push:self.insertedTask];
    }
    
    BOOL canPopTask = [self.stack canPopTask];
    
    XCTAssertFalse(canPopTask, @"canPopTask should return NO)");
}

#pragma mark - Pop

- (void)test_pop_shouldReturnItem
{
    [self.stack push:self.insertedTask];
    
    EDSDownloadTaskInfo *extractedTask = [self.stack pop];
    
    XCTAssertEqual(extractedTask, self.insertedTask, @"Item was not extracted from the stack");
}

- (void)test_pop_shouldReturnNil
{
    EDSDownloadTaskInfo *extractedTask = [self.stack pop];
    
    XCTAssertNil(extractedTask, @"Unexpected Item was extracted from the stack");
}

- (void)test_pop_shouldReturnLastItem
{
    EDSDownloadTaskInfo *lastItemInTheStack =  [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                                          URL:nil
                                                                                      session:nil
                                                                              stackIdentifier:nil
                                                                                     progress:nil
                                                                                      success:nil
                                                                                      failure:nil
                                                                                   completion:nil];
    
    [self.stack push:self.insertedTask];
    [self.stack push:lastItemInTheStack];
    
    EDSDownloadTaskInfo *extractedTask = [self.stack pop];
    
    XCTAssertEqual(extractedTask, lastItemInTheStack, @"Item was not extracted from the stack");
}

- (void)test_pop_shouldIncreaseCurrentDownloads
{
    [self.stack push:self.insertedTask];
    
    self.stack.currentDownloads = 6;
    
    [self.stack pop];
    
    XCTAssertEqual(self.stack.currentDownloads, 7, @"Pop did not increase the current downloads counter, found: %@ expected: %@", @(self.stack.currentDownloads), @(7));
}

- (void)test_pop_shouldNotIncreaseCurrentDownloads
{
    NSUInteger currentDowloads = 6;
    
    self.stack.currentDownloads = currentDowloads;
    
    [self.stack pop];

    XCTAssertEqual(self.stack.currentDownloads, currentDowloads, @"Pop increased the current downloads counter, found: %@ expected: %@", @(self.stack.currentDownloads), @(currentDowloads));
}

#pragma mark - Clear

- (void)test_clear_shouldRemoveAllObjects
{
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.stack push:self.insertedTask];
    }
    
    [self.stack clear];
    
    XCTAssertEqual(self.stack.currentDownloads, 0, @"Item count %@ does not match the expected: 0", @(self.stack.currentDownloads));
}

- (void)test_clear_countShouldMatchItemNumbers
{
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.stack push:self.insertedTask];
    }
    
    [self.stack clear];
    
    XCTAssertEqual(self.stack.count, 0, @"Item count %@ does not match the expected: 0", @(self.stack.count));
}

#pragma mark - RemoveTaskInfo

- (void)test_removeTaskInfo_shouldRemoveTask
{
    EDSDownloadTaskInfo *lastItemInTheStack =  [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                                          URL:nil
                                                                                      session:nil
                                                                              stackIdentifier:nil
                                                                                     progress:nil
                                                                                      success:nil
                                                                                      failure:nil
                                                                                   completion:nil];
    
    [self.stack push:self.insertedTask];
    [self.stack push:lastItemInTheStack];
    
    [self.stack removeTaskInfo:self.insertedTask];
    
    BOOL taskContainsItem = NO;
    
    for (NSInteger i = 0; i < self.stack.downloadsArray.count; i++)
    {
        EDSDownloadTaskInfo *extractedItem = (EDSDownloadTaskInfo *)self.stack.downloadsArray[i];
        
        taskContainsItem = taskContainsItem || [extractedItem isEqual:self.insertedTask];
    }
    
    XCTAssertFalse(taskContainsItem, @"Task was not removed from stack");
}

- (void)test_removeTaskInfo_shouldNotCrash_EmptyStack
{
    [self.stack removeTaskInfo:self.insertedTask];
    
    XCTAssertTrue(YES);
}

- (void)test_removeTaskInfo_shouldDecreaseCount
{
    [self.stack push:self.insertedTask];
    
    [self.stack removeTaskInfo:self.insertedTask];
    
    XCTAssertEqual(self.stack.count, 0, @"RemoveTaskInfo did not decrease the current downloads counter, found: %@ expected:0", @(self.stack.count));
}

- (void)test_removeTaskInfo_shouldNotDecreaseCount
{
    EDSDownloadTaskInfo *lastItemInTheStack =  [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                                          URL:nil
                                                                                      session:nil
                                                                              stackIdentifier:nil
                                                                                     progress:nil
                                                                                      success:nil
                                                                                      failure:nil
                                                                                   completion:nil];
    
    [self.stack push:lastItemInTheStack];
    
    [self.stack removeTaskInfo:self.insertedTask];
    
    XCTAssertEqual(self.stack.count, 1, @"RemoveTaskInfo did not decrease the current downloads counter, found: %@ expected: 1", @(self.stack.count));
}

#pragma mark - ReleaseMemory

- (void)test_releaseMemory_shouldCallReleaseMemory
{
    NSUInteger callCounter = 0;
    
    NSUInteger taskCounter = 3;
    
    FakeDownloadTaskInfo *lastItemInTheStack =  [[FakeDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                                          URL:nil
                                                                                      session:nil
                                                                              stackIdentifier:nil
                                                                                     progress:nil
                                                                                      success:nil
                                                                                      failure:nil
                                                                                   completion:nil];

    
    for (NSInteger i = 0; i < taskCounter; i++)
    {
        [self.stack push:[[FakeDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"%@-%@" ,@(i), self.insertedTaskId]
                                                                      URL:nil
                                                                  session:nil
                                                          stackIdentifier:nil
                                                                 progress:nil
                                                                  success:nil
                                                                  failure:nil
                                                               completion:nil]];
    }

    [self.stack releaseMemory];
    
    for (NSInteger i = 0; i < self.stack.downloadsArray.count; i++)
    {
        FakeDownloadTaskInfo *extractedItem = (FakeDownloadTaskInfo *)self.stack.downloadsArray[i];
        
        callCounter = callCounter + extractedItem.callCounter;
    }
    
    XCTAssertEqual(taskCounter, callCounter, @"ReleaseMemory was called: %@ expected: %@", @(taskCounter), @(lastItemInTheStack.callCounter));
}

@end


