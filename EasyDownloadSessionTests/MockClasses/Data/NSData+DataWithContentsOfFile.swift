//
//  NSData+DataWithContentsOfFile.swift
//  EasyDownloadSession
//
//  Created by Javier Laguna on 13/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

import Foundation

extension NSData {
    
    class func new_dataWithContentsOfFile(path: String) -> NSData? {
        
        return path.dataUsingEncoding(NSUTF8StringEncoding)
    }
}