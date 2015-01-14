//
//  GlView.m
//  GlView
//
//  Created by jovision on 13-12-14.
//  Copyright (c) 2013年 jovision. All rights reserved.
//

#import "GlView.h"
#import "OpenGLView20.h"
#include <pthread.h>

#define MIN_LENGTH 10.0


@interface GlView (){

   pthread_mutex_t        mutex;
}

@end
@implementation GlView

CGPoint pan_start_point;
CGPoint pinch_start_point1;
CGPoint pinch_start_point2;
CGSize originSize;
CGPoint originCenter;

@synthesize _kxOpenGLView;


-(id)init:(int)decoderWidth withdecoderHeight:(int)decoderHeight withDisplayWidth:(int)width withDisplayHeight:(int)height{
    if (self=[super init]) {
        
        OpenGLView20 *openGlViewObj          = [[OpenGLView20 alloc] init];
        [openGlViewObj setVideoSize:decoderWidth height:decoderHeight];
        self._kxOpenGLView                   = openGlViewObj;
        openGlViewObj.userInteractionEnabled = FALSE;
        
        [self updateDecoderFrame:width displayFrameHeight:height];
        
        pthread_mutex_init(&mutex,NULL);
        
        [openGlViewObj release];
    }
    
    return self;

}

/**
 *  上锁
 */
-(void)lock{

    pthread_mutex_lock(&mutex);
}

/**
 *  下锁
 */
-(void)unlock{
    
    pthread_mutex_unlock(&mutex);
}

/**
 *	屏幕旋转之后更新画布
 *
 *	@param	displayFrameWidth	更新画布的高
 *	@param	displayFrameHeight	更新画布的宽
 */
-(void)updateDecoderFrame:(int)displayFrameWidth displayFrameHeight:(int)displayFrameHeight{

    [self lock];
    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    openGlViewObj.frame = CGRectMake(openGlViewObj.frame.origin.x, openGlViewObj.frame.origin.y, displayFrameWidth, displayFrameHeight);
    [self unlock];
}

-(void)decoder:(char*)imageBufferY imageBufferU:(char*)imageBufferU imageBufferV:(char*)imageBufferV decoderFrameWidth:(int)decoderFrameWidth decoderFrameHeight:(int)decoderFrameHeight {

    
//    NSLog(@"decoderFrameWidth %d decoderFrameHeight %d",decoderFrameWidth,decoderFrameHeight);
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    
    [self lock];
    
    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
    [openGlViewObj displayYUV420pData:imageBufferY imageBufferU:imageBufferU imageBufferV:imageBufferV width:decoderFrameWidth height:decoderFrameHeight];

    [self unlock];

    [pool release];
}

/**
 *  隐藏OpenGL画布
 */
-(void)hiddenWithOpenGLView{

     OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
     if (!openGlViewObj.hidden) {
        
         openGlViewObj.hidden = YES;
     }
}

/**
 *  显示OpenGL画布
 */
-(void)showWithOpenGLView{
    
    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
    if (openGlViewObj.hidden) {
        
        openGlViewObj.hidden = NO;
        
        if ([openGlViewObj superview]) {
            
            [[openGlViewObj superview] bringSubviewToFront:openGlViewObj];
        }
    }
}

/**
 *  OpenGl画布双击变大（变小）
 *
 *  @param x  居中显示的x
 *  @param y  居中显示的y
 */
-(void)setScaleToLargestWithCenterX:(float)x withCenterY:(float)y;{

    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
    [self lock];
    
    CGPoint point;
    point.x = x;
    point.y = y;
    
    [openGlViewObj setScaleToLargest:openGlViewObj.scale<=1.0 FromCenterPoint:point];
    
    [self unlock];

}

-(void)restoreGlViewFrame{

    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
    if (openGlViewObj.scale > 1.0) {
        
        [self lock];
        
        CGPoint point;
        
        [openGlViewObj setScaleToLargest:FALSE FromCenterPoint:point];
        
        [self unlock];
    }
}

/**
 *  设置GLView是否允许手势交互
 *
 *  @param enabled YES:允许
 */
-(void)setOpenGLViewUserInteractionEnabled:(BOOL)enabled{

    OpenGLView20 *openGlViewObj          = (OpenGLView20 *)self._kxOpenGLView;

    openGlViewObj.userInteractionEnabled = enabled;
}


- (void)clearVideo {

    OpenGLView20 *openGlViewObj = (OpenGLView20 *)self._kxOpenGLView;
    
    [self lock];
    [openGlViewObj clearFrame];
    [self unlock];

}

-(void)dealloc{
    
    pthread_mutex_destroy(&mutex);
    [_kxOpenGLView release];
    _kxOpenGLView  = nil;
    [super dealloc];
}

@end
