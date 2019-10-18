/*
 Copyright (c) 2018, Muh-Tarng Lin. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ORKMyTouchAbilityMyPinchTargetGuideView.h"

@implementation ORKMyTouchAbilityMyPinchTargetGuideView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    UIBezierPath * path = [UIBezierPath bezierPath];
    // 创建起点
    
    [path moveToPoint:CGPointMake(rect.origin.x+rect.size.width/2-20, rect.origin.y+rect.size.height/2)];
    // 添加线段到终点
    [path addLineToPoint:CGPointMake(rect.origin.x+rect.size.width/2+20, rect.origin.y+rect.size.height/2)];
    
    [path moveToPoint:CGPointMake(rect.origin.x+rect.size.width/2, rect.origin.y+rect.size.height/2-20)];
    [path addLineToPoint:CGPointMake(rect.origin.x+rect.size.width/2, rect.origin.y+rect.size.height/2+20)];
    path.lineWidth = 10.f;// 设置线宽
    path.lineCapStyle = kCGLineCapSquare;// 设置线头样式
    path.lineJoinStyle = kCGLineJoinBevel;// 设置交叉样式
    [UIColor.grayColor setStroke];
    [path stroke];// 渲染
    
    
    
    /*
     UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
     
     [UIColor.redColor setFill];
     [path fill];
     
     CGFloat dashes[2] = {4.0, 4.0};
     [path setLineDash:dashes count:2 phase:0];
     [path setLineCapStyle:kCGLineCapButt];
     [path setLineWidth:4.0];
     
     //[UIColor.redColor setFill];
     [UIColor.redColor setStroke];
     [path stroke];*/
    
    
    
    /*
     let path = UIBezierPath(roundedRect: rect, cornerRadius: 0)
     path.lineWidth = lineWidth
     
     let dashes: [CGFloat] = [lineWidth, lineWidth]
     path.setLineDash(dashes, count: dashes.count, phase: 0)
     path.lineCapStyle = CGLineCap.butt
     
     lineColor.setStroke()
     
     path.stroke()
     */
}

@end
