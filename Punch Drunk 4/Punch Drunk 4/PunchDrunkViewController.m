//
//  PunchDrunkViewController.m
//  Punch Drunk 4
//
//  Created by Gurmit Singh on 10/11/2013.
//  Copyright (c) 2013 RuleOnSix. All rights reserved.
//
#import "capsule.h"
#import "PunchDrunkViewController.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
float oldX, oldY, screenWidth, screenHeight, X, Y;
BOOL dragging;
float target;
// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX=0,
    UNIFORM_NORMAL_MATRIX2=1,
    UNIFORM_MODELVIEWPROJECTION_MATRIX3=2,
    UNIFORM_NORMAL_MATRIX3=3,
    UNIFORM_TARGET=4,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_UV,
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface PunchDrunkViewController () {
    GLuint _program, _program2;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    GLKMatrix4 _modelViewProjectionMatrix2;
    GLKMatrix3 _normalMatrix2;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer[2];
    
    GLuint _vertexArray2;
    GLuint _vertexBuffer2;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) GLKBaseEffect *effect1;
@property (strong, nonatomic) GLKBaseEffect *effect2;
- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)loadShaders2;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation PunchDrunkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    screenWidth = view.bounds.size.width;
    screenHeight = view.bounds.size.height;
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    //[self loadShaders];
    
    [self loadShaders2];
    self.effect2 = [[GLKBaseEffect alloc] init];
    self.effect2.light1.enabled = GL_TRUE;
    self.effect2.light1.diffuseColor = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    
    self.effect1 = [[GLKBaseEffect alloc] init];
    self.effect1.light0.enabled = GL_TRUE;
    self.effect1.light0.diffuseColor = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light2.enabled = GL_TRUE;
    self.effect.light2.diffuseColor = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(2, &_vertexBuffer[0]);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    //
     glGenBuffers(2, &_vertexBuffer2);
    glBindVertexArrayOES(_vertexArray2);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Capsule_vertex), Capsule_vertex, GL_STATIC_DRAW);
    
