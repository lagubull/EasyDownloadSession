//
//  EasyDownloadSession.h
//  EasyDownloadSession
//
//  Created by Javier Laguna on 27/02/2016.
//  Copyright © 2016 Javier Laguna. All rights reserved.
//

/**
 Umbrella for the library. It is needed to avoid a warning. 
 */
#ifndef EasyDownloadSession_h
#define EasyDownloadSession_h

#ifdef EDSDEBUG

#define EDSDebug(__FORMAT__, ...) NSLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define EDSDebug(...)

#endif

#endif /* EasyDownloadSession_h */
