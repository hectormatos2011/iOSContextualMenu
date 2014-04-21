//
//  UIImage+ImageWithUIView.h
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageWithUIView)

+ (UIImage *)imageWithUIView:(UIView *)view;

- (UIImage *)applyLightEffect;
- (UIImage *)applyExtraLightEffect;
- (UIImage *)applyDarkEffect;
- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor;
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;


@end
