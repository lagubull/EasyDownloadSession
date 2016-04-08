//
//  EDSDownloadTaskInfoTests.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 07/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "EasyDownloadSession.h"
#import "EDSFakeDownloadTaskInfo.h"
#import "EDSFakeNSURLSessionTask.h"
#import "EDSFakeSession.h"

@interface EDSDownloadTaskInfoTests : XCTestCase

@property (nonatomic, strong) EDSDownloadTaskInfo *insertedTask;
@property (nonatomic, strong) NSString *insertedTaskId;
@property (nonatomic, strong) EDSFakeNSURLSessionTask *task;
@property (nonatomic, strong) EDSFakeSession *session;

@property (nonnull, strong) XCTestExpectation *progressExpectation;
@property (nonnull, strong) XCTestExpectation *successExpectation;
@property (nonnull, strong) XCTestExpectation *failureExpectation;
@property (nonnull, strong) XCTestExpectation *completionExpectation;

@end

@interface EDSDownloadTaskInfo ()

/**
 Block to be executed upon success.
 */
@property (nonatomic, copy) void (^success)(EDSDownloadTaskInfo *downloadTask, NSData *responseData);

/**
 Block to be executed upon error.
 */
@property (nonatomic, copy) void (^failure)(EDSDownloadTaskInfo *downloadTask, NSError *error);

/**
 Block to be executed upon progress.
 */
@property (nonatomic, copy) void (^progress)(EDSDownloadTaskInfo *downloadTask);

/**
 Block to be executed upon finishing.
 */
@property (nonatomic, copy) void (^completion)(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error);

@end

@implementation EDSDownloadTaskInfoTests

#pragma mark - TestLifeCycle

- (void)setUp
{
    [super setUp];
    
    self.insertedTaskId = @"TASKID";
    
    self.session = [[EDSFakeSession alloc] init];
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:nil
                                                                success:nil
                                                                failure:nil
                                                             completion:nil];
    
    self.insertedTask.isDownloading = YES;
    self.task = [[EDSFakeNSURLSessionTask alloc] init];
    self.insertedTask.task = self.task;
}

- (void)tearDown
{
    self.insertedTaskId = nil;
    
    self.task = nil;
    
    self.insertedTask = nil;
    
    [super tearDown];
}

#pragma mark - Pause

- (void)test_pause_isDownloadingShouldBeNO
{
    [self.insertedTask pause];
    
    XCTAssertFalse(self.insertedTask.isDownloading, "IsDownloading should be NO");
}

- (void)test_pause_taskShouldBeSuspended
{
    [self.insertedTask pause];
    
    XCTAssertTrue(self.task.didInvokeSuspend, "Task suspend was not invoked");
}

- (void)test_pause_taskCancelByProducingResumeDataInvoked
{
    [self.insertedTask pause];
    
    XCTAssertTrue(self.task.didInvokeCancelByProducingResumeDataInvoked, "Task CancelByProducingResumeData suspend was not invoked");
}

- (void)test_pause_taskCurrentDataIsSaved
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Data should be saved"];
    
    self.task.pausedSavedDataExpectation = expectation;
    
    self.insertedTask.task = self.task;
    
    [self.insertedTask pause];
    
    [self waitForExpectationsWithTimeout:1.0
                                 handler:^(NSError *error)
     {
         XCTAssertEqual(self.insertedTask.taskResumeData, self.task.pausedSavedData, @"Data was not saved");
     }];
}

#pragma mark - Resume

- (void)test_resume_isDownloadindShouldBeYES
{
    [self.insertedTask resume];
    
    XCTAssertTrue(self.insertedTask.isDownloading, "IsDownloading should be YES");
}

- (void)test_resume_taskResumeShouldBeInvoked
{
    [self.insertedTask resume];
    
    XCTAssertTrue(self.task.didInvokeResume, "Task Resume suspend was not invoked");
}

- (void)test_resume_taskDownloadTaskWithResumeDataShouldBeInvoked
{
    NSString *stringtobeData = @"This is a text";
    
    self.insertedTask.taskResumeData = [stringtobeData dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.insertedTask resume];
    
    XCTAssertTrue(self.session.didInvokeDownloadTaskWithResumeData, "Task DownloadTaskWithResumeData was not invoked");
}

- (void)test_resume_taskDownloadTaskWithRequestShouldBeInvoked
{
    //We need to change the value manually as initialization will call this method aswell
    self.session.didInvokeDownloadTaskWithRequest = NO;
    
    [self.task setState: NSURLSessionTaskStateCompleted];
    
    [self.insertedTask resume];
    
    XCTAssertTrue(self.session.didInvokeDownloadTaskWithRequest, "Task DownloadTaskWithRequest was not invoked");
}

