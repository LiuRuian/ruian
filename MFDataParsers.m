//
//  MFDataParsers.m
//  mFashion
//
//  Created by Aaron Lau on 13-3-25.
//  Copyright (c) 2013年 RoseVision. All rights reserved.
//

#import "MFDataParsers.h"
#import "MSBrandDataManager.h"
#import "MSAccountDataManager.h"
#import "MSConfigurationDataManager.h"
#import "MSSearchProductsManager.h"
#import "MSProductMananger.h"
#import "MSProductConfigurationManager.h"
#import "NSDictionary+StripNSNull.h"
#import "NSArray+StripNSNull.h"
#import "MSProductCommentsManager.h"
#import "MSProductFavoriteManager.h"
#import "MSSearchKeywordDataManager.h"
#import "MSProductFavoriteUserListManager.h"
#import "MSFollowerProfileDataManager.h"
#import "MSFriendProfileDataManager.h"
#import "MSFavoriteProductProfileDataManager.h"
#import "MSChatMessageDataManager.h"
#import "MSChatBoxDataManager.h"
#import "MSSNSManager.h"
#import "OFOrderListDataManager.h"
#import "OFGoodsInfoDataManager.h"
#import "OFOrderInfoDataManager.h"
#import "OFUserProfileDataManager.h"
#import "OFSellerCommentDataManager.h"
#import "MSMessageFlowDataManager.h"
#import "OFGoodsDataManager.h"
#import "MSCommons.h"
#import "OFGoodsListDataManager.h"
#import "OFFavoriteGoodsIDDataManager.h"
#import "OFSellerIDDataManager.h"
#import "OFSystemNotificationListDataManager.h"
#import "OFSystemNotificationDataManager.h"
#import "OFGoodsFavoriteUserProfileDataManager.h"
#import "OFSellerProfileListDataManager.h"
#import "OFSeekingPostsDataManager.h"
#import "OFSeekingPostsListDataManager.h"
#import "OFGoodsTopicListDataManager.h"
#import "OFSearchKeywordDataManager.h"
#import "MSProductsFlowDataManager.h"
#import "OFHomeCategoryDataManager.h"
#import "OFRecommendListDataManager.h"
#import "OFSellerListDataManager.h"
#import "OFGoodsCommentListDataManager.h"
#import "MSPostsListDataManager.h"
#import "OFCommentsListDataManager.h"
#import "OFTopicItemDataManager.h"

#define DEBUG_DATAPARSER    0

#define kOFErrorDomainParseResult @"kOFErrorDomainParseResult"
typedef enum {
    kOFErrorCodeNone,
} OFErrorCode;

@interface MFDataParsers ()
+ (NSDictionary *)parsedResultWithRequestType:(MFRequestType)requestType
                                   parsedInfo:(id)parsedInfo
                                     userInfo:(NSDictionary *)userInfo;
@end

@implementation MFDataParsers

+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType {
	return [self parserData:data requestType:requestType requestURL:nil];
}

+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType requestURL:(NSURL *)requestURL {
    
	return [self parserData:data requestType:requestType requestURL:requestURL userInfo:nil];
}

