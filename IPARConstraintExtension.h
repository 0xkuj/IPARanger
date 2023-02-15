#import <UIKit/UIKit.h>

@interface UIView (extension)
-(void)top:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)top leading:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)leading bottom:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)bottom trailing:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)trailing padding:(UIEdgeInsets)insets;
-(void)top:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)top padding:(CGFloat)size;
-(void)leading:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)leading padding:(CGFloat)size;
-(void)trailing:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)trailing padding:(CGFloat)size;
-(void)bottom:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)bottom padding:(CGFloat)size;
-(void)size:(CGSize)size;
-(void)width:(CGFloat)size;
-(void)height:(CGFloat)size;
-(void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX;
-(void)y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY;
-(void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX padding:(CGFloat)size;
-(void)y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY padding:(CGFloat)size;
-(void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY;
-(void)fill;
@end