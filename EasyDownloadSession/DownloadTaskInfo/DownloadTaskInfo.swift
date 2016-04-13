//
//  DownloadTaskInfo.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 11/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

/**
 Inline function for printing log messages only while on debug configuration.
 */
func EDSDebug(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
        NSLog("[\(NSURL(fileURLWithPath: filename).lastPathComponent!):\(line)] \(function) - \(message)")
    #endif
}

/**
 Represents a download task and its metadata.
 */
@objc(EDSDownloadTaskInfo)

class DownloadTaskInfo: NSObject
{
    //MARK: Getters
    
    /**
     Identifies the object.
     */
    var downloadId: String
    
    /**
     Data already downloaded.
     */
    var taskResumeData: NSData?
    
    /**
     Progress of the download.
     */
    var downloadProgress: CGFloat
    
    /**
     Indicates whethere the task is executing.
     */
    var isDownloading: Bool
    
    /**
     Indicates where the download has finished.
     */
    var downloadComplete: Bool
    
    /**
     The task itself.
     */
    var task: NSURLSessionDownloadTask?
    
    /**
     Identifies the stack.
     */
    var stackIdentifier: String
    
    /**
     Block to be executed upon success.
     */
    private var success: ((downloadTask: DownloadTaskInfo, responseData: NSData?) -> Void)?
    
    /**
     Block to be executed upon error.
     */
    private var failure: ((downloadTask: DownloadTaskInfo, error: NSError?) -> Void)?
    
    /**
     Block to be executed upon progress.
     */
    private var progress: ((downloadTask: DownloadTaskInfo) -> Void)?
    
    /**
     Block to be executed upon finishing.
     */
    private var completion: ((downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) -> Void)?
    
    /**
     Internal callback queue to make sure callbacks execute on same queue task is created on.
     */
    private var callbackQueue: NSOperationQueue?
    
    /**
     Session that will own the task.
     */
    private var session: NSURLSession
    
    /**
     Request for a download.
     */
    private var request: NSURLRequest
    
    //MARK: Init
    
    /**
     Creates a new DownloadTaskInfo object.
     
     @param downloadId - used to identify the task.
     @param request - request for a download.
     @param session - Session that will own the task.
     @param progress -  Block to be executed upon progress.
     @param success -  Block to be executed upon success.
     @param failure -  Block to be executed upon failure.
     @param completion - Block to be executed upon finishing.
     
     @return Instance of the class.
     */
    init(downloadId: String,
         request: NSURLRequest,
         session: NSURLSession,
         stackIdentifier: String,
         progress: ((downloadTask: DownloadTaskInfo!) -> Void)?,
         success: ((downloadTask: DownloadTaskInfo!, responseData: NSData?) -> Void)?,
         failure: ((downloadTask: DownloadTaskInfo!, error: NSError?) -> Void)?,
         completion:((downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) -> Void)?) {
        
        self.downloadId = downloadId
        self.session = session
        self.request = request
        self.stackIdentifier = stackIdentifier
        self.downloadProgress = 0.0
        self.isDownloading = false
        self.downloadComplete = false
        
        super.init()
        
        self.task = session.downloadTaskWithRequest(request)
        self.success = success
        self.progress = progress
        self.failure = failure
        self.completion = completion
        self.callbackQueue = NSOperationQueue.currentQueue()
    }
    
    /**
     Creates a new DownloadTaskInfo object.
     
     @param downloadId - used to identify the task.
     @param url - URL task will download from.
     @param session - Session that will own the task.
     @param progress -  Block to be executed upon progress.
     @param success -  Block to be executed upon success.
     @param failure -  Block to be executed upon faiilure.
     @param completion - Block to be executed upon finishing.
     
     @return Instance of the class.
     */
    convenience init(downloadId: String,
                     URL: NSURL,
                     session: NSURLSession,
                     stackIdentifier: String,
                     progress: ((downloadTask: DownloadTaskInfo!) -> Void)?,
                     success: ((downloadTask: DownloadTaskInfo!, responseData: NSData?) -> Void)?,
                     failure: ((downloadTask: DownloadTaskInfo!, error: NSError?) -> Void)?,
                     completion:((downloadTask: DownloadTaskInfo, responseData: NSData?, error: NSError?) -> Void)?){
        
        self.init(downloadId: downloadId,
                  request: NSURLRequest(URL: URL),
                  session: session,
                  stackIdentifier: stackIdentifier,
                  progress: progress,
                  success: success,
                  failure: failure,
                  completion: completion)
    }
    