#pragma mark - Progress

- (void)test_didUpdateProgress_progessIsUpdated
{
    CGFloat newProgress = 5.0f;
    
    [self.insertedTask didUpdateProgress:newProgress];
    
    XCTAssertEqual(self.insertedTask.downloadProgress, newProgress, @"Progress was not updated, currentProgress: %@, expected: %@", @(self.insertedTask.downloadProgress), @(newProgress));
}

- (void)test_didUpdateProgress_progessShouldBeInvoked
{
    CGFloat newProgress = 5.0f;
    
    __weak typeof(self) weakSelf = self;
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:^(EDSDownloadTaskInfo *downloadTask)
                         {
                             [weakSelf.progressExpectation fulfill];
                         }
                                                                success:nil
                                                                failure:nil
                                                             completion:nil];
    
    [self.insertedTask didUpdateProgress:newProgress];
    
    self.progressExpectation = [self expectationWithDescription:@"Progress expectation"];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

#pragma mark - Success

- (void)test_didSucceedWithLocation_successLocationIsUsed
{
    NSString *locationString = @"LocationString";
    
    __weak typeof(self) weakSelf = self;
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:nil
                                                                success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                         {
                             NSString *resultString = [[NSString alloc] initWithData:responseData
                                                                            encoding:NSUTF8StringEncoding];
                             
                             if ([resultString isEqualToString:locationString])
                             {
                                 [weakSelf.successExpectation fulfill];
                             }
                         }
                                                                failure:nil
                                                             completion:nil];
    
    [self.insertedTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    self.successExpectation = [self expectationWithDescription:@"Location is not used"];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_didSucceedWithLocation_didFailWithErrorIsInvoked
{
    EDSFakeDownloadTaskInfo *task = [[EDSFakeDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                                     {
                                     }
                                                                                failure:nil
                                                                             completion:nil];
    
    [task didSucceedWithLocation:nil];
    
    XCTAssertTrue(task.didInvokeDidFailWithError, "DidFailWithError was not invoked");
}

- (void)test_didSucceedWithLocation_completionLocationIsUsed
{
    NSString *locationString = @"LocationString";
    
    __weak typeof(self) weakSelf = self;
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:nil
                                                                success:nil
                                                                failure:nil
                                                             completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                         {
                             NSString *resultString = [[NSString alloc] initWithData:responseData
                                                                            encoding:NSUTF8StringEncoding];
                             
                             if ([resultString isEqualToString:locationString])
                             {
                                 [weakSelf.completionExpectation fulfill];
                             }
                         }];
    
    [self.insertedTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    self.completionExpectation = [self expectationWithDescription:@"Location is not used"];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

#pragma mark - Failure

- (void)test_didFailWithError_failureErrorIsUsed
{
    __weak typeof(self) weakSelf = self;
    
    NSError *testError = [[NSError alloc] init];
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:nil
                                                                success:nil
                                                                failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                         {
                             if ([error isEqual:testError])
                             {
                                 [weakSelf.failureExpectation fulfill];
                             }
                         }
                                                             completion:nil];
    
    [self.insertedTask didFailWithError:testError];
    
    self.failureExpectation = [self expectationWithDescription:@"Failure Error is never used"];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_didFailWithError_completionErrorIsUsed
{
    __weak typeof(self) weakSelf = self;
    
    NSError *testError = [[NSError alloc] init];
    
    self.insertedTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                    URL:nil
                                                                session:self.session
                                                        stackIdentifier:nil
                                                               progress:nil
                                                                success:nil
                                                                failure:nil
                                                             completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                         {
                             if ([error isEqual:testError])
                             {
                                 [weakSelf.completionExpectation fulfill];
                             }
                         }];
    
    [self.insertedTask didFailWithError:testError];
    
    self.completionExpectation = [self expectationWithDescription:@"Completion Error is never used"];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

#pragma mark - Coalescing

- (void)test_canCoalesceWithTaskInfo_ShouldReturnYES
{
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    BOOL canCoalesce = [self.insertedTask canCoalesceWithTaskInfo:newTask];
    
    XCTAssertTrue(canCoalesce, "CanColaseceWithTaskInfo should return YES");
}

- (void)test_canCoalesceWithTaskInfo_ShouldReturnNO
{
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    BOOL canCoalesce = [self.insertedTask canCoalesceWithTaskInfo:newTask];
    
    XCTAssertFalse(canCoalesce, "CanColaseceWithTaskInfo should return NO");
}

#pragma mark Success

- (void)test_coalesceSuccesWithTaskInfo_SuccessShouldBeNil
{
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [self.insertedTask coalesceWithTaskInfo:newTask];
    
    XCTAssertNil(self.insertedTask.success, "Success should be nil");
}

- (void)test_coalesceSuccesWithTaskInfo_SuccessShouldBeOriginalSuccess
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    self.successExpectation = [self expectationWithDescription:@"Success should be Original task's"];
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                                         {
                                             [weakSelf.successExpectation fulfill];
                                         }
                                                                                failure:nil
                                                                             completion:nil];
    
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewSuccess
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    self.successExpectation = [self expectationWithDescription:@"Success should be New task's"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                                    {
                                        [weakSelf.successExpectation fulfill];
                                    }
                                                                           failure:nil
                                                                        completion:nil];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:nil
                                                                             completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewOrginalThenNew
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    __block NSString *result = @"";
    
    __block NSString *originalSucess = @"1";
    
    __block NSString *newSucess = @"2";
    
    __block NSString *expectedResult = @"12";
    
    __block XCTestExpectation *originalSuccessExpectation = [self expectationWithDescription:@"Original task's expectation was not met"];
    
    self.successExpectation = [self expectationWithDescription:@"New task's expectation was not met"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                                    {
                                        result = [NSString stringWithFormat:@"%@%@", result, newSucess];
                                        
                                        [weakSelf.successExpectation fulfill];
                                    }
                                                                           failure:nil
                                                                        completion:nil];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
                                         {
                                             result = [NSString stringWithFormat:@"%@%@", result, originalSucess];
                                             
                                             [originalSuccessExpectation fulfill];
                                         }
                                                                                failure:nil
                                                                             completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:^(NSError * _Nullable error)
     {
         XCTAssertTrue([result isEqualToString:expectedResult], @"Success should be new success then original, Obtained: %@ expected: %@", result, expectedResult);
     }];
}

