#import "IPARConstraintExtension.h"

@implementation UIView (extension)
- (void)top:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)top leading:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)leading bottom:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)bottom trailing:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)trailing padding:(UIEdgeInsets)insets {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (top) {
        [self.topAnchor constraintEqualToAnchor:top constant:insets.top].active = YES;
    }
    
    if (leading) {
        [self.leadingAnchor constraintEqualToAnchor:leading constant:insets.left].active = YES;
    }
    
    if (trailing) {
        [self.trailingAnchor constraintEqualToAnchor:trailing constant:insets.right].active = YES;
    }
    
    if (bottom) {
        [self.bottomAnchor constraintEqualToAnchor:bottom constant:insets.bottom].active = YES;
    }
    
}

- (void)top:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)top padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (top) {
        [self.topAnchor constraintEqualToAnchor:top constant:size].active = YES;
    }
}

- (void)leading:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)leading padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (leading) {
        [self.leadingAnchor constraintEqualToAnchor:leading constant:size].active = YES;
    }
}

- (void)trailing:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)trailing padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (trailing) {
        [self.trailingAnchor constraintEqualToAnchor:trailing constant:size].active = YES;
    }
}

- (void)bottom:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)bottom padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (bottom) {
        [self.bottomAnchor constraintEqualToAnchor:bottom constant:size].active = YES;
    }
}

- (void)size:(CGSize)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (size.width != 0) {
        [self.widthAnchor constraintEqualToConstant:size.width].active = YES;
    }
    
    if (size.height != 0) {
        [self.heightAnchor constraintEqualToConstant:size.height].active = YES;
    }
    
}

- (void)width:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.widthAnchor constraintEqualToConstant:size].active = YES;
}

- (void)height:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.heightAnchor constraintEqualToConstant:size].active = YES;
}

- (void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [[self centerXAnchor] constraintEqualToAnchor:centerX].active = true;
    [[self centerYAnchor] constraintEqualToAnchor:centerY].active = true;
}

- (void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [[self centerXAnchor] constraintEqualToAnchor:centerX].active = true;
}

- (void)y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [[self centerYAnchor] constraintEqualToAnchor:centerY].active = true;
}

- (void)x:(nullable NSLayoutAnchor <NSLayoutXAxisAnchor *> *)centerX padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [[self centerXAnchor] constraintEqualToAnchor:centerX constant:size].active = true;
}

- (void)y:(nullable NSLayoutAnchor <NSLayoutYAxisAnchor *> *)centerY padding:(CGFloat)size {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [[self centerYAnchor] constraintEqualToAnchor:centerY constant:size].active = true;
}

- (void)fill {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor].active = YES;
    [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor].active = YES;
    [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:self.superview.bottomAnchor].active = YES;
    
}
@end