    //MARK: Pause
    
    /**
     Stops the task and stores the progress.
     */
    func pause() {
        
        isDownloading = false
        
        guard let task = task else { return }
        
        task.suspend()
        
        task.cancelByProducingResumeData( { (resumeData: NSData?) in
            
            guard let resumeData = resumeData else { return }
            
            self.taskResumeData = NSData(data: resumeData)
        })
    }
    
    //MARK: Resume
    
    /**
     Starts the task.
     */
    func resume() {
        
        var didResumeWithData = false
        
        guard let task = task else { return }
        
        if let unwrappedTaskResumeData = taskResumeData {
            
            if unwrappedTaskResumeData.length > 0 {
                
                EDSDebug("Resuming task - \(downloadId)")
                
                //we cancelled this operation before it actually started
                self.task = session.downloadTaskWithResumeData(unwrappedTaskResumeData)
                
                didResumeWithData = true
            }
        }
        
        if !didResumeWithData {
            
            if task.state == .Completed {
                
                EDSDebug("Resuming task - \(downloadId)")
                
                //we cancelled this operation before it actually started
                self.task = session.downloadTaskWithRequest(request)
            } else {
                
                EDSDebug("Starting task - \(downloadId)")
            }
        }
        
        isDownloading = true
        
        task.resume()
    }
    
    //MARK: Progress
    
    /**
     Notifies the task of its progress.
     
     - Parameter newProgress: completion status.
     */
    func didUpdateProgress(newProgress: CGFloat) {
        
        downloadProgress = newProgress
        
        guard let progress = progress,
            let callbackQueue = callbackQueue else { return }
        
        callbackQueue.addOperationWithBlock( {
            
            progress(downloadTask: self)
        })
    }
    
    //MARK: Success
    
    /**
     Notifies the task wwhen has finish succesfully.
     
     - Parameter location: local path to the downloaded data.
     */
    func didSucceedWithLocation(location: NSURL)
    {
        var isDataNil = false
        
        guard let callbackQueue = callbackQueue,
            let path = location.path else { return }
        
        let data: NSData? = NSData(contentsOfFile: path)
        
        if let _ = data where data!.length > 0 {
            
            isDataNil = true
        }
        
        if !isDataNil {
            
            didFailWithError(nil)
        } else {
            
            if let success = success {
                
                callbackQueue.addOperationWithBlock( {
                    
                    success(downloadTask: self, responseData: data)
                })
            } else {
                
                guard let completion = completion else { return }
                
                callbackQueue.addOperationWithBlock( {
                    
                    completion(downloadTask: self, responseData: data, error: nil)
                })
            }
        }
    }
    
    //Mark: Failure
    
    /**
     Notifies the task when it is finished with error.
     
     - Parameter error: completion status.
     */
    func didFailWithError(error: NSError?)
    {
        guard let callbackQueue = callbackQueue else { return }
        
        if let failure = failure {
            
            callbackQueue.addOperationWithBlock({
                
                failure(downloadTask:self, error: error)
            })
        } else {
            
            guard let completion = completion else { return }
            
            callbackQueue.addOperationWithBlock( {
                
                completion(downloadTask:self, responseData: nil, error: error)
            })
            
        }
    }
    
    //MARK: Coalescing
    
    /**
     Checks weather the taskInfo provided equals self.
     
     - Parameter taskInfo: new task.
     */
    func canCoalesceWithTaskInfo(taskInfo: DownloadTaskInfo) -> Bool {
        
        return self.isEqual(taskInfo)
    }
    
    /**
     Merges a new task with self.
     
     - Parameter taskInfo: new task.
     */
    func coalesceWithTaskInfo(taskInfo: DownloadTaskInfo) {
        
        self.coalesceSuccesWithTaskInfo(taskInfo)
        
        self.coalesceFailureWithTaskInfo(taskInfo)
        
        self.coalesceProgressWithTaskInfo(taskInfo)
        
        self.coalesceCompletionWithTaskInfo(taskInfo)
    }
    
