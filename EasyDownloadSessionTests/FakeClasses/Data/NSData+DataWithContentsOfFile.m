//
//  NSData+DataWithContentsOfFile.m
//  EasyDownloadSession
//
//  Created by Javier Laguna on 08/04/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

#import "NSData+DataWithContentsOfFile.h"

@implementation NSData (DataWithContentsOfFile)

+ (NSData *)dataWithContentsOfFile:(NSString *)path
{
    return [path dataUsingEncoding:NSUTF8StringEncoding];
}

@end