+ (NSDictionary *)parserData:(NSData *)data requestType:(MFRequestType)requestType requestURL:(NSURL *)requestURL userInfo:(NSDictionary *)userInfo {
    
    if (!data) {
        return nil;
    }
    
	id parsedInfo = nil;
	NSError *parseError = nil;

#if defined(USE_ENCODE)&&USE_ENCODE
#if __has_feature(objc_arc)
    NSString *contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#else
    NSString *contentString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
#endif // #if __has_feature(objc_arc)
    
#if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
    NSLog(@"content string : %@", contentString);
#endif // #if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
    
    NSRange range = [contentString rangeOfString:@"}" options:NSBackwardsSearch];
    NSString *resultString = contentString;
    if (range.location != NSNotFound) {
        resultString = [contentString substringToIndex:range.location + 1];
    }
    data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
#else
#if __has_feature(objc_arc)
    NSString *contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#else
    NSString *contentString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
#endif // #if __has_feature(objc_arc)
    
#if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
    NSLog(@"content string : %@", contentString);
#endif // #if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
#endif // #if defined(USE_ENCODE)&&USE_ENCODE
    
    if (!data) {
        return nil;
    }
    
	if (NSClassFromString(@"NSJSONSerialization")) {
		parsedInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
#if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
        if (parseError) {
            NSLog(@"parseError : %@", parseError.description);
        }
#endif // #if defined(DEBUG_DATAPARSER) && DEBUG_DATAPARSER
	} else {
//		parsedInfo = [[CJSONDeserializer deserializer] deserialize:data error:&parseError];
	}
    
    id resultDic = parsedInfo;
    if ([parsedInfo isKindOfClass: [NSDictionary class]]) {
        resultDic = [parsedInfo stripNullValues];
    } else if ([parsedInfo isKindOfClass: [NSArray class]]) {
        resultDic = [parsedInfo stripNullValues];
    }
	
	if (!parsedInfo) {
        if (parseError) {
            return [NSDictionary dictionaryWithObject:parseError forKey:@"error"];
        } else {
            return nil;
        }
	}

    NSDictionary *originalDic = [resultDic objectForKey:@"original"];
    NSDictionary *authInfoDic = [originalDic objectForKey:@"auth_info"];
    if (authInfoDic && authInfoDic.count != 0) {
        NSString *status = [authInfoDic objectForKey:@"status"];
        NSString *message = [authInfoDic objectForKey:@"msg"];
        if ([status isEqualToString:@"fail"]) {
            // 退出自有账号以及环信账号
            [[NSNotificationCenter defaultCenter] postNotificationName:OF_NOTIFICATION_BLOCKUSER
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"msg", nil]];
            
            // 展示错误信息
        }
    }
	return [self parsedResultWithRequestType:requestType parsedInfo:originalDic userInfo:userInfo];
}

