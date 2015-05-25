//
//  KDETextView.m
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/23/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#include <OpenGL/gl.h>
#include <fontconfig/fontconfig.h>

#import "KDETextView.h"
#import "KDETextViewFont.h"
#import "KDETextViewBuffer.h"

#include "freetype-gl.h"
#include "font-manager.h"
#include "vertex-buffer.h"
#include "text-buffer.h"
#include "markup.h"
#include "shader.h"
#include "mat4.h"
#include "edtaa3func.h"

#include "VKConsts.h"



unsigned char *
make_distance_map( unsigned char *img,
                  unsigned int width, unsigned int height )
{
    short * xdist = (short *)  malloc( width * height * sizeof(short) );
    short * ydist = (short *)  malloc( width * height * sizeof(short) );
    double * gx   = (double *) calloc( width * height, sizeof(double) );
    double * gy      = (double *) calloc( width * height, sizeof(double) );
    double * data    = (double *) calloc( width * height, sizeof(double) );
    double * outside = (double *) calloc( width * height, sizeof(double) );
    double * inside  = (double *) calloc( width * height, sizeof(double) );
    int i;
    
    // Convert img into double (data)
    double img_min = 255, img_max = -255;
    for( i=0; i<width*height; ++i)
    {
        double v = img[i];
        data[i] = v;
        if (v > img_max) img_max = v;
        if (v < img_min) img_min = v;
    }
    // Rescale image levels between 0 and 1
    for( i=0; i<width*height; ++i)
    {
        data[i] = (img[i]-img_min)/img_max;
    }
    
    // Compute outside = edtaa3(bitmap); % Transform background (0's)
    computegradient( data, width, height, gx, gy);
    edtaa3(data, gx, gy, width, height, xdist, ydist, outside);
    for( i=0; i<width*height; ++i)
        if( outside[i] < 0 )
            outside[i] = 0.0;
    
    // Compute inside = edtaa3(1-bitmap); % Transform foreground (1's)
    memset(gx, 0, sizeof(double)*width*height );
    memset(gy, 0, sizeof(double)*width*height );
    for( i=0; i<width*height; ++i)
        data[i] = 1 - data[i];
    computegradient( data, width, height, gx, gy);
    edtaa3(data, gx, gy, width, height, xdist, ydist, inside);
    for( i=0; i<width*height; ++i)
        if( inside[i] < 0 )
            inside[i] = 0.0;
    
    // distmap = outside - inside; % Bipolar distance field
    unsigned char *out = (unsigned char *) malloc( width * height * sizeof(unsigned char) );
    for( i=0; i<width*height; ++i)
    {
        outside[i] -= inside[i];
        outside[i] = 128+outside[i]*16;
        if( outside[i] < 0 ) outside[i] = 0;
        if( outside[i] > 255 ) outside[i] = 255;
        out[i] = 255 - (unsigned char) outside[i];
        //out[i] = (unsigned char) outside[i];
    }
    
    free( xdist );
    free( ydist );
    free( gx );
    free( gy );
    free( data );
    free( outside );
    free( inside );
    return out;
}


@interface KDETextView ()
{
    text_buffer_t *textBuffer;
    markup_t markup;
    vec2 pen;
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
}

@property (nonatomic, readwrite, assign) GLuint shader;
@property (nonatomic, readwrite, strong) KDETextViewBuffer *buffer;

@end


@implementation KDETextView

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) prepareOpenGL
{
    [self.openGLContext makeCurrentContext];
    
    KDETextViewFont *font = [[KDETextViewFont alloc] initWithFontName:@"Menlo"];
    self.buffer = [[KDETextViewBuffer alloc] initWithFont:font];
    
    NSString *vertPath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"vert" inDirectory:@"shaders"];
    NSString *fragPath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"frag" inDirectory:@"shaders"];
    
    self.shader = shader_load( [vertPath cStringUsingEncoding:NSUTF8StringEncoding], [fragPath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    pen.x = 10.0f;
    pen.y = 500.0f;
    
    mat4_set_identity( &modelMatrix);
    mat4_set_identity( &viewMatrix);
    mat4_set_identity( &projectionMatrix);
    
    glDisable( GL_BLEND);
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    
    GLenum error = glGetError();
    if( error != GL_NO_ERROR)
    {
        NSLog( @"GL ERROR: %@", @(error));
    }
}

- (void) reshape
{
    [self.openGLContext makeCurrentContext];
    
    NSRect bounds = self.bounds;
    GLint x = NSMinX(bounds);
    GLint y = NSMinY(bounds);
    GLsizei width = NSWidth(bounds) * 2.0f;
    GLsizei height = NSHeight(bounds) * 2.0f;
    
    glViewport( x, y, width, height);
    mat4_set_orthographic( &projectionMatrix, x, x + width, y, y + height, -1, 1);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.openGLContext makeCurrentContext];
    
    CGFloat gray = 1.0f;
    glClearColor( gray, gray, gray, 1.0f);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    glColor4f(1.00,1.00,1.00,1.00);
    glUseProgram( self.shader );
    
    glUniformMatrix4fv( glGetUniformLocation( self.shader, "model" ),
                       1, 0, modelMatrix.data);
    glUniformMatrix4fv( glGetUniformLocation( self.shader, "view" ),
                       1, 0, viewMatrix.data);
    glUniformMatrix4fv( glGetUniformLocation( self.shader, "projection" ),
                       1, 0, projectionMatrix.data);
    
    [self.buffer render];
    
    [self.openGLContext flushBuffer];
    
    GLenum error = glGetError();
    if( error != GL_NO_ERROR)
    {
        NSLog( @"GL ERROR: %@", @(error));
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSLog(@"mouse up");
    [self setNeedsDisplay:YES];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *string = theEvent.characters;
    static vec4 color = (vec4) { 0,0,0,1 };
    if( theEvent.keyCode == kVK_Return)
    {
        string = @"\n";
        switch( random() % 4)
        {
            case 0:
                color.r = 0.0f;
                color.g = 0.0f;
                color.b = 0.0f;
                break;
                
            case 1:
                color.r = 0.729f;
                color.g = 0.173f;
                color.b = 0.639f;
                break;
                
            case 2:
                color.r = 0.149f;
                color.g = 0.165f;
                color.b = 0.847f;
                break;
                
            case 3:
                color.r = 0.306f;
                color.g = 0.506f;
                color.b = 0.533f;
                break;
        }
        [self.buffer addChar:'\n'
                       color:color];
    }
    else if( theEvent.keyCode == kVK_Delete)
    {
        [self.buffer deleteLastChar];
    }
    else
    {
        [self.buffer addChar:[string characterAtIndex:0]
                       color:color];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    mat4_translate( &viewMatrix, 0.0f, -theEvent.scrollingDeltaY, 0.0f);
    [self setNeedsDisplay:YES];
}

@end
