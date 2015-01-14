//
//  OpenGLView20.h
//  MyTest
//
//  Created by smy  on 12/20/11.
//  Copyright (c) 2011 ZY.SYM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#include <sys/time.h>

@interface OpenGLView20 : UIView
{
    /**
     OpenGL绘图上下文
     */
    EAGLContext             *_glContext;
    
    /**
     帧缓冲区
     */
    GLuint                  _framebuffer;
    
    /**
     渲染缓冲区
     */
    GLuint                  _renderBuffer;
    
    /**
     着色器句柄
     */
    GLuint                  _program;
    
    /**
     YUV纹理数组
     */
    GLuint                  _textureYUV[3];
    
    /**
     视频宽度
     */
    GLuint                  _videoW;
    
    /**
     视频高度
     */
    GLuint                  _videoH;
    
    //viewport x y;
    GLint                  _x;
    GLint                  _y;
    
    GLsizei                 viewport_width;
    GLsizei                 viewport_height;
    
    //最后的scale大小
    CGFloat                 lastpinch_scale;
    
    //    设备分辨率倍数
    GLsizei                 _viewScale;
	   
    //void                    *_pYuvData;
    
#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}
#pragma mark - 接口
- (void)displayYUV420pData:(char*)imageBufferY imageBufferU:(char*)imageBufferU imageBufferV:(char*)imageBufferV width:(NSInteger)w height:(NSInteger)h;

- (void)setVideoSize:(GLuint)width height:(GLuint)height;

-(void)didPinchGesture:(UIPinchGestureRecognizer *)pinch;

//设置最大或最小缩放
-(void)setScaleToLargest:(BOOL)is FromCenterPoint:(CGPoint)center;

/** 
 清除画面
 */
- (void)clearFrame;

@end
