//
//  OSXQRDetect.h
//  OSXQRDetect
//
//  Created by Calin Culianu <calin.culianu@gmail.com> on 5/23/19.
//  Copyright © 2019 electroncash.org. MIT License.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CIDetector.h>
#include <stdint.h>

@interface OSXQRDetect : NSObject
@property (nonatomic, strong) CIDetector *detector;
@property (nonatomic) BOOL verbose;
- (id) init;
- (void) dealloc;
@end


/* External interface to this library - For now it's barebones simple for our Electron
Cash QR reader to simply operate. */

// returned value will actually be an OSXQRDetect object
extern void *context_create(int verbose);
// pass the context created in context_create
extern void context_destroy(void *ctx);

struct DetectionResult {
    double topLeftX, topLeftY; ///< note these are in pixels, despite being a double
    double width, height; ///< pixels
    char str[4096]; ///< detection result is UTF8 encoded, always NUL terminated
};

// img must be 8-bit grayscale. returns 1 on success, 0 on no detection. If 1, detectionResult is valid.
extern int detect_qr(void *context, ///< pointer obtained by calling context_create()
                     const void *img, ///< pointer to img buffer
                     int width, int height, ///< x,y size in pixels
                     int rowsize_bytes, ///< row length in bytes (should be >= width)
                     struct DetectionResult *detectionResult);
