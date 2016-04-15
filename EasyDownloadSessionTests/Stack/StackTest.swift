//
//  StackTest.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 15/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import XCTest

@testable import EasyDownloadSession

//configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

class StackTest: XCTestCase {
    
    //MARK: Getters
    
    var stack: Stack?
    var session: SessionMock?
    var insertedTask: DownloadTaskInfo?
    
    let insertedTaskId = "TASKID"
    let sessionIdentifier =  "SESSIONIDENTIFIER"
    let testURL = NSURL(string: "URL")!
    let locationString = "locationString"
    
    //MARK: TestLifeCycle
    
    override func setUp() {
        
        super.setUp()
        
        stack = Stack()
        
        self.session =  SessionMock()
        
        self.insertedTask = DownloadTaskInfo(downloadId: insertedTaskId,
                                             URL: testURL,
                                             session: session!,
                                             stackIdentifier: sessionIdentifier,
                                             progress: nil,
                                             success: nil,
                                             failure: nil,
                                             completion: nil)
    }
    
    override func tearDown() {
        
        self.stack?.clear()
        
        self.stack = nil;
        
        self.insertedTask = nil;
        
        super.tearDown()
    }
    
    //MARK: Push
    
    func test_push_shouldAddItem() {
        
        stack?.push(insertedTask!)
        
        XCTAssertEqual(stack!.downloadsArray[0], insertedTask, "Item was not inserted in stack");
    }
    
    func test_push_countShouldMatchItemNumbers () {
        
        for _ in 0...2 {
            
            stack?.push(insertedTask!)
        }
        
        XCTAssertEqual(self.stack!.downloadsArray.count, self.stack!.count, "Item count\(self.stack!.downloadsArray.count) does not match \(self.stack!.count)items in the stack")
    }
    
    //MARK: CanPop
    
    func test_canPopTask_ShouldReturnYes() {
        
        for _ in 0...2 {
            
            stack?.push(insertedTask!)
        }
        
        let canPopTask = stack!.canPopTask()
        
        XCTAssertTrue(canPopTask, "canPopTask should return YES")
    }
    
    func test_canPopTask_ShouldReturnNO_EmptyStack() {
        
        let canPopTask = stack!.canPopTask()
        
        XCTAssertFalse(canPopTask, "canPopTask should return NO)")
    }
    
    func test_canPopTask_ShouldReturnNO_LimitReached_EmptyStack() {
        
        stack?.maxDownloads = 1;
        
        stack?.currentDownloads = 1;
        
        let canPopTask = stack!.canPopTask()
        
        XCTAssertFalse(canPopTask, "canPopTask should return NO")
    }
    
    func test_canPopTask_ShouldReturnNO_LimitReached() {
        
        stack?.maxDownloads = 1;
        
        stack?.currentDownloads = 1;
        
        for _ in 0...2 {
            
            stack?.push(insertedTask!)
        }
        
        let canPopTask = stack!.canPopTask()
        
        XCTAssertFalse(canPopTask, "canPopTask should return NO)")
    }
    
    //
    //MARK: Pop
    
    func test_pop_shouldReturnItem() {
        
        stack?.push(insertedTask!)
        
        let extractedTask = stack!.pop()
        
        XCTAssertEqual(extractedTask, insertedTask, "Item was not extracted from the stack");
    }
    
    func test_pop_shouldReturnNil() {
        
        let extractedTask = stack!.pop()
        
        XCTAssertNil(extractedTask, "Unexpected Item was extracted from the stack");
    }
    
    func test_pop_shouldReturnLastItem() {
        
        let lastItemInTheStack = DownloadTaskInfo(downloadId: "NEW\(insertedTaskId)",
                                                  URL: testURL,
                                                  session: session!,
                                                  stackIdentifier: sessionIdentifier,
                                                  progress: nil,
                                                  success: nil,
                                                  failure: nil,
                                                  completion: nil)
        
        stack?.push(self.insertedTask)
        stack?.push(lastItemInTheStack)
        
        let extractedTask = self.stack!.pop()
        
        XCTAssertEqual(extractedTask, lastItemInTheStack, "Item was not extracted from the stack");
    }
    
    func test_pop_shouldIncreaseCurrentDownloads() {
        
        stack?.push(insertedTask!)
        
        stack?.currentDownloads = 6
        
        stack?.pop()
        
        XCTAssertEqual(stack!.currentDownloads, 7, "Pop did not increase the current downloads counter, found: \(self.stack!.currentDownloads) expected: 7")
    }
    
