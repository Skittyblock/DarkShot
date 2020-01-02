// DSRootListController.m

#include "DSRootListController.h"

@implementation DSRootListController

- (id)init {
  self = [super init];

  if (self) {
    //UIBarButtonItem *respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
    //self.navigationItem.rightBarButtonItem = respringButton;
  }

  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  self.view.tintColor = kTintColor;
  keyWindow.tintColor = kTintColor;
  [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = kTintColor;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  keyWindow.tintColor = nil;
}

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
  }

  return _specifiers;
}

@end
