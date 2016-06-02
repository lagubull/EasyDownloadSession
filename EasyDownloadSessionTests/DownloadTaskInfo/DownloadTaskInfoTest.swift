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
    var task: SessionTaskMock?
    var session: SessionMock?
    
    weak var progressExpectation: XCTestExpectation?
    weak var successExpectation: XCTestExpectation?
    weak var failureExpectation: XCTestExpectation?
    weak var completionExpectation: XCTestExpectation?
    
    let insertedTaskId = "TASKID"
    let stackIdentifier =  "STACKIDENTIFIER"
    let testURL = NSURL(string: "URL")!
    let locationString = "locationString"
    
    //MARK: - TestLifeCycle
    
    override func setUp() {
        
        super.setUp()
        
        self.session =  SessionMock()
        
        self.insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                             URL: testURL,
                                             session: session!,
                                             stackIdentifier: stackIdentifier,
                                             progress: nil,
                                             success: nil,
                                             failure: nil,
                                             completion: nil)
        
        self.insertedTask?.isDownloading = true
        self.task = SessionTaskMock()
        self.insertedTask?.task = self.task
    }
    
    override func tearDown() {
        
        self.task = nil
        
        self.insertedTask = nil
        
        super.tearDown()
    }
    
    //MARK: - Pause
    
    func test_pause_isDownloadingShouldBeNO() {
        
        insertedTask?.pause()
        
        XCTAssertFalse((insertedTask?.isDownloading)!, "IsDownloading should be NO")
    }
    
    func test_pause_taskShouldBeSuspended() {
        
        insertedTask?.pause()
        
        XCTAssertTrue(task!.didInvokeSuspend!, "Task suspend was not invoked")
    }
    
    func test_pause_taskCancelByProducingResumeDataInvoked() {
        
        insertedTask?.pause()
        
        XCTAssertTrue(task!.didInvokeCancelByProducingResumeDataInvoked!, "Task CancelByProducingResumeData suspend was not invoked")
    }
    
    func test_pause_taskCurrentDataIsSaved() {
        
        let expectation = expectationWithDescription("Data should be saved") as XCTestExpectation
        
        task!.pausedSavedDataExpectation = expectation
        
        insertedTask?.task = task
        
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
        
        task?.resume()
        
        XCTAssertTrue(task!.didInvokeResume!, "Task Resume suspend was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithResumeDataShouldBeInvoked() {
        
        let stringToBeData = "This is a text"
        
        insertedTask?.taskResumeData = stringToBeData.dataUsingEncoding(NSUTF8StringEncoding)
        
        insertedTask?.resume()
        
        XCTAssertTrue(session!.didInvokeDownloadTaskWithResumeData!, "Task DownloadTaskWithResumeData was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithRequestShouldBeInvoked() {
        
        //We need to change the value manually as initialization will call this method aswell
        session!.didInvokeDownloadTaskWithRequest = false
        
        task!.state = .Completed
        
        insertedTask?.resume()
        
        XCTAssertTrue(session!.didInvokeDownloadTaskWithRequest!, "Task DownloadTaskWithRequest was not invoked")
    }
    
    //MARK: - Progress
    
    func test_didUpdateProgress_progessIsUpdated() {
        
        let newProgress = 5.0 as CGFloat
        
        insertedTask?.didUpdateProgress(newProgress)
        
        XCTAssertEqual(insertedTask?.downloadProgress, newProgress, "Progress was not updated, currentProgress: \(insertedTask?.downloadProgress), expected: \(newProgress)")
    }
    
    func test_didUpdateProgress_progessShouldBeInvoked () {
        
        let newProgress = 5.0 as CGFloat
        
        insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
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
    
    
    //MARK: - Success
    
    func test_didSucceedWithLocation_successLocationIsUsed() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
                                        progress: nil,
                                        success: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                            
                                            guard let responseData = responseData else { return }
                                            
                                            let resultString =  String(data: responseData, encoding: NSUTF8StringEncoding)
                                            
                                            guard let unwrappedResultString = resultString else { return }
                                            
                                            if unwrappedResultString.isEqual(self.locationString) {
                                                
                                                self.successExpectation?.fulfill()
                                            }
            },
                                        failure: nil,
                                        completion: nil)
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        successExpectation = expectationWithDescription("Location is not used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }

    func test_didSucceedWithLocation_completionLocationIsUsed() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
                                        progress: nil,
                                        success:nil,
                                        failure:nil,
                                        completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                            
                                            guard let responseData = responseData else { return }
                                            
                                            let resultString =  String(data: responseData, encoding: NSUTF8StringEncoding)
                                            
                                            guard let unwrappedResultString = resultString else { return }
                                            
                                            if unwrappedResultString.isEqual(self.locationString) {
                                                
                                                self.completionExpectation?.fulfill()
                                            }
            })
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        completionExpectation = expectationWithDescription("Location is not used")
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    //MARK: - Failure
    
    func test_didFailWithError_failureErrorIsUsed() {
        
        let testError = NSError(domain: "domain",
                                code: 0,
                                userInfo: nil)
        
        insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
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
        
        insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
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
    
    //MARK: - Coalescing
    
    func test_canCoalesceWithTaskInfo_ShouldReturnYES() {
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        let canCoalesce = insertedTask!.canCoalesceWithTaskInfo(newTask)
        
        XCTAssertTrue(canCoalesce, "CanColaseceWithTaskInfo should return YES")
    }
    
    func test_canCoalesceWithTaskInfo_ShouldReturnNO() {
        
        let newTask = DownloadTaskInfo(downloadId: "NEW\(insertedTaskId)",
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        let canCoalesce = insertedTask!.canCoalesceWithTaskInfo(newTask)
        
        XCTAssertFalse(canCoalesce, "CanColaseceWithTaskInfo should return NO")
    }
    
    //MARK: - Success
    
    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNil() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                        
                                        self.successExpectation?.fulfill()
            })
        
        successExpectation = expectationWithDescription("Success should be nil")
        
        insertedTask?.coalesceWithTaskInfo(newTask)
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeOriginalSuccess() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        successExpectation = expectationWithDescription("Success should be Original task's")
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                                
                                                self.successExpectation?.fulfill()
            },
                                            failure: nil,
                                            completion: nil)
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewSuccess() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        successExpectation = expectationWithDescription("Success should be New task's")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                        
                                        self.successExpectation?.fulfill()
            },
                                       failure: nil,
                                       completion: nil)
        
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_coalesceSuccesWithTaskInfo_SuccessShouldBeNewOrginalThenNew () {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        let originalSuccessExpectation = expectationWithDescription("Original task's expectation was not met")
        
        var result = ""
        
        let originalSucess = "1"
        
        let newSucess = "2"
        
        let expectedResult = "12"
        
        successExpectation = expectationWithDescription("New task's expectation was not met")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                        
                                        result = "\(result)\(newSucess)"
                                        
                                        self.successExpectation?.fulfill()
            },
                                       failure: nil,
                                       completion: nil)
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: { (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                                
                                                result = "\(result)\(originalSucess)"
                                                
                                                originalSuccessExpectation.fulfill()
            },
                                            failure: nil,
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssertTrue(result.isEqual(expectedResult), "Success should be new success then original, Obtained: \(result) expected: \(expectedResult)")
        })
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    //MARK: - Failure
    
    func test_coalesceFailureWithTaskInfo_FailureShouldBeNil() {
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                        
                                        self.failureExpectation?.fulfill()
            })
        
        failureExpectation = expectationWithDescription("Failure should be nil")
        
        insertedTask?.coalesceWithTaskInfo(newTask)
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
    
    func test_coalesceFailureWithTaskInfo_FailureShouldBeOriginalSuccess () {
        
        failureExpectation = expectationWithDescription("Failure should be Original task's")
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: { [unowned self] (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                                
                                                self.failureExpectation?.fulfill()
            },
                                            completion:nil)
        
        
        let newTask =  DownloadTaskInfo(downloadId: insertedTaskId,
                                        URL: testURL,
                                        session: self.session!,
                                        stackIdentifier: stackIdentifier,
                                        progress: nil,
                                        success: nil,
                                        failure: nil,
                                        completion:nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didFailWithError(nil)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
    
    func test_coalesceFailureWithTaskInfo_FailureShouldBeNewFailure () {
        
        failureExpectation = expectationWithDescription("Failure should be New task's")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: { [unowned self] (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                        
                                        self.failureExpectation?.fulfill()
            },
                                       completion:nil)
        
        let originalTask =  DownloadTaskInfo(downloadId: insertedTaskId,
                                             URL: testURL,
                                             session: self.session!,
                                             stackIdentifier: stackIdentifier,
                                             progress: nil,
                                             success: nil,
                                             failure: nil,
                                             completion:nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didFailWithError(nil)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
    
    func test_coalesceFailureWithTaskInfo_FailureShouldBeNewOrginalThenNew() {
        
        let originalFailureExpectation = expectationWithDescription("Original task's expectation was not met")
        
        var result = ""
        
        let originalFailure = "1"
        
        let newFailure = "2"
        
        let expectedResult = "12"
        
        self.failureExpectation = expectationWithDescription("New task's expectation was not met")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: { [unowned self] (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                        
                                        result = "\(result)\(newFailure)"
                                        
                                        self.failureExpectation?.fulfill()
            },
                                       completion: nil)
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: { (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                                
                                                result = "\(result)\(originalFailure)"
                                                
                                                originalFailureExpectation.fulfill()
            },
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didFailWithError(nil)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssertTrue(result.isEqual(expectedResult), "Failure should be new failure then original, Obtained: \(result) expected: \(expectedResult)")
        })
    }
    
    //MARK: - Completion
    
    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNil() {
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        insertedTask?.coalesceWithTaskInfo(newTask)
        
        insertedTask?.didSucceedWithLocation(NSURL(string: locationString)!)
        
        XCTAssertNotNil(insertedTask, "Completion should be nil")
    }
    
    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeOriginalCompletion() {
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        completionExpectation = expectationWithDescription("Completion should be Original task's")
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil,
                                            completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                self.completionExpectation?.fulfill()
            })
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewCompletion() {
        
        completionExpectation = expectationWithDescription("Completion should be New task's")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: { [unowned self] (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                        
                                        self.completionExpectation?.fulfill()
            })
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    func test_coalesceCompletionWithTaskInfo_CompletionShouldBeNewOrginalThenNew() {
        
        let originalCompletionExpectation = expectationWithDescription("Original task's expectation was not met")
        
        var result = ""
        
        let originalCompletion = "1"
        
        let newCompletion = "2"
        
        let expectedResult = "12"
        
        self.completionExpectation = expectationWithDescription("New task's expectation was not met")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                        
                                        result = "\(result)\(newCompletion)"
                                        
                                        self.completionExpectation?.fulfill()
        })
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                result = "\(result)\(originalCompletion)"
                                                
                                                originalCompletionExpectation.fulfill()
        })
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didSucceedWithLocation(NSURL(string: locationString)!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssertTrue(result.isEqual(expectedResult), "Completion should be new completion then original, Obtained: \(result) expected: \(expectedResult)")
        })
    }
    
    //MARK: - Progress
    
    func test_coalesceProgressWithTaskInfo_ProgressShouldBeNil() {
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        insertedTask?.coalesceWithTaskInfo(newTask)
        
        insertedTask?.didUpdateProgress(5.0)
        
        XCTAssertNil(insertedTask!.progress, "Progress should be nil")
    }
    
    func test_coalesceProgressWithTaskInfo_ProgressShouldBeOriginalCompletion() {
        
        progressExpectation = expectationWithDescription("Progress should be Original task's")
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: { [unowned self] (downloadTask: DownloadTaskInfo!) in
                                                
                                                self.progressExpectation?.fulfill()
            },
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: nil,
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didUpdateProgress(5.0)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    func test_coalesceProgressWithTaskInfo_ProgressShouldBeNewCompletion() {
        
        progressExpectation = expectationWithDescription("Progress should be New task's")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress: { [unowned self] (downloadTask: DownloadTaskInfo!) in
                                        
                                        self.progressExpectation?.fulfill()
            },
                                       success: nil,
                                       failure: nil,
                                       completion: nil)
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didUpdateProgress(5.0)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    func test_coalesceProgressWithTaskInfo_ProgressShouldBeNewOrginalThenNew() {
        
        let originalCompletionExpectation = expectationWithDescription("Original task's expectation was not met")
        
        var result = ""
        
        let originalProgress = "1"
        
        let newProgress = "2"
        
        let expectedResult = "12"
        
        self.completionExpectation = expectationWithDescription("New task's expectation was not met")
        
        let newTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                       URL: testURL,
                                       session: self.session!,
                                       stackIdentifier: stackIdentifier,
                                       progress:  { (downloadTask: DownloadTaskInfo!) in
                                        
                                        result = "\(result)\(newProgress)"
                                        
                                        self.completionExpectation?.fulfill()
            },
                                       success: nil,
                                       failure: nil,
                                       completion:nil)
        
        let originalTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                            URL: testURL,
                                            session: self.session!,
                                            stackIdentifier: stackIdentifier,
                                            progress: { (downloadTask: DownloadTaskInfo!) in
                                                
                                                result = "\(result)\(originalProgress)"
                                                
                                                originalCompletionExpectation.fulfill()
            },
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        originalTask.coalesceWithTaskInfo(newTask)
        
        originalTask.didUpdateProgress(5.0)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssertTrue(result.isEqual(expectedResult), "Progress should be new progress then original, Obtained: \(result) expected: \(expectedResult)")
        })
    }
    
    //MARK: - IsEqual
    
    func test_isEqual_ShouldReturnNO_nilObject() {
        
        XCTAssertFalse(insertedTask!.isEqual(nil), "Is Equal should return NO if the object is nil")
    }
    
    func test_isEqual_ShouldReturnNO_otherClass() {
        
        let otherObject = ""
        
        XCTAssertFalse(insertedTask!.isEqual(otherObject), "Is Equal should return NO if the object is not of the EDSDownloadTaskInfo class")
    }
    
    func test_isEqual_ShouldReturnNO() {
        
        let otherTask = DownloadTaskInfo(downloadId: "NEW\(insertedTaskId)",
                                         URL: testURL,
                                         session: self.session!,
                                         stackIdentifier: stackIdentifier,
                                         progress: nil,
                                         success: nil,
                                         failure: nil,
                                         completion: nil)
        
        XCTAssertFalse(insertedTask!.isEqual(otherTask), "Is Equal should return NO if the object if objects have different DownloadIds")
    }
    
    func test_isEqual_ShouldReturnYES() {
        
        let otherTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                         URL: testURL,
                                         session: self.session!,
                                         stackIdentifier: stackIdentifier,
                                         progress: nil,
                                         success: nil,
                                         failure: nil,
                                         completion: nil)
        
        XCTAssertTrue(insertedTask!.isEqual(otherTask), "Is Equal should return YES if the object if objects have same DownloadIds")
    }
    
    //MARK: - ReleaseMemory
    
    func test_releaseMemory_downloadProgressShouldUpdate() {
        
        insertedTask?.downloadProgress = 9.0
        
        insertedTask?.releaseMemory()
        
        XCTAssertEqual(insertedTask!.downloadProgress, 0.0, "DownloadProgress should be 0.0")
    }
    
    func test_releaseMemory_taskResumeDataShouldBeNil() {
        
        insertedTask?.taskResumeData = "this is a text".dataUsingEncoding(NSUTF8StringEncoding)
        
        insertedTask?.releaseMemory()
        
        XCTAssertNil(insertedTask!.taskResumeData, "TaskResumeData should be nil")
    }
    
    //MARK: - Swizzle
    
    /**
     Swaps the implementation of NSData.init(contentsOfFile:) with our mocked one.
     
     - Parameter on: True - original to swizzled, False - swizzled to original
     */
    func swizzleNSDataWithContentsOfFile(on on: Bool) {
        
        let originalSelector = #selector(NSData.init(contentsOfFile:))
        let swizzledSelector =  #selector(NSData.new_dataWithContentsOfFile(_:))
        
        let originalMethod = class_getInstanceMethod(NSData.self, originalSelector)
        let swizzledMethod = class_getClassMethod(NSData.self, swizzledSelector)
        
        if on {
            
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        else {
            
            method_exchangeImplementations(swizzledMethod, originalMethod)
        }
    }
}