//    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
//    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 16, BUFFER_OFFSET(0));
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(8));
//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(20));
    //
    glEnableVertexAttribArray(7);
    glVertexAttribPointer(7, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(20));
    glEnableVertexAttribArray(8);
    glVertexAttribPointer(8, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(8));
    //  glEnableVertexAttribArray(GLKVertexAttribColor);
    // glVertexAttribPointer(GLKVertexAttribColor, 2, GL_FLOAT, GL_FALSE, 64, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(5);
    glVertexAttribPointer(5, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
   // glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(2, &_vertexBuffer[0]);
    glDeleteVertexArraysOES(2, &_vertexArray);
    
    self.effect = nil;
    self.effect1 = nil;
    self.effect2 = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
        if (_program2) {
            glDeleteProgram(_program2);
            _program2 = 0;
    }
}
#pragma mark - touchesBegan and touchesMoved and touchesEnded


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    
   
            oldX = touchLocation.x;
    oldY = touchLocation.y;
    CGPoint touch_point = [[touches anyObject] locationInView:self.view];
    touch_point = CGPointMake(touch_point.x, 480-touch_point.y);
    
    X = 2*touch_point.x/screenWidth-1;
    Y =  2*touch_point.y/screenHeight-1;
    //NSLog(@"X = %g, Y = %g", X,Y);
    NSLog(@"screenWidth = %g, screenHeight = %g", screenWidth,screenHeight);
    NSLog(@"touch_point.x = %g, touch_point.y = %g", touch_point.x,touch_point.y);
    NSLog(@"X = %g, Y = %g", X, Y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    dragging = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    
    if ([[touch.view class] isSubclassOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)touch.view;
        
        if (dragging) {
            CGRect frame = label.frame;
            frame.origin.x = label.frame.origin.x + touchLocation.x - oldX;
            frame.origin.y =  label.frame.origin.y + touchLocation.y - oldY;
            label.frame = frame;
        }
        
    }
    
    
}
#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    self.effect1.transform.projectionMatrix=
    projectionMatrix;
    self.effect2.transform.projectionMatrix=
    projectionMatrix;
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(-0.4, 0.4, -4.0f);
    //baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 1.0f, 0.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(-0.50f, 0.2f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    GLKMatrix4  modelViewScale = GLKMatrix4MakeScale(0.25, 0.18, 0.16);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, modelViewScale);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    GLKMatrix4 modelViewMatrix2 = GLKMatrix4MakeTranslation(0.10f, -0.48f, -1.5f);
    modelViewMatrix2 = GLKMatrix4Rotate(modelViewMatrix2, _rotation, 1.0f, 0.0f, -1.0f);
    modelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix2);
    GLKMatrix4  modelViewScale2 = GLKMatrix4MakeScale(0.5, 0.48, 0.36);
    modelViewMatrix2 = GLKMatrix4Multiply(modelViewMatrix2, modelViewScale2);
    
    self.effect1.transform.modelviewMatrix =
    modelViewMatrix2; //blue cube
    
    //
    GLKMatrix4 modelViewMatrix3 = GLKMatrix4MakeTranslation(X, Y, -1.5f);
    modelViewMatrix3 = GLKMatrix4Rotate(modelViewMatrix3, _rotation, 1.0f, 0.0f, 1.0f);
    //modelViewMatrix3 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix3);
    GLKMatrix4  modelViewScale3 = GLKMatrix4MakeScale(0.25, 0.248, 0.26);
    modelViewMatrix3 = GLKMatrix4Multiply(modelViewMatrix3, modelViewScale3);
    
    self.effect2.transform.modelviewMatrix =
    modelViewMatrix3; //different coloured cube
    //
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.30f, 0.30f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    modelViewMatrix = GLKMatrix4MakeScale(.3f,.9f,.8f);
    GLKMatrix4 modelViewMatrix5 = GLKMatrix4MakeTranslation(-0.38, -0.72, -1.5f);
    _normalMatrix2 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix5), NULL);
    modelViewScale = GLKMatrix4MakeScale(0.245, 0.238, 0.31);
    modelViewMatrix5 = GLKMatrix4Rotate(modelViewMatrix5, _rotation, 1.0f, 1.0f, 0.0f);
    _modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix5);
    _modelViewProjectionMatrix2 = GLKMatrix4Multiply(_modelViewProjectionMatrix2, modelViewScale);
    target = 0;
    //
    GLKMatrix4 modelViewMatrix4 = GLKMatrix4MakeTranslation(-0.8, -1.2, -1.5f);
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix4), NULL);
    //modelViewMatrix = GLKMatrix4MakeTranslation(-0.20f, -0.30f, -1.5f);
    modelViewMatrix4 = GLKMatrix4Rotate(modelViewMatrix4, _rotation, 0.0f, 1.0f, 0.0f);
    modelViewMatrix4 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix4);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix4);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(_modelViewProjectionMatrix, modelViewScale);
    _rotation += self.timeSinceLastUpdate * 0.5f;
 
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.30f, 0.65f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
   // glBindVertexArrayOES(_vertexArray);
    [self.effect1 prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    [self.effect2 prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    // Render the object again with ES2 second
    glUseProgram(_program);
    target = 0.0;
    glBindVertexArrayOES(_vertexArray);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX2], 1, 0, _normalMatrix.m);
    glUniform1f(uniforms[UNIFORM_TARGET], target);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    //
    glUseProgram(_program);
    glBindVertexArrayOES(_vertexArray2);
    target = 1.0;
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX3], 1, 0, _modelViewProjectionMatrix2.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX3], 1, 0, _normalMatrix2.m);
    glUniform1f(uniforms[UNIFORM_TARGET], target);
     glDrawElements(GL_TRIANGLES,Capsule_polygoncount*3,GL_UNSIGNED_INT,Capsule_index);

    // Render the object again with ES2
   // glUseProgram(_program);
    
    
}
#pragma mark - second OpenGL ES 2 shaders
- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader3" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    //
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX2] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders2
{
    GLuint vertShader2, fragShader2;
    NSString *vertShaderPathname2;
    NSString *fragShaderPathname2;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname2 = [[NSBundle mainBundle] pathForResource:@"Shader2" ofType:@"vsh"];
    if (![self compileShader:&vertShader2 type:GL_VERTEX_SHADER file:vertShaderPathname2]) {
        NSLog(@"Failed to compile vertex shader2");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname2 = [[NSBundle mainBundle] pathForResource:@"Shader3" ofType:@"fsh"];
    if (![self compileShader:&fragShader2 type:GL_FRAGMENT_SHADER file:fragShaderPathname2]) {
        NSLog(@"Failed to compile fragment shader3");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader2);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader2);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, 7, "position2");
    glBindAttribLocation(_program, 8, "normal2");
    glBindAttribLocation(_program,  GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader2) {
            glDeleteShader(vertShader2);
            vertShader2 = 0;
        }
        if (fragShader2) {
            glDeleteShader(fragShader2);
            fragShader2 = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX3] = glGetUniformLocation(_program, "modelViewProjectionMatrix2");
    uniforms[UNIFORM_NORMAL_MATRIX3] = glGetUniformLocation(_program, "normalMatrix2");
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX2] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_TARGET] = glGetUniformLocation(_program, "target");
    
    // Release vertex and fragment shaders.
    if (vertShader2) {
        glDetachShader(_program, vertShader2);
        glDeleteShader(vertShader2);
    }
    if (fragShader2) {
        glDetachShader(_program, fragShader2);
        glDeleteShader(fragShader2);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
