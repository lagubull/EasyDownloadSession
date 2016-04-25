//
//  DownloadSession.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 18/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import UIKit

/**
 Constant to indicate cancelled task.
 */
let kEDSCancelled = -999

/**
 Constant for identifying the background session.
 */
let kEDSBackgroundEasyDownloadSessionConfigurationIdentifier = "kEDSBackgroundEasyDownloadSessionConfigurationIdentifier"

/**
 Protocol to indicate the status of the downloads.
 */
@objc(EDSDownloadSessionDelegate)
public protocol DownloadSessionDelegate {
    
    /**
     Notifies the delegate a download has been resumed.
     
     - Parameter downloadTaskInfo: - metadata on the resumed download.
     */
    func didResumeDownload(downloadTaskInfo: DownloadTaskInfo)
}

/**
 Defines a session with custom methods to download.
 */
@objc(EDSDownloadSession)
public class DownloadSession: NSObject, NSURLSessionDownloadDelegate {
    
    //MARK: Getters
    
    /**
     Delegate for the DownloadSessionDelegate class.
     */
    public var delegate:DownloadSessionDelegate?
    
    @objc(sharedInstance)
    public static let sharedInstance = DownloadSession()
    
    /**
     Background Session Object.
     */
    private var backgroundSession: NSURLSession?
    
    /**
     Current downloads.
     */
    internal var inProgressDownloadsDictionary: Dictionary<Int, DownloadTaskInfo> = [:]
    
    /**
     Default Session Object.
     */
    private var defaultSession: NSURLSession?
    
    /**
     Dictionary of stacks.
     */
    private var stackDictionary: Dictionary<String, Stack> = [:]
    
    /**
     Used to ensure synchronized access to the dictionaries.
     */
    private let lock = NSLock()
    
    //MARK: Init
    