#pragma mark Failure

- (void)test_coalesceFailureWithTaskInfo_FailureShouldBeNil
{
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [self.insertedTask coalesceWithTaskInfo:newTask];
    
    XCTAssertNil(self.insertedTask.failure, "Failure should be nil");
}

- (void)test_coalesceFailureWithTaskInfo_FailureShouldBeOriginalSuccess
{
    __weak typeof(self) weakSelf = self;
    
    self.failureExpectation = [self expectationWithDescription:@"Failure should be Original task's"];
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                                         {
                                             [weakSelf.failureExpectation fulfill];
                                         }
                                                                             completion:nil];
    
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didFailWithError:nil];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceFailureWithTaskInfo_FailureShouldBeNewFailure
{
    __weak typeof(self) weakSelf = self;
    
    self.failureExpectation = [self expectationWithDescription:@"Failure should be New task's"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                                    {
                                        [weakSelf.failureExpectation fulfill];
                                    }
                                                                        completion:nil];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:nil
                                                                             completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didFailWithError:nil];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceFailureWithTaskInfo_FailureShouldBeNewOrginalThenNew
{
    __weak typeof(self) weakSelf = self;
    
    __block NSString *result = @"";
    
    __block NSString *originalFailure = @"1";
    
    __block NSString *newFailure = @"2";
    
    __block NSString *expectedResult = @"12";
    
    __block XCTestExpectation *originalFailureExpectation = [self expectationWithDescription:@"Original task's expectation was not met"];
    
    self.failureExpectation = [self expectationWithDescription:@"New task's expectation was not met"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                                    {
                                        result = [NSString stringWithFormat:@"%@%@", result, newFailure];
                                        
                                        [weakSelf.failureExpectation fulfill];
                                    }
                                                                        completion:nil];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
                                         {
                                             result = [NSString stringWithFormat:@"%@%@", result, originalFailure];
                                             
                                             [originalFailureExpectation fulfill];
                                         }
                                                                             completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didFailWithError:nil];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:^(NSError * _Nullable error)
     {
         XCTAssertTrue([result isEqualToString:expectedResult], @"Failure should be new failure then original, Obtained: %@ expected: %@", result, expectedResult);
     }];
}

#pragma mark Completion

- (void)test_coalesceCompletionWithTaskInfo_CompletionShouldBeNil
{
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [self.insertedTask coalesceWithTaskInfo:newTask];
    
    XCTAssertNil(self.insertedTask.completion, "Completion should be nil");
}