#pragma mark -
#pragma mark Private Methods
+ (NSDictionary *)parsedResultWithRequestType:(MFRequestType)requestType
                                   parsedInfo:(id)parsedInfo
                                     userInfo:(NSDictionary *)userInfo {
    
    NSDictionary *result = nil;
    
    switch (requestType) {
            /**
             * Account相关
             */
        case MFRequestTypePinSellerAddr:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parsePinSellerAddressResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
					  [NSNumber numberWithBool:parsedResult], @"result",
					  [NSNumber numberWithInteger:requestType], @"type",
					  nil];
        }
            break;
        case MFRequestTypeRegisterOpenAccount:
        {
            BOOL parsedResult = [[MSSNSManager sharedManager] parseRegisterOpenAccountResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:parsedResult], @"result",
                                             [NSNumber numberWithInteger:requestType], @"type", nil];
            NSString *userID = [parsedInfo objectForKey:@"uid"];
            NSString *userName = [parsedInfo objectForKey:@"username"];
            NSString *mobilePhone = [parsedInfo objectForKey:@"mobile_phone"];
            NSString *countryCode = [parsedInfo objectForKey:@"country_code"];
            NSNumber *isRegistered = [parsedInfo objectForKey:@"is_registered"];
            NSString *openID = [userInfo objectForKey:@"userid"];
            if (userID && userID.length != 0) {
                [tempDic setObject:userID forKey:@"userID"];
            }
            if (userName && userName.length != 0) {
                [tempDic setObject:userName forKey:@"userName"];
            }
            if (openID && openID.length != 0) {
                [tempDic setObject:openID forKey:@"openID"];
            }
            if (mobilePhone && mobilePhone.length != 0) {
                [tempDic setObject:mobilePhone forKey:@"mobilePhone"];
            }
            if (countryCode && countryCode.length != 0) {
                [tempDic setObject:countryCode forKey:@"countrycode"];
            }
            if (isRegistered) {
                [tempDic setObject:isRegistered forKey:@"isRegistered"];
            }
            
			result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypeRegisterSelfAccount:
        {
            BOOL parsedResult = [[MSSNSManager sharedManager] parseRegistResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
			NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithBool:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypeUnregister:
        {
            BOOL parsedResult = [[MSSNSManager sharedManager] parseUnregistResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
			result = [NSDictionary dictionaryWithObjectsAndKeys:
					  [NSNumber numberWithBool:parsedResult], @"result",
					  [NSNumber numberWithInteger:requestType], @"type",
					  nil];
        }
            break;
        case MFRequestTypeGetUserProfile:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseUserProfileData:(NSDictionary *)parsedInfo userInfo:userInfo];
			result = [NSDictionary dictionaryWithObjectsAndKeys:
					  [NSNumber numberWithBool:parsedResult], @"result",
					  [NSNumber numberWithInteger:requestType], @"type",
					  nil];
            
            // 推送代付款订单
            NSDictionary *dataDic = [(NSDictionary *)parsedInfo objectForKey:@"data"];
            if (dataDic && [dataDic isKindOfClass:[NSDictionary class]]) {
                NSString *tradeNumber = [dataDic objectForKey:@"waiting_pay_trade_no"];
                if (tradeNumber && tradeNumber.length != 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:OF_NOTIFICATION_SHOWALERT_WAITINGPAY
                                                                        object:nil
                                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:tradeNumber, @"tradeNumber", nil]];
                }
            }
        }
            break;
        case MFRequestTypeReportError:
        {
            NSString *postResult = [(NSDictionary *)parsedInfo objectForKey:@"status"];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:[postResult isEqualToString:@"success"]],
                      @"result",
					  [NSNumber numberWithInteger:requestType],
                      @"type",
					  nil];
        }
            break;
        case MFRequestTypeGetBrands:
        {
            BOOL parsedResult = [[MSBrandDataManager manager] parseAllBrandsData:(NSDictionary *)parsedInfo userInfo:userInfo];
			result = [NSDictionary dictionaryWithObjectsAndKeys:
					  [NSNumber numberWithBool:parsedResult], @"result",
					  [NSNumber numberWithInteger:requestType], @"type",
					  nil];
        }
            break;
            
        case MFRequestTypeGetConfig:
        {
            BOOL parsedResult = [[MSConfigurationDataManager manager] parseData: (NSDictionary*)parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeRegisterDevices:
        {
            BOOL parsedResult = [(NSDictionary *)parsedInfo count] != 0;
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],
                      @"result",
                      [NSNumber numberWithInteger:requestType],
                      @"type",
                      (NSDictionary *)parsedInfo,
                      @"userinfo",
                      nil];
        }
            break;
            
        case MFRequestTypeGetProductConfiguration:
        {
            BOOL parsedResult = [[MSProductConfigurationManager manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypePostPorductComment:
        {
            NSString *postResult = [(NSDictionary *)parsedInfo objectForKey:@"status"];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:[postResult isEqualToString:@"success"]],
                      @"result",
					  [NSNumber numberWithInteger:requestType],
                      @"type",
					  nil];
        }
            break;
            
            /**
             * 单品相关
             */
        case MFRequestTypeGetProducts:
        case MFRequestTypeSearch:
        {
            BOOL parsedResult = [[MSSearchProductsManager manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetProductByID:
        {
            BOOL parsedResult = [[MSProductMananger manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetProductComments:
        {
            BOOL parsedResult = [[MSProductCommentsManager manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetFavoriteProduct:
        {
            BOOL parsedResult = [[MSProductFavoriteManager manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypePostFavoriteProduct:
        {
            BOOL parsedResult = [[MSProductFavoriteManager manager] parseFavoriteProductResponseData: parsedInfo
                                                                                            userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetSearchKeywords:
        {
            BOOL parsedResult = [[MSSearchKeywordDataManager manager] parseData: parsedInfo userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeGetProductSalesQuote:
        {
            BOOL parsedResult = [[OFGoodsInfoDataManager manager] parseFetchProductSalesQuoteResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult], @"result",
                      [NSNumber numberWithInteger:requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypePostSalesQuote:
        {
            BOOL parsedResult = [[OFGoodsInfoDataManager manager] parsePostSalesQuoteData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool: parsedResult], @"result",
                                            [NSNumber numberWithInteger: requestType], @"type",
                                            nil];
            if (parsedResult) {
                NSNumber *isNew = [parsedInfo objectForKey:@"is_new"];
                if (isNew) {
                 [tempDic setObject:isNew forKey:@"is_new"];   
                }
                
                NSString *gid = [parsedInfo objectForKey:@"gid"];
                if (gid && gid.length != 0) {
                    [tempDic setObject:gid forKey:@"gid"];
                }
            }
            
            if (!parsedResult && [userInfo isKindOfClass:[NSMutableDictionary class]]) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [(NSMutableDictionary *)userInfo setObject:error forKey:@"error"];
            }
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
            
            /**
             *
             */
        case MFRequestTypeGetMessages:
        {
            BOOL parsedResult = [[MSMessageFlowDataManager manager] parseMessagesData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetProductUsersByID:
        {
            BOOL parsedResult = [[MSProductFavoriteUserListManager manager] parseUsersData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            /**
             *  帖子功能
             */
        case MSRequestTypeGetPostsList:
        {
            BOOL parsedResult = [[MSPostsListDataManager manager] parseRequestPostsListResponseData: parsedInfo
                                                                                           userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeGetBestPostsList:
        {
            BOOL parsedResult = [[MSPostsListDataManager manager] parseRequestBestPostsListResponseData:parsedInfo
                                                                                               userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MSRequestTypeSearchPostsList:
        {
            BOOL parsedResult = [[MSPostsListDataManager manager] parseSearchPostsListResponseData: parsedInfo
                                                                                          userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MSRequestTypeGetPostsByID:
        {
            BOOL parsedResult = [[MSPostsDataManager manager] parseRequestPostsResponseData: parsedInfo
                                                                                   userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MSRequestTypeCreatePosts:
        {
            BOOL parsedResult = [[MSPostsListDataManager manager] parseCreatePostsResonponseData: parsedInfo
                                                                                        userInfo: userInfo];
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithBool: parsedResult], @"result",
                                              [NSNumber numberWithInteger: requestType], @"type", nil];
            if (parsedResult) {
                NSString *errorMessage = [parsedInfo objectForKey:@"error_msg"];
                if (errorMessage && errorMessage.length != 0) { // 发布帖子失败
                    [resultDic setObject:errorMessage forKey:@"errorMessage"];
                } else { // 发布帖子成功
                    NSString *postID = [parsedInfo objectForKey:@"postid"];
                    if (postID && postID.length != 0) {
                        [resultDic setObject:postID forKey:@"postID"];
                    }
                }
            }
            result = [NSDictionary dictionaryWithDictionary:resultDic];
        }
            break;
            
        case MSRequestTypeReplyPosts:
        {
            BOOL parsedResult = [[MSPostsDataManager manager] parseReplyPostsResponseData: parsedInfo
                                                                                 userInfo: userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool: parsedResult], @"result",
                                            [NSNumber numberWithInteger: requestType], @"type",
                                            nil];
            //            if (parsedResult) {
            //                NSString *errorMessage = [parsedInfo objectForKey:@"error_msg"];
            //                if (errorMessage && errorMessage.length != 0) {
            //                    [tempDic setObject:errorMessage forKey:@"errorMessage"];
            //                }
            //            }
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"msg", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
            
        case MSRequestTypeDeletePostsByID:
        {
            BOOL parsedResult = [[MSPostsDataManager manager] parseDeletePostsResponseData: parsedInfo
                                                                                  userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MSRequestTypeDeletePostsCommentByID:
        {
            BOOL parsedResult = [[MSPostsDataManager manager] parsedDeletePostsCommentResponseData: parsedInfo
                                                                                          userInfo: userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetGoodsIntroductionList:
        {
            BOOL parsedResult = [[MSPostsListDataManager manager] parseHomePostsRequestPostsListResponseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetFollowers:
        {
            BOOL parsedResult = [[MSFollowerProfileDataManager manager] parseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetFriends:
        {
            BOOL parsedResult = [[MSFriendProfileDataManager manager] parseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeFollowUser:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseFollowUserResponseData:parsedInfo
                                                                                   userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            
        case MFRequestTypeGetFavoriteProductProfile:
        {
            BOOL parsedResult = [[MSFavoriteProductProfileDataManager manager] parseData:parsedInfo
                                                                                userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeGetPostsCommentList:
        {
            BOOL parsedResult = [[OFCommentsListDataManager manager] parsePostsCommentData:parsedInfo
                                                                                  userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;

            /**
             * 私信模块
             */
        case MFRequestTypeGetPrivateMessageList:
        {
            BOOL parsedResult = [[MSChatMessageDataManager manager] parseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeSendPrivateMessage:
        {
            BOOL parsedResult = [[MSChatMessageDataManager manager] parseSendMessageResultData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case MFRequestTypeGetStrangerMessageProfile:
        case MFRequestTypeGetPrivateMessageProfile:
        {
            BOOL parsedResult = [[MSChatBoxDataManager manager] parseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSystemConversationList:
        {
            BOOL parsedResult = [[MSChatBoxDataManager manager] parseSystemConversationListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool: parsedResult], @"result",
                      [NSNumber numberWithInteger: requestType], @"type",
                      nil];
        }
            break;
            /**
             *获取用户地址信息
             */
        case OFRequestTypeGetUserAddress:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseGetUserAddressOriginalData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
            
        case OFRequestTypePostUserAddress:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parsePostUserAddressOrginalData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult], @"result",
                                            [NSNumber numberWithInteger:requestType], @"type",
                                            nil];
            if (parsedResult) {
                NSString *addrID = [parsedInfo objectForKey:@"addr_id"];
                if (addrID) {
                    [tempDic setObject:addrID forKey:@"addrID"];
                }
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
            
        case MFRequestTypeGetOrderList:
        {
            BOOL parsedResult = [[OFOrderListDataManager manager] parseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;

        case OFRequestTypeFetchSMSVCode:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseSMSVCode:parsedInfo userInfo:nil];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypeGetOrderDetail:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeDetailData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithBool:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradeOrder:
        {
            NSString *tradeNum = nil;
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseCreateTradeData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (parsedResult) {
                tradeNum = [parsedInfo objectForKey:@"trade_no"];
                if (tradeNum) {
                    [tempDic setObject:tradeNum forKey:@"tradeNum"];
                }
                NSNumber *tradeStatus = [parsedInfo objectForKey:@"trade_status"];
                [tempDic setObject:tradeStatus forKey:@"tradeStatus"];
                NSNumber *payPrice = [parsedInfo objectForKey:@"pay_price"];
                [tempDic setObject:payPrice forKey:@"payPrice"];
            } else {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            result = [NSDictionary dictionaryWithDictionary:tempDic];
            
        }
            break;
        case MFRequestTypePostTradeAccept:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeAcceptData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradePay:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradePayData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradeDelivery:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeDeliveryData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradeSign:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeSignData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradeCancel:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeCancelData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypeGetUnionpayNo:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseTradeCancelData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            NSString *tn = nil;
            if (parsedResult) {
                tn = [parsedInfo objectForKey:@"tn"];
                if (tn) {
                    [tempDic setObject:tn forKey:@"tn"];
                }
            } else {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostTradeLogistics:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parsePostLogisticData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
            
        }
            break;
        case MFRequestTypeGetTradeLogistics:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseGetLogisticData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeTradeComment:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parsePostTradeCommentData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case OFRequestTypeReplyTradeComment:
        {
            BOOL parsedResult = [[OFSellerCommentDataManager manager] parsePostReplyCommentData:parsedInfo userInfo:userInfo];
            result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSellerAccountInfo:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseSellerAccountInfoData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequstTypeGetSellerAccountHistory:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseSellerAccountHistoryData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeVerifyTradeAvailable:
        {
            BOOL parsedResult = [[OFOrderInfoDataManager manager] parseVerifyTradeAvailable:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult], @"result",
                                            [NSNumber numberWithInteger:requestType], @"type", nil];
            if (parsedResult) {
                NSString *currTime = [parsedInfo objectForKey:@"updatetime"];
                if (currTime && currTime.length != 0) {
                    NSString *tradeNum = [userInfo objectForKey:@"tradeNum"];
                    OFOrderInfoData *orderInfoData = [[OFOrderInfoDataManager manager] fetchOrderDataWithTradeNum:tradeNum];
                    if (orderInfoData) {
                        NSDateComponents *dateComponents = [[MSCommons common] differentDateComponentsFromDateString:currTime
                                                                                                              toDate:[[MSCommons common] dateFromDateString:orderInfoData.triggerTime]];
                        if (dateComponents && dateComponents.day >= 0 && dateComponents.hour >= 0 && dateComponents.minute >= 0) {
                            NSInteger timeout = dateComponents.minute;
                            timeout += dateComponents.hour * 60;
                            timeout += dateComponents.day * 60 * 24;
                            // 向上取1分钟，保证交易系统超时时不会付款
                            [tempDic setObject:[NSNumber numberWithInteger:timeout + 1] forKey:@"itBPay"];
                        } else {
                            NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                                 code:kOFErrorCodeNone
                                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       @"订单已过期，请重新下单", @"errorMessage", nil]];
                            [tempDic setObject:error forKey:@"error"];
                        }
                    }
                }
            } else {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case OFRequestTypeGetTradeComments:
        {
            BOOL parsedResult = [[OFSellerCommentDataManager manager] parseGetTradeComments:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypePostRealPersonalInfo:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parsePostRealPersonalInfoOriginalData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case OFRequestTypeGetGoodsDetail:
        {
            BOOL parsedResult = [[OFGoodsInfoDataManager manager] pareseGetGoodsDetail:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeSearchUsers:
        {
            
            BOOL parsedResult = [[OFUserProfileDataManager manager] parseSearchUsersData:parsedInfo userInfo:userInfo];
            NSInteger resultCount = [[parsedInfo objectForKey:@"total"] integerValue];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      [NSNumber numberWithInteger:resultCount], @"resultCount",
                      nil];
        }
            break;
        case OFRequestTypeGetSellerList:
        {
            BOOL parsedResult = [[OFUserProfileDataManager manager] parseGetSellerListData:parsedInfo usetInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        
        }
            break;
        case OFRequestTypeGetGoodsTopicsList:
        {
            BOOL parsedResult = [[OFTopicItemDataManager manager] parseGetGoodsTopicData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsTopicsDetail:
        {
            BOOL parsedResult = [[OFGoodsDataManager manager] parseGoodsTopicsDetailData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeSMSCountry:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseSMSCountryData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeLoginAccount:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseLoginAccount:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
            NSString *uid = nil;
            if (parsedResult) {
                uid = [parsedInfo objectForKey:@"uid"];
                if (uid) {
                    [tempDic setObject:uid forKey:@"uid"];
                }
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case OFRequestTypePostRegisterAccountWithPhone:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseRegisterAccountWithData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypePostResetPassword:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseResetPasswordWithData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeUpgradeAccountWithPhone:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseUpgradeAccountWithData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case MFRequestTypePostUpdateUserAvatarImage:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseUpdateUserAvatarImageData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostUpdateUserNickName:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseUpdateUserNickNameData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostChangePassword:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseChangePasswordData:parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypePostBindWeiboAccount:
        {
            BOOL parsedResult = [[MSSNSManager sharedManager] parseBindResponseData:(NSDictionary *)parsedInfo userInfo:userInfo];
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:parsedResult],@"result",
                                            [NSNumber numberWithInteger:requestType],@"type",
                                            nil];
            if (!parsedResult) {
                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
                                                     code:kOFErrorCodeNone
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
                [tempDic setObject:error forKey:@"error"];
            }
            
            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case MFRequestTypeGetSearchGoods:
        {
            BOOL parsedResult = [[OFGoodsDataManager manager] parseSearchGoodsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case MFRequestTypeGetSearchStoreGoods:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] pareseGetSearchStoreGoodsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypePostFavoriteGoods:
        {
            BOOL parsedResult = [[OFGoodsInfoDataManager manager] parsePostFavoriteGoodsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
//            NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                            [NSNumber numberWithBool:parsedResult],@"result",
//                                            [NSNumber numberWithBool:requestType],@"type",
//                                            nil];
//            if (!parsedResult) {
//                NSError *error = [NSError errorWithDomain:kOFErrorDomainParseResult
//                                                     code:kOFErrorCodeNone
//                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                           [parsedInfo objectForKey:@"msg"], @"errorMessage", nil]];
//                [tempDic setObject:error forKey:@"error"];
//            }
//            
//            result = [NSDictionary dictionaryWithDictionary:tempDic];
        }
            break;
        case OFRequestTypeGetExpertInfo:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseExpertProfileData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithBool:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSellerInfo:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseGetSellerInfoData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsBrands:
        {
            BOOL parsedResult = [[OFGoodsDataManager manager] parseGetGoodsBrandsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetFavoriteGoodsList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parsedGoodsListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsClassification:
        {
            BOOL parsedResult = [[OFGoodsDataManager manager] parseGetGoodsClassifyData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSellerGoodsList: {
            BOOL parsedResult = [[MSAccountDataManager manager] parseGetSellerStoreGoodsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetInterestUserList: {
            BOOL parsedResult = [[MSAccountDataManager manager] parsedGetInterestedUserListData:parsedInfo usetInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithBool:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetFavoriteGoodsIDList: {
            BOOL parsedResult = [[OFFavoriteGoodsIDDataManager manager] parsedFavoriteGoodsIDData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetTradeNoticeList:
        {
            BOOL parsedResult = [[MSMessageFlowDataManager manager] parseGetTradeNotificeListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSystemNoriceList:
        {
            BOOL parsedResult = [[MSMessageFlowDataManager manager] parseGetSystemNotificeListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetUserInfoByEMList:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseGetUserInfoByEMListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetUserInfoByEMID:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseGetUserInfoByEMIDData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSellerIDList:
        {
            BOOL parsedResult = [[OFSellerIDDataManager manager] parsedSellerIDListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetDesireList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parsedDesireListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetUpdateNoticeList:
        {
            BOOL parsedResult = [[OFSystemNotificationListDataManager manager] parsedSystemNotificationListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeDeleteUpdateNotice:
        {
            BOOL parsedResult = [[OFSystemNotificationDataManager manager] parsedSystemNotificationData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetFavoriteUsersByGoodsID:
        {
            BOOL parsedResult = [[OFGoodsFavoriteUserProfileDataManager manager] parsedGoodsFavoriteUserProfileData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsAndProductsList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parsedGetGoodsAndProductListResponseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeSearchGoodsAndProducts:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parsedSearchGoodsAndProductResponseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeSearchSellers:
        {
            BOOL parsedResult = [[OFSellerProfileListDataManager manager] parseSearchSellerListData:parsedInfo usetInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypePostSeekingBuyerInfo:
        {
            BOOL parsedResult = [[OFSeekingPostsDataManager manager] parsePostSeekingBuyerInfoData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithBool:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeDeleteSeekingPostsInfo:
        {
            BOOL parsedResult = [[OFSeekingPostsDataManager manager] parseDeleteSeekingPostsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSeekingPostsList:
        {
            BOOL parsedResult = [[OFSeekingPostsListDataManager manager] paraseGetSeekingPostsListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSeekingPostsInfo:
        {
            BOOL parsedResult = [[OFSeekingPostsDataManager manager] parseGetSeekingPostsInfoData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetSeekingPostsSalesQuoteList:
        {
            BOOL parsedResult = [[OFSeekingPostsDataManager manager] parseGetSeekingPostsSalesQuoteListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case MFRequestTypeGetSellerGoodsList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parseGetSellerGoodsList:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetHotSearchKeywords:
        {
            BOOL parsedResult = [[OFSearchKeywordDataManager manager] paraseGetHotSearchKeywordsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case MFRequestTypeFeedback:
        {
            BOOL parsedResult = [[MSAccountDataManager manager] parseFeedback:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetProductsList:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetProductsListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeSearchProducts:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseSearchProductsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetNewestProductsList:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetNewestProductListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetBestBrandsProductsList:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetBestBrandsProductListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetHotSalesProductsList:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetHotSalesProductListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetDiscountProductsList:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetDiscountProductListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetHotGoodsList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parseGetSellerHotGoodsList:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetLatestGoodsList:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parseGetSellerLatestGoodsList:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetIndex:
        {
            BOOL parsedResult = [[OFHomeCategoryDataManager manager] parsedHomeCategoryData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetEditorRecommend:
        {
            BOOL parsedResult = [[OFRecommendListDataManager manager] parsedRecommendData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetDiscoveryShopList:
        {
            BOOL parsedResult = [[OFSellerListDataManager manager] parsedSellerListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsComments:
        {
            BOOL parsedResult =  [[OFGoodsCommentListDataManager manager] parsedGoodsCommentListData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetProductsListByTags:
        {
            BOOL parsedResult = [[MSProductsFlowDataManager manager] paraseGetProductslistByTagsData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypeGetGoodsCollections:
        {
            BOOL parsedResult = [[OFGoodsListDataManager manager] parseGetGoodsCollectionResponseData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        case OFRequestTypePostGetuiRegisterInfo:
        {
            BOOL parsedResult = [[MSConfigurationDataManager manager] parseUpdateGeiTuiClientData:parsedInfo userInfo:userInfo];
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:parsedResult],@"result",
                      [NSNumber numberWithInteger:requestType],@"type",
                      nil];
        }
            break;
        default:
			break;
	}
    
    return result;
}

@end
