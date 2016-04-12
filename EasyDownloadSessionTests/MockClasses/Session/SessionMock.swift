//
//  SessionMock.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 12/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import Foundation

class SessionMock: NSURLSession {
    
    var didInvokeDownloadTaskWithResumeData: Bool?
    
    var didInvokeDownloadTaskWithRequest: Bool?
    
    override func downloadTaskWithResumeData(resumeData: NSData) -> NSURLSessionDownloadTask {
        
        didInvokeDownloadTaskWithResumeData = true
        
        return SessionTaskMock()
    }
    
    override func downloadTaskWithRequest(request: NSURLRequest) -> NSURLSessionDownloadTask {
        
        didInvokeDownloadTaskWithRequest = true
        
        return SessionTaskMock()
    }
}
