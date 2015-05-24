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
#include "freetype-gl.h"
#include "font-manager.h"
#include "vertex-buffer.h"
#include "text-buffer.h"
#include "markup.h"
#include "shader.h"
#include "mat4.h"

enum {
    kVK_ANSI_A                    = 0x00,
    kVK_ANSI_S                    = 0x01,
    kVK_ANSI_D                    = 0x02,
    kVK_ANSI_F                    = 0x03,
    kVK_ANSI_H                    = 0x04,
    kVK_ANSI_G                    = 0x05,
    kVK_ANSI_Z                    = 0x06,
    kVK_ANSI_X                    = 0x07,
    kVK_ANSI_C                    = 0x08,
    kVK_ANSI_V                    = 0x09,
    kVK_ANSI_B                    = 0x0B,
    kVK_ANSI_Q                    = 0x0C,
    kVK_ANSI_W                    = 0x0D,
    kVK_ANSI_E                    = 0x0E,
    kVK_ANSI_R                    = 0x0F,
    kVK_ANSI_Y                    = 0x10,
    kVK_ANSI_T                    = 0x11,
    kVK_ANSI_1                    = 0x12,
    kVK_ANSI_2                    = 0x13,
    kVK_ANSI_3                    = 0x14,
    kVK_ANSI_4                    = 0x15,
    kVK_ANSI_6                    = 0x16,
    kVK_ANSI_5                    = 0x17,
    kVK_ANSI_Equal                = 0x18,
    kVK_ANSI_9                    = 0x19,
    kVK_ANSI_7                    = 0x1A,
    kVK_ANSI_Minus                = 0x1B,
    kVK_ANSI_8                    = 0x1C,
    kVK_ANSI_0                    = 0x1D,
    kVK_ANSI_RightBracket         = 0x1E,
    kVK_ANSI_O                    = 0x1F,
    kVK_ANSI_U                    = 0x20,
    kVK_ANSI_LeftBracket          = 0x21,
    kVK_ANSI_I                    = 0x22,
    kVK_ANSI_P                    = 0x23,
    kVK_ANSI_L                    = 0x25,
    kVK_ANSI_J                    = 0x26,
    kVK_ANSI_Quote                = 0x27,
    kVK_ANSI_K                    = 0x28,
    kVK_ANSI_Semicolon            = 0x29,
    kVK_ANSI_Backslash            = 0x2A,
    kVK_ANSI_Comma                = 0x2B,
    kVK_ANSI_Slash                = 0x2C,
    kVK_ANSI_N                    = 0x2D,
    kVK_ANSI_M                    = 0x2E,
    kVK_ANSI_Period               = 0x2F,
    kVK_ANSI_Grave                = 0x32,
    kVK_ANSI_KeypadDecimal        = 0x41,
    kVK_ANSI_KeypadMultiply       = 0x43,
    kVK_ANSI_KeypadPlus           = 0x45,
    kVK_ANSI_KeypadClear          = 0x47,
    kVK_ANSI_KeypadDivide         = 0x4B,
    kVK_ANSI_KeypadEnter          = 0x4C,
    kVK_ANSI_KeypadMinus          = 0x4E,
    kVK_ANSI_KeypadEquals         = 0x51,
    kVK_ANSI_Keypad0              = 0x52,
    kVK_ANSI_Keypad1              = 0x53,
    kVK_ANSI_Keypad2              = 0x54,
    kVK_ANSI_Keypad3              = 0x55,
    kVK_ANSI_Keypad4              = 0x56,
    kVK_ANSI_Keypad5              = 0x57,
    kVK_ANSI_Keypad6              = 0x58,
    kVK_ANSI_Keypad7              = 0x59,
    kVK_ANSI_Keypad8              = 0x5B,
    kVK_ANSI_Keypad9              = 0x5C
};

