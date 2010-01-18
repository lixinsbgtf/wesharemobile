/*
 
 /*
 
 WeShare for iPhone - A library to easily share information on various networks
 
 WeShare for iPhone - Copyright (C) 2009, Reiner Pittinger, Initiative neofonie open, 
 neofonie Technologieentwicklung und Informationsmanagement GmbH, http://open.neofonie.de
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 You may obtain a commercial licence to use this library in non-GPL projects. Please contact open@neofonie.de for further information and assistance.
 
 Created by Reiner Pittinger <reiner.pittinger@neofonie.de> on 18.12.09.
 
 */

#import "WeShareGlobal.h"

@implementation WSDialog

@synthesize delegate;

- (void)setTitle:(NSString *)aTitle
{
	[super setTitle: aTitle];
	if (aTitle) {
		titleLabel.text = aTitle;
	}
}

- (void)showInView:(UIView*)hostView
{
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
	
	CGRect viewFrame = [UIScreen mainScreen].applicationFrame;
	
	BOOL isShareDialog = [self isKindOfClass: [WSShareDialog class]];
	
	if (isShareDialog) {
		backgroundView = [[UIView alloc] initWithFrame: viewFrame];
		backgroundView.backgroundColor = [UIColor colorWithWhite: 0.2 alpha: 0.6];
		backgroundView.alpha = 0;
		
		[window addSubview: backgroundView];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration: kWSTransitionDuration/1.5];
		backgroundView.alpha = 1;
		[UIView commitAnimations];
	}
	
	self.view.frame = viewFrame;
	[window addSubview: self.view];
	
	self.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
	// Make sure the layer is visible
	self.view.alpha = 1;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: kWSTransitionDuration/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	self.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
	[UIView commitAnimations];
	
	[WSShareCenter sharedCenter].dialogCount++;
}

- (IBAction)dismiss
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: kWSTransitionDuration/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dismissAnimationStopped)];
	if (backgroundView) {
		backgroundView.alpha = 0;
	}
	self.view.alpha = 0;
	[UIView commitAnimations];
}

- (void)dismissAnimationStopped
{
	[self.view removeFromSuperview];
	[WSShareCenter sharedCenter].dialogCount--;
	if (backgroundView) {
		[backgroundView removeFromSuperview];
		[backgroundView release], backgroundView = nil;
	}
	
	if (self.delegate && [self.delegate respondsToSelector: @selector(didDismissDialog:)]) {
		[self.delegate didDismissDialog: self];
	}
}

#pragma mark Plugin Animations

// Borrowed from FBConnect/FBDialog.m

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: kWSTransitionDuration/2];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];	
	[UIView setAnimationDuration: kWSTransitionDuration/2];
	self.view.transform = CGAffineTransformIdentity;	
	[UIView commitAnimations];
}

@end