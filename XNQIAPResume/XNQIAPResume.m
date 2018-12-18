//
//  XNQIAPResume.m
//  XNQIAPResume
//
//  Created by semyon on 2018/12/18.
//  Copyright © 2018 cm. All rights reserved.
//

#import "XNQIAPResume.h"
#import <StoreKit/StoreKit.h>

#ifdef DEBUG
    #define NSLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
    #define NSLog(...);
#endif

static NSString const *kProductionHost = @"https://buy.itunes.apple.com/verifyReceipt";
static NSString const *kSandboxHost = @"https://sandbox.itunes.apple.com/verifyReceipt";

@interface XNQIAPResume () <SKRequestDelegate>

@property (nonatomic, copy) ReceiptComplete temComplete;
@property (nonatomic, copy) NSString *iapFirstVer; // 内购开始的版本号, 必须要提前传进去

@end

@implementation XNQIAPResume

+ (instancetype)sharedInstace {
    static id __ins = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__ins == nil) {
            __ins = [[[self class] alloc] init];
        }
    });
    return __ins;
}

- (void)resumeBuyReceiptComplete:(ReceiptComplete)complete {
    self.temComplete = complete;
    NSData *receiptData = [self getLocalReceiptData];
    if (receiptData) {
        [self requestCheckReceipt:receiptData];
    }
    else {
        SKReceiptRefreshRequest *refreshReqeust = [[SKReceiptRefreshRequest alloc] init];
        refreshReqeust.delegate = self;
        [refreshReqeust start];
    }
}

- (NSString *)getCheckReceiptUrl {
#ifdef DEBUG
    return (NSString *)kSandboxHost;
#endif
    return (NSString *)kProductionHost;
}

- (NSData *)getLocalReceiptData {
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    return receiptData;
}

- (void)requestCheckReceipt:(NSData *)receiptData {
    [self requestCheckReceipt:receiptData password:nil];
}

- (void)requestCheckReceipt:(NSData *)receiptData password:(NSString *)password {
    NSError *error = nil;
    NSString *receiptBase64Str = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSDictionary *paramDic;
    if (password) {
        paramDic = @{
                     @"receipt-data" : receiptBase64Str,
                     @"password" : password
                       };
    }
    else {
        paramDic = @{ @"receipt-data" : receiptBase64Str };
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramDic options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"[IAP]: error %@", error);
        if (self.temComplete) {
            self.temComplete(NO, [self createError:kResumeReceiptErrorDataInvalid]);
        }
        return;
    }
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *requestUrl = [NSURL URLWithString:[self getCheckReceiptUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    
    NSURLSessionTask *sessionTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonError = nil;
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
        NSLog(@"[IAP]: responseDic %@", responseDic);
        if (jsonError) {
            return ;
        }
        NSInteger status = [responseDic[@"status"] integerValue];
        if (status != 0) { // 交易收据有错误
            if (self.temComplete) {
                self.temComplete(NO, [self createError:kResumeReceiptErrorDataInvalid]);
            }
            return;
        }
        NSString *oriBuyVerStr = responseDic[@"receipt"][@"original_application_version"]; // 最初购买的 App 的版本
        NSAssert(self.iapFirstVer, @"请配置内购开始版本号！");
        NSString *iapFirstVerStr = self.iapFirstVer; // 内购开始的第一个版本号
        if ([iapFirstVerStr compare:oriBuyVerStr options:NSNumericSearch] == NSOrderedDescending) { // 如果最初购买的版本号小于我们内购开始的第一个版本说明是下载的之前版本，直接跳过内购；
            NSLog(@"[IAP]: 之前下载过付费版本，不需要再内购");
            if (self.temComplete) {
                self.temComplete(YES, nil);
            }
        }
        
        NSArray *inAppArr = responseDic[@"receipt"][@"in_app"];
        if (inAppArr.count > 0) { // 说明有内购，可以进行内购恢复
            NSLog(@"[IAP]: 之前内购过，可以执行恢复");
        }
    }];
    [sessionTask resume];
}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request NS_AVAILABLE(10_7, 3_0) {
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        NSData *receiptData = [self getLocalReceiptData];
        if (receiptData) {
            NSLog(@"[IAP]: force refresh receipt success");
            [self requestCheckReceipt:receiptData];
        }
        else { //
            NSLog(@"[IAP]: force refresh receipt failure");
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error NS_AVAILABLE(10_7, 3_0) {
    NSLog(@"[IAP]: force refresh receipt request failure");
    if (self.temComplete) {
        self.temComplete(NO, [self createError:kResumeReceiptErrorForceFailure]);
    }
}

- (NSError *)createError:(NSUInteger)code {
    return [NSError errorWithDomain:@"com.xnq" code:code userInfo:nil];
}

#pragma mark - Public

+ (void)resumeBuyReceiptWithIapFirstVer:(NSString *)iapFirstVer complete:(ReceiptComplete)complete {
    XNQIAPResume *resume = [XNQIAPResume sharedInstace];
    resume.iapFirstVer = iapFirstVer;
    [resume resumeBuyReceiptComplete:complete];
}

@end
