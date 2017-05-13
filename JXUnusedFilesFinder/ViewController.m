//
//  ViewController.m
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import "ViewController.h"
#import "JXUnusedFilesFinder.h"

@interface ViewController ()

// Project
@property (weak) IBOutlet NSButton *browseButton;
@property (weak) IBOutlet NSTextField *pathTextField;

// Settings
@property (weak) IBOutlet NSButton *ignoreCategoryCheckBox;

// Result
@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;
@property (weak) IBOutlet NSProgressIndicator *processIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSButton *searchButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)showAlertWithStyle:(NSAlertStyle)style title:(NSString *)title subtitle:(NSString *)subtitle
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = style;
    [alert setMessageText:title];
    [alert setInformativeText:subtitle];
    [alert runModal];
}

-(NSUInteger)getSettings
{
    NSUInteger setting = 0;
    
    if ([self.ignoreCategoryCheckBox state])
    {
        setting = setting | SearchOptionsIgnoreCategory;
    }
    
    return setting;
}

- (void)setUIEnabled:(BOOL)state
{
    if (state)
    {
        [self.processIndicator stopAnimation:self];
    }
    else
    {
        [self.processIndicator startAnimation:self];
        self.statusLabel.stringValue = @"Searching...";
        [self.resultTextView setString:@""];
    }

    [self.browseButton setEnabled:state];
    [self.pathTextField setEnabled:state];
    [self.ignoreCategoryCheckBox setEnabled:state];
    [self.searchButton setEnabled:state];
//    [self.resultTextView setEditable:state];
    [self.processIndicator setHidden:state];
}

#pragma mark - Action
- (IBAction)onBrowseButtonClicked:(id)sender
{
    // Show an open panel
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    BOOL okButtonPressed = ([openPanel runModal] == NSModalResponseOK);
    if (okButtonPressed)
    {
        // Update the path text field
        NSString *path = [[openPanel URL] path];
        [self.pathTextField setStringValue:path];
    }
}

- (IBAction)onSearchButtonClicked:(id)sender
{
    NSString *projectPath = self.pathTextField.stringValue;
    if (!projectPath.length)
    {
        [self showAlertWithStyle:NSAlertStyleWarning title:@"Path Error" subtitle:@"Project path is empty"];
        return;
    }

    BOOL pathExists = [[NSFileManager defaultManager] fileExistsAtPath:projectPath];
    if (!pathExists)
    {
        [self showAlertWithStyle:NSAlertStyleWarning title:@"Path Error" subtitle:@"Project folder is not exists"];
        return;
    }
    
    [self setUIEnabled:NO];
    
    NSUInteger settings = [self getSettings];
    __weak __typeof__(self) weakSelf = self;
    [[JXUnusedFilesFinder sharedFinder] startSearchInDirectory:projectPath withSearchOptions:settings completion:^(NSArray *resultList) {
        
        NSString *allResultStr = @"";
        for (NSString *path in resultList)
        {
            allResultStr = [allResultStr stringByAppendingFormat:@"%@\n",path];
        }
        
        [weakSelf.resultTextView setString:allResultStr];
        [weakSelf.statusLabel setStringValue:[NSString stringWithFormat:@"found unused files : %ld",resultList.count]];
        [weakSelf setUIEnabled:YES];
    }];
}

@end
