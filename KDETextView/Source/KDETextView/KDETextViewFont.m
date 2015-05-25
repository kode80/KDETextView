//
//  KDETextViewFont.m
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import "KDETextViewFont.h"
#import "KDEWCharString.h"
#import "KDETextViewBuffer.h"

#include "freetype-gl.h"
#include "edtaa3func.h"


const float KDETextViewFontDefaultSize = 24.0f;


@interface KDETextViewFont ()

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSString *path;

@property (nonatomic, readwrite, assign) texture_font_t *textureFont;
@property (nonatomic, readwrite, assign) texture_atlas_t *textureAtlas;

@end


@implementation KDETextViewFont

- (void) dealloc
{
    if( self.textureFont)  { texture_font_delete( self.textureFont); }
    if( self.textureAtlas) { texture_atlas_delete( self.textureAtlas); }
}

- (instancetype) initWithFontName:(NSString *)fontName
{
    self = [super init];
    
    if( self)
    {
        NSUInteger atlasSize = 2048;
        NSString *fontPath = [KDETextViewFont pathForFontName:fontName];
        KDEWCharString *cache = [KDEWCharString wcharString:@" !\"#$%&'()*+,-./0123456789:;<=>?"
                                                            @"@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
                                                            @"`abcdefghijklmnopqrstuvwxyz{|}~"];
        
        self.textureAtlas = texture_atlas_new( atlasSize, atlasSize, 1);
        self.textureFont = texture_font_new_from_file( self.textureAtlas, KDETextViewFontDefaultSize, [fontPath cStringUsingEncoding:NSUTF8StringEncoding]);
        size_t missed = texture_font_load_glyphs( self.textureFont, cache.wcharString);
        NSLog(@"Missed glyphs: %@", @(missed));
    }
    
    return self;
}

- (float) height
{
    return self.textureFont->height;
}

- (float) lineGap
{
    return self.textureFont->linegap;
}

+ (NSString *)pathForFontName:(NSString *)fontName
{
    CTFontDescriptorRef fontRef = CTFontDescriptorCreateWithNameAndSize ((CFStringRef)fontName, KDETextViewFontDefaultSize);
    CFURLRef url = (CFURLRef)CTFontDescriptorCopyAttribute(fontRef, kCTFontURLAttribute);
    NSString *fontPath = [NSString stringWithString:[(NSURL *)CFBridgingRelease(url) path]];
    return fontPath;
}

- (void) addChar:(unichar)chr
        toBuffer:(KDETextViewBuffer *)buffer
       withColor:(vec4)color
    previousChar:(unichar)previousChar
             pen:(vec2 *)pen
{
     texture_glyph_t *glyph  = texture_font_get_glyph( self.textureFont, chr);
     if( previousChar != L'\0' )
     {
         pen->x += texture_glyph_get_kerning( glyph, previousChar);
     }
    
     int x0  = pen->x + glyph->offset_x;
     int y0  = pen->y + glyph->offset_y;
     int x1  = x0 + (int)glyph->width;
     int y1  = y0 - (int)glyph->height;
     
     pen->x += glyph->advance_x;
     pen->y += glyph->advance_y;
    
    [buffer addQuadXY0:(vec2){ x0, y0}
                   xy1:(vec2){ x1, y1}
                   st0:(vec2){ glyph->s0, glyph->t0 }
                   st1:(vec2){ glyph->s1, glyph->t1 }
                 color:color];
}

- (vec2) glyphAdvanceForChar:(unichar)chr
{
    texture_glyph_t *glyph  = texture_font_get_glyph( self.textureFont, chr);
    return (vec2){ glyph->advance_x, glyph->advance_y};
}

@end
