package pt.tribeiro.flutter_pdf_viewer;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterPdfViewerPlugin */
public class FlutterPdfViewerPlugin implements MethodCallHandler {
  private static Registrar instance;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_pdf_viewer");
    instance = registrar;
    channel.setMethodCallHandler(new FlutterPdfViewerPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Thread thread = new Thread(new Runnable() {
      @Override
      public void run() {
        switch (call.method) {
          case "getNumberOfPages":
            result.success(getNumberOfPages((String) call.argument("filePath")));
            break;
          case "getPage":
            result.success(getPagePreview((String) call.argument("filePath"), (int) call.argument("pageNumber")));
            break;
          default:
            result.notImplemented();
            break;
        }
      }
    });
    thread.start();
  }

private String getNumberOfPages(String filePath) {
  File pdf = new File(filePath);
 try {
   PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdf, ParcelFileDescriptor.MODE_READ_ONLY));
   Bitmap bitmap;
   final int pageCount = renderer.getPageCount();
   return String.format("%d", pageCount);
   } catch (Exception ex) {
   ex.printStackTrace();
 }
 return null;
}

    private String createTempPreview(Bitmap bmp, String name, int page){
        String filePath = name.substring(name.lastIndexOf('/') + 1);
        filePath = name.substring(name.lastIndexOf('.'));
        File file;
        try {
            String fileName = String.format("%s-%d.png", filePath, page);
            file = File.createTempFile(fileName, null, instance.context().getCacheDir());
            FileOutputStream out = new FileOutputStream(file);
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out);
            out.flush();
            out.close();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
        return file.getAbsolutePath();
    }


private String getPage(String filePath, int pageNumber) {
  File pdf = new File(filePath);
  try {
    PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdf, ParcelFileDescriptor.MODE_READ_ONLY));
    Bitmap bitmap;
    final int pageCount = renderer.getPageCount();
    if(pageNumber > pageCount) {
      pageNumber = pageCount;
    }

      PdfRenderer.Page page = renderer.openPage(pageNumber);

      double width = instance.activity().getResources().getDisplayMetrics().densityDpi  * page.getWidth();
      double height = instance.activity().getResources().getDisplayMetrics().densityDpi  * page.getHeight();
      final double docRatio = width / height;

      width = 2048;
      height = (int)(width / docRatio);

      bitmap = Bitmap.createBitmap((int)width, (int)height, Bitmap.Config.ARGB_8888);

      page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);

      try {
        return createTempPreview(bitmap, fileName , pageNumber);
      }finally {
        // close the page
        page.close();
        // close the renderer
        renderer.close();
      }
  } catch (Exception ex) {
    ex.printStackTrace();
  }

  return null;
}

}
