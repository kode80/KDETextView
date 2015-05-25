//
//  KDETextViewFont.h
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "vec234.h"


@class KDETextViewBuffer;


@interface KDETextViewFont : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *path;
@property (nonatomic, readonly, assign) float height;
@property (nonatomic, readonly, assign) float lineGap;

- (instancetype) initWithFontName:(NSString *)fontName;

- (void) addChar:(unichar)chr
        toBuffer:(KDETextViewBuffer *)buffer
       withColor:(vec4)color
    previousChar:(unichar)previousChar
             pen:(vec2 *)pen;

- (vec2) glyphAdvanceForChar:(unichar)chr;

@end
