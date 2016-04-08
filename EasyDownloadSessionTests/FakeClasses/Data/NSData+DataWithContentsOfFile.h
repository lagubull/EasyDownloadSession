//
//  NSData+DataWithContentsOfFile.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (DataWithContentsOfFile)

+ (NSData *)dataWithContentsOfFile:(NSString *)path;

@end
