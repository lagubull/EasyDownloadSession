//
//  DownloadSessionTest.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 18/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import XCTest

@testable import EasyDownloadSession

class DownloadSessionTest: XCTestCase {
    
    var stack: Stack?
    
    let stackIdentifier = "stackIdentifier"
    let downloadId = "DownloadId"
    let testURL = NSURL(string: "URL")!
    var soughtAfterTask: DownloadTaskInfo? = DownloadTaskInfo()
    
    let delay: UInt32 = 1
    
    override func setUp() {
        
        super.setUp()
        
        self.stack = Stack()
        
        soughtAfterTask!.downloadId = downloadId
        
        DownloadSession.sharedInstance.registerStack(stack: stack!, stackIdentifier: stackIdentifier)
    }
    
    override func tearDown() {
        
        DownloadSession.cancelDownloads()
        
        self.stack = nil
        
        soughtAfterTask = nil
        
        super.tearDown()
    }
    
    //MARK: - scheduleDownloadWithId
    
    func test_scheduleDownloadWithId_fromURL_completion_shouldAddTask() {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ScheduleDownloadWithId should add a task to the stack")
    }
    
    func test_scheduleDownloadWithId_request_completion_shouldAddTask() {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: NSURLRequest(URL: testURL),
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ScheduleDownloadWithId should add a task to the stack")
        
    }
    
    func test_scheduleDownloadWithId_fromURL_success_shouldAddTask() {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               success: nil,
                                               failure: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ScheduleDownloadWithId should add a task to the stack")
        
    }
    
    func test_scheduleDownloadWithId_request_success_shouldAddTask() {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: NSURLRequest(URL: testURL),
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               success: nil,
                                               failure: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ScheduleDownloadWithId should add a task to the stack")
    }
    
    //MARK: - ForceDownload
    
