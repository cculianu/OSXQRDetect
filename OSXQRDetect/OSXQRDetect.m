//
//  OSXQRDetect.m
//  OSXQRDetect
//
//  Created by Calin Culianu <calin.culianu@gmail.com> on 5/23/19.
//  Copyright © 2019 electroncash.org. MIT License.
//

#import "OSXQRDetect.h"
#import <Foundation/Foundation.h>
#import <CoreImage/CIDetector.h>
#import <CoreImage/CIImage.h>
#import <CoreImage/CIFeature.h>


@interface OSXQRDetect : NSObject
@property (nonatomic, strong) CIDetector *detector;
@property (nonatomic) BOOL verbose;
- (id) init;
- (void) dealloc;
@end


@implementation OSXQRDetect
- (id) init {
    if ((self = [super init])) {
        self.detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
    }
    return self;
}
-(void) dealloc {
    if (self.verbose) NSLog(@"OSXQRDetect dealloc");
    self.detector = nil;
}
@end


// external interface
void *context_create(int verbose)
{
    OSXQRDetect *ret = [[OSXQRDetect alloc] init];
    ret.verbose = (BOOL)verbose;
    return (void *)CFBridgingRetain(ret);
}

void context_destroy(void *ctx)
{
    CFBridgingRelease(ctx);
}

// img must be 8-bit grayscale. returns 1 on success, 0 on no detection. If 1, detectionResult is valid.
int detect_qr(void *context, ///< pointer obtained by calling context_create()
              const void *img, ///< pointer to img buffer
              int width, int height, ///< x,y size in pixels
              int rowsize_bytes, ///< row length in bytes (should be >= width)
              struct DetectionResult *detectionResult)
{
    // returns YES IFF a is bigger than b in terms of area
    static BOOL (^is_bigger)(CIFeature *, CIFeature *) = ^BOOL(CIFeature *a, CIFeature *b)
    {
        const CGFloat area_a = a.bounds.size.height * a.bounds.size.width,
        area_b = b.bounds.size.height * b.bounds.size.width;
        return area_a > area_b;
    };

    int ret = 0;
    if (context && img && width > 0 && height > 0 && rowsize_bytes >= width && detectionResult) {
        OSXQRDetect *q = (__bridge OSXQRDetect *)context;
        memset(detectionResult, 0, sizeof(*detectionResult));
        NSData *imgdata = [NSData dataWithBytesNoCopy:(void *)img length:height*rowsize_bytes freeWhenDone:NO];
        CGSize size = CGSizeMake(width, height);
        CIImage *cimg = [CIImage imageWithBitmapData:imgdata
                                         bytesPerRow:rowsize_bytes
                                                size:size
                                              format:kCIFormatR8 colorSpace:nil];
        NSArray <CIFeature *> *features = [q.detector featuresInImage:cimg];
        CIFeature *candidate = nil;
        for (CIFeature *f in features) {
            if ([f.type isEqualToString:CIFeatureTypeQRCode]
                    && (!candidate || is_bigger(f, candidate)))
            {
                if (q.verbose)
                    NSLog(@"Feature %@ at %f,%f,%f,%f",f.type, f.bounds.origin.x, f.bounds.origin.y, f.bounds.size.width, f.bounds.size.height);
                // remember candidate
                candidate = f;
            }
        }
        if (candidate) {
            CIQRCodeFeature *qr = (CIQRCodeFeature *)candidate;
            struct DetectionResult *r = detectionResult;
            if (q.verbose)
                NSLog(@"Message: %@", qr.messageString);
            NSString *msg = qr.messageString;
            const NSUInteger lenBytes = [msg lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            // put detected string in results buffer
            memcpy(r->str, msg.UTF8String, MIN(lenBytes, sizeof(r->str)-1));
            r->topLeftX = qr.bounds.origin.x;
            r->topLeftY = qr.bounds.origin.y;
            r->width = qr.bounds.size.width;
            r->height = qr.bounds.size.height;
            ret = 1; // indicate a detection
        }
    }
    return ret;
}
