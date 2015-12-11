//
//  StepSlider.m
//  StepSlider
//
//  Created by Nick on 10/15/15.
//  Copyright © 2015 spromicky. All rights reserved.
//

#import "StepSlider.h"

#define GENERATE_SETTER(PROPERTY, TYPE, SETTER, UPDATER) \
- (void)SETTER:(TYPE)PROPERTY { \
    if (_##PROPERTY != PROPERTY) { \
        _##PROPERTY = PROPERTY; \
        UPDATER \
        [self setNeedsLayout]; \
    } \
}

static NSString * const kTrackAnimation = @"kTrackAnimation";

typedef void (^withoutAnimationBlock)(void);
void withoutCAAnimation(withoutAnimationBlock code)
{
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    code();
    [CATransaction commit];
}

@interface StepSlider ()
{
    CAShapeLayer *_trackLayer;
    CAShapeLayer *_sliderCircleLayer;
    CAShapeLayer *_sliderCircleLayer2;
    NSMutableArray <CAShapeLayer *> *_trackCirclesArray;
    NSMutableArray <CATextLayer *>  *_trackLabelsArray;
    
    BOOL animateLayouts;
    
    CGFloat maxRadius;
    CGFloat diff;
    
    CGPoint startTouchPosition;
    CGPoint startSliderPosition;
    
    CGPoint startTouchPosition2;
    CGPoint startSliderPosition2;
    
    NSInteger trakcingIndex;
}

@end

@implementation StepSlider

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self generalSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self generalSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addLayers];
    }
    return self;
}

- (void)addLayers
{
    _trackCirclesArray = [[NSMutableArray alloc] init];
    _trackLabelsArray  = [[NSMutableArray alloc] init];
    
    _trackLayer = [CAShapeLayer layer];
    _sliderCircleLayer = [CAShapeLayer layer];
    _sliderCircleLayer2 = [CAShapeLayer layer];
    
    [self.layer addSublayer:_sliderCircleLayer];
    [self.layer addSublayer:_sliderCircleLayer2];
    [self.layer addSublayer:_trackLayer];
}

- (void)generalSetup
{
    [self addLayers];
    
    _maxCount           = 4;
    _index              = 2;
    _trackHeight        = 4.f;
    _trackCircleRadius  = 5.f;
    _sliderCircleRadius = 12.5f;
    _trackColor         = [UIColor colorWithWhite:0.41f alpha:1.f];
    _sliderCircleColor  = [UIColor whiteColor];
    _doubleTracker      = NO;
    
    
    [self setNeedsLayout];
}

