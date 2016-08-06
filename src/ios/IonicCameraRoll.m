/**
 * Camera Roll PhoneGap Plugin.
 *
 * Reads photos from the iOS Camera Roll.
 *
 * Copyright 2013 Drifty Co.
 * http://drifty.com/
 *
 * See LICENSE in this project for licensing info.
 */

#import "IonicCameraRoll.h"
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <CoreLocation/CoreLocation.h>
@import Photos;

#define CAMERA_ROLL_PREFIX @"camera_roll"

@implementation IonicCameraRoll

+ (PHImageManager *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static PHImageManager *library = nil;
    dispatch_once(&pred, ^{
        library = [PHImageManager defaultManager];
    });
    
    // TODO: Dealloc this later?
    return library;
}

- (void)saveToCameraRoll:(CDVInvokedUrlCommand*)command
{
    NSString *base64String = [command argumentAtIndex:0];
    NSURL *url = [NSURL URLWithString:base64String];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:imageData];
    
    // save the image to photo album
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"saved"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
/**
 * Get all the photos in the library.
 *
 * TODO: This should support block-type reading with a set of images
 */
- (void)getPhotos:(CDVInvokedUrlCommand*)command
{
    
    // Run a background job
    [self.commandDelegate runInBackground:^{
        
        long int offset = [[command.arguments objectAtIndex:3] integerValue];
        long int limit = [[command.arguments objectAtIndex:2] integerValue];
        long int limitOffset = limit + offset;
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.fetchLimit = limitOffset;
        options.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
        
        
        [assetsFetchResult enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(offset, limit)] options:0 usingBlock:^(PHAsset *result, NSUInteger index, BOOL *stop){
            
            [self sendPluginResult:result forCommand:command];
            
        }];
        
    }];
    
}

- (void)getPhotoByLocalIdentifier:(CDVInvokedUrlCommand*)command {
    
    // Run a background job
    [self.commandDelegate runInBackground:^{
        
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[[command.arguments objectAtIndex:2]] options:nil];
        PHAsset* result = [assetsFetchResult firstObject];
        
        [self sendPluginResult:result forCommand:command];
        
    }];
    
}


-(void)sendPluginResult:(PHAsset *)result forCommand:(CDVInvokedUrlCommand*)command
{
    
    PHImageManager *library = [IonicCameraRoll defaultAssetsLibrary];
    PHImageContentMode contentMode = PHImageContentModeAspectFill;
    
    CGSize size;
    long int width = [[command.arguments objectAtIndex:0] integerValue];
    long int height =[[command.arguments objectAtIndex:1] integerValue];
    
    if(!width && !height){
        size = PHImageManagerMaximumSize;
        contentMode = PHImageContentModeDefault;
    }
    else {
        size = CGSizeMake(width, height);
    }
    
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = true;
    imageOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    [library requestImageForAsset:result
                       targetSize:size
                      contentMode:contentMode
                          options:imageOptions
                    resultHandler:^(UIImage *image, NSDictionary *info) {
                        
                        NSString *localIdentifier = result.localIdentifier;
                        NSString *filePath = [self tempFilePath:@"png" withIdentifier:[localIdentifier substringWithRange:NSMakeRange(0, 32)] ];
                        NSDictionary *resp = @{
                                               @"localIdentifier": localIdentifier,
                                               @"url":[[NSURL fileURLWithPath:filePath] absoluteString]
                                               };
                        
                        NSData *data = UIImagePNGRepresentation(image);
                        
                        CDVPluginResult *pluginResult;
                        NSError* err = nil;
                        
                        if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                        } else {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resp];
                        }
                        
                        [pluginResult setKeepCallbackAsBool:YES];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        
                    }];
    
}



- (NSString*)tempFilePath:(NSString*)extension withIdentifier:(NSString *)localIdentifier
{
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSString* filePath;
    
    filePath = [NSString stringWithFormat:@"%@/%@_%@.%@", docsPath, CAMERA_ROLL_PREFIX, localIdentifier, extension];
    
    return filePath;
}



- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

@end

