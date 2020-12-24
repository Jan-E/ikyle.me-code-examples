//
//  ViewController.m
//  Photo Picker ObjC
//
//  Created by Kyle Howells on 23/06/2020.
//

#import "PHPickerController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
@import MobileCoreServices;

@interface ViewController () <PHPickerViewControllerDelegate>

@end

@implementation ViewController{
    UIScrollView *scrollView;
    NSMutableArray <UIImageView*>* imageViews;
    UIButton *selectButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    imageViews = [NSMutableArray array];
    
    // Create ScrollView
    scrollView = [[UIScrollView alloc] init];
    scrollView.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
    [self.view addSubview:scrollView];
    
    // Select Photos Button
    selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [selectButton setTitle:@"Picker" forState:UIControlStateNormal];
    [selectButton addTarget:self action:@selector(selectPressed:) forControlEvents:UIControlEventTouchUpInside];
    [selectButton sizeToFit];
    [self.view addSubview:selectButton];

    // Handle the app's library of videos
    NSError *error = nil;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist;
    NSString *fileName;
    NSString *thumbName;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSURL *libraryURL = [[filemgr URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    long long librarySize = 0;
    float recordingDuration = 0;
    filemgr =[NSFileManager defaultManager];
    filelist = [filemgr contentsOfDirectoryAtPath:paths[0] error:&error];
    librarySize = [filelist count];
    NSLog(@"library files: %lld", librarySize);
    int i;
    for (i = 0; i < librarySize; i++) {
        fileName = [filelist objectAtIndex: i];
        NSURL *fileURL = [libraryURL URLByAppendingPathComponent:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        NSDate *fileDate = [fileAttributes objectForKey:NSFileCreationDate];
        if ([fileName containsString:@".mov"]) {
            // imported videos
            AVURLAsset *avUrl = [AVURLAsset assetWithURL:fileURL];
            CMTime time = [avUrl duration];
            recordingDuration = time.value/time.timescale;
            NSLog(@"%@ size %@ date %@ url %@ duration %f", fileName, fileSizeNumber, fileDate, fileURL, recordingDuration);
            thumbName = [fileName stringByReplacingOccurrencesOfString:@".mov" withString:@""];
            NSURL *thumbURL = [libraryURL URLByAppendingPathComponent:thumbName];
            NSString *thumbPath = [thumbURL path];
            if ([filemgr fileExistsAtPath:thumbPath]) {
                NSDictionary *thumbAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thumbURL.path error:nil];
                NSNumber *thumbSizeNumber = [thumbAttributes objectForKey:NSFileSize];
                NSDate *thumbDate = [thumbAttributes objectForKey:NSFileCreationDate];
                NSLog(@"thumb %@ size %@ date %@ url %@", thumbName, thumbSizeNumber, thumbDate, thumbURL);
                // clean up on app load for demonstration purposes
                [filemgr removeItemAtPath:thumbPath error:nil];
            }
            NSString *filePath = [fileURL path];
            if ([filemgr fileExistsAtPath:filePath]) {
                NSLog(@"file %@ existed, duration %f", filePath, recordingDuration);
                // clean up on app load for demonstration purposes
                [filemgr removeItemAtPath:filePath error:nil];
            }
        }
    }
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    const CGSize size = self.view.bounds.size;
    const UIEdgeInsets safeArea = self.view.safeAreaInsets;
    
    selectButton.frame = ({
        CGRect frame = CGRectZero;
        frame.size.width = MIN(size.width - 10, 250);
        frame.size.height = 40;
        frame.origin.y = size.height - (frame.size.height + 10 + safeArea.bottom);
        frame.origin.x = (size.width - frame.size.width) * 0.5;
        frame;
    });
    
    scrollView.frame = ({
        CGRect frame = CGRectZero;
        frame.origin.y = safeArea.top + 10;
        frame.size.height = (selectButton.frame.origin.y - 10) - frame.origin.y;
        frame.size.width = size.width - 20;
        frame.origin.x = (size.width - frame.size.width) * 0.5;
        frame;
    });

    CGFloat y = 10;
    for (NSInteger i = 0; i < imageViews.count; i++) {
        UIImageView *imageView = imageViews[i];
        imageView.frame = ({
            CGRect frame = CGRectZero;
            frame.origin.y = y;
            frame.size.width = MIN(scrollView.bounds.size.width - 20, 300);
            frame.origin.x = (scrollView.bounds.size.width - frame.size.width) * 0.5;
            frame.size.height = MIN(frame.size.width * 0.75, 250);
            y += frame.size.height + 10;
            frame;
        });
    }
    scrollView.contentSize = CGSizeMake(0, y);
}

#pragma mark Helpers

-(UIImageView*)newImageViewForImage:(UIImage*)image{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor blackColor];
    imageView.image = image;
    return imageView;
}

-(void)clearImageViews{
    for (UIImageView *imageView in imageViews) {
        [imageView removeFromSuperview];
    }
    [imageViews removeAllObjects];
}

#pragma mark - PHPicker

-(void)selectPressed:(id)sender{
    // This is needed to access the creation date in the Photos library
    // If we wait for the built-in detection the first import might have the wrong date
    [self requestAuthorizationToPhotos];
    // https://developer.apple.com/forums/thread/650902
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] initWithPhotoLibrary: photoLibrary];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter videosFilter];
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
    pickerViewController.delegate = self;
    [self presentViewController:pickerViewController animated:YES completion:nil];
}

