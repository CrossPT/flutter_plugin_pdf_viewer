#import "FlutterPluginPdfViewerPlugin.h"

static NSString* const kDirectory = @"FlutterPluginPdfViewer";
static NSString* const kOutputBaseName = @"page";
static NSString* const kFilePath = @"file:///";

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
    NSURL * sourcePDFUrl;
    if([url containsString:kFilePath]){
        sourcePDFUrl = [NSURL URLWithString:url];
    }else{
        sourcePDFUrl = [NSURL URLWithString:[kFilePath stringByAppendingString:url]];
    }
    CGPDFDocumentRef SourcePDFDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)sourcePDFUrl);
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(SourcePDFDocument);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathAndDirectory = [documentsDirectory stringByAppendingPathComponent:kDirectory];
    NSError *error;

    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
        return nil;
    }
    return [NSString stringWithFormat:@"%zd", numberOfPages];
}

-(NSString*)getPage:(NSString *)url ofPage:(size_t)pageNumber
{
    NSURL * sourcePDFUrl;
    if([url containsString:kFilePath]){
        sourcePDFUrl = [NSURL URLWithString:url];
    }else{
        sourcePDFUrl = [NSURL URLWithString:[kFilePath stringByAppendingString:url]];
    }
    CGPDFDocumentRef SourcePDFDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)sourcePDFUrl);
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(SourcePDFDocument);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathAndDirectory = [documentsDirectory stringByAppendingPathComponent:kDirectory];
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
    CGPDFPageRef SourcePDFPage = CGPDFDocumentGetPage(SourcePDFDocument, pageNumber);
    // CoreGraphics: MUST retain the Page-Reference manually
    CGPDFPageRetain(SourcePDFPage);
    NSString *relativeOutputFilePath = [NSString stringWithFormat:@"%@/%@%d.png", kDirectory, kOutputBaseName, (int)pageNumber];
    NSString *imageFilePath = [documentsDirectory stringByAppendingPathComponent:relativeOutputFilePath];
    CGRect sourceRect = CGPDFPageGetBoxRect(SourcePDFPage, kCGPDFMediaBox);
    CGFloat docRatio = sourceRect.size.width / sourceRect.size.height;
    int width = 2048;
    int height = (int) ceil(width/docRatio);
    UIGraphicsBeginPDFContextToFile(imageFilePath, sourceRect, nil);
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(currentContext, [UIColor whiteColor].CGColor);
    CGContextTranslateCTM(currentContext, 0.0, height);
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    CGContextDrawPDFPage (currentContext, SourcePDFPage); // draws the page in the graphics context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [UIImagePNGRepresentation(image) writeToFile: imageFilePath atomically:YES];
    return imageFilePath;
}

@end
