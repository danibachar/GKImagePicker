//
//  GKImagePicker.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImagePicker.h"

#import "GKImageCropViewController.h"

@import Photos;
#import <AssetsLibrary/AssetsLibrary.h>

NSUInteger const kGKNoPermissionsAlertViewTag = 2500;

//No Permission messages
NSString const *kGKCameraErrorTitle = @"Camera Access Denied";
NSString const *kGKCameraErrorMessage = @"You Didn't authorized access to the Camera, so we can't change the profile picture from live camera";

NSString const *kGKPhotoLibraryErrorTitle = @"Library Access Denied";
NSString const *kGKPhotoLibraryErrorMessage = @"You Didn't authorized access to the Photo Library, so we can't change the profile picture from photos library";

typedef NS_ENUM(NSUInteger, GKPickerOption)
{
    GKPickerOptionCamera = 0,
    GKPickerOptionPhotoLibrary,
    GKPickerOptionNone
};

typedef NS_ENUM(NSUInteger, GKPickerAppSettingsOptions)
{
    GKPickerAppSettingsOptionsNone = 0,
    GKPickerAppSettingsOptionsOpen
};

@interface GKImagePicker ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, GKImageCropControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *popoverView;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
- (void)_hideController;
@end

@implementation GKImagePicker

#pragma mark -
#pragma mark Getter/Setter

@synthesize cropSize, delegate, resizeableCropArea;

#pragma mark -
#pragma mark Init Methods

- (id)init
{
    if (self = [super init]) {
        
        self.cropSize = CGSizeMake(320, 320);
        self.resizeableCropArea = NO;
    }
    return self;
}

# pragma mark -
# pragma mark Private Methods

- (void)_hideController
{
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - UIImagePickerController Init
- (void)initImagePickerIfNeededByType:(UIImagePickerControllerSourceType)type
{
    if (!self.imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsEditing = YES;
    }
    
    if (self.useFrontCameraAsDefault) {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    
    self.imagePickerController.sourceType = type;
}

#pragma mark UIImagePickerDelegate Methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
        [self.delegate imagePickerDidCancel:self];
        [self _hideController];
    } else {
        [self _hideController];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
    cropController.enforceRatioLimits = self.enforceRatioLimits;
    cropController.maxWidthRatio = self.maxWidthRatio;
    cropController.minWidthRatio = self.minWidthRatio;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    cropController.preferredContentSize = picker.preferredContentSize;
#else
    cropController.contentSizeForViewInPopover = picker.contentSizeForViewInPopover;
#endif
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    cropController.sourceImage = img;
    cropController.resizeableCropArea = self.resizeableCropArea;
    cropController.cropSize = self.cropSize;
    cropController.delegate = self;
    [picker pushViewController:cropController animated:YES];
    
}

#pragma mark -
#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage
{
    if ([self.delegate respondsToSelector:@selector(imagePicker:pickedImage:)]) {
        [self _hideController];
        [self.delegate imagePicker:self pickedImage:croppedImage];
    }
}


#pragma mark -
#pragma mark - Action Sheet and Image Pickers

- (void)showActionSheetOnViewController:(UIViewController *)viewController onPopoverFromView:(UIView *)popoverView
{
    self.presentingViewController = viewController;
    self.popoverView = popoverView;
    NSString *fromCameraString = NSLocalizedString(@"Image from Camera", @"Image from Camera");
    NSString *fromLibraryString = NSLocalizedString(@"Image from Library", @"Image from Library");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel");
    
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil];
        
        __weak typeof (self) weakSelf = self;
        UIAlertAction *fromCameraAction = [UIAlertAction actionWithTitle:fromCameraString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf showCameraImagePicker];
            
        }];
        
        UIAlertAction *fromLibraryAction = [UIAlertAction actionWithTitle:fromLibraryString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf showGalleryImagePicker];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:fromCameraAction];
        [alertController addAction:fromLibraryAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:(id)self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Image from Camera", @"Image from Camera"), NSLocalizedString(@"Image from Library", @"Image from Library"), nil];
        actionSheet.delegate = self;
        
        if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
            [actionSheet showFromRect:self.popoverView.frame inView:self.presentingViewController.view animated:YES];
        } else {
            if (self.presentingViewController.navigationController.toolbar) {
                [actionSheet showFromToolbar:self.presentingViewController.navigationController.toolbar];
            } else {
                [actionSheet showInView:self.presentingViewController.view];
            }
        }
    }
}

- (void)presentImagePickerController
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        [self.popoverController presentPopoverFromRect:self.popoverView.frame
                                                inView:self.presentingViewController.view
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        
    } else {
        
        [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
        
    }
}

- (void)showCameraImagePickerOnViewController:(UIViewController *)viewController {
    self.presentingViewController = viewController;
    [self showCameraImagePicker];
}

- (void)showCameraImagePicker
{
#if TARGET_IPHONE_SIMULATOR
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Simulator" message:@"Camera not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
#elif TARGET_OS_IPHONE
    
    if ([self hasPermissionToCamera]) {
        
        [self initImagePickerIfNeededByType:UIImagePickerControllerSourceTypeCamera];
        [self presentImagePickerController];
    } else {
        [self triggerNoPermissionFlow:GKPickerOptionCamera];
    }
    
#endif
    
}

- (void)showGalleryImagePickerOnViewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;
    [self showGalleryImagePicker];
}

- (void)showGalleryImagePicker
{    
    if ([self hasPermissionToPhotoLibrary]) {
        
        [self initImagePickerIfNeededByType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentImagePickerController];
    } else {
        [self triggerNoPermissionFlow:GKPickerOptionPhotoLibrary];
    }
}

#pragma mark - Private Error Handling
- (void)triggerNoPermissionFlow:(NSUInteger)type
{
    switch (type) {
        case 0://Camera
            [self showNoPermissionAlert:[kGKCameraErrorTitle mutableCopy]
                                message:[kGKCameraErrorMessage mutableCopy]];
            break;
        case 1://Photo Library
            [self showNoPermissionAlert:[kGKPhotoLibraryErrorTitle mutableCopy]
                                message:[kGKPhotoLibraryErrorMessage mutableCopy]];
            break;
        default:
            break;
    }
}

- (void)showNoPermissionAlert:(NSString*)title
                      message:(NSString*)message
{
    if (title.length == 0) {
        title = @"No Permission";
    }
    if (message.length == 0) {
        message = @"There are no permissions...Please visit app settings";
    }
    
    UIAlertView *notAuthorizedAlert = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:self
                                                       cancelButtonTitle:@"Dismiss"
                                                       otherButtonTitles:@"Settings", nil];
    
    notAuthorizedAlert.tag = kGKNoPermissionsAlertViewTag;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [notAuthorizedAlert show];
    });
}


- (BOOL)hasPermissionToPhotoLibrary
{
    switch ([PHPhotoLibrary authorizationStatus])
    {
        case PHAuthorizationStatusAuthorized://We have permission
            return YES;
        default://We dont have permissions, or we need to ask for them
            return NO;
    }
}

- (BOOL)hasPermissionToCamera
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            return YES;
        default:
            return NO;
    }
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case GKPickerOptionCamera:
            [self showCameraImagePicker];
            break;
        case GKPickerOptionPhotoLibrary:
            [self showGalleryImagePicker];
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kGKNoPermissionsAlertViewTag) {
        if (buttonIndex == GKPickerAppSettingsOptionsOpen) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

@end