    func test_forceDownloadWithId_fromURL_completion_shouldAddTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ForceDownloadWithId should add a task to the stack")
        
    }
    
    func test_forceDownloadWithId_request_completion_shouldAddTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest(URL: testURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ForceDownloadWithId should add a task to the stack")
    }
    
    func test_forceDownloadWithId_fromURL_success_shouldAddTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssert(resultingTaskArray.count == 1, "ForceDownloadWithId should add a task to the stack")
    }
    
    func test_forceDownloadWithId_request_success_shouldAddTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest(URL: testURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: nil)
        
        let resultingTaskArray = (DownloadSession.sharedInstance.inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask!)
        
        XCTAssertTrue(resultingTaskArray.count == 1, "ForceDownloadWithId should add a task to the stack")
    }
    
    func test_forceDownloadWithId_request_success_shouldExecuteSuccess() {
        
        weak var expectation = expectationWithDescription("Success expectation")
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest(URL: testURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: { (downloadTask: DownloadTaskInfo, resposeData: NSData?) in
                                                
                                                expectation?.fulfill()
            },
                                            failure: nil)
        
        DownloadSession.sharedInstance.inProgressDownloadsDictionary.first!.1.didSucceedWithLocation(NSURL(string: "locationString")!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_forceDownloadWithId_request_success_shouldExecuteFailure() {
        
        weak var expectation = expectationWithDescription("Failure expectation")
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest(URL: testURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: nil,
                                            failure: { (downloadTask: DownloadTaskInfo, error: NSError?) in
                                                
                                                expectation?.fulfill()
        })

        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    //MARK: - CancelDownloads
    
    func test_cancelDownloads_shouldStopCurrentDownloads() {
        
        for i in 0...4 {
            
            DownloadSession.forceDownloadWithId("\(i)\(downloadId)",
                                                fromURL: testURL,
                                                stackIdentifier: stackIdentifier,
                                                progress: nil,
                                                completion: nil)
        }
        
        
        DownloadSession.cancelDownloads()
        
        XCTAssert(DownloadSession.sharedInstance.inProgressDownloadsDictionary.count == 0, "CancelDownloads should stop all current downloads")
    }
    
    func test_cancelDownloads_shouldStopScheduledDownloads() {
        
        stack?.maxDownloads = 1
        
        for i in 0...4 {
            
            DownloadSession.forceDownloadWithId("\(i)\(downloadId)",
                                                fromURL: testURL,
                                                stackIdentifier: stackIdentifier,
                                                progress: nil,
                                                completion: nil)
        }
        
        DownloadSession.cancelDownloads()
        
        XCTAssert(stack!.count == 0, "CancelDownloads should stop all pending downloads")
    }
    
    //MARK: - CancelDownload
    
    func test_cancelDownload() {
        
        stack?.maxDownloads = 1
        
        DownloadSession.forceDownloadWithId("\(downloadId)",
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        DownloadSession.cancelDownload("\(downloadId)",
                                       stackIdentifier: stackIdentifier)
        
        XCTAssert(stack!.count == 0, "CancelDownload should stop the specified download")
    }
    
    //MARK: - Resume
    
    func test_resumeDownloads_shouldStarThePendingDownloads_force() {
        
        var expectations: Array<XCTestExpectation> = []
        
        for i in 0...18 {
            
            expectations.append(expectationWithDescription("Task \(i) expectation"))
            
            DownloadSession.forceDownloadWithId("\(i)\(downloadId)",
                                                fromURL: testURL,
                                                stackIdentifier: stackIdentifier,
                                                progress: nil,
                                                completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                    
                                                    expectations[i].fulfill()
            })
        }
        
        DownloadSession.pauseDownloads()
        
        sleep(delay)
        
        DownloadSession.resumeDownloads()
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    func test_resumeDownloads_shouldStarThePendingDownloads_schedule() {
        
        var expectations: Array<XCTestExpectation> = []
        
        for i in 0...18 {
            
            expectations.append(expectationWithDescription("Task \(i) expectation"))
            
            DownloadSession.scheduleDownloadWithId("\(i)\(downloadId)",
                                                   fromURL: testURL,
                                                   stackIdentifier: stackIdentifier,
                                                   progress: nil,
                                                   completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                    
                                                    expectations[i].fulfill()
            })
        }
        
        DownloadSession.pauseDownloads()
        
        sleep(delay)
        
        DownloadSession.resumeDownloads()
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    func test_resumeDownloadsInStack() {
        
        var expectations: Array<XCTestExpectation> = []
        
        for i in 0...18 {
            
            expectations.append(expectationWithDescription("Task \(i) expectation"))
            
            DownloadSession.scheduleDownloadWithId("\(i)\(downloadId)",
                                                   fromURL: testURL,
                                                   stackIdentifier: stackIdentifier,
                                                   progress: nil,
                                                   completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                    
                                                    expectations[i].fulfill()
            })
        }
        
        DownloadSession.pauseDownloads()
        
        sleep(delay)
        
        DownloadSession.resumeDownloadsInStack(stackIdentifier)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler:nil)
    }
    
    //MARK: - Pause
    
    func test_pauseDownloads_allDownloadsBackInStack() {
        
        let downloadsCount = 18
        
        for i in 1...downloadsCount {
            
            DownloadSession.scheduleDownloadWithId("\(i)\(downloadId)",
                                                   fromURL: testURL,
                                                   stackIdentifier: stackIdentifier,
                                                   progress: nil,
                                                   completion: nil)
        }
        
        DownloadSession.pauseDownloads()
        
        XCTAssert(stack!.count == downloadsCount, "PauseDownloads should put all downloads back in the stack, exepcted: \(downloadsCount) found: \(stack!.count)")
    }
    
    func test_pauseDownloads_noDownloadShouldBeExecuting() {
        
        let downloadsCount = 18
        
        for i in 0...downloadsCount {
            
            DownloadSession.scheduleDownloadWithId("\(i)\(downloadId)",
                                                   fromURL: testURL,
                                                   stackIdentifier: stackIdentifier,
                                                   progress: nil,
                                                   completion: nil)
        }
        
        DownloadSession.pauseDownloads()
        
        XCTAssert(stack!.currentDownloads == 0, "PauseDownloads: should have all downloads stopped, exepcted: 0 found: \(stack!.currentDownloads)")
    }
    
    func test_pauseDownloads_allDownloadsShouldBeSuspended() {
        
        let downloadsCount = 18
        var areAllDownloadsSuspended = true
        
        for i in 0...downloadsCount {
            
            DownloadSession.scheduleDownloadWithId("\(i)\(downloadId)",
                                                   fromURL: testURL,
                                                   stackIdentifier: stackIdentifier,
                                                   progress: nil,
                                                   completion: nil)
        }
        
        DownloadSession.pauseDownloads()
        
        for task in stack!.downloadsArray {
            
            if areAllDownloadsSuspended &&
                task.task!.state == .Running {
                
                areAllDownloadsSuspended = false
            }
        }
        
        XCTAssert(areAllDownloadsSuspended, "PauseDownloads: should have all downloads suspended")
    }
    
    //MARK: - ShouldCoalesceDownloadTask
    
    func test_shouldCoalesceDownloadTask_scheduleDownloadWithId_inProgressTask_coalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -2
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 == runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_scheduleDownloadWithId_inProgressTask_notCoalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -1
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.scheduleDownloadWithId("NEW\(downloadId)",
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 != runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_scheduleDownloadWithId_suspendedTask_coalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -2
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.pauseDownloads()
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 == runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_scheduleDownloadWithId_suspendedTask_notCoalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -1
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.pauseDownloads()
        
        sleep(delay)
        
        DownloadSession.scheduleDownloadWithId("NEW\(downloadId)",
                                               fromURL: testURL,
                                               stackIdentifier: stackIdentifier,
                                               progress: nil,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 != runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_forceDownloadWithId_inProgressTask_coalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -2
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 == runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_forceDownloadWithId_inProgressTask_notCoalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -1
        
         weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
         weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.forceDownloadWithId("NEW\(downloadId)",
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.2,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 != runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_forceDownloadWithId_suspended_coalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -2
        
        weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
        weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.pauseDownloads()
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 == runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    func test_shouldCoalesceDownloadTask_forceDownloadWithId_suspendedTask_notCoalescing() {
        
        var runningTaskIdentifier1: Int = -1
        var runningTaskIdentifier2: Int = -1
        
         weak var runningTask1Expectation = expectationWithDescription("Task 1 expectation")
         weak var runningTask2Expectation = expectationWithDescription("Task 2 expectation")
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier1 = downloadTask.task!.taskIdentifier
                                                runningTask1Expectation?.fulfill()
        })
        
        DownloadSession.pauseDownloads()
        
        DownloadSession.forceDownloadWithId("NEW\(downloadId)",
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                runningTaskIdentifier2 = downloadTask.task!.taskIdentifier
                                                runningTask2Expectation?.fulfill()
        })
        
        waitForExpectationsWithTimeout(0.2,
                                       handler: { (error: NSError?) in
                                        
                                        XCTAssert(runningTaskIdentifier1 != runningTaskIdentifier2, "Task did not coalesce: found task1: \(runningTaskIdentifier1) and task2: \(runningTaskIdentifier2)")
        })
    }
    
    //MARK: - Finalize
    
    func test_finalizeTask_shoudlRemoveFromInProgressDictionary() {
        
        let failMessage = "FinalizeTask should remove it from the inProgressDictionary"
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        guard let task = DownloadSession.sharedInstance.inProgressDownloadsDictionary.first?.1 else {
            
            XCTFail(failMessage)
            
            return
        }
        
        DownloadSession.sharedInstance.finalizeTask(task)
        
        XCTAssert(DownloadSession.sharedInstance.inProgressDownloadsDictionary.count == 0, failMessage)
    }
    
    func test_finalizeTask_shoudlDecreaseCurrentTasksCounter() {
        
        let failMessage = "FinalizeTask should Decrease the number of active downloads"
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        guard let task = DownloadSession.sharedInstance.inProgressDownloadsDictionary.first?.1 else {
            
            XCTFail(failMessage)
            
            return
        }
        
        DownloadSession.sharedInstance.finalizeTask(task)
        
        XCTAssert(stack!.currentDownloads == 0, failMessage)
    }
    
    //MARK: - TaskWithIdentifier
    
    func test_taskInfoWithIdentfier_suspendedTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        DownloadSession.pauseDownloads()
        
        let task: DownloadTaskInfo = DownloadSession.sharedInstance.taskInfoWithIdentfier(downloadId,
                                                                                          stackIdentifier: stackIdentifier)!
        
        XCTAssert(task.downloadId.isEqual(downloadId), "taskInfoWithIdentfier Should Return the task from the suspended tasks pool")
    }
    
    func test_taskInfoWithIdentfier_CurrentTask() {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            fromURL: testURL,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            completion: nil)
        
        let task: DownloadTaskInfo = DownloadSession.sharedInstance.taskInfoWithIdentfier(downloadId,
                                                                                          stackIdentifier: stackIdentifier)!
        
        XCTAssert(task.downloadId.isEqual(downloadId), "taskInfoWithIdentfier Should Return the task from the current tasks pool")
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
    
    //MARK: - NSURLSessionDownloadDelegate
    
    func test_didFinishDownloadingToURL() {
        
        let expectation = expectationWithDescription(" expectation")
        
        let session = SessionMock()
        
        let originalTask = DownloadTaskInfo(downloadId: downloadId,
                                            URL: testURL,
                                            session: session,
                                            stackIdentifier: stackIdentifier,
                                            progress: nil,
                                            success: { (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                                
                                                expectation.fulfill()
            },
                                            failure: nil,
                                            completion: nil)
        
        originalTask.resume()
        
        DownloadSession.sharedInstance.inProgressDownloadsDictionary[originalTask.task!.taskIdentifier] = originalTask
        
        swizzleNSDataWithContentsOfFile(on: true)
        
        DownloadSession.sharedInstance.URLSession(session,
                                                  downloadTask: originalTask.task!,
                                                  didFinishDownloadingToURL: NSURL(string: "URLString")!)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
        
        swizzleNSDataWithContentsOfFile(on: false)
    }
    
    func test_progress() {
        
        let expectation = expectationWithDescription(" expectation")
        
        let session = SessionMock()
        
        let originalTask = DownloadTaskInfo(downloadId: downloadId,
                                            URL: testURL,
                                            session: session,
                                            stackIdentifier: stackIdentifier,
                                            progress: { (downloadTask: DownloadTaskInfo!) in
                                                
                                                expectation.fulfill()
            },
                                            success: nil,
                                            failure: nil,
                                            completion: nil)
        
        originalTask.resume()
        
        DownloadSession.sharedInstance.inProgressDownloadsDictionary[originalTask.task!.taskIdentifier] = originalTask
        
        DownloadSession.sharedInstance.URLSession(session,
                                                  downloadTask: originalTask.task!,
                                                  didWriteData: 1,
                                                  totalBytesWritten: 10,
                                                  totalBytesExpectedToWrite: 10)
        
        waitForExpectationsWithTimeout(0.1,
                                       handler: nil)
    }
}