/* keycodes for keys that are independent of keyboard layout*/
enum {
    kVK_Return                    = 0x24,
    kVK_Tab                       = 0x30,
    kVK_Space                     = 0x31,
    kVK_Delete                    = 0x33,
    kVK_Escape                    = 0x35,
    kVK_Command                   = 0x37,
    kVK_Shift                     = 0x38,
    kVK_CapsLock                  = 0x39,
    kVK_Option                    = 0x3A,
    kVK_Control                   = 0x3B,
    kVK_RightShift                = 0x3C,
    kVK_RightOption               = 0x3D,
    kVK_RightControl              = 0x3E,
    kVK_Function                  = 0x3F,
    kVK_F17                       = 0x40,
    kVK_VolumeUp                  = 0x48,
    kVK_VolumeDown                = 0x49,
    kVK_Mute                      = 0x4A,
    kVK_F18                       = 0x4F,
    kVK_F19                       = 0x50,
    kVK_F20                       = 0x5A,
    kVK_F5                        = 0x60,
    kVK_F6                        = 0x61,
    kVK_F7                        = 0x62,
    kVK_F3                        = 0x63,
    kVK_F8                        = 0x64,
    kVK_F9                        = 0x65,
    kVK_F11                       = 0x67,
    kVK_F13                       = 0x69,
    kVK_F16                       = 0x6A,
    kVK_F14                       = 0x6B,
    kVK_F10                       = 0x6D,
    kVK_F12                       = 0x6F,
    kVK_F15                       = 0x71,
    kVK_Help                      = 0x72,
    kVK_Home                      = 0x73,
    kVK_PageUp                    = 0x74,
    kVK_ForwardDelete             = 0x75,
    kVK_F4                        = 0x76,
    kVK_End                       = 0x77,
    kVK_F2                        = 0x78,
    kVK_PageDown                  = 0x79,
    kVK_F1                        = 0x7A,
    kVK_LeftArrow                 = 0x7B,
    kVK_RightArrow                = 0x7C,
    kVK_DownArrow                 = 0x7D,
    kVK_UpArrow                   = 0x7E
};

/* ISO keyboards only*/
enum {
    kVK_ISO_Section               = 0x0A
};

/* JIS keyboards only*/
enum {
    kVK_JIS_Yen                   = 0x5D,
    kVK_JIS_Underscore            = 0x5E,
    kVK_JIS_KeypadComma           = 0x5F,
    kVK_JIS_Eisu                  = 0x66,
    kVK_JIS_Kana                  = 0x68
};