- (void)test_coalesceCompletionWithTaskInfo_CompletionShouldBeOriginalCompletion
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    self.completionExpectation = [self expectationWithDescription:@"Completion should be Original task's"];
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:nil
                                                                             completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                                         {
                                             [weakSelf.completionExpectation fulfill];
                                         }];
    
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewCompletion
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    self.completionExpectation = [self expectationWithDescription:@"Completion should be New task's"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                                    {
                                        [weakSelf.completionExpectation fulfill];
                                    }];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:nil
                                                                             completion:nil];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:nil];
}

- (void)test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewOrginalThenNew
{
    __weak typeof(self) weakSelf = self;
    
    NSString *locationString = @"LocationString";
    
    __block NSString *result = @"";
    
    __block NSString *originalCompletion = @"1";
    
    __block NSString *newCompletion = @"2";
    
    __block NSString *expectedResult = @"12";
    
    __block XCTestExpectation *originalCompletionsExpectation = [self expectationWithDescription:@"Original task's expectation was not met"];
    
    self.completionExpectation = [self expectationWithDescription:@"New task's expectation was not met"];
    
    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                               URL:nil
                                                                           session:self.session
                                                                   stackIdentifier:nil
                                                                          progress:nil
                                                                           success:nil
                                                                           failure:nil
                                                                        completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                                    {
                                        result = [NSString stringWithFormat:@"%@%@", result, newCompletion];
                                        
                                        [weakSelf.completionExpectation fulfill];
                                    }];
    
    
    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                    URL:nil
                                                                                session:self.session
                                                                        stackIdentifier:nil
                                                                               progress:nil
                                                                                success:nil
                                                                                failure:nil
                                                                             completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
                                         {
                                             result = [NSString stringWithFormat:@"%@%@", result, originalCompletion];
                                             
                                             [originalCompletionsExpectation fulfill];
                                         }];
    
    [originalTask coalesceWithTaskInfo:newTask];
    
    
    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]];
    
    [self waitForExpectationsWithTimeout:0.1
                                 handler:^(NSError * _Nullable error)
     {
         XCTAssertTrue([result isEqualToString:expectedResult], @"Completion should be new completion then original, Obtained: %@ expected: %@", result, expectedResult);
     }];
}


#pragma mark - IsEqual

- (void)test_isEqual_ShouldReturnNO_nilObject
{
    XCTAssertFalse([self.insertedTask isEqual:nil], @"Is Equal should return NO if the object is nil");
}

- (void)test_isEqual_ShouldReturnNO_otherClass
{
    NSString *otherObject= @"";
    
    XCTAssertFalse([self.insertedTask isEqual:otherObject], @"Is Equal should return NO if the object is not of the EDSDownloadTaskInfo class");
}

- (void)test_isEqual_ShouldReturnNO
{
    EDSDownloadTaskInfo *otherTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
                                                                                 URL:nil
                                                                             session:self.session
                                                                     stackIdentifier:nil
                                                                            progress:nil
                                                                             success:nil
                                                                             failure:nil
                                                                          completion:nil];
    
    XCTAssertFalse([self.insertedTask isEqual:otherTask], @"Is Equal should return NO if the object if objects have different DownloadIds");
}

- (void)test_isEqual_ShouldReturnYES
{
    EDSDownloadTaskInfo *otherTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
                                                                                 URL:nil
                                                                             session:self.session
                                                                     stackIdentifier:nil
                                                                            progress:nil
                                                                             success:nil
                                                                             failure:nil
                                                                          completion:nil];
    
    XCTAssertTrue([self.insertedTask isEqual:otherTask], @"Is Equal should return YES if the object if objects have same DownloadIds");
}

#pragma mark - ReleaseMemory

- (void)test_releaseMemory_downloadProgressShouldUpdate
{
    self.insertedTask.downloadProgress = 9.0f;
    
    [self.insertedTask releaseMemory];
    
    XCTAssertEqual(self.insertedTask.downloadProgress, 0.0f, @"DownloadProgress should be 0.0");
}

- (void)test_releaseMemory_taskResumeDataShouldBeNil
{
    self.insertedTask.taskResumeData = [@"this is a text" dataUsingEncoding:kCFStringEncodingUTF8];
    
    [self.insertedTask releaseMemory];
    
    XCTAssertNil(self.insertedTask.taskResumeData, @"TaskResumeData should be nil");
}

@end