- (void)layoutLayersAnimated:(BOOL)animated
{
    CGRect contentFrame = CGRectMake(maxRadius, 0.f, self.bounds.size.width - 2 * maxRadius, self.bounds.size.height - 50);
    
    CGFloat stepWidth       = contentFrame.size.width / (self.maxCount - 1);
    CGFloat circleFrameSide = self.trackCircleRadius * 2.f;
    CGFloat sliderDiameter  = self.sliderCircleRadius * 2.f;
    CGFloat sliderFrameSide = fmaxf(self.sliderCircleRadius * 2.f, 44.f);
    CGRect  sliderDrawRect  = CGRectMake((sliderFrameSide - sliderDiameter) / 2.f, (sliderFrameSide - sliderDiameter) / 2.f, sliderDiameter, sliderDiameter);
    
    CGPoint oldPosition = _sliderCircleLayer.position;
    CGPoint oldPosition2 = _sliderCircleLayer2.position;
    CGPathRef oldPath   = _trackLayer.path;
    
    if (!animated) {
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    }
    
    _sliderCircleLayer.frame     = CGRectMake(0.f, 0.f, sliderFrameSide, sliderFrameSide);
    _sliderCircleLayer.path      = [UIBezierPath bezierPathWithRoundedRect:sliderDrawRect cornerRadius:sliderFrameSide / 2].CGPath;
    _sliderCircleLayer.fillColor = [self.sliderCircleColor CGColor];
    _sliderCircleLayer.position  = CGPointMake(contentFrame.origin.x + stepWidth * self.index , (contentFrame.size.height ) / 2.f);
    
    
    
    _sliderCircleLayer2.frame     = CGRectMake(0.f, 0.f, sliderFrameSide, sliderFrameSide);
    _sliderCircleLayer2.path     = [UIBezierPath bezierPathWithRoundedRect:sliderDrawRect cornerRadius:sliderFrameSide / 2].CGPath;
    _sliderCircleLayer2.fillColor = [self.sliderCircleColor CGColor];
    _sliderCircleLayer2.position  = CGPointMake(contentFrame.origin.x + stepWidth * self.indexMin, (contentFrame.size.height ) / 2.f);
    
    if (animated) {
        CABasicAnimation *basicSliderAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        basicSliderAnimation.duration = [CATransaction animationDuration];
        basicSliderAnimation.fromValue = [NSValue valueWithCGPoint:(oldPosition)];
        [_sliderCircleLayer addAnimation:basicSliderAnimation forKey:@"position"];
        
        
        CABasicAnimation *basicSliderAnimation2 = [CABasicAnimation animationWithKeyPath:@"position"];
        basicSliderAnimation2.duration = [CATransaction animationDuration];
        basicSliderAnimation2.fromValue = [NSValue valueWithCGPoint:(oldPosition2)];
        [_sliderCircleLayer2 addAnimation:basicSliderAnimation2 forKey:@"position"];
        
    }
    
    _trackLayer.frame = CGRectMake(contentFrame.origin.x,
                                   (contentFrame.size.height - self.trackHeight) / 2.f,
                                   contentFrame.size.width,
                                   self.trackHeight);
    _trackLayer.path            = [self fillingPath];
    _trackLayer.backgroundColor = [self.trackColor CGColor];
    _trackLayer.fillColor       = [self.tintColor CGColor];
    
    if (animated) {
        CABasicAnimation *basicTrackAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        basicTrackAnimation.duration = [CATransaction animationDuration];
        basicTrackAnimation.fromValue = (__bridge id _Nullable)(oldPath);
        [_trackLayer addAnimation:basicTrackAnimation forKey:@"path"];
    }

    
    if (_trackCirclesArray.count > self.maxCount) {
        
        for (NSUInteger i = self.maxCount; i < _trackCirclesArray.count; i++) {
            [_trackCirclesArray[i] removeFromSuperlayer];
        }
        
        _trackCirclesArray = [[_trackCirclesArray subarrayWithRange:NSMakeRange(0, self.maxCount)] mutableCopy];
    }
    
    if (_trackLabelsArray.count > self.maxCount) {
        
        for (NSUInteger i = self.maxCount; i < _trackCirclesArray.count; i++) {
            [_trackLabelsArray[i] removeFromSuperlayer];
        }
        
        _trackLabelsArray = [[_trackLabelsArray subarrayWithRange:NSMakeRange(0, self.maxCount)] mutableCopy];
    }
    
    for (NSUInteger i = 0; i < self.maxCount; i++) {
        CAShapeLayer *trackCircle;
        CATextLayer  *trackLabel;
        
        if (i < _trackCirclesArray.count) {
            trackCircle = _trackCirclesArray[i];
            trackLabel = _trackLabelsArray[i];
        } else {
            trackCircle       = [CAShapeLayer layer];
            trackLabel        = [self textLayerWithText:[NSString stringWithFormat:@"%ld",i]];//[CATextLayer layer];

            [self.layer addSublayer:trackCircle];
            [self.layer addSublayer:trackLabel];
            
            [_trackCirclesArray addObject:trackCircle];
            [_trackLabelsArray addObject:trackLabel];
        }
        
        trackCircle.frame    = CGRectMake(0.f, 0.f, circleFrameSide, circleFrameSide);
        trackCircle.path     = [UIBezierPath bezierPathWithRoundedRect:trackCircle.bounds cornerRadius:circleFrameSide / 2].CGPath;
        trackCircle.position = CGPointMake(contentFrame.origin.x + stepWidth * i, contentFrame.size.height / 2.f);
        
        
        trackLabel.frame     = CGRectMake(0.f,0.f, circleFrameSide*2, circleFrameSide*2);
        trackLabel.position  = CGPointMake(contentFrame.origin.x + stepWidth * i, contentFrame.size.height + 20);
//        trackLabel.string    = [NSString stringWithFormat:@"%ld",i];
        
        if (animated) {
            CGColorRef newColor = [self trackCircleColor:trackCircle];
            CGColorRef oldColor = trackCircle.fillColor;
            
            if (!CGColorEqualToColor(newColor, trackCircle.fillColor)) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([CATransaction animationDuration] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    trackCircle.fillColor = newColor;
                    CABasicAnimation *basicTrackCircleAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
                    basicTrackCircleAnimation.duration = [CATransaction animationDuration] / 2.f;
                    basicTrackCircleAnimation.fromValue = (__bridge id _Nullable)(oldColor);
                    [trackCircle addAnimation:basicTrackCircleAnimation forKey:@"fillColor"];
                });
            }
        } else {
            trackCircle.fillColor = [self trackCircleColor:trackCircle];
        }
        
    }
    
    if (!animated) {
        [CATransaction commit];
    }
    
    [_sliderCircleLayer removeFromSuperlayer];
    [_sliderCircleLayer2 removeFromSuperlayer];
    
    [self.layer addSublayer:_sliderCircleLayer];
    [self.layer addSublayer:_sliderCircleLayer2];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self layoutLayersAnimated:animateLayouts];
    animateLayouts = NO;
}

- (CATextLayer *)textLayerWithText:(NSString*)text{
    //create a text layer
    CATextLayer *textLayer = [CATextLayer layer];
//    textLayer.frame = self.labelView.bounds;
//    [self.labelView.layer addSublayer:textLayer];
    
    //set text attributes
    textLayer.foregroundColor = [UIColor blackColor].CGColor;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.wrapped = YES;
    
    //choose a font
    UIFont *font = [UIFont systemFontOfSize:15];
    
    //set layer font
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    textLayer.font = fontRef;
    textLayer.fontSize = font.pointSize;
    CGFontRelease(fontRef);
    
    
    //set layer text
    textLayer.string = text;
    return textLayer;
}

