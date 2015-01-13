//
//  OpenGLView.m
//  MyTest
//
//  Created by smy on 12/20/11.
//  Copyright (c) 2011 ZY.SYM. All rights reserved.
//

#import "OpenGLView20.h"

#define MAX_WIDTH SIZE.width
#define MAX_HEIGHT SIZE.height

// 放大倍数
#define TIMES 2.0
#define SIZE self.bounds.size

enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_COLOR,
};

enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV,
    TEXC
};

//#define PRINT_CALL 1

@interface OpenGLView20()

/**
 初始化YUV纹理
 */
- (void)setupYUVTexture;

/**
 创建缓冲区
 @return 成功返回TRUE 失败返回FALSE
 */
- (BOOL)createFrameAndRenderBuffer;

/**
 销毁缓冲区
 */
- (void)destoryFrameAndRenderBuffer;

//加载着色器
/**
 初始化YUV纹理
 */
- (void)loadShader;

/**
 编译着色代码
 @param shader        代码
 @param shaderType    类型
 @return 成功返回着色器 失败返回－1
 */
- (GLuint)compileShader:(NSString*)shaderCode withType:(GLenum)shaderType;

/**
 渲染
 */
- (void)render;

@end

@implementation OpenGLView20
CGPoint pinch_start_point1;
CGPoint pinch_start_point2;
//- (void)debugGlError
//{
//    GLenum r = glGetError();
//    if (r != 0)
//    {
//        printf("%d   \n", r);
//    }
//}

//-(void)setFrame:(CGRect)frame{
//    [super setFrame:frame];
//    [self initViewport];
//    viewport_width = frame.size.width*_viewScale;
//    viewport_height = frame.size.height*_viewScale;
//    _x = 0;
//    _y = 0;
//    NSLog(@"viewport width %d heigth %d",viewport_width,viewport_height);
//    glViewport(_x, _y, viewport_width, viewport_height);
//
//}

-(void)initViewport{
    _viewScale = [UIScreen mainScreen].scale;
    lastpinch_scale = 1.0;
    scale = 1.0;
    [self removeGestureRecognizer:panGestureRecognizer];
}

UIPanGestureRecognizer *panGestureRecognizer;
- (BOOL)doInit
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    //eaglLayer.opaque = YES;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                    //[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                    nil];
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    
    [self initViewport];
    
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //[self debugGlError];
    
    if(!_glContext || ![EAGLContext setCurrentContext:_glContext])
    {
        return NO;
    }
    
    [self setupYUVTexture];
    [self loadShader];
    glUseProgram(_program);
    
    GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
    GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
    GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformU, 1);
    glUniform1i(textureUniformV, 2);
    
    UIPinchGestureRecognizer *pinchGestureRecognizer=[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchGesture:)];
    [self addGestureRecognizer:pinchGestureRecognizer];
    
    
//    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
//    panGestureRecognizer.maximumNumberOfTouches = 1;
//    [self addGestureRecognizer:panGestureRecognizer];
    
    return YES;
}

CGPoint last_pan_point;
-(void)handlePanGesture:(UIPanGestureRecognizer *)pan{
    
    NSLog(@"pan start _x %d _y %d width %d height %d",_x,_y,viewport_width,viewport_height);

    CGPoint point = [pan translationInView:self];
    
    int max_width = viewport_width - SIZE.width*_viewScale;
    int max_height = viewport_height - SIZE.height*_viewScale;
    
    int tmp_x = _x + (point.x-last_pan_point.x)*_viewScale;
    int tmp_y = _y - (point.y-last_pan_point.y)*_viewScale;
    
//    NSLog(@"width %d height %d x %d y %d viewport_width %d viewport_heigth %d",max_width,max_height,_x,_y,viewport_width,viewport_height);
//    NSLog(@"videow %d videoh %d",_videoW,_videoH);
    
    switch (pan.state) {
        case UIGestureRecognizerStateChanged:
                _x = tmp_x;
                _y = tmp_y;
            
            last_pan_point = point;
            break;
         case UIGestureRecognizerStateEnded:
            last_pan_point.x = 0.0;
            last_pan_point.y = 0.0;
            break;
        default:
            break;
    }
    
    if (_x>0) {
        _x = 0;
    }
    if (_y>0) {
        _y = 0;
    }
    
    if (_x<-max_width) {
        _x = -max_width;
    }
    
    if (_y<-max_height) {
        _y = -max_height;
    }
    
    NSLog(@"pan _x %d _y %d width %d height %d",_x,_y,viewport_width,viewport_height);
    [self render];
}

