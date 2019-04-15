#import "FlutterPluginPdfViewerPlugin.h"

static NSString* const pluginDirectory = @"FlutterPluginPdfViewer";
static NSString* const filePath = @"file:///";
static NSString* fileName = @"";

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
              result([self getPage:filePath page:pageNumber]);
          } else if ([@"getpageCount" isEqualToString:call.method]) {
              NSString * filePath = call.arguments[@"filePath"];
              result([self getpageCount:filePath]);
          }
          else {
              NSLog(@"[FlutterPluginPDFViewer] Trying to call an unknown method");
              result(FlutterMethodNotImplemented);
          }
      });
}

-(NSString *)getpageCount:(NSString *)url
{
    NSURL * pdfPathUrl;
    // CGPDFDocumentCreateWithURL requires file:/// to be loaded
    if([url containsString:filePath]){
        pdfPathUrl = [NSURL URLWithString:url];
    }else{
        pdfPathUrl = [NSURL URLWithString:[filePath stringByAppendingString:url]];
    }
    CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfPathUrl);
    size_t pageCount = CGPDFDocumentGetpageCount(pdfDoc);
    NSArray *getPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [getPath objectAtIndex:0];
    NSString *saveDirectory = [documentsDirectory stringByAppendingPathComponent:pluginDirectory];
    NSError *error;

    // Clear cache folder
    if ([[NSFileManager defaultManager] fileExistsAtPath:saveDirectory]) {
        NSLog(@"[FlutterPluginPDFViewer] Removing old documents cache");
        [[NSFileManager defaultManager] removeItemAtPath:saveDirectory error:&error];
    }

    if (![[NSFileManager defaultManager] createDirectoryAtPath:saveDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"[FlutterPluginPDFViewer] Creating save directory returned error: %@", error);
        return nil;
    }
    // Generate random file size for document, will be used later when saving images into memory
    fileName = [[NSUUID UUID] UUIDString];
    NSLog(@"[FlutterPluginPdfViewer] File has %zd pages", pageCount);
    return [NSString stringWithFormat:@"%zd", pageCount];
}

-(NSString*)getPage:(NSString *)url page:(size_t)pageNumber
{
    NSURL * pdfPathUrl;
    if([url containsString:filePath]){
        pdfPathUrl = [NSURL URLWithString:url];
    }else{
        pdfPathUrl = [NSURL URLWithString:[filePath stringByAppendingString:url]];
    }
    CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfPathUrl);
    size_t pageCount = CGPDFDocumentGetpageCount(pdfDoc);
    NSArray *getPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [getPath objectAtIndex:0];
    NSString *saveDirectory = [documentsDirectory stringByAppendingPathComponent:pluginDirectory];
    NSError *error;

    // Prevent user to load a page higher then the total
    if (pageNumber > pageCount) {
        pageNumber = pageCount;
    }

    if (![[NSFileManager defaultManager] createDirectoryAtPath:saveDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"[FlutterPluginPDFViewer] Creating save directory returned error: %@", error);
        return nil;
    }
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDoc, pageNumber);
    CGPDFPageRetain(pdfPage);
    NSString *saveFile = [NSString stringWithFormat:@"%@/%@-%d.png", pluginDirectory, fileName, (int)pageNumber];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:saveFile];
    // Create a rect from PDF
    CGRect rect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    UIGraphicsBeginPDFContextToFile(filePath, rect, nil);
    // Change DPI to 300
    CGFloat dpi = 300.0 / 72.0;
    CGFloat width = rect.size.width * dpi;
    CGFloat height = rect.size.height * dpi;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
        // Fill background with white color
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(currentContext, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(currentContext, CGContextGetClipBoundingBox(currentContext));
    // Change interpolation settings
    CGContextSetInterpolationQuality(currentContext, kCGInterpolationHigh);
    CGContextTranslateCTM(currentContext, 0.0, height);
    // Scale
    CGContextScaleCTM(currentContext, dpi, -dpi);
    CGContextSaveGState(currentContext);
    // Draw the page on the context
    CGContextDrawPDFPage (currentContext, pdfPage);
    CGContextRestoreGState(currentContext);
    // Get generated image and load in file
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [UIImagePNGRepresentation(image) writeToFile: filePath atomically:YES];
    return filePath;
}

@end
