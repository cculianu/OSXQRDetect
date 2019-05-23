//
//  OSXQRDetect.h
//  OSXQRDetect
//
//  Created by Calin Culianu <calin.culianu@gmail.com> on 5/23/19.
//  Copyright © 2019 electroncash.org. MIT License.
//

/*
 OSX QR Detection. A barebone QR detection library that uses native macOS
 calls for Electron Cash.

 External interface to this library is below. Intented to be called using ctypes.
*/

/* Create a context. Object. returned value will actually be an OSXQRDetect obj-c object */
extern void *context_create(int verbose);
/* Deallocate a context. Pass the context object created in context_create */
extern void context_destroy(void *ctx);

struct DetectionResult {
    /// Result detection rectangle.
    /// Note these are in pixels, despite being a double
    double topLeftX,
           topLeftY,
           width,
           height;
    /// Detection result string eg 'bitcoincash:bla'.
    /// This field is UTF8 encoded, and always has a terminating NUL byte
    char str[4096];
};

/// img must be 8-bit grayscale. returns 1 on success, 0 on no detection.
/// If 1, detectionResult struct is filled-in and will be valid.
extern int detect_qr(void *context, ///< pointer obtained by calling context_create()
                     const void *img, ///< pointer to img buffer data (8 bit grayscale)
                     int width, int height, ///< x,y size of img in pixels
                     int rowsize_bytes, ///< row length in bytes (should be >= width)
                     struct DetectionResult *detectionResult);
