package pt.tribeiro.flutter_plugin_pdf_viewer;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.pdf.PdfRenderer;
import android.os.Process;
import android.os.*;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.util.Locale;

/**
 * FlutterPluginPdfViewerPlugin
 */
public class FlutterPluginPdfViewerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private static final String TAG = "PdfViewerPlugin";

    private Handler backgroundHandler;
    private final Object pluginLocker = new Object();
    private final String filePrefix = "FlutterPluginPdfViewer";

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context context;
    private Activity activity;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_plugin_pdf_viewer");
        channel.setMethodCallHandler(this);
        context = binding.getApplicationContext();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {
        synchronized (pluginLocker) {
            if (backgroundHandler == null) {
                HandlerThread handlerThread = new HandlerThread("flutterPdfViewer", Process.THREAD_PRIORITY_BACKGROUND);
                handlerThread.start();
                backgroundHandler = new Handler(handlerThread.getLooper());
            }
        }
        final Handler mainThreadHandler = new Handler(Looper.myLooper());
        backgroundHandler.post(
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
                                Integer pageNumber = call.<Integer>argument("pageNumber");
                                final String pageResult = getPage((String) call.argument("filePath"), pageNumber);
                                if (pageResult == null) {
                                    Log.d(TAG, "Retrieving page failed.");
                                    result.notImplemented();
                                }else {
                                    mainThreadHandler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.success(pageResult);
                                        }
                                    });
                                }
                                break;
                            default:
                                result.notImplemented();
                                break;
                        }
                    }
                }
        );
    }

    private String getNumberOfPages(String filePath) {
        try (PdfRenderer renderer = new PdfRenderer(getPdfFile(filePath))) {
            final int pageCount = renderer.getPageCount();
            if (!clearCacheDir()) {
                Log.d("NumPages", "getNumberOfPages: failed to clean cache.");
            }
            return String.format(Locale.US, "%d", pageCount);
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }

    private ParcelFileDescriptor getPdfFile(String filePath) throws FileNotFoundException {
        File pdfFile = new File(filePath);
        if (!pdfFile.canRead()) {
            Log.d(TAG, "getPdfFile: Can't read file: " + filePath);
        }
        return ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY);
    }

    private boolean clearCacheDir() {
        try {
            File directory = context.getCacheDir();
            FilenameFilter myFilter = new FilenameFilter() {
                @Override
                public boolean accept(File dir, String name) {
                    return name.toLowerCase().startsWith(filePrefix.toLowerCase());
                }
            };
            File[] files = directory.listFiles(myFilter);
            // Log.d("Cache Files", "Size: " + files.length);
            for (File file : files != null ? files : new File[0]) {
                if (!file.delete()) {
                    Log.d("Cache files", String.format("Deleting file %s failed.", file.getName()));
                }
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
     if (context == null) {
            Log.d(TAG, "createTempPreview: Context is null!");
            return null;
        }
        String fileNameOnly = getFileNameFromPath(name);
        File file;
        File to;
        try {
            String fileName = String.format(Locale.US, "%s-%d.png", fileNameOnly, page);
            file = File.createTempFile(fileName, null, context.getCacheDir());
            FileOutputStream out = new FileOutputStream(file);
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out);
            out.flush();
            out.close();
            //what you are renaming the file to
            to = new File(context.getCacheDir(), fileName);
//            //now rename
            file.renameTo(to);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
        return to.getAbsolutePath();
    }

    private String getPage(String filePath, @Nullable Integer pageNumber) {
        try (PdfRenderer renderer = new PdfRenderer(getPdfFile(filePath))) {
            final int pageCount = renderer.getPageCount();
            if (pageNumber == null || pageNumber > pageCount) {
                pageNumber = pageCount;
            }

            PdfRenderer.Page page = renderer.openPage(--pageNumber);

            final int densityDpi = activity.getResources().getDisplayMetrics().densityDpi;
            double width = densityDpi * page.getWidth();
            double height = densityDpi * page.getHeight();
            final double docRatio = width / height;

            width = 2048;
            height = (int) (width / docRatio);
            Bitmap bitmap = Bitmap.createBitmap((int) width, (int) height, Bitmap.Config.ARGB_8888);
            // Change background to white
            Canvas canvas = new Canvas(bitmap);
            canvas.drawColor(Color.WHITE);
            // Render to bitmap
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
            String ret;
            try {
                ret = createTempPreview(bitmap, filePath, pageNumber);
            } finally {
                page.close();
            }
            return ret;
        } catch (Exception ex) {
            System.out.println(ex.getMessage());
            ex.printStackTrace();
        }
        return null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
}