    func test_pop_shouldNotIncreaseCurrentDownloads() {
        
        let currentDowloads = 6
        
        stack?.currentDownloads = currentDowloads
        
        self.stack?.pop()
        
        XCTAssertEqual(self.stack!.currentDownloads, currentDowloads, "Pop increased the current downloads counter, found:\(self.stack!.currentDownloads) expected: \(currentDowloads)")
    }
    
    //MARK: Clear
    
    func test_clear_shouldRemoveAllObjects() {
        
        for _ in 0...2 {
            
            stack?.push(insertedTask!)
        }
        
        stack?.clear()
        
        XCTAssertEqual(self.stack!.currentDownloads, 0, "Item count \(self.stack!.currentDownloads) does not match the expected: 0");
    }
    
    func test_clear_countShouldMatchItemNumbers() {
        
        for _ in 0...2 {
            
            stack?.push(insertedTask!)
        }
        
        stack?.clear()
        
        XCTAssertEqual(self.stack!.count, 0, "Item count \(self.stack!.count) does not match the expected: 0");
    }
    
    //MARK: RemoveTaskInfo
    
    func test_removeTaskInfo_shouldRemoveTask() {
        
        let lastItemInTheStack = DownloadTaskInfo(downloadId: "NEW\(insertedTaskId)",
                                                  URL: testURL,
                                                  session: session!,
                                                  stackIdentifier: sessionIdentifier,
                                                  progress: nil,
                                                  success: nil,
                                                  failure: nil,
                                                  completion: nil)
        
        stack?.push(self.insertedTask)
        stack?.push(lastItemInTheStack)
        
        stack?.removeTaskInfo(insertedTask!)
        
        var taskContainsItem = false
        
        for index in 0...stack!.downloadsArray.count - 1 {
            
            let extractedItem = stack!.downloadsArray[index]
            
            taskContainsItem = taskContainsItem || extractedItem.isEqual(insertedTask!)
        }
        
        XCTAssertFalse(taskContainsItem, "Task was not removed from stack")
    }
    
    func test_removeTaskInfo_shouldNotCrash_EmptyStack() {
        
        stack!.removeTaskInfo(insertedTask!)
        
        XCTAssertTrue(true);
    }
    
    func test_removeTaskInfo_shouldDecreaseCount() {
        
        stack?.push(insertedTask!)
        
        stack?.removeTaskInfo(insertedTask!)
        
        XCTAssertEqual(self.stack!.count, 0, "RemoveTaskInfo did not decrease the current downloads counter, found: \(self.stack!.count) expected: 0")
    }
    
    func test_removeTaskInfo_shouldNotDecreaseCount() {
        
        let lastItemInTheStack = DownloadTaskInfo(downloadId: "NEW\(insertedTaskId)",
                                                  URL: testURL,
                                                  session: session!,
                                                  stackIdentifier: sessionIdentifier,
                                                  progress: nil,
                                                  success: nil,
                                                  failure: nil,
                                                  completion: nil)
        
        stack?.push(lastItemInTheStack)
        
        stack?.removeTaskInfo(self.insertedTask!)
        
        XCTAssertEqual(stack!.count, 1, "RemoveTaskInfo did not decrease the current downloads counter, found: \(self.stack!.count) expected: 1")
    }
    
    //MARK: ReleaseMemory
    
    func test_releaseMemory_shouldCallReleaseMemory() {
        
        var callCounter = 0
        
        let taskCounter = 3
        
        for index in 0...taskCounter - 1 {
            
            stack?.push(DownloadTaskInfoMock(downloadId: "\(index), \(insertedTaskId)",
                URL: testURL,
                session: session!,
                stackIdentifier: sessionIdentifier,
                progress: nil,
                success: nil,
                failure: nil,
                completion: nil))
        }
        
        stack?.releaseMemory()
        
        for index in 0...stack!.downloadsArray.count - 1 {
            
            let extractedItem = stack!.downloadsArray[index] as! DownloadTaskInfoMock
            
            callCounter = callCounter + extractedItem.callCounter
        }
        
        XCTAssertEqual(taskCounter, callCounter, "ReleaseMemory was called: \(taskCounter) expected: \(callCounter)");
    }
}