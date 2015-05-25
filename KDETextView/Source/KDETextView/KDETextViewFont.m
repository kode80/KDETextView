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
        
        unsigned char *map = [KDETextViewFont makeDistanceMapWithBytes:self.textureAtlas->data
                                                                 width:(unsigned int)self.textureAtlas->width
                                                                height:(unsigned int)self.textureAtlas->height];
        memcpy( self.textureAtlas->data, map, self.textureAtlas->width * self.textureAtlas->height * sizeof(unsigned char));
        free( map);
        texture_atlas_upload( self.textureAtlas);
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

+ (unsigned char *) makeDistanceMapWithBytes:(unsigned char *)img
                                       width:(unsigned int)width
                                      height:(unsigned int)height
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