    /**
     Merges success block of new task with self's.
     
     @param taskInfo - new task.
     */
    private func coalesceSuccesWithTaskInfo(taskInfo: DownloadTaskInfo) {
        
        var isMySuccessNil = false
        var isTheirSuccessNil = false
        
        if let _ =  self.success {
            
        } else {
            
            isMySuccessNil = true
        }
        
        if let _ =  taskInfo.success {
            
        } else {
            
            isTheirSuccessNil = true
        }
        
        if (!isMySuccessNil ||
            !isTheirSuccessNil)
        {
            self.success = { (downloadTask: DownloadTaskInfo, responseData: NSData?) in
                
                if (isMySuccessNil)
                {
                    let mySuccess =  self.success!
                    
                    mySuccess(downloadTask: downloadTask, responseData: responseData);
                }
                
                if (isTheirSuccessNil)
                {
                    let theirSuccess =  taskInfo.success!
                    
                    theirSuccess(downloadTask: downloadTask, responseData: responseData);
                }
            }
        }
    }
    
    /**
     Merges failure block of new task with self's.
     
     - Parameter taskInfo: new task.
     */
    private func coalesceFailureWithTaskInfo(taskInfo: DownloadTaskInfo) {
        
        var isMyFailureNil = false
        var isTheirFailureNil = false
        
        if let _ =  self.failure {
            
        } else {
            
            isMyFailureNil = true
        }
        
        if let _ =  taskInfo.failure {
            
        } else {
            
            isTheirFailureNil = true
        }
        
        if (!isMyFailureNil ||
            !isTheirFailureNil)
        {
            self.failure = { (downloadTask: DownloadTaskInfo, error: NSError?) in
                
                if (isMyFailureNil)
                {
                    let myFailure =  self.failure!
                    
                    myFailure(downloadTask: downloadTask, error: error);
                }
                
                if (isTheirFailureNil)
                {
                    let theirFailure =  taskInfo.failure!
                    
                    theirFailure(downloadTask: downloadTask, error: error);
                }
            }
        }
    }
    
    /**
     Merges progress block of new task with self's.
     
     - Parameter taskInfo: new task.
     */
    private func coalesceProgressWithTaskInfo(taskInfo: DownloadTaskInfo) {
        
        var isMyProgressNil = false
        var isTheirProgressNil = false
        
        if let _ =  self.progress {
            
        } else {
            
            isMyProgressNil = true
        }
        
        if let _ =  taskInfo.progress {
            
        } else {
            
            isTheirProgressNil = true
        }
        
        if (!isMyProgressNil ||
            !isTheirProgressNil)
        {
            self.progress = { (downloadTask: DownloadTaskInfo) in
                
                if (isMyProgressNil)
                {
                    let myProgress =  self.progress!
                    
                    myProgress(downloadTask: downloadTask);
                }
                
                if (isTheirProgressNil)
                {
                    let theirProgress = taskInfo.progress!
                    
                    theirProgress(downloadTask: downloadTask);
                }
            }
        }
    }
    
    /**
     Merges completion block of new task with self's.
     
     - Parameter taskInfo: new task.
     */
    private func coalesceCompletionWithTaskInfo(taskInfo: DownloadTaskInfo) {
        
        var isMyCompletionNil = false
        var isTheirCompletionNil = false
        
        if let _ =  self.completion {
            
        } else {
            
            isMyCompletionNil = true
        }
        
        if let _ =  taskInfo.completion {
            
        } else {
            
            isTheirCompletionNil = true
        }
        
        if (!isMyCompletionNil ||
            !isTheirCompletionNil)
        {
            self.completion = { (downloadTask: DownloadTaskInfo, responseData: NSData? , error: NSError?) in
                
                if (isMyCompletionNil)
                {
                    let myCompletion =  self.completion!
                    
                    myCompletion(downloadTask: downloadTask, responseData: responseData, error: error);
                }
                
                if (isTheirCompletionNil)
                {
                    let theirCompletion =  taskInfo.completion!
                    
                    theirCompletion(downloadTask: downloadTask, responseData: responseData, error: error);
                }
            }
        }
    }
    
    //MARK: IsEqual
    
    override func isEqual(object: AnyObject?) -> Bool {
        
        var equals = false
        
        guard let unwrappedObject = object else { return  false}
        
        let objectMirror = Mirror(reflecting: unwrappedObject)
        
        if objectMirror.subjectType == DownloadTaskInfo.self {
            
            if downloadId.isEqual(unwrappedObject.downloadId) {
                
                equals = true
            }
        }
        
        return equals
    }
    
    //MARK: ReleaseMemory
    
    /**
     Release the data of paused downloads.
     */
    func releaseMemory() {
        
        downloadProgress = 0.0
        taskResumeData = nil
    }
}
