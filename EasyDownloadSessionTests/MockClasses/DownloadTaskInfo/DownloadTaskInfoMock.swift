//
//  DownloadTaskInfoMock.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 12/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import Foundation

@testable import EasyDownloadSession

class DownloadTaskInfoMock: DownloadTaskInfo {
    
    var callCounter: Int = 0
    
    var didInvokeDidFailWithError: Bool = false
    
    override func releaseMemory() {
        
        callCounter = callCounter + 1
    }
    
    override func didFailWithError(error: NSError?) {
        
        didInvokeDidFailWithError = true
    }
}
