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

// clear
@property (weak) IBOutlet NSButton *clearButton;
@property (nonatomic,strong) NSArray <NSString *> *resultList;

@end

@implementation ViewController

#pragma mark - lifecycle
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.clearButton setEnabled:NO];
}

#pragma mark - UI
- (void)showAlertWithStyle:(NSAlertStyle)style title:(NSString *)title subtitle:(NSString *)subtitle
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = style;
    [alert setMessageText:title];
    [alert setInformativeText:subtitle];
    [alert runModal];
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
    }
    
    [self.browseButton setEnabled:state];
    [self.pathTextField setEnabled:state];
    [self.ignoreCategoryCheckBox setEnabled:state];
    [self.searchButton setEnabled:state];
    //    [self.resultTextView setEditable:state];
    [self.processIndicator setHidden:state];
    [self.clearButton setEnabled:state];
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
    self.statusLabel.stringValue = @"Searching...";
    [self.resultTextView setString:@""];
    
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
        weakSelf.resultList = resultList;
    }];
}

- (IBAction)clearAllButtonClicked:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert setMessageText:@"Confirm!"];
    [alert setInformativeText:@"This operation will comment out all the unused files, continue?"];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];

    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == NSAlertFirstButtonReturn)
        {
            [self commentOutAll];
        }
    }];
}

#pragma mark - clear
-(void)commentOutAll
{
    if (!self.resultList ||self.resultList.count == 0)
    {
        return;
    }
    
    self.statusLabel.stringValue = @"Processing...";
    [self setUIEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSString *filePath in self.resultList)
        {
            NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            if (!content)
            {
                continue;
            }
            
            content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@"\n//"];
            content = [[self createCommentHeader] stringByAppendingString:content];
            if(!content)
            {
                continue;
            }
            
            [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.statusLabel.stringValue = [NSString stringWithFormat:@"unused files : %ld",self.resultList.count];
            self.resultList = nil;
            [self setUIEnabled:YES];
            [self.clearButton setEnabled:NO];
            [self showAlertWithStyle:NSAlertStyleInformational title:@"Done!" subtitle:@"All files are commented out."];
        });
    });
}

-(NSString *)createCommentHeader
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"/******************** Commented out by JXUnusedFilesFinder on %@ ********************/\n\n//",dateStr];
}

@end
