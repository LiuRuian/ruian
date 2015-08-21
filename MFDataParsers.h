//
//  MFDataParsers.h
//  mFashion
//
//  Created by Aaron Lau on 13-3-25.
//  Copyright (c) 2013年 RoseVision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFRequest.h"

@interface MFDataParsers : NSObject
+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType;
+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType requestURL:(NSURL *)requestURL;
+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType requestURL:(NSURL *)requestURL userInfo:(NSDictionary *)userInfo;
@end
