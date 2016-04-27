//
//  SessionTaskMock.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 12/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import Foundation
import XCTest

class SessionTaskMock: NSURLSessionDownloadTask {
    
    var NSURLSessionTask: NSURLSessionDownloadTask?
    
    var didInvokeSuspend: Bool?
    
    var didInvokeResume: Bool?
    
    var didInvokeCancelByProducingResumeDataInvoked: Bool?
    
    var pausedSavedData: NSData?
    
    var pausedSavedDataExpectation: XCTestExpectation?
    
    //MARK: - Identifier
    
    override var taskIdentifier: Int {
        
        get {
            
            return _taskIdentifer
        }
        set {
            
            willChangeValueForKey("taskIdentifier")
            self._taskIdentifer = newValue
            didChangeValueForKey("taskIdentifier")
        }
    }
    
    private lazy var _taskIdentifer: Int = {
        
        return -3
    }()
    
    override var state: NSURLSessionTaskState {
        
        get {
            
            return _state
        }
        set {
            
            willChangeValueForKey("state")
            self._state = newValue
            didChangeValueForKey("state")
        }
    }
    
    private lazy var _state: NSURLSessionTaskState = {
        
        return .Suspended
    }()
    
    override func suspend() {
        
        didInvokeSuspend = true
    }
    
    override func resume() {
        
        didInvokeResume = true
    }
    
    override func cancelByProducingResumeData(completionHandler: ((data: NSData?) -> Void)?) {
        
        didInvokeCancelByProducingResumeDataInvoked = true
        
        let pausedSavedData = NSData()
        
        guard let unwrappedCompletionHandler = completionHandler,
            let pausedSavedDataExpectation = pausedSavedDataExpectation else { return }
        
        let completionHandler =  { [unowned self] (resumedData: NSData?) in
            
            if let unwrappedResumedData = resumedData {
                
                self.pausedSavedData = unwrappedResumedData
                
                pausedSavedDataExpectation.fulfill()
                
                unwrappedCompletionHandler(data: unwrappedResumedData)
            }
        }
        
        completionHandler(pausedSavedData)
    }
    
    override func cancel() {
        
        NSLog("Do Nothing")
    }
}