-(void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results{
    NSLog(@"-picker:%@ didFinishPicking:%@", picker, results);

    [self clearImageViews];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    for (PHPickerResult *result in results) {
        NSLog(@"result: %@", result);
        // 2020-12-20 03:03:03.468064+0100 Photo Picker ObjC[12542:1871998] result: <PHPickerResult: 0x282f29080>
        NSLog(@"result.assetIdentifier: %@", result.assetIdentifier);
        // 2020-12-20 03:03:03.468123+0100 Photo Picker ObjC[12542:1871998] result.assetIdentifier: EB4437ED-55D5-4CAA-A210-6CF2FF32A375/L0/001
        NSLog(@"result.itemProvider: %@", result.itemProvider);
        // 2020-12-20 03:03:03.468212+0100 Photo Picker ObjC[12542:1871998] result.itemProvider: <NSItemProvider: 0x28041dea0> {types = ( "public.mpeg-4" )}
        
        __block PHAsset *refAsset = nil;
        NSString *refID = result.assetIdentifier;
        NSArray *refIDs = @[refID];
        PHFetchResult *assetResults;
        // Fetch the (single) asset with refID from Photos
        NSLog(@"assetIdentifier %@", refID);
        assetResults = [PHAsset fetchAssetsWithLocalIdentifiers:refIDs options:nil];
        NSLog(@"assetResults = %@", assetResults);
        for (PHAsset *phAsset in assetResults) {
            float recordingDuration = phAsset.duration;
            NSLog(@"recordingDuration %f", recordingDuration);
            NSDate *PHAssetCreationDate = phAsset.creationDate;
            NSLog(@"PHAssetCreationDate %@", PHAssetCreationDate);
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = NO;
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset
                                                                    options:options
                                                              resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
                NSLog(@"PHImageResultIsInCloudKey %d", [info[PHImageResultIsInCloudKey] boolValue]);
                NSLog(@"info %@", info);
                NSURL *videoURL = (NSURL *)[[(AVURLAsset *)avAsset URL] fileReferenceURL];
                NSLog(@"videoURL absoluteString = %@", [videoURL absoluteString]);
                NSLog(@"videoURL relativePath   = %@", [videoURL relativePath]);
                AVURLAsset *avUrl = [AVURLAsset assetWithURL:videoURL];
                CMTime time = [avUrl duration];
                float recordingDuration;
                recordingDuration = time.value/time.timescale;
                NSArray *tracks = [avUrl tracksWithMediaType:AVMediaTypeVideo];
                // check duration and tracks to detect https://stackoverflow.com/q/64090158/872051
                // Request AVAsset using iCloud PHAsset returns an AVAsset with no VideoTracks
                NSLog(@"duration %f, tracks %lu", recordingDuration, (unsigned long)tracks.count);
            }];
        }

        [result.itemProvider loadFileRepresentationForTypeIdentifier:(NSString *)kUTTypeMovie completionHandler:^(id item, NSError *error) {
            NSLog(@"item: %@", item);
            // 2020-12-20 03:03:03.755649+0100 Photo Picker ObjC[12542:1872028] item: file:///private/var/mobile/Containers/Data/Application/6BB518A0-927A-4723-B886-E684B60EE489/tmp/.com.apple.Foundation.NSItemProvider.oA0J1x/IMG_0409.mp4
            NSLog(@"item class: %@", [item class]);
            // 2020-12-20 03:03:03.755774+0100 Photo Picker ObjC[12542:1872028] item class: NSURL
            
            NSURL *videoURL = item;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:videoURL.path error:nil];
            // default fileDate, overridden if we find refAsset:
            NSDate *fileDate = [fileAttributes objectForKey:NSFileCreationDate];
            NSLog(@"fileAttributes objectForKey:NSFileCreationDate %@", fileDate);

            // This sometimes fails: https://stackoverflow.com/q/42848260/872051
            for (PHAsset *phAsset in assetResults){
                NSLog(@"phAsset id = %@, type = %zd, date = %@", phAsset.localIdentifier, phAsset.mediaType, phAsset.creationDate);
                if ([phAsset.localIdentifier containsString:refID]) {
                    refAsset = phAsset;
                    break;
                }
            }
            if (refAsset == nil) {
                // Fall-back solution: loop through all video assets from Photos
                PHFetchResult *assetResults = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
                NSLog(@"new assetResults = %@", assetResults);
                for (PHAsset *phAsset in assetResults){
                    NSLog(@"phAsset id = %@, type = %zd, date = %@", phAsset.localIdentifier, phAsset.mediaType, phAsset.creationDate);
                    if ([phAsset.localIdentifier containsString:refID]) {
                        refAsset = phAsset;
                        break;
                    }
                }
            }
            if (refAsset != nil) {
                NSLog(@"refAsset id = %@, type = %zd, date = %@", refAsset.localIdentifier, refAsset.mediaType, refAsset.creationDate);
                NSLog(@"NSFileCreationDate    %@", fileDate);
                // override NSFileCreationDate
                fileDate = refAsset.creationDate;
                NSLog(@"refAsset.creationDate %@", fileDate);
                // On iPhone (1)
                // 2020-12-22 22:36:58.320198+0100 Photo Picker ObjC[24579:3550430] NSFileCreationDate    Sat Jun 20 18:49:23 2020
                // 2020-12-22 22:36:58.320405+0100 Photo Picker ObjC[24579:3550430] refAsset.creationDate Sat Aug 26 16:18:31 2017
                // On iPad (1)
                // 2020-12-22 22:49:36.171521+0100 Photo Picker ObjC[41187:2704718] NSFileCreationDate    Sat Aug 26 16:18:31 2017
                // 2020-12-22 22:49:36.171608+0100 Photo Picker ObjC[41187:2704718] refAsset.creationDate Sat Aug 26 16:18:31 2017
                
                // On iPhone (2)
                // 2020-12-22 22:36:42.103254+0100 Photo Picker ObjC[24579:3550243] NSFileCreationDate    Mon Apr 27 18:43:40 2020
                // 2020-12-22 22:36:42.103296+0100 Photo Picker ObjC[24579:3550243] refAsset.creationDate Mon Apr 27 18:43:38 2020
                // On iPad (2):
                // 2020-12-22 22:49:15.463148+0100 Photo Picker ObjC[41187:2704659] NSFileCreationDate    Mon Apr 27 18:44:56 2020
                // 2020-12-22 22:49:15.463237+0100 Photo Picker ObjC[41187:2704659] refAsset.creationDate Mon Apr 27 18:43:38 2020
                AVURLAsset *avUrl = [AVURLAsset assetWithURL:videoURL];
                CMTime time = [avUrl duration];
                float recordingDuration;
                recordingDuration = time.value/time.timescale;
                NSArray *tracks = [avUrl tracksWithMediaType:AVMediaTypeVideo];
                // check duration and tracks to detect https://stackoverflow.com/q/64090158/872051
                // Request AVAsset using iCloud PHAsset returns an AVAsset with no VideoTracks
                NSLog(@"duration %f, tracks %lu", recordingDuration, (unsigned long)tracks.count);
            } else {
                NSLog(@"No PHAsset with id = %@ found. Is Photos access enabled?", refID);
            }

            unsigned long long fileSize;
            NSFileManager *filemgr = [NSFileManager defaultManager];
            NSString *inputFilePath = [videoURL path];
            NSString *uuidString = [[NSUUID UUID] UUIDString];
            NSString *fileName;
            // imported filename would be something like IMG_0409.mov: do not use
            // fileName = [[inputFilePath lastPathComponent] stringByDeletingPathExtension];
            NSString *inputFileName;
            inputFileName = [inputFilePath lastPathComponent];
            // mimic the filenames used by UIImagePickerController for imported filename
            fileName = @"trim.";
            fileName = [fileName stringByAppendingString:uuidString];
            fileName = [fileName stringByAppendingString:@".mov"];
            NSURL *libraryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *outputFileURL = [libraryURL URLByAppendingPathComponent:fileName];
            NSString *outputFilePath = [outputFileURL path];
            NSLog(@"outputFilePath %@", outputFilePath);
            if (![filemgr fileExistsAtPath:inputFilePath]) {
                NSLog(@"inputFilePath %@ does not exist", inputFilePath);
            }
            if ([filemgr fileExistsAtPath:inputFilePath]) {
                fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:inputFilePath error:nil] fileSize];
                NSLog(@"fileName %@, size %llu, date %@", fileName, fileSize, fileDate);
                if ([filemgr fileExistsAtPath:outputFilePath]) {
                    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:outputFilePath error:nil] fileSize];
                    NSLog(@"outputFilePath %@ exists (%llu)", outputFilePath, fileSize);
                    // remove and regenerate every time for demonstration purposes
                    [filemgr removeItemAtPath:outputFilePath error:nil];
                }
                if (![filemgr fileExistsAtPath:outputFilePath]) {
                    NSLog(@"copy %@ from camera roll to library as %@", inputFileName, fileName);
                    if([filemgr copyItemAtPath:inputFilePath toPath:outputFilePath error:&error]) {
                        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:outputFilePath error:nil] fileSize];
                        NSLog(@"%@ copied, size %llu", outputFilePath, fileSize);
                        fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputFilePath error:nil];
                        // https://stackoverflow.com/a/6916766/872051
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSDictionary *creationDateAttr = [NSDictionary dictionaryWithObjectsAndKeys: fileDate, NSFileCreationDate, nil];
                        NSDictionary *modificationDateAttr = [NSDictionary dictionaryWithObjectsAndKeys: fileDate, NSFileModificationDate, nil];
                        [fileManager setAttributes:modificationDateAttr ofItemAtPath:outputFilePath error:&error];
                        [fileManager setAttributes:creationDateAttr ofItemAtPath:outputFilePath error:&error];
                        // NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                        NSString *recordingKey = [fileName stringByReplacingOccurrencesOfString:@".mov" withString:@""];
                        AVURLAsset *avUrl = [AVURLAsset assetWithURL:outputFileURL];
                        CMTime time = [avUrl duration];
                        float recordingDuration;
                        recordingDuration = time.value/time.timescale;
                        // https://stackoverflow.com/a/14490490/872051
                        NSArray *tracks = [avUrl tracksWithMediaType:AVMediaTypeVideo];
                        if (tracks.count >= 1) {
                            AVAssetTrack *track = [tracks objectAtIndex:0];
                            UIImageOrientation AssetOrientation_ = UIImageOrientationUp;
                            BOOL isAssetTilted = false;
                            CGAffineTransform thisTransform = track.preferredTransform;
                            if(thisTransform.a == 0 && thisTransform.b == 1.0 && thisTransform.c == -1.0 && thisTransform.d == 0)  {
                                // Orientation 90 degrees, used for iOS screen recording in landscape
                                AssetOrientation_ = UIImageOrientationRight;
                                isAssetTilted = true;
                                NSLog(@"Video %@ %ld %s", fileName,  (long)AssetOrientation_, "UIImageOrientationRight");
                            }
                            if(thisTransform.a == 0 && thisTransform.b == -1.0 && thisTransform.c == 1.0 && thisTransform.d == 0) {
                                // Orientation 270 degrees, used for iOS screen recording in landscape
                                AssetOrientation_ =  UIImageOrientationLeft;
                                isAssetTilted = true;
                                NSLog(@"Video %@ %ld %s", fileName, (long)AssetOrientation_, "UIImageOrientationLeft");
                            }
                            if(thisTransform.a == 1.0 && thisTransform.b == 0 && thisTransform.c == 0 && thisTransform.d == 1.0) {
                                AssetOrientation_ =  UIImageOrientationUp;
                                NSLog(@"Video %@ %ld %s", fileName, (long)AssetOrientation_, "UIImageOrientationUp");
                            }
                            if(thisTransform.a == -1.0 && thisTransform.b == 0 && thisTransform.c == 0 && thisTransform.d == -1.0) {
                                AssetOrientation_ = UIImageOrientationDown;
                                NSLog(@"Video %@ %ld %s", fileName, (long)AssetOrientation_, "UIImageOrientationDown");
                            }
                            CGSize mediaSize = track.naturalSize;
                            int recordingWidth;
                            int recordingHeight;
                            if (isAssetTilted) {
                                recordingWidth = (int)mediaSize.height;
                                recordingHeight = (int)mediaSize.width;
                            } else {
                                recordingWidth = (int)mediaSize.width;
                                recordingHeight = (int)mediaSize.height;
                            }
                            // Generate thumb
                            AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:outputFileURL options:nil];
                            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                            [generator setAppliesPreferredTrackTransform:YES];
                            // filename of the thumb = filename of imported video without ".mov"
                            NSURL *thumbURL = [libraryURL URLByAppendingPathComponent:recordingKey];
                            CMTime thumbTime = CMTimeMakeWithSeconds(1.0, 1);
                            
                            AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                                if (result != AVAssetImageGeneratorSucceeded) {
                                    NSLog(@"couldn't generate thumbnail, error:%@", error);
                                } else {
                                    NSLog(@"Thumbnail generated %@", recordingKey);
                                    UIImage *thumbImage = [UIImage imageWithCGImage:im];
                                    NSData *data = UIImageJPEGRepresentation(thumbImage, 0.5);
                                    [data writeToFile:thumbURL.path atomically:YES];
                                    NSLog(@"thumb UIImage: %@", thumbImage);
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UIImageView *imageView = [self newImageViewForImage:thumbImage];
                                        [self->imageViews addObject:imageView];
                                        [self->scrollView addSubview:imageView];
                                        [self.view setNeedsLayout];
                                        if (![[NSFileManager defaultManager] fileExistsAtPath:thumbURL.path]) {
                                            NSLog(@"thumb does not exist ?? %@", thumbURL);
                                        }
                                    });
                                }
                            };
                            CGSize maxSize = CGSizeMake(recordingWidth, recordingHeight);
                            generator.maximumSize = maxSize;
                            [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
                        }
                    } else {
                        NSLog(@"copy error %@", error);
                    }
                }
            }
        }];
    }
}

- (void)requestAuthorizationToPhotos {
    // https://stackoverflow.com/a/38395022/872051
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        BOOL success = 0;
        switch (status) {
            case PHAuthorizationStatusAuthorized:
                NSLog(@"PHAuthorizationStatusAuthorized");
                success = 1;
                break;
            case PHAuthorizationStatusDenied:
                NSLog(@"PHAuthorizationStatusDenied");
                break;
            case PHAuthorizationStatusNotDetermined:
                NSLog(@"PHAuthorizationStatusNotDetermined");
                break;
            case PHAuthorizationStatusRestricted:
                NSLog(@"PHAuthorizationStatusRestricted");
                break;
//          case PHAuthorizationStatusLimited:
            default:
                NSLog(@"default (Xcode 11), PHAuthorizationStatusLimited is XCode 12");
                break;
        }
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:^(void) {
                    NSLog(@"Import video does not have access to the Photos library. Please change the privacy settings.");
                }];
            });
        }
    }];
}

@end
