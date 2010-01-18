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
 
 Author: Reiner Pittinger <reiner.pittinger@neofonie.de>, <DATE: 2009-09-22>
 
 */

#import "WeShareGlobal.h"
#import "WSFacebookPlugin.h"
#import "FBConnect/FBConnect.h"

@interface WSFacebookPlugin ()

- (void)createSession;
- (void)showStreamDialog;

@end

@implementation WSFacebookPlugin

@synthesize apiKey;
@synthesize appSecret;
@synthesize useSessionProxy;
@synthesize sessionProxyUrl;
@synthesize attachmentTemplate;

- (id)initWithConfig:(NSDictionary*)configDict
{
	self = [super initWithConfig:configDict];
	if (self != nil) {
		self.apiKey = [self.config objectForKey: @"apiKey"];
		if (!self.apiKey) {
			// No API-Key supplied, disabled the plugin
			self.enabled = NO;
		}
		self.useSessionProxy = [[self.config objectForKey: @"useSessionProxy"] boolValue];
		if (useSessionProxy) {
			self.sessionProxyUrl = [self.config objectForKey: @"sessionProxyUrl"];
		} else {
			self.appSecret = [self.config objectForKey: @"appSecret"];
		}
		self.attachmentTemplate = [self.config objectForKey: @"attachmentTemplate"];
		
		[self createSession];
	}
	return self;
}

- (void)dealloc
{
	[facebookSession.delegates removeObject: self];
	[facebookSession logout];
	[facebookSession release];
    [apiKey release], apiKey = nil;
    [sessionProxyUrl release], sessionProxyUrl = nil;
	[super dealloc];
}

- (void)shareData:(NSDictionary*)data hostViewController:(UIViewController*)viewController
{
	self.dataDict = [NSMutableDictionary dictionaryWithDictionary: data];
	if (![facebookSession isConnected]) {
		// The user has to login first
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession: facebookSession] autorelease];
		dialog.delegate = self;
		[dialog show];
	} else {
		[facebookSession resume];
		[self showStreamDialog];
	}
}

- (void)showStreamDialog
{
	FBStreamDialog* dialog = [[[FBStreamDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.userMessagePrompt = WSLocalizedString(@"Share this with Facebook", nil);	
	dialog.attachment = [self streamDialogAttachment];
	[dialog show];
}

- (NSString*)streamDialogAttachment
{		
	NSString* result;
	
	/*
	 streamParamsDict is a mapping of WeShare shareDict keys (see WeShare.h) to
	 Facebook attachment keys (see http://wiki.developers.facebook.com/index.php/Attachment_%28Streams%29)
	 */
	NSDictionary* streamParamsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"name", kWSTitleDataDictKey,
									  @"href", kWSUrlDataDictKey,
									  @"description", kWSDescriptionDictKey,
									  @"media", kWSImageURLDictKey,
									  @"caption", kWSFacebookCaptionKey,
									  nil];
	
	// Create a JSON string that only contains actually existing parameters
	
	NSMutableArray* actualParameters = [[NSMutableArray alloc] init];
	
	BOOL descriptionSet = NO;
	
	for (NSString* key in [streamParamsDict allKeys]) {
		NSString* value = [self.dataDict objectForKey: key];
		
		if (value) {
			NSString* streamKey = [streamParamsDict objectForKey: key];
			// Special handling for media items
			if ([streamKey isEqualToString: @"media"]) {
				NSString* href = [[self.dataDict objectForKey: kWSUrlDataDictKey] absoluteString];
				value = [NSString stringWithFormat: @"[{\"type\":\"image\",\"src\":\"%@\",\"href\":\"%@\"}]", value, href];
				
				[actualParameters addObject: [NSString stringWithFormat: @"\"%@\":%@", streamKey, value]];
			} else {
				// WeShare self promotion
				if ([streamKey isEqualToString: @"description"]) {
					value = [NSString stringWithFormat: @"%@ (%@)", value, WSLocalizedString(@"Shared through WeShare", nil)];
					descriptionSet = YES;
				}
				
				[actualParameters addObject: [NSString stringWithFormat: @"\"%@\":\"%@\"", streamKey, value]];
			}
		}
	}
	
	if (!descriptionSet) {
		[actualParameters addObject: [NSString stringWithFormat: @"\"%@\":\"%@\"", @"description", WSLocalizedString(@"Shared through WeShare", nil)]];
	}
	
	NSString* parameterString = [actualParameters componentsJoinedByString: @","];
	result = [NSString stringWithFormat: @"{%@}", parameterString];
	
	[actualParameters release];
	return result;
}

- (void)createSession
{
	if (!self.useSessionProxy) {
		facebookSession = [[FBSession sessionForApplication: self.apiKey
														 secret: self.appSecret
													   delegate: self] retain];
	} else {
		facebookSession = [[FBSession sessionForApplication: self.apiKey
												getSessionProxy: self.sessionProxyUrl
													   delegate: self] retain];
	}
}

#pragma mark FBDialogDelegate methods

- (void)dialogDidSucceed:(FBDialog*)dialog {
	if ([dialog isKindOfClass: [FBLoginDialog class]]) {
		[self showStreamDialog];
	}
	if ([dialog isKindOfClass: [FBStreamDialog class]]) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kWSSharingSuccessfulNotification object: self];
	}
}

- (void)dialogDidCancel:(FBDialog*)dialog {
	[[NSNotificationCenter defaultCenter] postNotificationName: kWSSharingCancelledNotification object: self];
}

#pragma mark FBSessionDelegate methods

- (void)session:(FBSession*)session didLogin:(FBUID)uid
{
	NSLog(@"User with id %lld logged in.", uid);
}

@end