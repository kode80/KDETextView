//
//  NSString+wchar.m
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import "NSString+wchar.h"

@implementation NSString (wchar)

- (wchar_t *) createWCharString
{
    NSUInteger usedLength = 0;
    NSRange remainingRange = NSMakeRange( 0, 0);
    
    size_t size = (self.length + 1) * sizeof( wchar_t);
    wchar_t *wcharString = malloc( size);
 
    if( wcharString)
    {
        [self getBytes:wcharString
             maxLength:size
            usedLength:&usedLength
              encoding:NSUTF32LittleEndianStringEncoding
               options:0
                 range:NSMakeRange( 0, self.length)
        remainingRange:&remainingRange];
        
        if( remainingRange.length)
        {
            free( wcharString);
            wcharString = NULL;
        }
        else
        {
            wcharString[ self.length] = 0;
        }
    }
    
    return wcharString;
}

@end
