//
//  AppDelegate.h
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/23/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class KDETextView;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet KDETextView *textView;

- (IBAction) sliderChanged:(id)sender;

@end