#pragma mark - Helpers
/*
 Calculate distance from trackCircle center to point where circle cross track line.
 */
- (void)updateDiff
{
    diff = sqrtf(fmaxf(0.f, powf(self.trackCircleRadius, 2.f) - pow(self.trackHeight / 2.f, 2.f)));
}

- (void)updateMaxRadius
{
    maxRadius = fmaxf(self.trackCircleRadius, self.sliderCircleRadius);
}

- (void)updateIndex
{
    if (_index > (_maxCount - 1)) {
        _index = _maxCount - 1;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (CGPathRef)fillingPath
{
    CGRect fillRect     = _trackLayer.bounds;
    fillRect.size.width = self.sliderRangeLength;//self.sliderPosition;
    fillRect.origin.x   = _sliderCircleLayer2.position.x;
    
    return [UIBezierPath bezierPathWithRect:fillRect].CGPath;
}

- (CGFloat)sliderPosition
{
    return _sliderCircleLayer.position.x - maxRadius;
}

- (CGFloat)sliderPosition2
{
    return _sliderCircleLayer2.position.x - maxRadius;
}

- (CGFloat)sliderRangeLength
{
    return _sliderCircleLayer.position.x - _sliderCircleLayer2.position.x;
}

- (CGFloat)trackCirclePosition:(CAShapeLayer *)trackCircle
{
    return trackCircle.position.x - maxRadius;
}

- (CGFloat)indexCalculate
{
    return self.sliderPosition / (_trackLayer.bounds.size.width / (self.maxCount - 1));
}

- (CGColorRef)trackCircleColor:(CAShapeLayer *)trackCircle
{
    return self.sliderPosition + diff >= [self trackCirclePosition:trackCircle] ? self.tintColor.CGColor : self.trackColor.CGColor;
}

#pragma mark - Touches

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    trakcingIndex = 0;
    startTouchPosition = [touch locationInView:self];
    startSliderPosition = _sliderCircleLayer.position;
    
    startTouchPosition2 = [touch locationInView:self];
    startSliderPosition2 = _sliderCircleLayer2.position;
    
    if (CGRectContainsPoint(_sliderCircleLayer.frame, startTouchPosition)) {
        trakcingIndex  = 1;
        return YES;
    }else if(CGRectContainsPoint(_sliderCircleLayer2.frame, startSliderPosition2)){
        trakcingIndex = 2;
        return YES;
    }
    
    return  NO;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGFloat position = startSliderPosition.x - (startTouchPosition.x - [touch locationInView:self].x);
    CGFloat limitedPosition = fminf(fmaxf(maxRadius, position), self.bounds.size.width - maxRadius);
    
    CGFloat position2 = startSliderPosition2.x - (startTouchPosition2.x - [touch locationInView:self].x);
    CGFloat limitedPosition2 = fminf(fmaxf(maxRadius, position2), self.bounds.size.width - maxRadius);
    
    withoutCAAnimation(^{
        if (trakcingIndex == 1) {
            _sliderCircleLayer.position = CGPointMake(limitedPosition, _sliderCircleLayer.position.y);
        }else {
            _sliderCircleLayer2.position = CGPointMake(limitedPosition2, _sliderCircleLayer2.position.y);
        }
        _trackLayer.path = [self fillingPath];
        
        NSUInteger index = (self.sliderPosition + diff) / (_trackLayer.bounds.size.width / (self.maxCount - 1));
        NSUInteger index2 = (self.sliderPosition2 + diff) / (_trackLayer.bounds.size.width / (self.maxCount - 1));
        if (_index != index && trakcingIndex == 1) {
            for (CAShapeLayer *trackCircle in _trackCirclesArray) {
                trackCircle.fillColor = [self trackCircleColor:trackCircle];
            }
            _index = index;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        
        if (_indexMin != index2 && trakcingIndex == 2) {
            for (CAShapeLayer *trackCircle in _trackCirclesArray) {
                trackCircle.fillColor = [self trackCircleColor:trackCircle];
            }
            _indexMin = index2;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    });
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSUInteger oldIndex = _index;
    _index = roundf([self indexCalculate]);
    
    if (oldIndex != _index) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    animateLayouts = YES;
    [self setNeedsLayout];
}

#pragma mark - Access methods

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    [self setNeedsLayout];
}

GENERATE_SETTER(index, NSUInteger, setIndex, [self sendActionsForControlEvents:UIControlEventValueChanged];);
GENERATE_SETTER(maxCount, NSUInteger, setMaxCount, [self updateIndex];);
GENERATE_SETTER(trackHeight, CGFloat, setTrackHeight, [self updateDiff];);
GENERATE_SETTER(trackCircleRadius, CGFloat, setTrackCircleRadius, [self updateDiff]; [self updateMaxRadius];);
GENERATE_SETTER(sliderCircleRadius, CGFloat, setSliderCircleRadius, [self updateMaxRadius];);
GENERATE_SETTER(trackColor, UIColor*, setTrackColor, );
GENERATE_SETTER(sliderCircleColor, UIColor*, setSliderCircleColor, );

@end
