//
//  ViewController.m
//  DownloadMovieExample
//
//  Created by Miles Matthias on 10/3/13.
//  Copyright (c) 2013 Dojo4. All rights reserved.
//

#import "ViewController.h"
#import "AFURLSessionManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)downloadButtonTapped:(id)sender {
    NSURL* movieURL = [NSURL URLWithString:@"http://www.html5rocks.com/en/tutorials/video/basics/Chrome_ImF.mp4"];
    
    /*
     Both of the following work for the above URL.
     
     However, when I replace the above URL with the url of a .ismv file we have on S3, AFNetworking download does not work, 
        while NSURLSessionDownload does work.
     
     Here are curl -I's for each of the URLs (with our S3 .ismv url redacted):
     
     ○ → curl -I [redacted URL].ismv
     HTTP/1.1 200 OK
     x-amz-id-2: QJo4MYnMmNKjxxqBMfEQsJmOKNkVTKC1xUhYdPvVtGOEqhr4fkKgljCmUzGf6IaE
     x-amz-request-id: 08DFDF41205F9044
     Date: Thu, 03 Oct 2013 20:10:35 GMT
     Last-Modified: Tue, 21 May 2013 08:45:28 GMT
     ETag: "a9a5e55bb93b8131aed083f5070f90fb"
     Accept-Ranges: bytes
     Content-Type: application/octet-stream
     Content-Length: 796023314
     Server: AmazonS3
     
     
     ○ → curl -I http://www.html5rocks.com/en/tutorials/video/basics/Chrome_ImF.mp4
     HTTP/1.1 200 OK
     ETag: "b_WQIA"
     Content-Type: audio/mp4
     Date: Wed, 02 Oct 2013 14:05:12 GMT
     Expires: Fri, 01 Nov 2013 14:05:12 GMT
     Server: Google Frontend
     Cache-Control: public, max-age=2592000
     Age: 108339
     Transfer-Encoding: chunked
     Alternate-Protocol: 80:quic,80:quic
     
     */
    
    //[self afNetworkingDownloadForUrl:movieURL];
    [self nsURLSessionDownloadForUrl:movieURL];
}

- (void)nsURLSessionDownloadForUrl:(NSURL*)url {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask* downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void)afNetworkingDownloadForUrl:(NSURL*)url {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSLog(@"Got asked for the download destination.");
        NSURL *documentsDirectoryPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
        return [documentsDirectoryPath URLByAppendingPathComponent:[targetPath lastPathComponent]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@ with response = %@ and error = %@", filePath, response, error);
    }];
    
    [downloadTask resume];

}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [urls objectAtIndex:0];
    
    NSURL *originalUrl = [[downloadTask originalRequest] URL];
    NSURL *destinationUrl = [documentsDirectory URLByAppendingPathComponent:[originalUrl lastPathComponent]];
    NSError *error;
    
    [fileManager removeItemAtURL:destinationUrl error:NULL];
    BOOL success = [fileManager copyItemAtURL:location toURL:destinationUrl error:&error];
    NSLog(@"downloadTask didFinishDownloadingToURL = %@ with success = %hhd", [location absoluteString], success);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"downloadTask, didWriteData with totalBytesWritten = %lld and totalBytesExpectedToWrite = %lld", totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}


@end
