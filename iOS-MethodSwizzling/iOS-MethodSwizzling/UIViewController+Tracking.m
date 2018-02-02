//
//  UIViewController+Tracking.m
//  iOS-MethodSwizzling
//
//  Created by zhangzhiliang on 2018/2/2.
//  Copyright © 2018年 zhangzhiliang. All rights reserved.
//

#import "UIViewController+Tracking.h"
#import <objc/runtime.h>

@implementation UIViewController (Tracking)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //先取得两个方法的SEL
        SEL originSEL = @selector(viewWillAppear:);
        SEL swizzledSEL = @selector(BG_viewWillAppear:);
        
        //通过两个SEL 获得对应的方法
        Method originMethod = class_getInstanceMethod([self class], originSEL);
        Method swizzledMethod = class_getInstanceMethod([self class], swizzledSEL);
        
        BOOL didAddMethod = class_addMethod([self class], originSEL, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        
        // 如果是类方法的话，使用下面的代码
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        if (didAddMethod) {
            class_addMethod([self class], swizzledSEL, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
        } else {
            method_exchangeImplementations(originMethod, swizzledMethod);
        }
    });
    
}

- (void)BG_viewWillAppear:(BOOL)animated {
    
    [self.view addSubview:self.backgroundView];
    [self BG_viewWillAppear:animated];
}

/**
 上面的代码中， class_addMethod 方法只是为了作一个判断，检测 self 是否已经有了 originalSelector 方法。如果没有这个方法，就会添加一个 SEL 为 originalSelector 的方法，并将 swizzledSelector 的实现赋给它。接着会进入 if (didAddMethod) 分支。如果 self 中已经有了这个方法，那么 class_addMethod 方法就会失败，直接进入 else 分支交换 IMP。

 一个容易让人疑惑的点是：在 xxx_viewWillAppear: 的方法内部又调用了 [self xxx_viewWillAppear:animated]; 这是因为两个方法的 IMP 已经被调换，这里其实是调用原来的 viewWillAppear: 方法的实现。
 
 在这个例子中，虽然可以不用 Method Swizzling 方法，直接在 category 中重写 viewWillAppear: 方法也能达到目的。但是前者可以控制执行的顺序，以及可以用在非系统类中。而 category 中的方法是直接覆盖了原来的方法的，调用顺序是既定的，且只能用在系统类中。
 
 (这里有一个值得注意的地方，就是如果在 self 中没有实现这个方法，而父类中有实现，那么在 if (didAddMethod) 分支中，其实是将父类的 originalSelector 的实现赋给 swizzledSelector，也就是说会调用父类的方法。
 　　如果父类也没有实现，消息转发也找不到这个方法，那么才是调用之前添加进入 class 的 originalSelector。结果就是 originalSelector 和 swizzledSelector 的实现均为 xxx_viewWillAppear: 。)
 
 注意事项
 +load
 一般来说，Method Swizzling 应该只在 +load 方法中完成。 在 Objective-C 的运行时中，每个类都会自动调用两个方法。+load 是在一个类被初始装载时调用的，+initialize 是在应用第一次调用该类的类方法或实例方法前调用的。在应用程序的一开始就调用执行，是最安全的，避免了很多并发、异常等问题。如果在 +initialize 初始化方法中调用，runtime 很可能死于一个诡异的状态。
 
 dispatch_once
 由于 swizzling 改变了全局的状态，所以需要确保在运行时，我们采用的预防措施是可用的。原子操作就是这样一个用于确保代码只会被执行一次的预防措施，就算是在不同的线程中也能确保代码只执行一次。Grand Central Dispatch 的 dispatch_once 满足了这些需求，所以，Method Swizzling 应该在 dispatch_once 中完成。
 
 调用原始实现
 由于很多内部实现对我们来说是不可见的，使用方法交换可能会导致代码结构的改变，而对程序产生其他影响，因此应该调用原始实现来保证内部操作的正常运行。
 
 注意命名
 这也是方法命名的规则，给需要转换的方法加前缀，以区别于原生方法。
 
 类簇
 Method Swizzling对NSArray、NSMutableArray、NSDictionary、NSMutableDictionary 等这些类簇是不起作用的。因为这些类簇类，其实是一种抽象工厂的设计模式。抽象工厂内部有很多其它继承自当前类簇的子类，抽象工厂类会根据不同情况，创建不同的抽象对象来进行使用，真正执行操作的并不是类簇本身。
 */

- (UIImageView *)backgroundView {
    UIImageView *backgroundView = objc_getAssociatedObject(self, @selector(backgroundView));
    if (!backgroundView) {
        backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back.jpeg"]];
        backgroundView.contentMode = UIViewContentModeScaleAspectFill;
        backgroundView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return backgroundView;
}

- (void)setBackgroundView:(UIImageView *)backgroundView {
    
    objc_setAssociatedObject(self, @selector(backgroundView), backgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