CGFloat scale = 1.0;
-(void)didPinchGesture:(UIPinchGestureRecognizer *)pinch
{
    int touchCount = (int)pinch.numberOfTouches;
    if (touchCount == 2) {
        
        CGPoint p1,p2;
        switch (pinch.state) {
            case UIGestureRecognizerStateBegan:
//                scale = scale*lastpinch_scale;
                break;
            case UIGestureRecognizerStateChanged:
                lastpinch_scale = pinch.scale;
                break;
            default:
                break;
        }
        
        p1 = [pinch locationOfTouch:0 inView:self];
        p2 = [pinch locationOfTouch:1 inView:self];
        
        CGFloat center_x = (p1.x+p2.x)/2;
        CGFloat center_y = (p1.y+p2.y)/2;
        
        CGFloat width = SIZE.width*_viewScale*scale*pinch.scale;
        CGFloat height = SIZE.height*_viewScale*scale*pinch.scale;
       
        
//        center_x = center_x*_viewScale;
//        center_y = center_y*_viewScale;
//        NSLog(@"center x %f y %f ",center_x,center_y);
//        //新中心与定点距离
//        CGFloat xMid = center_x - _x;
//        CGFloat yMid = SIZE.width - center_y-_y;
//        NSLog(@"xmid %f ymid %f",xMid,yMid);
//        viewport_width = width;
//        viewport_height = height;
//        _x =  center_x - xMid*pinch.scale/lastpinch_scale;
//        _y =  (SIZE.width-center_y)-(yMid*pinch.scale/lastpinch_scale);
        
//        NSLog(@"width %d height %d _x %d _y %d",viewport_width,viewport_height,_x,_y);
        
        if (width<(MAX_WIDTH*_viewScale*TIMES) &&height<(MAX_HEIGHT*_viewScale*TIMES)) {
            viewport_width = width;
            viewport_height = height;
            
            int x = center_x*(1.0-scale*pinch.scale)*1.1;
            int y = center_y*(1.0-scale*pinch.scale)*1.1;
            
            _x = x;
            _y = y;
            
        }
        
//        NSLog(@"center_x %f center_y %f x %d y %d scale %f",center_x,center_y,_x,_y,pinch.scale/lastpinch_scale);
//        NSLog(@"scale %f last scale %f",pinch.scale,lastpinch_scale);
        
        [self render];
        NSLog(@"pinch _x %d _y %d width %d height %d",_x,_y,viewport_width,viewport_height);

    }
    
    if(pinch.state == UIGestureRecognizerStateEnded){
        scale = scale*lastpinch_scale;
        if (scale>1.0) {
            
            [self removeGestureRecognizer:panGestureRecognizer];
            NSLog(@"remove pan gesture");
            
            panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
            panGestureRecognizer.maximumNumberOfTouches = 1;
            
            NSLog(@"scale(%f) > 1.0 ",scale);
            if (![self.gestureRecognizers containsObject:panGestureRecognizer]) {
                NSLog(@"add gesture");
                [self addGestureRecognizer:panGestureRecognizer];
            }
            
        }else{
            NSLog(@"scale %f",scale);
            [self removeGestureRecognizer:panGestureRecognizer];
            NSLog(@"remove pan gesture");
            
        }
    }
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        if (![self doInit])
        {
            self = nil;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        if (![self doInit])
        {
            self = nil;
        }
    }
    return self;
}

- (void)layoutSubviews
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        @synchronized(self)
        {
            [EAGLContext setCurrentContext:_glContext];
            [self destoryFrameAndRenderBuffer];
            [self createFrameAndRenderBuffer];
        }
        
        NSLog(@"layoutSubviews");
        
        viewport_width = self.bounds.size.width*_viewScale;
        viewport_height = self.bounds.size.height*_viewScale;
        
        _x = 0;
        _y = 0;
        
        [self initViewport];
        glViewport(_x, _y, viewport_width, viewport_height);

    });
}

