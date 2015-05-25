//
//  KDETextViewBuffer.h
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "vec234.h"


@class KDETextViewFont;

@interface KDETextViewBuffer : NSObject

@property (nonatomic, readonly, strong) KDETextViewFont *font;

- (instancetype) initWithFont:(KDETextViewFont *)font;

- (void) addChar:(unichar)chr color:(vec4)color;

- (void) deleteLastChar;

- (void) addQuadXY0:(vec2)xy0
                xy1:(vec2)xy1
                st0:(vec2)st0
                st1:(vec2)st1
              color:(vec4)color;

- (void) render;

@end
