//
//  DSS_UIDelgateProxy.m
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/17.
//

#import "DSS_UIDelegateProxy.h"

@implementation DSS_UIDelegateProxy

+ (instancetype)dss_defaultProxy {
    return [DSS_UIDelegateProxy alloc];
}

- (NSPointerArray *)dss_delegates {
    if (!_dss_delegates) {
        _dss_delegates = [NSPointerArray weakObjectsPointerArray];
    }
    return _dss_delegates;
}

- (void)dss_addUIDelegate:(id<WKUIDelegate>)dss_delegate {
    [self.dss_delegates insertPointer:(__bridge void *)dss_delegate atIndex:0];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    [self.dss_delegates compact];
    for (id delegate in self.dss_delegates) {
        if ([delegate respondsToSelector:aSelector]) {
            return YES;
        }
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    [self.dss_delegates compact];
    for (id delegate in self.dss_delegates) {
        if ([delegate respondsToSelector:aSelector]) {
            return [delegate methodSignatureForSelector:aSelector];
        }
    }
    return NULL;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [self.dss_delegates compact];
    for (id delegate in self.dss_delegates) {
        if ([delegate respondsToSelector:anInvocation.selector]) {
            [anInvocation invokeWithTarget:delegate];
            return;
        }
    }
}

@end
