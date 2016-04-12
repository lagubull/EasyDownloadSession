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
        
        self.insertedTask = DownloadTaskInfo.init(downloadId: self.insertedTaskId!,
                                                  URL: NSURL.init(string: "URL")!,
                                                  session: self.session!,
                                                  stackIdentifier: "SessionIdentifier",
                                                  progress: nil,
                                                  success: nil,
                                                  failure: nil,
                                                  completion: nil)
        
        self.insertedTask!.isDownloading = true
        self.task = SessionTaskMock()
        self.insertedTask!.task = self.task;
    }
    
    override func tearDown() {
        
        self.insertedTaskId = nil
        
        self.task = nil
        
        self.insertedTask = nil
        
        super.tearDown()
    }
    
    //MARK: Pause
    
    func test_pause_isDownloadingShouldBeNO() {
        
        insertedTask!.pause()
        
        XCTAssertFalse(insertedTask!.isDownloading, "IsDownloading should be NO");
    }
    
    func test_pause_taskShouldBeSuspended() {
        
        insertedTask!.pause()
        
        XCTAssertTrue(task!.didInvokeSuspend!, "Task suspend was not invoked");
    }
    
    func test_pause_taskCancelByProducingResumeDataInvoked() {
        
        insertedTask!.pause()
        
        XCTAssertTrue(task!.didInvokeCancelByProducingResumeDataInvoked!, "Task CancelByProducingResumeData suspend was not invoked");
    }
    
    func test_pause_taskCurrentDataIsSaved() {
        
        let expectation = expectationWithDescription("Data should be saved") as XCTestExpectation
        
        task!.pausedSavedDataExpectation = expectation;
        
        insertedTask!.task = task;
        
        insertedTask!.pause()
        
        waitForExpectationsWithTimeout(1.0, handler: { (error: NSError?) in
            
            XCTAssertEqual(self.insertedTask!.taskResumeData, self.task!.pausedSavedData, "Data was not saved")
        })
    }
    
    //MAR: Resume
    
    func test_resume_isDownloadindShouldBeYES() {
        
        insertedTask!.resume()
    
        XCTAssertTrue(insertedTask!.isDownloading, "IsDownloading should be YES")
    }
    
    func test_resume_taskResumeShouldBeInvoked() {
        
        insertedTask!.resume()
    
        XCTAssertTrue(self.task!.didInvokeResume!, "Task Resume suspend was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithResumeDataShouldBeInvoked() {
        
        let stringToBeData = "This is a text"
    
        insertedTask!.taskResumeData = stringToBeData.dataUsingEncoding(NSUTF8StringEncoding)
    
        insertedTask!.resume()
        
        XCTAssertTrue(self.session!.didInvokeDownloadTaskWithResumeData!, "Task DownloadTaskWithResumeData was not invoked")
    }
    
    func test_resume_taskDownloadTaskWithRequestShouldBeInvoked() {
    
        //We need to change the value manually as initialization will call this method aswell
        session!.didInvokeDownloadTaskWithRequest = false
    
        task!.state = .Completed
    
        insertedTask!.resume()
    
        XCTAssertTrue(session!.didInvokeDownloadTaskWithRequest!, "Task DownloadTaskWithRequest was not invoked");
    }
    
}
