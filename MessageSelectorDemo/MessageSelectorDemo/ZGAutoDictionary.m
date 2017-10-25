//
//  ZGAutoDictionary.m
//  MessageSelectorDemo
//
//  Created by zhanggui on 2017/10/24.
//  Copyright © 2017年 zhanggui. All rights reserved.
//

#import "ZGAutoDictionary.h"
#import <objc/runtime.h>
@interface ZGAutoDictionary()

@property (nonatomic,strong)NSMutableDictionary *backingStore;
@end

@implementation ZGAutoDictionary

@dynamic string,number,date,opaqueObject;


- (instancetype)init {
    self = [super init];
    if (self) {
        _backingStore = [NSMutableDictionary new];
    }
    return self;
}
id autoDictionaryGetter(id self, SEL _cmd) {
    ZGAutoDictionary *typedSelf = (ZGAutoDictionary *)self;
    NSMutableDictionary *backingStore = typedSelf.backingStore;
    
    NSString *key = NSStringFromSelector(_cmd);
    
    return [backingStore objectForKey:key];
}
void autoDictionarySetter(id self,SEL _cmd,id value) {
    ZGAutoDictionary *typedSelf = (ZGAutoDictionary *)self;
    NSMutableDictionary *backingStrore = typedSelf.backingStore;
    NSString *selectorString = NSStringFromSelector(_cmd);
    NSMutableString *key = [selectorString mutableCopy];
    
    [key deleteCharactersInRange:NSMakeRange(key.length - 1, 1)];
    
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    NSString *lowercaseFirstChar = [[key substringToIndex:1] lowercaseString];
    
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:lowercaseFirstChar];
    
    if (value) {
        [backingStrore setObject:value forKey:key];
    }else {
        [backingStrore removeObjectForKey:key];
    }
    
}
void printDescription(id self,SEL _cmd,id value) {
    ZGAutoDictionary *dic = (ZGAutoDictionary *)self;
    
    NSLog(@"%@",dic.description);
}
//第三步：完整的消息转发
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL sel = [anInvocation selector];
    if ([_backingStore respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:_backingStore];
    }else {
        [super forwardInvocation:anInvocation];
    }
    
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    return sign;
}
//第二步：备援接收者
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    return @(1);
//}
//第一步：动态方法解析：如果调用的方法是类方法，那么会执行这个函数
//+ (BOOL)resolveClassMethod:(SEL)sel {
//    NSString *selectorString = NSStringFromSelector(sel);
//    NSLog(@"%@",selectorString);
//    return YES;
//}
//第一步：动态方法解析：如果是实例方法，那么会执行这个函数。
//+ (BOOL)resolveInstanceMethod:(SEL)sel {
//    NSString *selectorString = NSStringFromSelector(sel);
//    if ([selectorString isEqualToString:@"printDescription:"]) {
//        class_addMethod(self, sel, (IMP)printDescription, "@@:");
//        return YES;
//    }
//    if ([selectorString hasPrefix:@"set"]) {
//        class_addMethod(self, sel, (IMP)autoDictionarySetter, "v@:@");
//    }else {
//        class_addMethod(self, sel, (IMP)autoDictionaryGetter, "@@:");
//    }
//    return [super resolveInstanceMethod:sel];
//}
@end
