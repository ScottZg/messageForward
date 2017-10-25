//
//  ViewController.m
//  MessageSelectorDemo
//
//  Created by zhanggui on 2017/10/24.
//  Copyright © 2017年 zhanggui. All rights reserved.
//

#import "ViewController.h"
#import "People.h"
#import <objc/message.h>
#import "ZGAutoDictionary.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    People *zhangSan = [[People alloc] init];
    People *lisi = [[People alloc] init];
    [zhangSan beFriendWith:lisi];
//    SEL sel = @selector(beFriendWith:);
//    IMP methodPoint = [zhangSan methodForSelector:sel];
//    [zhangSan performSelector:sel withObject:lisi];
////    objc_msgSend(zhangSan,@selector(beFriendWith:),lisi);
    [lisi performSelector:@selector(gotoschool) withObject:nil afterDelay:0];
    
}
- (void)gotoschool {
    NSLog(@"ViewController's go to school");
}
- (IBAction)showTimeAction:(id)sender {
    ZGAutoDictionary *dict = [ZGAutoDictionary new];
//    dict.date = [NSDate date];
//    NSLog(@"%@",dict.date);
    [dict performSelector:@selector(allKeys) withObject:@"zgzg" afterDelay:0];
   
}


@end
