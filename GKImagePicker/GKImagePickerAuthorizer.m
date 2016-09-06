//
//  GKImagePickerAuthorizer.m
//  GKImagePicker
//
//  Created by Daniel Bachar on 06/09/2016.
//  Copyright © 2016 Georg Kitz. All rights reserved.
//

#import "GKImagePickerAuthorizer.h"
@import Photos;
#import <AssetsLibrary/AssetsLibrary.h>

@implementation GKImagePickerAuthorizer


#pragma mark - Private Methods
+ (BOOL)hasPermissionToPhotoLibrary
{
    switch ([PHPhotoLibrary authorizationStatus])
    {
        case PHAuthorizationStatusAuthorized://We have permission
        {
            return YES;
        }
        default://We dont have permissions, or we need to ask for them
        {
            return NO;
        }
    }
}

+ (BOOL)hasPermissionToCamera
{
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (status) {
        case AVAuthorizationStatusAuthorized:
        {
            return YES;
        }
        default:
        {
            return NO;
        }
    }
    
}

@end