- (void)setupYUVTexture
{
    if (_textureYUV[TEXY])
    {
        glDeleteTextures(3, _textureYUV);
    }
    glGenTextures(3, _textureYUV);
    if (!_textureYUV[TEXY] || !_textureYUV[TEXU] || !_textureYUV[TEXV])
    {
        NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}


- (void)render
{
    [EAGLContext setCurrentContext:_glContext];
    
//    NSLog(@"viewport_width %d viewport_height %d x %d y %d",viewport_width,viewport_height,_x,_y);
    
    if (viewport_width>=SIZE.width*_viewScale||viewport_height>=SIZE.height*_viewScale) {
        glViewport(_x, _y, viewport_width, viewport_height);
    }else{
        
        glViewport(0, 0, SIZE.width*_viewScale, SIZE.height*_viewScale);
        scale = 1.0;
    }
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat coordVertices[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    
    // Update attribute values
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    
    
    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 设置openGL
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)createFrameAndRenderBuffer
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    
    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    return YES;
}

- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}

#define FSH @"varying lowp vec2 TexCoordOut;\
\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
\
void main(void)\
{\
mediump vec3 yuv;\
lowp vec3 rgb;\
\
yuv.x = texture2D(SamplerY, TexCoordOut).r;\
yuv.y = texture2D(SamplerU, TexCoordOut).r - 0.5;\
yuv.z = texture2D(SamplerV, TexCoordOut).r - 0.5;\
\
rgb = mat3( 1,       1,         1,\
0,       -0.39465,  2.03211,\
1.13983, -0.58060,  0) * yuv;\
\
gl_FragColor = vec4(rgb, 1);\
\
}"

#define VSH @"attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
\
void main(void)\
{\
gl_Position = position;\
TexCoordOut = TexCoordIn;\
}"

/**
 加载着色器
 */
- (void)loadShader
{
    /**
     1
     */
    GLuint vertexShader = [self compileShader:VSH withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:FSH withType:GL_FRAGMENT_SHADER];
    
    /**
     2
     */
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
    /**
     绑定需要在link之前
     */
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "TexCoordIn");
    
    glLinkProgram(_program);
    
    /**
     3
     */
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
        //exit(1);
    }
    
    if (vertexShader)
        glDeleteShader(vertexShader);
    if (fragmentShader)
        glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    
   	/**
     1
     */
    if (!shaderString) {
        //NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    else
    {
        //NSLog(@"shader code-->%@", shaderString);
    }
    
    /**
     2
     */
    GLuint shaderHandle = glCreateShader(shaderType);
    
    /**
     3
     */
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    /**
     4
     */
    glCompileShader(shaderHandle);
    
    /**
     5
     */
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

#pragma mark - 接口
- (void)displayYUV420pData:(char*)imageBufferY imageBufferU:(char*)imageBufferU imageBufferV:(char*)imageBufferV width:(NSInteger)w height:(NSInteger)h
{
    @synchronized(self)
    {
        if (w != _videoW || h != _videoH)
        {
            [self setVideoSize:w height:h];
        }
        
        [EAGLContext setCurrentContext:_glContext];
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RED_EXT, GL_UNSIGNED_BYTE, imageBufferY);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w/2, h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, imageBufferU);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w/2, h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, imageBufferV);
        
        [self render];
    }
    
}

- (void)setVideoSize:(GLuint)width height:(GLuint)height
{
    _videoW = width;
    _videoH = height;
    
//    viewport_width  = _videoW*_viewScale;
//    viewport_height = _videoH*_viewScale;
    
    void *blackData = malloc(width * height * 1.5);
    if(blackData)
        //bzero(blackData, width * height * 1.5);
        memset(blackData, 0x0, width * height * 1.5);
    
    [EAGLContext setCurrentContext:_glContext];
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
    
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height * 5 / 4);
    free(blackData);
}


- (void)clearFrame
{
    if ([self window])
    {
        [EAGLContext setCurrentContext:_glContext];
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    [self destoryFrameAndRenderBuffer];
    [self createFrameAndRenderBuffer];
}

@end
