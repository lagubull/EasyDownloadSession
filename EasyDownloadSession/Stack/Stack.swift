//
//  Stack.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 15/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import UIKit

@objc(EDSStack)

/**
 Stack to store DownloadTaskInfo objects.
 */
public class Stack: NSObject {
    
    //MARK: - Getters
    
    /**
     Number of items in the stack.
     */
    internal var count: Int = 0
    
    /**
     Items in the stack.
     */
    internal var downloadsArray: Array<DownloadTaskInfo> = []
    
    /**
     Maximum number of concurrent downloads.
     */
    public var maxDownloads:Int = 0
    
    /**
     Number of downloads that were started off this stack and have not finished yet.
     */
    public var currentDownloads: Int = 0
    
    /**
     Used to ensure synchronized access to the downloadsArray.
     */
    private let lock = NSLock()
    
    //MARK: - PUSH
    
    /**
     Inserts in the stack.
     
     - Parameter taskInfo: object to insert.
     */
    public func push(taskInfo: DownloadTaskInfo!) {
        
        downloadsArray.append(taskInfo)
        count = downloadsArray.count
    }
    
    /**
     Checks wethere a task can be started from the stack.
     
     - Returns: YES - A task can be started, NO - there are no tasks to start or the maximum running tasks operations has been reached.
     */
    public func canPopTask() -> Bool {
        
        var canPopTask = false
        
        if count > 0 {
            
            if count > 0 &&
                (maxDownloads == 0 ||
                    currentDownloads < self.maxDownloads) {
                
                canPopTask = true
            }
        }
        
        return canPopTask
    }
    
    /**
     Retrieves from the stack.
     
     - Returns: DownloadTaskInfo.
     */
    public func pop() -> DownloadTaskInfo? {
        
        var taskInfo: DownloadTaskInfo?
        
        if downloadsArray.count > 0 {
            
            taskInfo = downloadsArray.popLast()
            
            count = downloadsArray.count
            currentDownloads = currentDownloads + 1
        }
        
        return taskInfo
    }
    
    //MARK: - Clear
    
    /**
     Empties the stack.
     */
    public func clear() {
        
        downloadsArray.removeAll(keepCapacity: false)
        count = 0
    }
    
    //MARK: - RemoveTaskInfo
    
    /**
     Removes the task from the stack.
     
     - Parameter taskInfo: task to remove.
     */
    public func removeTaskInfo(taskInfo: DownloadTaskInfo) {
        
        if let index  = downloadsArray.indexOf(taskInfo) {
            
            count = count - 1
            downloadsArray.removeAtIndex(index)
        }
    }
    
    //MARK: - ReleaseMemory
    
    /**
     Releases the data of paused downloads.
     */
    public func releaseMemory() {
        
        lock.lock()
        
        for download in downloadsArray {
            
            download.releaseMemory()
        }
        
        lock.unlock()
    }
    
    //MARK: - DeInit
    
    deinit {
        
        downloadsArray.removeAll()
    }
    
}