char *match_description( char * family, float size, int bold, int italic )
{
    char *filename = 0;
    int weight = FC_WEIGHT_REGULAR;
    int slant = FC_SLANT_ROMAN;
    if ( bold )
    {
        weight = FC_WEIGHT_BOLD;
    }
    if( italic )
    {
        slant = FC_SLANT_ITALIC;
    }
    FcInit();
    FcPattern *pattern = FcPatternCreate();
    FcPatternAddDouble( pattern, FC_SIZE, size );
    FcPatternAddInteger( pattern, FC_WEIGHT, weight );
    FcPatternAddInteger( pattern, FC_SLANT, slant );
    FcPatternAddString( pattern, FC_FAMILY, (FcChar8*) family );
    FcConfigSubstitute( 0, pattern, FcMatchPattern );
    FcDefaultSubstitute( pattern );
    FcResult result;
    FcPattern *match = FcFontMatch( 0, pattern, &result );
    FcPatternDestroy( pattern );
    
    if ( !match )
    {
        fprintf( stderr, "fontconfig error: could not match family '%s'", family );
        return 0;
    }
    else
    {
        FcValue value;
        FcResult result = FcPatternGet( match, FC_FILE, 0, &value );
        if ( result )
        {
            fprintf( stderr, "fontconfig error: could not match family '%s'", family );
        }
        else
        {
            filename = strdup( (char *)(value.u.s) );
        }
    }
    FcPatternDestroy( match );
    return filename;
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
@end


@implementation KDETextView

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) prepareOpenGL
{
    
    /*
    NSString *fontPath = [self pathForFont:[NSFont fontWithName:@"Monaco" size:11.0f]];
    const wchar_t *cache = L" !\"#$%&'()*+,-./0123456789:;<=>?"
    L"@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
    L"`abcdefghijklmnopqrstuvwxyz{|}~";
    
    texture_atlas_t *atlas = texture_atlas_new( 1024, 1024, 1);
    texture_font_t *font = texture_font_new_from_file( atlas, 11.0f, [fontPath cStringUsingEncoding:NSUTF8StringEncoding]);
    size_t missedGlyphs = texture_font_load_glyphs( font, cache);
    texture_font_delete( font);
    
    NSLog(@"Missed glyphs: %@", @(missedGlyphs));
    */
    
    [self.openGLContext makeCurrentContext];
    
    char *family = match_description("Menlo", 23, 0, 0);
    vec4 clear  = {{0.0, 0.0, 0.0, 0.0}};
    vec4 white  = {{1.0, 1.0, 1.0, 1.0}};
    vec4 black  = {{0.0, 0.0, 0.0, 1.0}};
    markup.family  = family;
    markup.size    = 23;
    markup.bold    = 0;
    markup.italic  = 0;
    markup.rise    = 0.0;
    markup.spacing = 0.0;
    markup.gamma   = 2.;
    markup.foreground_color    = black;
    markup.background_color    = clear;
    markup.underline           = 0;
    markup.underline_color     = white;
    markup.overline            = 0;
    markup.overline_color      = white;
    markup.strikethrough       = 0;
    markup.strikethrough_color = white;
    markup.font = 0;
    
    NSLog(@"family: %s", family);
    
    NSString *vertPath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"vert" inDirectory:@"shaders"];
    NSString *fragPath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"frag" inDirectory:@"shaders"];
    
    
    pen.x = 10.0f;
    pen.y = 500.0f;
    
    textBuffer = text_buffer_new_ex( LCD_FILTERING_OFF,
                                     [vertPath cStringUsingEncoding:NSUTF8StringEncoding],
                                     [fragPath cStringUsingEncoding:NSUTF8StringEncoding]);
    text_buffer_printf( textBuffer, &pen, &markup, L"Test from KDETextView\nThis is a new line", NULL);
    
    mat4_set_identity( &modelMatrix);
    mat4_set_identity( &viewMatrix);
    mat4_set_identity( &projectionMatrix);
    
    //glDisable( GL_BLEND);
    //glEnable( GL_BLEND );
    //glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_ALPHA );
    
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
    glUseProgram( textBuffer->shader );
    
    glUniformMatrix4fv( glGetUniformLocation( textBuffer->shader, "model" ),
                       1, 0, modelMatrix.data);
    glUniformMatrix4fv( glGetUniformLocation( textBuffer->shader, "view" ),
                       1, 0, viewMatrix.data);
    glUniformMatrix4fv( glGetUniformLocation( textBuffer->shader, "projection" ),
                       1, 0, projectionMatrix.data);
    
    text_buffer_render( textBuffer);
    
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
    if( theEvent.keyCode == kVK_Return)
    {
        string = @"\n";
        switch( random() % 4)
        {
            case 0:
                markup.foreground_color.r = 0.0f;
                markup.foreground_color.g = 0.0f;
                markup.foreground_color.b = 0.0f;
                break;
                
            case 1:
                markup.foreground_color.r = 0.729f;
                markup.foreground_color.g = 0.173f;
                markup.foreground_color.b = 0.639f;
                break;
                
            case 2:
                markup.foreground_color.r = 0.149f;
                markup.foreground_color.g = 0.165f;
                markup.foreground_color.b = 0.847f;
                break;
                
            case 3:
                markup.foreground_color.r = 0.306f;
                markup.foreground_color.g = 0.506f;
                markup.foreground_color.b = 0.533f;
                break;
        }
    }
    
    text_buffer_printf( textBuffer, &pen, &markup, [string cStringUsingEncoding:NSUTF32LittleEndianStringEncoding], NULL);
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    mat4_translate( &viewMatrix, 0.0f, -theEvent.scrollingDeltaY, 0.0f);
    [self setNeedsDisplay:YES];
}

@end
