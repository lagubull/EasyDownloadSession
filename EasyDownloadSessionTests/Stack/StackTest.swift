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
    
}


////MARK: RemoveTaskInfo
//
//func test_removeTaskInfo_shouldRemoveTask
//{
//    EDSDownloadTaskInfo *lastItemInTheStack =  [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
//        URL:nil
//        session:nil
//        stackIdentifier:nil
//        progress:nil
//        success:nil
//        failure:nil
//        completion:nil];
//
//    [self.stack push:self.insertedTask];
//    [self.stack push:lastItemInTheStack];
//
//    [self.stack removeTaskInfo:self.insertedTask];
//
//    BOOL taskContainsItem = NO;
//
//    for (NSInteger i = 0; i < self.stack.downloadsArray.count; i++)
//    {
//        EDSDownloadTaskInfo *extractedItem = (EDSDownloadTaskInfo *)self.stack.downloadsArray[i];
//
//        taskContainsItem = taskContainsItem || [extractedItem isEqual:self.insertedTask];
//    }
//
//    XCTAssertFalse(taskContainsItem, @"Task was not removed from stack");
//    }
//
//    func test_removeTaskInfo_shouldNotCrash_EmptyStack
//        {
//            [self.stack removeTaskInfo:self.insertedTask];
//
//            XCTAssertTrue(YES);
//        }
//
//        func test_removeTaskInfo_shouldDecreaseCount
//            {
//                [self.stack push:self.insertedTask];
//
//                [self.stack removeTaskInfo:self.insertedTask];
//
//                XCTAssertEqual(self.stack.count, 0, @"RemoveTaskInfo did not decrease the current downloads counter, found: %@ expected:0", @(self.stack.count));
//            }
//
//            func test_removeTaskInfo_shouldNotDecreaseCount
//                {
//                    EDSDownloadTaskInfo *lastItemInTheStack =  [[EDSDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"NEW%@",self.insertedTaskId]
//                        URL:nil
//                        session:nil
//                        stackIdentifier:nil
//                        progress:nil
//                        success:nil
//                        failure:nil
//                        completion:nil];
//
//                    [self.stack push:lastItemInTheStack];
//
//                    [self.stack removeTaskInfo:self.insertedTask];
//
//                    XCTAssertEqual(self.stack.count, 1, @"RemoveTaskInfo did not decrease the current downloads counter, found: %@ expected: 1", @(self.stack.count));
//}
//
////MARK: ReleaseMemory
//
//func test_releaseMemory_shouldCallReleaseMemory
//{
//    NSUInteger callCounter = 0;
//
//    NSUInteger taskCounter = 3;
//
//    for (NSInteger i = 0; i < taskCounter; i++)
//    {
//        [self.stack push:[[EDSFakeDownloadTaskInfo alloc] initWithDownloadID:[NSString stringWithFormat:@"%@-%@" ,@(i), self.insertedTaskId]
//            URL:nil
//            session:nil
//            stackIdentifier:nil
//            progress:nil
//            success:nil
//            failure:nil
//            completion:nil]];
//    }
//
//    [self.stack releaseMemory];
//
//    for (NSInteger i = 0; i < self.stack.downloadsArray.count; i++)
//    {
//        EDSFakeDownloadTaskInfo *extractedItem = (EDSFakeDownloadTaskInfo *)self.stack.downloadsArray[i];
//
//        callCounter = callCounter + extractedItem.callCounter;
//    }
//
//    XCTAssertEqual(taskCounter, callCounter, @"ReleaseMemory was called: %@ expected: %@", @(taskCounter), @(callCounter));
//}