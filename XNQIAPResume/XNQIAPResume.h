//
//  XNQIAPResume.h
//  XNQIAPResume
//
//  Created by semyon on 2018/12/18.
//  Copyright © 2018 cm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, kResumeReceiptError) {
    kResumeReceiptErrorDataInvalid, // 数据验证失败
    kResumeReceiptErrorForceFailure, // 强制更新失败
    kResumeReceiptErrorJsonFailure, // json解析失败
};

// isBuyDownload：是否是付费下载，error：错误信息
typedef void(^ReceiptComplete)(BOOL isBuyDownload,  NSError * _Nullable error);

@interface XNQIAPResume : NSObject

+ (instancetype)sharedInstace;

/**
 恢复购买，主要是付费下载转换为内购
 */
+ (void)resumeBuyReceiptWithIapFirstVer:(NSString *)iapFirstVer complete:(ReceiptComplete)complete;

@end

NS_ASSUME_NONNULL_END
