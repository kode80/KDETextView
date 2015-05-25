//
//  KDETextViewBuffer.m
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import "KDETextViewBuffer.h"
#import "KDETextViewFont.h"

#include "freetype-gl.h"
#include "vertex-buffer.h"
#include "markup.h"
#include "shader.h"
#include "mat4.h"


typedef struct {
    float x, y, z;
    float s, t;
    float r, g, b, a;
} vertex_t;


@interface KDETextViewBuffer ()

@property (nonatomic, readwrite, assign) vec2 pen;
@property (nonatomic, readwrite, assign) vertex_buffer_t *vertexBuffer;
@property (nonatomic, readwrite, strong) KDETextViewFont *font;
@property (nonatomic, readwrite, strong) NSString *string;

@end


@implementation KDETextViewBuffer

- (instancetype) initWithFont:(KDETextViewFont *)font
{
    self = [super init];
    
    if( self)
    {
        self.font = font;
        self.vertexBuffer = vertex_buffer_new( "vertex:3f,tex_coord:2f,color:4f");
        self.string = @"";
    }
    
    return self;
}

- (void) addChar:(unichar)chr color:(vec4)color
{
    NSString *chrString = [NSString stringWithCharacters:&chr length:1];
    
    if( chr != '\n')
    {
        unichar previousChar = self.string.length ? [self.string characterAtIndex:self.string.length - 1] : 0;
        
        [self.font addChar:chr
                  toBuffer:self withColor:color
              previousChar:previousChar
                       pen:&_pen];
    }
    else
    {
        _pen.x = 0;
        _pen.y -= self.font.height - self.font.lineGap;
    }
    
    self.string = [self.string stringByAppendingString:chrString];
}

- (void) deleteLastChar
{
    if( self.string.length && [self.string characterAtIndex:self.string.length-1] != '\n')
    {
        vec2 advance = [self.font glyphAdvanceForChar:[self.string characterAtIndex:self.string.length - 1]];
        vertex_buffer_erase( self.vertexBuffer, vertex_buffer_size( self.vertexBuffer) - 1);
        self.string = [self.string substringToIndex:self.string.length - 1];
        
        _pen.x -= advance.x;
        _pen.y -= advance.y;
    }
}

- (void) addQuadXY0:(vec2)xy0
                xy1:(vec2)xy1
                st0:(vec2)st0
                st1:(vec2)st1
              color:(vec4)color
{
    GLuint indices[] = {0,1,2, 0,2,3};
    vertex_t vertices[] = { { xy0.x, xy0.y, 0,  st0.s, st0.t,  color.r, color.g, color.b, color.a },
                            { xy0.x, xy1.y, 0,  st0.s, st1.t,  color.r, color.g, color.b, color.a },
                            { xy1.x, xy1.y, 0,  st1.s, st1.t,  color.r, color.g, color.b, color.a },
                            { xy1.x, xy0.y, 0,  st1.s, st0.t,  color.r, color.g, color.b, color.a } };
    vertex_buffer_push_back( self.vertexBuffer, vertices, 4, indices, 6 );
}

- (void) render
{
    vertex_buffer_render( self.vertexBuffer, GL_TRIANGLES);
}

@end
