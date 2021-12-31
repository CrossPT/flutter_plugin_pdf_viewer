#import "FlutterPluginPdfViewerPlugin.h"

static NSString* const kDirectory = @"FlutterPluginPdfViewer";
static NSString* kFileName = @"";

@implementation FlutterPluginPdfViewerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_plugin_pdf_viewer"
            binaryMessenger:[registrar messenger]];
  FlutterPluginPdfViewerPlugin* instance = [[FlutterPluginPdfViewerPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          if ([@"getPage" isEqualToString:call.method]) {
              size_t pageNumber = (size_t)[call.arguments[@"pageNumber"] intValue];
              NSString * filePath = call.arguments[@"filePath"];
              result([self getPage:filePath ofPage:pageNumber]);
          } else if ([@"getNumberOfPages" isEqualToString:call.method]) {
              NSString * filePath = call.arguments[@"filePath"];
              result([self getNumberOfPages:filePath]);
          }
          else {
              result(FlutterMethodNotImplemented);
          }
      });
}

-(NSString *)getNumberOfPages:(NSString *)url
{
    NSURL * sourcePDFUrl = [[NSURL alloc] initFileURLWithPath:url];
    CGPDFDocumentRef sourcePDFDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)sourcePDFUrl);
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(sourcePDFDocument);
    CGPDFDocumentRelease(sourcePDFDocument);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *temporaryDirectory = [paths objectAtIndex:0];
    NSString *filePathAndDirectory = [temporaryDirectory stringByAppendingPathComponent:kDirectory];
    NSError *error;

    // Clear cache folder
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathAndDirectory]) {
        NSLog(@"[FlutterPluginPDFViewer] Removing old documents cache");
        [[NSFileManager defaultManager] removeItemAtPath:filePathAndDirectory error:&error];
    }

    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
        return nil;
    }
    // Generate random file size for this document

    kFileName = [[NSUUID UUID] UUIDString];
    NSLog(@"[FlutterPluginPdfViewer] File has %zd pages", numberOfPages);
    return [NSString stringWithFormat:@"%zd", numberOfPages];
}

-(NSString*)getPage:(NSString *)url ofPage:(size_t)pageNumber
{
    NSURL * sourcePDFUrl = [[NSURL alloc] initFileURLWithPath:url];
    CGPDFDocumentRef sourcePDFDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)sourcePDFUrl);
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(sourcePDFDocument);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *temporaryDirectory = [paths objectAtIndex:0];
    NSString *filePathAndDirectory = [temporaryDirectory stringByAppendingPathComponent:kDirectory];
    NSError *error;

    if (pageNumber > numberOfPages) {
        pageNumber = numberOfPages;
    }

    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
        return nil;
    }
    CGPDFPageRef sourcePDFPage = CGPDFDocumentGetPage(sourcePDFDocument, pageNumber);
    CGPDFPageRetain(sourcePDFPage);
    NSString *relativeOutputFilePath = [NSString stringWithFormat:@"%@/%@-%d.png", kDirectory, kFileName, (int)pageNumber];
    NSString *imageFilePath = [temporaryDirectory stringByAppendingPathComponent:relativeOutputFilePath];
    CGRect sourceRect = CGPDFPageGetBoxRect(sourcePDFPage, kCGPDFMediaBox);
    UIGraphicsBeginPDFContextToFile(imageFilePath, sourceRect, nil);
    // Calculate resolution
    // Set DPI to 300
    CGFloat dpi = 300.0 / 72.0;
    CGFloat width = sourceRect.size.width * dpi;
    CGFloat height = sourceRect.size.height * dpi;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    // Fill Background
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    // Change interpolation settings
    CGContextSetInterpolationQuality(currentContext, kCGInterpolationHigh);
    // Fill background with white color
    CGContextSetRGBFillColor(currentContext, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(currentContext, CGContextGetClipBoundingBox(currentContext));
    CGContextTranslateCTM(currentContext, 0.0, height);
    CGContextScaleCTM(currentContext, dpi, -dpi);
    CGContextSaveGState(currentContext);
    CGContextDrawPDFPage (currentContext, sourcePDFPage);
    CGContextRestoreGState(currentContext);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [UIImagePNGRepresentation(image) writeToFile: imageFilePath atomically:YES];
    CGPDFPageRelease(sourcePDFPage);
    CGPDFDocumentRelease(sourcePDFDocument);
    return imageFilePath;
}

@end
