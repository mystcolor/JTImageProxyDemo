/*
 * This file is part of the JTImageProxy package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "JTImageProxy.h"

NSString *const JTImageProxyProgressDidUpdateNotification = @"JTImageProxyProgressDidUpdateNotification";

@interface JTImageProxy () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation JTImageProxy
@synthesize URL, image, expectedContentLength, totalDownloadedSize, data, error, connection;

- (id)init {
    self.data = [NSMutableData data];
    return self;
}

#pragma mark Instance method

- (void)restartDownload {
    self.image = nil;
    self.data = [NSMutableData data];
    self.totalDownloadedSize = 0;
    self.expectedContentLength = 0;
    [self.connection cancel];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark Properties

- (void)setURL:(NSURL *)aURL {
    URL = aURL;
    [self restartDownload];
}

- (CGFloat)progress {
    return self.totalDownloadedSize/self.expectedContentLength;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError {
    self.error = anError;
    NSLog(@"error %@", self.error);
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self willChangeValueForKey:@"progress"];

    self.expectedContentLength = [response expectedContentLength];
    NSLog(@"expectedContentLength %f", self.expectedContentLength);
    
    [self didChangeValueForKey:@"progress"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData {
    [self willChangeValueForKey:@"progress"];
    self.totalDownloadedSize += [someData length];
    [self.data appendData:someData];
    
    NSLog(@"totalDownloadedSize %f", self.totalDownloadedSize);
    if (self.totalDownloadedSize == self.expectedContentLength) {
        return; // Wait until connection Did finished loading
    }
    
    
    [self didChangeValueForKey:@"progress"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    self.image = [UIImage imageWithData:self.data];
    NSLog(@"finishedImage %@", self.image);
    [self didChangeValueForKey:@"progress"];
}

#pragma mark NSProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.image methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.image];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.image respondsToSelector:aSelector]) {
        return YES;
    }
    return [[self class] instancesRespondToSelector:aSelector];
}

//+ (BOOL)instancesRespondToSelector:(SEL)aSelector {
//    if ([UIImage instancesRespondToSelector:aSelector]) {
//        return YES;
//    }
//    return NO;
//}

- (BOOL)isProxy {
    return YES;
}

#pragma mark Class method

+ (JTImageProxy *)proxyWithURL:(NSURL *)URL {
    JTImageProxy *proxy = [[JTImageProxy alloc] init];
    proxy.URL = URL;
    return proxy;
}

@end
