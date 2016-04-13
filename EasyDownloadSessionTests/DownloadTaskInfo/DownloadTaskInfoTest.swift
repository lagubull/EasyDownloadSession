//
//  DownloadTaskInfoTest.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 12/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import XCTest

@testable import EasyDownloadSession

class DownloadTaskInfoTest: XCTestCase {
    
    var insertedTask: DownloadTaskInfo?
    var insertedTaskId: String?
    var task: SessionTaskMock?
    var session: SessionMock?
    
    var progressExpectation: XCTestExpectation?
    var successExpectation: XCTestExpectation?
    var failureExpectation: XCTestExpectation?
    var completionExpectation: XCTestExpectation?
    
    //MARK: TestLifeCycle
    
    override func setUp() {
        
        super.setUp()
        
        self.insertedTaskId = "TASKID";
        
        self.session =  SessionMock()
        
        self.insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                             URL: NSURL(string: "URL")!,
                                             session: self.session!,
                                             stackIdentifier: "SessionIdentifier",
                                             progress: nil,
                                             success: nil,
                                             failure: nil,
                                             completion: nil)
        
        self.insertedTask?.isDownloading = true
        self.task = SessionTaskMock()
        self.insertedTask?.task = self.task;
    }
    
    override func tearDown() {
        
        self.insertedTaskId = nil
        
        self.task = nil
        
        self.insertedTask = nil
        
        super.tearDown()
    }
    
    //MARK: Pause
    
    func test_pause_isDownloadingShouldBeNO() {
        
        insertedTask?.pause()
        
        XCTAssertFalse((insertedTask?.isDownloading)!, "IsDownloading should be NO");
    }
    
    func test_pause_taskShouldBeSuspended() {
        
        insertedTask?.pause()
        
        XCTAssertTrue(task!.didInvokeSuspend!, "Task suspend was not invoked");
    }
    
    func test_pause_taskCancelByProducingResumeDataInvoked() {
        
        insertedTask?.pause()
        
        XCTAssertTrue(task!.didInvokeCancelByProducingResumeDataInvoked!, "Task CancelByProducingResumeData suspend was not invoked");
    }
    
    func test_pause_taskCurrentDataIsSaved() {
        
        let expectation = expectationWithDescription("Data should be saved") as XCTestExpectation
        
        task!.pausedSavedDataExpectation = expectation;
        
        insertedTask?.task = task;
        
        insertedTask?.pause()
        
        waitForExpectationsWithTimeout(1.0, handler: { (error: NSError?) in
            
            XCTAssertEqual(self.insertedTask?.taskResumeData, self.task!.pausedSavedData, "Data was not saved")
        })
    }
    
    //MAR: Resume
    
    func test_resume_isDownloadindShouldBeYES() {
        
        insertedTask?.resume()
        
        XCTAssertTrue((insertedTask?.isDownloading)!, "IsDownloading should be YES")
    }
    
    func test_resume_taskResumeShouldBeInvoked() {
        
        insertedTask?.resume()
        
        XCTAssertTrue(self.task!.didInvokeResume!, "Task Resume suspend was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithResumeDataShouldBeInvoked() {
        
        let stringToBeData = "This is a text"
        
        insertedTask?.taskResumeData = stringToBeData.dataUsingEncoding(NSUTF8StringEncoding)
        
        insertedTask?.resume()
        
        XCTAssertTrue(self.session!.didInvokeDownloadTaskWithResumeData!, "Task DownloadTaskWithResumeData was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithRequestShouldBeInvoked() {
        
        //We need to change the value manually as initialization will call this method aswell
        session!.didInvokeDownloadTaskWithRequest = false
        
        task!.state = .Completed
        
        insertedTask?.resume()
        
        XCTAssertTrue(session!.didInvokeDownloadTaskWithRequest!, "Task DownloadTaskWithRequest was not invoked");
    }
    
    //MARK: Progress
    
    func test_didUpdateProgress_progessIsUpdated() {
        
        let newProgress = 5.0 as CGFloat
        
        insertedTask?.didUpdateProgress(newProgress)
        
        XCTAssertEqual(insertedTask?.downloadProgress, newProgress, "Progress was not updated, currentProgress: \(insertedTask?.downloadProgress), expected: \(newProgress)");
    }
    
    func test_didUpdateProgress_progessShouldBeInvoked () {
        
        let newProgress = 5.0 as CGFloat
        
        insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                        URL: NSURL(string: "URL")!,
                                        session: self.session!,
                                        stackIdentifier: "SessionIdentifier",
                                        progress: { [unowned self] (downloadTask: DownloadTaskInfo!) in
                                            
                                            self.progressExpectation?.fulfill()
            },
                                        success: nil,
                                        failure: nil,
                                        completion: nil)
        
        insertedTask?.didUpdateProgress(newProgress)
        
        progressExpectation = expectationWithDescription("Progress expectation")
        
        self.waitForExpectationsWithTimeout(0.1,
                                            handler: nil)
    }
    
    
    //MARK: Success
    
    func test_didSucceedWithLocation_successLocationIsUsed() {
        
        let locationString = "LocationString"
        
        let originalSelector = #selector(NSData.init(contentsOfFile:))
        let swizzledSelector =  #selector(NSData.new_dataWithContentsOfFile(_:))
        
        let originalMethod = class_getInstanceMethod(NSData.self, originalSelector);
        let swizzledMethod = class_getClassMethod(NSData.self, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                        URL: NSURL(string: "URL")!,
                                        session: self.session!,
                                        stackIdentifier: "SessionIdentifier",
                                        progress: nil,
                                        success: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                            
                                            guard let responseData = responseData else { return }
                                            
                                            let resultString =  String(data: responseData, encoding: NSUTF8StringEncoding)
                                            
                                            guard let unwrappedResultString = resultString else { return }
                                            
                                            if unwrappedResultString.isEqual(locationString) {
                                                
                                                self.successExpectation?.fulfill()
                                            }
            },
                                        failure: nil,
                                        completion: nil)
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        successExpectation = expectationWithDescription("Location is not used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
        
        method_exchangeImplementations(swizzledMethod, originalMethod);
    }
    
    func test_didSucceedWithLocation_didFailWithErrorIsInvoked() {
        
        let task =  DownloadTaskInfoMock(downloadId: self.insertedTaskId!,
                                         URL: NSURL(string: "URL")!,
                                         session: self.session!,
                                         stackIdentifier: "SessionIdentifier",
                                         progress: nil,
                                         success: nil,
                                         failure: nil,
                                         completion: nil)
        
        
        task.didSucceedWithLocation(NSURL(string: "URL")!)
        
        XCTAssertTrue(task.didInvokeDidFailWithError, "DidFailWithError was not invoked");
    }
    
    func test_didSucceedWithLocation_completionLocationIsUsed() {
        
        let locationString = "LocationString"
        
        let originalSelector = #selector(NSData.init(contentsOfFile:))
        let swizzledSelector =  #selector(NSData.new_dataWithContentsOfFile(_:))
        
        let originalMethod = class_getInstanceMethod(NSData.self, originalSelector);
        let swizzledMethod = class_getClassMethod(NSData.self, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                        URL: NSURL(string: "URL")!,
                                        session: self.session!,
                                        stackIdentifier: "SessionIdentifier",
                                        progress: nil,
                                        success:nil,
                                        failure:nil,
                                        completion: { [unowned self] (downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) in
                                            
                                            guard let responseData = responseData else { return }
                                            
                                            let resultString =  String(data: responseData, encoding: NSUTF8StringEncoding)
                                            
                                            guard let unwrappedResultString = resultString else { return }
                                            
                                            if unwrappedResultString.isEqual(locationString) {
                                                
                                                self.completionExpectation?.fulfill()
                                            }
            })
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        completionExpectation = expectationWithDescription("Location is not used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        method_exchangeImplementations(swizzledMethod, originalMethod);
    }
    
    //MARK: Failure
    
    func test_didFailWithError_failureErrorIsUsed() {
        
        let testError = NSError(domain: "domain",
                                code: 0,
                                userInfo: nil)
        
        insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                        URL: NSURL(string: "URL")!,
                                        session: self.session!,
                                        stackIdentifier: "SessionIdentifier",
                                        progress: nil,
                                        success:nil,
                                        failure: { [unowned self] (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                            
                                            guard let error = error else { return }
                                            
                                            if error.isEqual(testError) {
                                                
                                                self.failureExpectation?.fulfill()
                                            }
            },
                                        completion:nil)
        
        insertedTask?.didFailWithError(testError)
        
        failureExpectation = expectationWithDescription("Failure Error is never used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
    
    func test_didFailWithError_completionErrorIsUsed() {
        
        let testError = NSError(domain: "domain",
                                code: 0,
                                userInfo: nil)
        
        insertedTask = DownloadTaskInfo(downloadId: self.insertedTaskId!,
                                        URL: NSURL(string: "URL")!,
                                        session: self.session!,
                                        stackIdentifier: "SessionIdentifier",
                                        progress: nil,
                                        success:nil,
                                        failure:nil,
                                        completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                            
                                            guard let error = error else { return }
                                            
                                            if error.isEqual(testError) {
                                                
                                                self.completionExpectation?.fulfill()
                                            }
            })
        
        insertedTask?.didFailWithError(testError)
        
        completionExpectation = expectationWithDescription("Completion Error is never used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
    //
    //    //MARK: Coalescing
    //
    //    func test_canCoalesceWithTaskInfo_ShouldReturnYES
    //    {
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    BOOL canCoalesce = [self.insertedTask canCoalesceWithTaskInfo:newTask
    //
    //    XCTAssertTrue(canCoalesce, "CanColaseceWithTaskInfo should return YES");
    //    }
    //
    //    func test_canCoalesceWithTaskInfo_ShouldReturnNO
    //    {
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    BOOL canCoalesce = [self.insertedTask canCoalesceWithTaskInfo:newTask
    //
    //    XCTAssertFalse(canCoalesce, "CanColaseceWithTaskInfo should return NO");
    //    }
    //
    //    //MARK: Success
    //
    //    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNil
    //    {
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [self.insertedTask coalesceWithTaskInfo:newTask
    //
    //    XCTAssertNil(self.insertedTask.success, "Success should be nil");
    //    }
    //
    //    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeOriginalSuccess
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    self.successExpectation = [self expectationWithDescription:@"Success should be Original task's"
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
    //    {
    //    [weakSelf.successExpectation fulfill
    //    }
    //    failure:nil
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewSuccess
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    self.successExpectation = [self expectationWithDescription:@"Success should be New task's"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
    //    {
    //    [weakSelf.successExpectation fulfill
    //    }
    //    failure:nil
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewOrginalThenNew
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    __block NSString *result = @"";
    //
    //    __block NSString *originalSucess = @"1";
    //
    //    __block NSString *newSucess = @"2";
    //
    //    __block NSString *expectedResult = @"12";
    //
    //    __block XCTestExpectation *originalSuccessExpectation = [self expectationWithDescription:@"Original task's expectation was not met"
    //
    //    self.successExpectation = [self expectationWithDescription:@"New task's expectation was not met"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, newSucess
    //
    //    [weakSelf.successExpectation fulfill
    //    }
    //    failure:nil
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, originalSucess
    //
    //    [originalSuccessExpectation fulfill
    //    }
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:^(NSError * _Nullable error)
    //    {
    //    XCTAssertTrue([result isEqualToString:expectedResult], @"Success should be new success then original, Obtained: %@ expected: %@", result, expectedResult);
    //    }
    //    }
    //
    //MARK: Failure
    
    //    func test_coalesceFailureWithTaskInfo_FailureShouldBeNil
    //    {
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [self.insertedTask coalesceWithTaskInfo:newTask
    //
    //    XCTAssertNil(self.insertedTask.failure, "Failure should be nil");
    //    }
    //
    //    func test_coalesceFailureWithTaskInfo_FailureShouldBeOriginalSuccess
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    self.failureExpectation = [self expectationWithDescription:@"Failure should be Original task's"
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
    //    {
    //    [weakSelf.failureExpectation fulfill
    //    }
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didFailWithError:nil
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceFailureWithTaskInfo_FailureShouldBeNewFailure
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    self.failureExpectation = [self expectationWithDescription:@"Failure should be New task's"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
    //    {
    //    [weakSelf.failureExpectation fulfill
    //    }
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didFailWithError:nil
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceFailureWithTaskInfo_FailureShouldBeNewOrginalThenNew
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    __block NSString *result = @"";
    //
    //    __block NSString *originalFailure = @"1";
    //
    //    __block NSString *newFailure = @"2";
    //
    //    __block NSString *expectedResult = @"12";
    //
    //    __block XCTestExpectation *originalFailureExpectation = [self expectationWithDescription:@"Original task's expectation was not met"
    //
    //    self.failureExpectation = [self expectationWithDescription:@"New task's expectation was not met"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, newFailure
    //
    //    [weakSelf.failureExpectation fulfill
    //    }
    //    completion:nil
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:^(EDSDownloadTaskInfo *downloadTask, NSError *error)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, originalFailure
    //
    //    [originalFailureExpectation fulfill
    //    }
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didFailWithError:nil
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:^(NSError * _Nullable error)
    //    {
    //    XCTAssertTrue([result isEqualToString:expectedResult], @"Failure should be new failure then original, Obtained: %@ expected: %@", result, expectedResult);
    //    }
    //    }
    //
    //    #pragma mark Completion
    //
    //    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNil
    //    {
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [self.insertedTask coalesceWithTaskInfo:newTask
    //
    //    XCTAssertNil(self.insertedTask.completion, "Completion should be nil");
    //    }
    //
    //    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeOriginalCompletion
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    self.completionExpectation = [self expectationWithDescription:@"Completion should be Original task's"
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
    //    {
    //    [weakSelf.completionExpectation fulfill
    //    }
    //
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewCompletion
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    self.completionExpectation = [self expectationWithDescription:@"Completion should be New task's"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
    //    {
    //    [weakSelf.completionExpectation fulfill
    //    }
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:nil
    //    }
    //
    //    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewOrginalThenNew
    //    {
    //    __weak typeof(self) weakSelf = self;
    //
    //    NSString *locationString = @"LocationString";
    //
    //    __block NSString *result = @"";
    //
    //    __block NSString *originalCompletion = @"1";
    //
    //    __block NSString *newCompletion = @"2";
    //
    //    __block NSString *expectedResult = @"12";
    //
    //    __block XCTestExpectation *originalCompletionsExpectation = [self expectationWithDescription:@"Original task's expectation was not met"
    //
    //    self.completionExpectation = [self expectationWithDescription:@"New task's expectation was not met"
    //
    //    EDSDownloadTaskInfo *newTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, newCompletion
    //
    //    [weakSelf.completionExpectation fulfill
    //    }
    //
    //
    //    EDSDownloadTaskInfo *originalTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:^(EDSDownloadTaskInfo *downloadTask, NSData *responseData, NSError *error)
    //    {
    //    result = [NSString stringWithFormat:@"%@%@", result, originalCompletion
    //
    //    [originalCompletionsExpectation fulfill
    //    }
    //
    //    [originalTask coalesceWithTaskInfo:newTask
    //
    //
    //    [originalTask didSucceedWithLocation:[NSURL URLWithString:locationString]
    //
    //    [self waitForExpectationsWithTimeout:0.1
    //    handler:^(NSError * _Nullable error)
    //    {
    //    XCTAssertTrue([result isEqualToString:expectedResult], @"Completion should be new completion then original, Obtained: %@ expected: %@", result, expectedResult);
    //    }
    //    }
    //
    //
    //    #pragma mark - IsEqual
    //
    //    func test_isEqual_ShouldReturnNO_nilObject
    //    {
    //    XCTAssertFalse([self.insertedTask isEqual:nil], @"Is Equal should return NO if the object is nil");
    //    }
    //
    //    func test_isEqual_ShouldReturnNO_otherClass
    //    {
    //    NSString *otherObject= @"";
    //
    //    XCTAssertFalse([self.insertedTask isEqual:otherObject], @"Is Equal should return NO if the object is not of the EDSDownloadTaskInfo class");
    //    }
    //
    //    func test_isEqual_ShouldReturnNO
    //    {
    //    EDSDownloadTaskInfo *otherTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    XCTAssertFalse([self.insertedTask isEqual:otherTask], @"Is Equal should return NO if the object if objects have different DownloadIds");
    //    }
    //
    //    func test_isEqual_ShouldReturnYES
    //    {
    //    EDSDownloadTaskInfo *otherTask = [[EDSDownloadTaskInfo alloc] initWithDownloadID:self.insertedTaskId
    //    URL:nil
    //    session:self.session
    //    stackIdentifier:nil
    //    progress:nil
    //    success:nil
    //    failure:nil
    //    completion:nil
    //
    //    XCTAssertTrue([self.insertedTask isEqual:otherTask], @"Is Equal should return YES if the object if objects have same DownloadIds");
    //    }
    //
    //    #pragma mark - ReleaseMemory
    //
    //    func test_releaseMemory_downloadProgressShouldUpdate
    //    {
    //    self.insertedTask.downloadProgress = 9.0f;
    //
    //    [self.insertedTask releaseMemory
    //
    //    XCTAssertEqual(self.insertedTask.downloadProgress, 0.0f, @"DownloadProgress should be 0.0");
    //    }
    //
    //    func test_releaseMemory_taskResumeDataShouldBeNil
    //    {
    //    self.insertedTask.taskResumeData = [@"this is a text" dataUsingEncoding:kCFStringEncodingUTF8
    //
    //    [self.insertedTask releaseMemory
    //
    //    XCTAssertNil(self.insertedTask.taskResumeData, @"TaskResumeData should be nil");
    //    }
}
