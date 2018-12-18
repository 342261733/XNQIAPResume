//
//  ViewController.m
//  XNQIAPResume
//
//  Created by semyon on 2018/12/18.
//  Copyright © 2018 cm. All rights reserved.
//

#import "ViewController.h"
#import "XNQIAPResume.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // test
    [XNQIAPResume resumeBuyReceiptWithIapFirstVer:@"1.2.0" complete:^(BOOL isBuyDownload, NSError * _Nullable error) {
        if (isBuyDownload) { // 执行购买恢复操作
            NSLog(@"之前付费下载，执行内购恢复操作");
        }
        else {
            NSLog(@"error : %@", error);
        }
    }];
}


@end
