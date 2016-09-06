//
//  GKImagePickerAuthorizer.h
//  GKImagePicker
//
//  Created by Daniel Bachar on 06/09/2016.
//  Copyright © 2016 Georg Kitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GKImagePickerAuthorizer

+ (BOOL)hasPermissionToPhotoLibrary;
+ (BOOL)hasPermissionToCamera;

@end
