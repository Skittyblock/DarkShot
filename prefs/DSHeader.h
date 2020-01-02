// DSHeader.m

#import <Preferences/PSSpecifier.h>

#define kTintColor [UIColor colorWithRed:0.36 green:0.81 blue:0.38 alpha:1.0]

@interface DSHeader : UITableViewCell

@property (nonatomic, retain) UILabel *title;
@property (nonatomic, retain)  UILabel *subtitle;

- (id)initWithSpecifier:(PSSpecifier *)specifier;

@end
