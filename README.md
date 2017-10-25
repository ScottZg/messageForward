#### 深入浅出理解消息的传递和转发机制
##### 前言
在面试过程中你也许会被问到消息转发机制。这篇文章就是对消息的转发机制进行一个梳理。主要包括什么是消息、静态绑定/动态绑定、消息的传递和消息的转发。接下来开发进入正题。
##### 消息的解释
在其他语言里面，我们可以用一个类去调用某个方法，在OC里面，这个方法就是消息。某个类调用一个方法就是向这个类发送一条消息。举个例子：
```objective-c
People *zhangSan = [[People alloc] init];
People *lisi = [[People alloc] init];
[zhangSan beFriendWith:lisi];
```
我们有个People的类，zhangSan这个实例发送了一条beFriendWith:的消息。你也许还看过这种调用方式：
```objective-c
[zhangSan performSelector:@selector(beFriendWith:) withObject:lisi];
```
其目和上面的一样，都是向zhangSan发送了一条beFriendWith:的消息，传人的参数都是lisi。
这里简单介绍一下SEL和IMP：
>SEL:类成员方法的指针，但和C的函数指针还不一样，函数指针直接保存了方法的地址，但是SEL只是方法编号。
>IMP:函数指针，保存了方法地址。

我们叫@selector(beFriendWith:)为消息的选择子或者选择器。(A selector identifying the message to send)
##### 静态绑定/动态绑定
所谓静态绑定，就是在编译期就能决定运行时所调用的函数，例如：
```c
void printHello() {
    printf("Hello,world!\n");
}
void printGoodBye() {
    printf("Goodbye,world!\n");
}

void doTheThing(int type) {
    if (type == 0) {
        printHello();
    }else {
        printGoodBye();
    }
}
```
所谓动态绑定，就是在运行期才能确定调用函数：
```c
void printHello() {
    printf("Hello,world!\n");
}
void printGoodBye() {
    printf("Goodbye,world!\n");
}
void doTheThing(int type) {
    void (*fnc)(void);
    if (type == 0) {
        fnc = printHello;
    }else {
        fnc = printGoodBye;
    }
    fnc();
}
```
在OC中，对象发送消息，就会使用动态绑定机制来决定需要调用的方法。其实底层都是C语言实现的函数，当对象收到消息后，究竟调用那个方法完全决定于运行期，甚至你也可以直接在运行时改变方法，这些特性都使OC成为一门动态语言。
##### 消息的传递
先看一下一条简单的消息：
```objective-c
id returnValue = [someObject messageName:parameter];
```
其中：
someObject叫做接收者(receiver)。
messageName叫做选择器(selector)
选择器和参数合起来成为消息(message)
当编译器看到这条消息，就会转换成一条标准的C函数：objc_msgSend,此时会变成：
```objective-c
id returnValue = objc_msgSend(someObject,@selector(messageName:),parameter);
```
objc_msgSend可以在objc里面的message.h中看到:
![objc_msgSend](https://raw.githubusercontent.com/ScottZg/MarkDownResource/master/messageforward/objc_msgSend.png)
根据官方注释可以看到：
>When it encounters a method call, the compiler generates a call to one of the functions objc_msgSend, objc_msgSend_stret, objc_msgSendSuper, or objc_msgSendSuper_stret. Messages sent to an object’s superclass (using the super keyword) are sent using objc_msgSendSuper; other messages are sent using objc_msgSend. Methods that have data structures as return values are sent using objc_msgSendSuper_stret and objc_msgSend_stret.

它的作用是向一个实例类发送一个带有简单返回值的message。是一个参数个数不定的函数。当遇到一个方法调用，编译器会生成一个objc_msgSend的调用，有：objc_msgSend_stret、objc_msgSendSuper或者是objc_msgSendSuper_stret。发送个父类的message会使用objc_msgSendSuper，其他的消息会使用objc_msgSend。如果方法的返回值是一个结构体(structures)，那么就会使用objc_msgSendSuper_stret或者objc_msgSend_stret。
第一个参数是：指向接收该消息的类的实例的指针
第二个参数是：要处理的消息的selector。
其他的就是要传入的参数。
这样消息派发系统就在接收者所属类中查找器方法列表，如果找到和选择器名称相符的方法就跳转其实现代码，如果找不到，就再起父类找，等找到合适的方法在跳转到实现代码。这里跳转到实现代码这一操作利用了[尾递归优化](http://www.cnblogs.com/zhanggui/p/7722541.html)。
如果该消息无法被该类或者其父类解读，就会开始进行消息转发。
##### 理解消息转发机制(message forwarding)
###### 动态方法解析
不要把消息转发机制想象得很难，其实看过下面的你就会发现，没有那么难。
我们有的时候会遇到这样的crash：
![crash](https://raw.githubusercontent.com/ScottZg/MarkDownResource/master/messageforward/crash.png)
我们都知道crash的原因是People没有gotoschool这个方法，但是你调用了该方法，所以会产生NSInvalidArgumentException，reason：
```
-[People gotoschool]: unrecognized selector sent to instance 0x1d4201780'
```
接下来让我们看看从发送消息到此crash的过程。前面消息的传递没有成功找到实现，所以会走到消息转发里面，我先在People类里面实现了这样一个方法：
```objective-c
void gotoSchool(id self,SEL _cmd,id value) {
    printf("go to school");
}
//对象在收到无法解读的消息后，首先将调用所属类的该方法。
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *selectorString = NSStringFromSelector(sel);
    if ([selectorString isEqualToString:@"gotoschool"]) {
        class_addMethod(self, sel, (IMP)gotoSchool, "@@:");
    }
    return [super resolveInstanceMethod:sel];
}
```
然后再次运行程序，你会发现没有crash了，而且顺利打印出来"go to school"。
这个是什么个情况呢？先看看这个方法：
```objective-c
+ (BOOL)resolveInstanceMethod:(SEL)sel OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0, 2.0);
+ (BOOL)resolveClassMethod:(SEL)sel OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0, 2.0);
```
这个方法是objc里面NSObject.h里面的方法。从字面理解就是处理实例方法(处理类方法)。下面是对其的介绍：
![resolveInstanceMethod／forwardingTargetForSelector:](https://raw.githubusercontent.com/ScottZg/MarkDownResource/master/messageforward/resolveInstanceMethod.png)
它的作用就是给一个实例方法（给定的选择器）动态提供一个实现。注释也提供了一个demo告诉我们如何动态添加实现。
也就是说当消息传递无法处理的时候，首先会看一下所属类，是否能动态添加方法，以处理当前未知的选择子。这个过程叫做“动态方法解析”(dynamic method resolution)。
这里我在动态方法解析这里动态添加了实现，然后程序就不会崩溃啦。
如果是类方法，就调用resolveClassMethod:方法进行操作，和上面的resolveInstanceMethod一样的处理方式。
这里还用到了calss_addMethod，后面会单独写篇博客对其介绍。感兴趣的可以先自行查看API。
###### 备援接收者
当动态方法解析没有实现或者无法处理的时候，就会执行
```objective-c
- (id)forwardingTargetForSelector:(SEL)aSelector OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0, 2.0);
```
这个方法也是objc里面NSObject.h里面的方法。我对People进行了如下处理：
```objective-c
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *selectorString = NSStringFromSelector(aSelector);
    if ([selectorString isEqualToString:@"gotoschool"]) {
        return self.student;
    }
    return nil;
    
}
```
我在People里面添加了一个Student类实例，然后实现了forwardingTargetForSelector：方法。然后运行，奇迹地发现程序也没有崩溃。该方法的作用是（上图也有介绍）：
返回一个对未识别消息处理的对象。如果实现了该方法，并且该方法没有返回nil，那么这个返回的对象就会作为新的接收对象，这个未知的消息将会被新对象处理。通过此方案，我们可以用组合来模拟多重继承的某些特性，比如我返回多个类的组合，那么就像继承多个类一样进行处理。在对外调用者来说，好像就是该对象亲自处理的这些消息。
###### 消息转发
当动态方法解析和备援接收者都没有进行处理的话，就会执行：
```objective-c
- (void)forwardInvocation:(NSInvocation *)anInvocation OBJC_SWIFT_UNAVAILABLE("");
```
这个方法也是objc里面NSObject.h里面的方法，我对People进行如下处理：
```objective-c
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"%@ can't handle by People",NSStringFromSelector([anInvocation selector]));
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    return sign;
}
```
再次运行程序，发现程序没有崩溃，只不过打印出来了“gotoschool can't handle by People”。
forwardInvocation:方法是将消息转发给其他对象。
![forwardInvocation:](https://raw.githubusercontent.com/ScottZg/MarkDownResource/master/messageforward/forwardInvocation.png)
从注释看：对一个你的对象不识别的消息进行相应，你必须重写methodSignatureForSelector:方法，该方法返回一个NSMethodSIgnature对象，该对象包含了给定选择器所标识方法的描述。主要包含返回值的信息和参数信息。
实现forwardInvocation:方法时，若发现调用的message不是由本类处理，则续调用超类的同名方法。这样所有父类均有机会处理此消息，直到NSObject。如果最后调用了NSObject的方法，那么该方法就会调用“doesNotRecognizerSelector：”，抛出异常，标明选择器最终未能得到处理。也就是上面的crash:NSInvalidArgumentException。
至此，真个消息转发全流程结束。
上一个王图：
![消息转发全流程](https://raw.githubusercontent.com/ScottZg/MarkDownResource/master/messageforward/allprocess.png)
#### 总结
接收者在每一步都有机会对未知消息进行处理，一句话：越早处理越好。如果能在第一步做完，就不进行其他操作，因为动态方法解析会将此方法缓存。如果动态方法解析不了，就放到第二步备援接收者，因为第三步还要创建完整的NSInvocation。
在完整来一遍：
Q:说一下你理解的消息转发机制？
A:
先会调用objc_msgSend方法，首先在Class中的缓存查找IMP，没有缓存则初始化缓存。如果没有找到，则向父类的Class查找。如果一直查找到根类仍旧没有实现，则执行消息转发。
1、调用resolveInstanceMethod：方法。允许用户在此时为该Class动态添加实现。如果有实现了，则调用并返回YES，重新开始objc_msgSend流程。这次对象会响应这个选择器，一般是因为它已经调用过了class_addMethod。如果仍没有实现，继续下面的动作。
2、调用forwardingTargetForSelector:方法，尝试找到一个能响应该消息的对象。如果获取到，则直接把消息转发给它，返回非nil对象。否则返回nil，继续下面的动作。注意这里不要返回self，否则会形成死循环。
3、调用methodSignatureForSelector:方法，尝试获得一个方法签名。如果获取不到，则直接调用doesNotRecognizeSelector抛出异常。如果能获取，则返回非nil;传给一个NSInvocation并传给forwardInvocation：。
4、调用forwardInvocation:方法，将第三步获取到的方法签名包装成Invocation传入，如何处理就在这里面了，并返回非nil。
5、调用doesNotRecognizeSelector：，默认的实现是抛出异常。如果第三步没能获得一个方法签名，执行该步骤 。

另附相关[杂乱代码](https://github.com/ScottZg/messageForward)(里面有动态方法解析demo)。
转载请注明来源：[http://www.cnblogs.com/zhanggui/p/7731394.html](http://www.cnblogs.com/zhanggui/p/7731394.html)
