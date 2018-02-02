//
//  ViewController.m
//  iOS-MethodSwizzling
//
//  Created by zhangzhiliang on 2018/2/2.
//  Copyright © 2018年 zhangzhiliang. All rights reserved.
//

#import "ViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "UIViewController+Tracking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/**
     一些有关于Method的函数
 */
- (void)test {
    
    SEL methodSEL = NSSelectorFromString(@"methodSwizzling");
    
    //通过 SEL 获取一个方法 Method
    Method method = class_getInstanceMethod([self class], methodSEL);
    
    //通过 Method 获取该方法的实现 IMP
    IMP methodIMP = method_getImplementation(method);
    //通过 SEL 获取方法的实现 IMP
    methodIMP = class_getMethodImplementation([self class], methodSEL);
    
    //返回一个字符串，描述了方法的参数和返回类型
    const char *canshu =  method_getTypeEncoding(method);
    NSLog(@"%s", canshu);
    
    //通过SEL以及IMP给一个类添加新的方法Method，其中types就是method_getTypeEncoding的返回值
    class_addMethod([self class], methodSEL, method_getImplementation(method), method_getTypeEncoding(method));
    
    //通过给定的SEL替换同一个类中的方法的实现IMP，其中SEL是想要替换的selector名，IMP是替换后的实现
    IMP otherMethodIMP = class_replaceMethod([self class], methodSEL, method_getImplementation(method), method_getTypeEncoding(method));
    
    Method otherMethod = class_getInstanceMethod([self class], methodSEL);
    
    //交换两个方法的实现IMP
    method_exchangeImplementations(method, otherMethod);
    
    //class_replaceMethod、method_exchangeImplementations 这两个方法的不同之处在于，前者只是将方法 A 的实现替换为方法 B 的实现，而方法 B 的实现并没有改变。后者则是交换了两个方法的实现。
    
}

- (NSString *)methodSwizzling:(NSString *)name {
    NSLog(@"success");
    return name;
}

@end
