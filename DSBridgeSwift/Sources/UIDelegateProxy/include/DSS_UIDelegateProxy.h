//
//  DSS_UIDelgateProxy.h
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/17.
//

#import <Foundation/Foundation.h>
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface DSS_UIDelegateProxy : NSProxy<WKUIDelegate>

@property (nonatomic, strong) NSPointerArray *dss_delegates;

+ (instancetype)dss_defaultProxy;

- (void)dss_addUIDelegate:(id<WKUIDelegate>)dss_delegate;
@end

NS_ASSUME_NONNULL_END
