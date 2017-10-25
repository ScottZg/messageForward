//
//  People.m
//  MessageSelectorDemo
//
//  Created by zhanggui on 2017/10/24.
//  Copyright © 2017年 zhanggui. All rights reserved.
//

#import "People.h"
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Student.h"
void autoDictionaryGetter(id self,SEL _cmd);
void autoDictionarySetter(id  self,SEL _cmd,id value);
@interface People()

@property (nonatomic,strong)NSMutableArray *friends;
@property (nonatomic,strong)Student *student;
@end

@implementation People


- (void)work {
    NSLog(@"work");
}
- (void)beFriendWith:(People *)po {
    NSLog(@"开始成为朋友....");
    [self.friends addObject:po];
    NSLog(@"已成为朋友");

}
//void gotoSchool(id self,SEL _cmd,id value) {
//    printf("go to school");
//}
////第一步：对象在收到无法解读的消息后，首先将调用所属类的该方法。
//+ (BOOL)resolveInstanceMethod:(SEL)sel {
//    NSString *selectorString = NSStringFromSelector(sel);
//    if ([selectorString isEqualToString:@"gotoschool"]) {
//        class_addMethod(self, sel, (IMP)gotoSchool, "@@:");
//    }
//    return [super resolveInstanceMethod:sel];
//}
//第三步：备援接收者，让其他对象进行处理
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    NSString *selectorString = NSStringFromSelector(aSelector);
//    if ([selectorString isEqualToString:@"gotoschool"]) {
//        return self.student;
//    }
//    return nil;
//}
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"%@ can't handle by People",NSStringFromSelector([anInvocation selector]));
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    return sign;
}
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    NSLog(@"sdfsd");
//    return nil;
//}
#pragma mark - Lazy load
- (Student *)student {
    if (!_student) {
        _student = [Student new];
    }
    return _student;
}
- (NSMutableArray *)friends {
    if (!_friends) {
        _friends = [NSMutableArray array];
    }
    return _friends;
}
@end
