# XNQIAPResume

造个轮子，因为有个swift版本SwiftyStoreKit，没有找到oc版本。

swift内购很强大库：https://github.com/bizz84/SwiftyStoreKit

# 使用场景
付费下载，版本删除后重新下载，这时候我们app改成了内购版本，需要判断是否是之前付费下载用户，然后默认打开购买权益。

# 解决方案

1）获取Receipt数据, 如果本地有直接获取。

```
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
```

如果本地没有，去苹果刷新，然后再从本地获取。 

```
        SKReceiptRefreshRequest *refreshReqeust = [[SKReceiptRefreshRequest alloc] init];
        refreshReqeust.delegate = self;
        [refreshReqeust start];
```

2) 拿Receipt数据去苹果验证

苹果验证域名：

```
NSString *production = @"https://buy.itunes.apple.com/verifyReceipt"; // 正式环境
NSString *sandbox = @"https://sandbox.itunes.apple.com/verifyReceipt"; // 沙盒环境
```
需要将Receipt，base64编码成string，请求参数json如下：

|key|value|
|----|----|----|
|receipt-data|base64 编码的收据数据。|
| password | 仅用于包含自动续期订阅的收据。您App的共享密钥（十六进制字符串）。|
|exclude-old-transactions|仅用于包含自动续期订阅或非续期订阅的iOS7样式App收据。如果值为 true，仅响应包括所有订阅的最新续期交易。|

获取苹果返回结果如下：

```
{
    environment = Sandbox;
    receipt =     {
        "adam_id" = 0;
        "app_item_id" = 0;
        "application_version" = "1.1.0";
        "bundle_id" = "com.xxx";
        "download_id" = 0;
        "in_app" =         ( // App 内购买项目收据字段
                        {
                "is_trial_period" = false;
                "original_purchase_date" = "2018-12-13 06:43:11 Etc/GMT";
                "original_purchase_date_ms" = 1544683391000;
                "original_purchase_date_pst" = "2018-12-12 22:43:11 America/Los_Angeles";
                "original_transaction_id" = 1000000486729404;
                "product_id" = "com.xxx";
                "purchase_date" = "2018-12-13 06:43:11 Etc/GMT";
                "purchase_date_ms" = 1544683391000;
                "purchase_date_pst" = "2018-12-12 22:43:11 America/Los_Angeles";
                quantity = 1;
                "transaction_id" = 1000000486729404;
            }
        );
        "original_application_version" = "1.0"; // 最初购买的 App 的版本
        "original_purchase_date" = "2013-08-01 07:00:00 Etc/GMT";
        "original_purchase_date_ms" = 1375340400000;
        "original_purchase_date_pst" = "2013-08-01 00:00:00 America/Los_Angeles";
        "receipt_creation_date" = "2018-12-14 12:28:12 Etc/GMT";
        "receipt_creation_date_ms" = 1544790492000;
        "receipt_creation_date_pst" = "2018-12-14 04:28:12 America/Los_Angeles";
        "receipt_type" = ProductionSandbox;
        "request_date" = "2018-12-18 07:10:21 Etc/GMT";
        "request_date_ms" = 1545117021021;
        "request_date_pst" = "2018-12-17 23:10:21 America/Los_Angeles";
        "version_external_identifier" = 0;
    };
    status = 0;
}
```

通过解析最初购买app的版本original\_application_version，跟内购第一个版本进行比较，判断是不是需要恢复购买身份

in_app字段下是内购的信息，可以用来判断是不是内购过。


苹果官方文档：
https://developer.apple.com/cn/app-store/Receipt-Validation-Programming-Guide-CN.pdf