    override init(){
        
        super.init()
        
        let backgrounfConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(kEDSBackgroundEasyDownloadSessionConfigurationIdentifier)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        backgrounfConfiguration.HTTPMaximumConnectionsPerHost = 100
        backgrounfConfiguration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        
        configuration.HTTPMaximumConnectionsPerHost = 100
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        
        self.defaultSession = NSURLSession.init(configuration: configuration,
                                                delegate: self,
                                                delegateQueue: NSOperationQueue.mainQueue())
        
        self.backgroundSession = NSURLSession.init(configuration: backgrounfConfiguration,
                                                   delegate: self,
                                                   delegateQueue: NSOperationQueue.mainQueue())
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue(),
                                                                usingBlock: { (notification: NSNotification) in
                                                                    
                                                                    for stack in self.stackDictionary.values {
                                                                        
                                                                        stack.releaseMemory()
                                                                    }
        })
    }
    
    //MARK: Register
    
    /**
     Registers the stack in the session.
     
     - Parameter stackIdentifier: identifies the stack.
     */
    public func registerStack(stack stack: Stack, stackIdentifier: String) {
        
        stackDictionary[stackIdentifier] = stack
    }
    
    //MARK: ScheduleDownload
    
    /**
     Adds a downloading task to the stack.
     
     - Parameter downloadId: identifies the download.
     - Parameter request: request for a download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter success: to be executed when the task finishes succesfully.
     - Parameter failure: to be executed when the task finishes with an error.
     - Parameter completion: to be executed when the task finishes either with an error or a success.
     */
    private class func scheduleDownloadWithId(downloadId: String,
                                              request: NSURLRequest,
                                              stackIdentifier: String,
                                              progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                              success: ((downloadTask: DownloadTaskInfo!, responseData: NSData?) -> Void)?,
                                              failure: ((downloadTask: DownloadTaskInfo!, error: NSError?) -> Void)?,
                                              completion: ((downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) -> Void)?) {
        
        let task = DownloadTaskInfo.init(downloadId: downloadId,
                                         request: request,
                                         session: DownloadSession.sharedInstance.defaultSession!,
                                         stackIdentifier: stackIdentifier,
                                         progress: progress,
                                         success: success,
                                         failure: failure,
                                         completion: completion)
        
        if !DownloadSession.sharedInstance.shouldCoalesceDownloadTask(task, stackIdentifier: stackIdentifier) {
            
            DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.push(task)
        }
        
        DownloadSession.resumeDownloadsInStack(stackIdentifier)
    }
    
    /**
     Adds a downloading task to the stack.
     
     - Parameter downloadId: identifies the download.
     - Parameter request: request for a download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter completion: to be executed when the task finishes either with an error or a success.
     */
    public class func scheduleDownloadWithId(downloadId: String,
                                             request: NSURLRequest,
                                             stackIdentifier: String,
                                             progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                             completion: ((downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) -> Void)?) {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: request,
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               success: nil,
                                               failure: nil,
                                               completion: completion)
    }
    
    /**
     Adds a downloading task to the stack.
     
     - Parameter downloadId: identifies the download.
     - Parameter URL: path to download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter completion: to be executed when the task finishes either with an error or a success.
     */
    public class func scheduleDownloadWithId(downloadId: String,
                                             fromURL: NSURL,
                                             stackIdentifier: String,
                                             progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                             completion: ((downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) -> Void)?) {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: NSURLRequest.init(URL: fromURL),
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               success: nil,
                                               failure: nil,
                                               completion: completion)
    }
    
    /**
     Adds a downloading task to the stack.
     
     - Parameter downloadId: identifies the download.
     - Parameter URL: path to download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter success: to be executed when the task finishes succesfully.
     - Parameter failure: to be executed when the task finishes with an error.
     */
    public class func scheduleDownloadWithId(downloadId: String,
                                             fromURL: NSURL,
                                             stackIdentifier: String,
                                             progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                             success: ((downloadTask: DownloadTaskInfo!, responseData: NSData?) -> Void)?,
                                             failure: ((downloadTask: DownloadTaskInfo!, error: NSError?) -> Void)?) {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: NSURLRequest.init(URL: fromURL),
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               success: success,
                                               failure: failure,
                                               completion: nil)
    }
    
    /**
     Adds a downloading task to the stack.
     
     - Parameter downloadId: identifies the download.
     - Parameter request: request for a download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter success: to be executed when the task finishes succesfully.
     - Parameter failure: to be executed when the task finishes with an error.
     */
    public class func scheduleDownloadWithId(downloadId: String,
                                             request: NSURLRequest,
                                             stackIdentifier: String,
                                             progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                             success: ((downloadTask: DownloadTaskInfo!, responseData: NSData?) -> Void)?,
                                             failure: ((downloadTask: DownloadTaskInfo!, error: NSError?) -> Void)?) {
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: request,
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               success: success,
                                               failure: failure,
                                               completion: nil)
    }
    
    //MARK: ForceDownload
    
    /**
     Stops the current download and adds it to the stack, the it begins executing this new download.
     
     - Parameter downloadId: identifies the download.
     - Parameter request: request for a download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter completion: to be executed when the task finishes either with an error or a success.
     */
    public class func forceDownloadWithId(downloadId: String,
                                          request: NSURLRequest,
                                          stackIdentifier: String,
                                          progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                          completion: ((downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) -> Void)?) {
        
        DownloadSession.pauseDownloadsInStack(stackIdentifier)
        
        let maxDownloads = DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads
        
        DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads = 1
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: request,
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               completion: { (downloadTask: DownloadTaskInfo!, responseData: NSData?, error: NSError?) in
                                                
                                                DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads = maxDownloads!
                                                
                                                DownloadSession.resumeDownloadsInStack(downloadTask.stackIdentifier)
                                                
                                                if let completion = completion {
                                                    
                                                    completion(downloadTask: downloadTask, responseData: responseData, error: error)
                                                }
        })
    }
    
    /**
     Stops the current download and adds it to the stack, the it begins executing this new download.
     
     - Parameter downloadId: identifies the download.
     - Parameter URL: path to download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter completion: to be executed when the task finishes either with an error or a success.
     */
    public class func forceDownloadWithId(downloadId: String,
                                          fromURL: NSURL,
                                          stackIdentifier: String,
                                          progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                          completion: ((downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) -> Void)?) {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest.init(URL: fromURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: progress,
                                            completion: completion)
    }
    
    /**
     Stops the current download and adds it to the stack, the it begins executing this new download.
     
     - Parameter downloadId: identifies the download.
     - Parameter URL: path to download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter success: to be executed when the task finishes succesfully.
     - Parameter failure: to be executed when the task finishes with an error.
     */
    public class func forceDownloadWithId(downloadId: String,
                                          fromURL: NSURL,
                                          stackIdentifier: String,
                                          progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                          success: ((downloadTask: DownloadTaskInfo, responseData: NSData?) -> Void)?,
                                          failure: ((downloadTask: DownloadTaskInfo, error: NSError?) -> Void)?) {
        
        DownloadSession.forceDownloadWithId(downloadId,
                                            request: NSURLRequest.init(URL: fromURL),
                                            stackIdentifier: stackIdentifier,
                                            progress: progress,
                                            success: success,
                                            failure: failure)
    }
    
    /**
     Stops the current download and adds it to the stack, the it begins executing this new download.
     
     - Parameter downloadId: identifies the download.
     - Parameter request: request for a download.
     - Parameter stackIdentifier: identifies the stack in which this download will be placed into.
     - Parameter progress: to be executed when as the task progresses.
     - Parameter success: to be executed when the task finishes succesfully.
     - Parameter failure: to be executed when the task finishes with an error.
     */
    public class func forceDownloadWithId(downloadId: String,
                                          request: NSURLRequest,
                                          stackIdentifier: String,
                                          progress: ((downloadId: DownloadTaskInfo!) -> Void)?,
                                          success: ((downloadTask: DownloadTaskInfo, responseData: NSData?) -> Void)?,
                                          failure: ((downloadTask: DownloadTaskInfo, error: NSError?) -> Void)?) {
        
        DownloadSession.pauseDownloadsInStack(stackIdentifier)
        
        let maxDownloads = DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads
        
        DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads = 1
        
        DownloadSession.scheduleDownloadWithId(downloadId,
                                               request: request,
                                               stackIdentifier: stackIdentifier,
                                               progress: progress,
                                               success: { (downloadTask: DownloadTaskInfo!, responseData: NSData?) in
                                                
                                                DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads = maxDownloads!
                                                
                                                DownloadSession.resumeDownloadsInStack(downloadTask.stackIdentifier)
                                                
                                                if let success = success {
                                                    
                                                    success(downloadTask: downloadTask, responseData: responseData)
                                                }
                                                
            },
                                               failure: { (downloadTask: DownloadTaskInfo!, error: NSError?) in
                                                
                                                DownloadSession.sharedInstance.stackDictionary[stackIdentifier]?.maxDownloads = maxDownloads!
                                                
                                                DownloadSession.resumeDownloadsInStack(downloadTask.stackIdentifier)
                                                
                                                if let failure = failure {
                                                    
                                                    failure(downloadTask: downloadTask, error: error)
                                                }
        })
    }
    
    //MARK: NSURLSessionDownloadDelegate
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        guard let taskInProgress = inProgressDownloadsDictionary[downloadTask.taskIdentifier] else { return }
        
        taskInProgress.didSucceedWithLocation(location)
        
        finalizeTask(taskInProgress)
        
        DownloadSession.resumeDownloadsInStack(taskInProgress.stackIdentifier)
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let taskInProgress = inProgressDownloadsDictionary[downloadTask.taskIdentifier] else { return }
        
        taskInProgress.didUpdateProgress((CGFloat)(totalBytesWritten / totalBytesExpectedToWrite))
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let unwrappedError = error {
            
            if unwrappedError.code != kEDSCancelled {
                
                guard let taskInProgress = inProgressDownloadsDictionary[task.taskIdentifier] as DownloadTaskInfo! else { return }
                
                taskInProgress.didFailWithError(unwrappedError)
                
                //  Handle error
                NSLog("task: \(taskInProgress.downloadId) Error: \(unwrappedError)")
                
                finalizeTask(taskInProgress)
                
                DownloadSession.resumeDownloadsInStack(taskInProgress.stackIdentifier)
            }
        }
    }
    
    //MARK: Cancel
    
    /**
     Stop and remove all the pending downloads without executing the completion block.
     */
    public class func cancelDownloads() {
        
        DownloadSession.sharedInstance.lock.lock()
        
        for task in DownloadSession.sharedInstance.inProgressDownloadsDictionary.values {
            
            DownloadSession.sharedInstance.cancelTask(task)
        }
        
        for stack in DownloadSession.sharedInstance.stackDictionary.values {
            
            stack.clear()
        }
        
        DownloadSession.sharedInstance.lock.unlock()
    }
    
    /**
     Stop and remove all the pending downloads without executing the completion block.
     
     - Parameter downloadId: identifies the download.
     - Parameter stackIndetifier: Identifier of the stack for the download.
     */
    public class func cancelDownload(downloadId: String, stackIdentifier: String) {
        
        let task = DownloadSession.sharedInstance.taskInfoWithIdentfier(downloadId, stackIdentifier: stackIdentifier)
        
        DownloadSession.sharedInstance.cancelTask(task)
    }
    
    /**
     Cancels a task.
     
     - Parameter task - task to finalize.
     */
    private func cancelTask(task: DownloadTaskInfo) {
        
        task.task!.cancel()
        
        DownloadSession.sharedInstance.finalizeTask(task)
    }
    
    //MARK: Resume
    
    /**
     Resume or starts the next pending downloads in every stack if there is capacity in each stack.
     */
    public class func resumeDownloads() {
        
        for downloadStackIdentifier in DownloadSession.sharedInstance.stackDictionary.keys {
            
            DownloadSession.resumeDownloadsInStack(downloadStackIdentifier)
        }
    }
    
    /**
     Resume or starts the next pending downloads if there is capacity in an specific stack.
     
     - Parameter stackIndetifier: Identifier of the stack for the download.
     */
    public class func resumeDownloadsInStack(downloadStackIdentifier: String) {
        
        let downloadStack = DownloadSession.sharedInstance.stackDictionary[downloadStackIdentifier]
        
        DownloadSession.sharedInstance.lock.lock()
        
        while (downloadStack!.canPopTask()) {
            
            if let downloadTaskInfo = downloadStack?.pop() {
                
                if !downloadTaskInfo.isDownloading {
                    
                    downloadTaskInfo.resume()
                    
                    DownloadSession.sharedInstance.delegate?.didResumeDownload(downloadTaskInfo)
                }
                
                DownloadSession.sharedInstance.inProgressDownloadsDictionary[downloadTaskInfo.task!.taskIdentifier] = downloadTaskInfo
            }
        }
        
        DownloadSession.sharedInstance.lock.unlock()
    }
    
    //MARK: Pause
    
    /**
     Stop the current downloads in every stack and save them back in the queue.
     */
    public class func pauseDownloads() {
        
        for taskInfo in DownloadSession.sharedInstance.inProgressDownloadsDictionary.values {
            
            DownloadSession.sharedInstance.pauseTask(taskInfo)
        }
    }
    
    /**
     Stop the current downloads and save them back in the queue for an specific stack.
     
     - Parameter stackIndetifier: Identifier of the stack for the download.
     */
    public class func pauseDownloadsInStack(stackIndetifier: String) {
        
        for taskInfo in DownloadSession.sharedInstance.inProgressDownloadsDictionary.values {
            
            if taskInfo.stackIdentifier.isEqual(stackIndetifier) {
                
                DownloadSession.sharedInstance.pauseTask(taskInfo)
            }
        }
    }
    
    /**
     Pauses a task.
     
     - Parameter task - task to finalize.
     */
    private func pauseTask(task: DownloadTaskInfo) {
        
        EDSDebug("Pausing task - \(task.downloadId)")
        
        task.pause()
        
        let downloadStack = DownloadSession.sharedInstance.stackDictionary[task.stackIdentifier]
        
        lock.lock()
        
        downloadStack?.push(task)
        
        DownloadSession.sharedInstance.finalizeTask(task)
        
        lock.unlock()
    }
    
    //MARK: Coalescing
    
    /**
     Tries to coales the operation.
     
     - Parameter newTaskInfo: new task to coalesce.
     
     - Returns: YES If the taskInfo is coalescing, NO otherwise.
     */
    internal func shouldCoalesceDownloadTask(newTaskInfo: DownloadTaskInfo, stackIdentifier: String) -> Bool {
        
        var didCoalesce = false
        
        for taskInfo in inProgressDownloadsDictionary.values {
            
            if taskInfo.canCoalesceWithTaskInfo(newTaskInfo) {
                
                taskInfo.coalesceWithTaskInfo(newTaskInfo)
                
                didCoalesce = true
            }
        }
        
        if !didCoalesce {
            
            for taskInfo in stackDictionary[stackIdentifier]!.downloadsArray {
                
                let canAskToCoalesce = taskInfo.isKindOfClass(DownloadTaskInfo.self)
                
                if canAskToCoalesce &&
                    newTaskInfo.canCoalesceWithTaskInfo(taskInfo) {
                    
                    newTaskInfo.coalesceWithTaskInfo(taskInfo)
                    
                    stackDictionary[stackIdentifier]?.removeTaskInfo(taskInfo)
                    
                    //If we coalesce we don't need to return FALSE as the task is already in the stack
                    
                    break
                }
            }
        }
        
        return didCoalesce
    }
    
    //MARK: Finalize
    
    internal func finalizeTask(task: DownloadTaskInfo) {
        
        if inProgressDownloadsDictionary.removeValueForKey(task.task!.taskIdentifier) != nil {
            
            stackDictionary[task.stackIdentifier]!.currentDownloads = (stackDictionary[task.stackIdentifier]!.currentDownloads - 1)
        }
    }
    
    //MARK: TaskWithIdentifier
    
    /**
     Obtains the task from the currently executed or the scheduled one.
     
     - Parameter downloadId: Identifier for the task.
     - Parameter stackIdentifier: Stack the task was scheduled to run in.
     
     - Returns: DownloadTaskInfo
     */
    internal func taskInfoWithIdentfier(downloadId: String, stackIdentifier: String) -> DownloadTaskInfo {
        
        var resultingTask: DownloadTaskInfo?
        
        let soughtAfterTask = DownloadTaskInfo()
        
        soughtAfterTask.downloadId = downloadId
        
        let resultingTaskKeyArray = (inProgressDownloadsDictionary as NSDictionary).allKeysForObject(soughtAfterTask)
        
        if resultingTaskKeyArray.count == 0 {
            
            let stack = DownloadSession.sharedInstance.stackDictionary[stackIdentifier]
            
            let indexOfTask = (stack!.downloadsArray as NSArray).indexOfObject(soughtAfterTask)
            
            if indexOfTask != NSNotFound {
                
                resultingTask = stack!.downloadsArray[indexOfTask]
            }
            
        }
        else {
            
            let taskKey = resultingTaskKeyArray[0] as! Int
            
            resultingTask = inProgressDownloadsDictionary[taskKey]
        }
        
        return resultingTask!
    }
}
