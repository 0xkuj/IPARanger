#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IPARDialogButtonStyle) {
    IPARDialogButtonStylePrimary,      // filled accent, main action
    IPARDialogButtonStyleCancel,       // subtle filled, secondary action
    IPARDialogButtonStyleDestructive,  // red, dangerous action
};

NS_ASSUME_NONNULL_BEGIN

/// A custom, brand-styled replacement for UIAlertController.
///
/// It presents a frosted card centered on a dimmed backdrop, laid out entirely
/// with Auto Layout + a vertical stack view — so the title, message, optional
/// text field / spinner / progress bar, and buttons always stay aligned and
/// centered, even at large Dynamic Type sizes (the old alerts positioned the
/// spinner at hardcoded points, which drifted when text got bigger).
///
/// Supports iOS 14+.
@interface IPARDialog : UIViewController

+ (instancetype)dialogWithTitle:(nullable NSString *)title message:(nullable NSString *)message;

/// Shared brand palette (adapts to light/dark), so the rest of the app can match
/// the dialog styling from one source of truth.
+ (UIColor *)accentColor;
+ (UIColor *)destructiveColor;

/// Adds a rounded text field to the card. The configuration block runs once so
/// callers can set placeholder / secureTextEntry / keyboard type etc.
- (void)addTextFieldWithConfiguration:(void (^)(UITextField *textField))configuration;
@property (nonatomic, readonly, nullable) UITextField *textField;

/// Adds a button. Buttons stack horizontally when there are two short titles,
/// otherwise vertically. The handler runs after the dialog dismisses (matching
/// UIAlertController semantics). Returns the button so callers can tweak it
/// (e.g. disable it or update its title for a countdown).
- (UIButton *)addButtonWithTitle:(NSString *)title
                           style:(IPARDialogButtonStyle)style
                         handler:(nullable void (^)(void))handler;

/// Turns the card into a loading dialog: a centered spinner above the message,
/// no buttons. Dismiss it with [presenter dismissViewControllerAnimated:...].
- (void)showSpinner;

/// Turns the card into a progress dialog: a rounded progress bar with a live
/// percentage label. Update it with -setProgress:.
- (void)showProgress;
- (void)setProgress:(float)progress; // 0.0 ... 1.0

/// Presents the dialog modally on the given view controller.
- (void)presentOn:(UIViewController *)presenter;

@end

NS_ASSUME_NONNULL_END
