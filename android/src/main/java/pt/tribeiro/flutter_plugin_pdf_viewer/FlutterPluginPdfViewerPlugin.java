package pt.tribeiro.flutter_plugin_pdf_viewer;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.pdf.PdfRenderer;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FilenameFilter;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.os.HandlerThread;
import android.os.Process;
import android.os.Handler;

/**
 * FlutterPluginPdfViewerPlugin
 */
public class FlutterPluginPdfViewerPlugin implements MethodCallHandler {
    private static Registrar instance;
    private HandlerThread handlerThread;
    private Handler backgroundHandler;
    private final Object pluginLocker = new Object();
    private final String filePrefix = "FlutterPluginPdfViewer";

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_plugin_pdf_viewer");
        instance = registrar;
        channel.setMethodCallHandler(new FlutterPluginPdfViewerPlugin());
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        synchronized (pluginLocker) {
            if (backgroundHandler == null) {
                handlerThread = new HandlerThread("flutterPdfViewer", Process.THREAD_PRIORITY_BACKGROUND);
                handlerThread.start();
                backgroundHandler = new Handler(handlerThread.getLooper());
            }
        }
        final Handler mainThreadHandler = new Handler();
        backgroundHandler.post(//
                new Runnable() {
                    @Override
                    public void run() {
                        switch (call.method) {
                        case "getNumberOfPages":
                            final String numResult = getNumberOfPages((String) call.argument("filePath"));
                            mainThreadHandler.post(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(numResult);
                                }
                            });
                            break;
                        case "getPage":
                            final String pageResult = getPage((String) call.argument("filePath"),
                                    (int) call.argument("pageNumber"));
                            mainThreadHandler.post(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(pageResult);
                                }
                            });
                            break;
                        default:
                            result.notImplemented();
                            break;
                        }
                    }
                });
    }

    private String getNumberOfPages(String filePath) {
        File pdf = new File(filePath);
        try {
            clearCacheDir();
            PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdf, ParcelFileDescriptor.MODE_READ_ONLY));
            Bitmap bitmap;
            final int pageCount = renderer.getPageCount();
            return String.format("%d", pageCount);
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }

    private boolean clearCacheDir() {
        try {
            File directory = instance.context().getCacheDir();
            FilenameFilter myFilter = new FilenameFilter() {
                @Override
                public boolean accept(File dir, String name) {
                    return name.toLowerCase().startsWith(filePrefix.toLowerCase());
                }
            };
            File[] files = directory.listFiles(myFilter);
            // Log.d("Cache Files", "Size: " + files.length);
            for (int i = 0; i < files.length; i++) {
                // Log.d("Files", "FileName: " + files[i].getName());
                files[i].delete();
            }
            return true;
        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }

    private String getFileNameFromPath(String name) {
        String filePath = name.substring(name.lastIndexOf('/') + 1);
        filePath = filePath.substring(0, filePath.lastIndexOf('.'));
        return String.format("%s-%s", filePrefix, filePath);
    }

    private String createTempPreview(Bitmap bmp, String name, int page) {
        String fileNameOnly = getFileNameFromPath(name);
        File file;
        try {
            String fileName = String.format("%s-%d.png", fileNameOnly, page);
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
            final int pageCount = renderer.getPageCount();
            if (pageNumber > pageCount) {
                pageNumber = pageCount;
            }

            PdfRenderer.Page page = renderer.openPage(--pageNumber);

            double width = instance.activity().getResources().getDisplayMetrics().densityDpi * page.getWidth();
            double height = instance.activity().getResources().getDisplayMetrics().densityDpi * page.getHeight();
            final double docRatio = width / height;

            width = 2048;
            height = (int) (width / docRatio);
            Bitmap bitmap = Bitmap.createBitmap((int) width, (int) height, Bitmap.Config.ARGB_8888);
            // Change background to white
            Canvas canvas = new Canvas(bitmap);
            canvas.drawColor(Color.WHITE);
            // Render to bitmap
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
            try {
                return createTempPreview(bitmap, filePath, pageNumber);
            } finally {
                // close the page
                page.close();
                // close the renderer
                renderer.close();
            }
        } catch (Exception ex) {
            System.out.println(ex.getMessage());
            ex.printStackTrace();
        }

        return null;
    }
}
