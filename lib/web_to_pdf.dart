import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';

class WebToPdf extends StatefulWidget {
  @override
  _WebToPdfState createState() => _WebToPdfState();
}

class _WebToPdfState extends State<WebToPdf> {
  WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse('https://flutter.dev'));
  final ScreenshotController screenshotController = ScreenshotController();
  bool hasBottomReached = false;
  bool buttonDisable = false;
  bool loading = false;

  void scrollToTop() {
    buttonDisable = false;
    setState(() {});
    _controller.runJavaScript("window.scrollTo({top: 0, behavior: 'smooth'});");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Screenshot'),
        actions: [
          IconButton(
              onPressed: () {
                _controller.reload();
              },
              icon: Icon(Icons.restart_alt)),
          IconButton(
              onPressed: scrollToTop,
              icon: Icon(
                Icons.arrow_circle_up_outlined,
                color: loading ? Colors.grey : Colors.black,
              )),
          IconButton(
              onPressed: buttonDisable || loading ? () {} : _scrollAndCapture,
              icon: Icon(
                Icons.arrow_circle_down_outlined,
                color: buttonDisable || loading ? Colors.grey : Colors.black,
              )),
        ],
      ),
      body: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
          loading
              ? Center(
                  child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue,
                            backgroundColor: Colors.black,
                          ),
                          Text('pdf is downloading, please wait ')
                        ],
                      )),
                )
              : SizedBox.shrink()
        ],
      ),
    );
  }

  Future<bool> isImagesBoxEmpty() async {
    final box = await openImagesBox();
    return box.isEmpty;
  }

  Future<void> convertImageToPdf() async {
    setState(() {
      loading = true;
    });
    final pdf = pw.Document();
    var box = await openImagesBox();
    final images = box.values.toList();
    if (box.isNotEmpty) {
      for (var image in images) {
        final imageProvider = pw.MemoryImage(image);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) =>
                pw.Center(child: pw.Image(imageProvider)),
          ),
        );
      }

      Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/webview_screenshot.pdf');
      await file.writeAsBytes(await pdf.save());
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Open pdf',
            onPressed: () {
              OpenFile.open(file.path);
            },
          )));

      await box.clear();
      scrollToTop();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image List is empty')));
    }
  }

  void _scrollAndCapture() async {
    buttonDisable = true;
    hasBottomReached = false; // Reset the flag
    setState(() {});

    while (!hasBottomReached) {
      // Scroll down and capture the screenshot
      await _scrollToBottom();
    }

    // After capturing all screenshots, enable the button again
    setState(() {
      buttonDisable = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Reached bottom of the content. All screenshots captured.')),
    );

    convertImageToPdf();
  }

  Future<void> _scrollToBottom() async {
    int durationInMs = 500;
   /* String jsScrollDown = """(function() {
      var viewportHeight = window.innerHeight;
      var scrollPosition = window.scrollY;
      window.scrollTo(0, scrollPosition + viewportHeight);
      return (window.innerHeight + window.scrollY) >= document.body.scrollHeight;
    })();""";*/
    String jsScrollDown =  """
    (function() {
      var viewportHeight = window.innerHeight;
      var scrollPosition = window.scrollY;
      var targetPosition = scrollPosition + viewportHeight;
      var startTime = null;

      function scrollStep(timestamp) {
        if (startTime === null) startTime = timestamp;
        var progress = timestamp - startTime;
        var proportion = Math.min(progress / $durationInMs, 1);

        window.scrollTo(0, scrollPosition + proportion * (targetPosition - scrollPosition));

        if (proportion < 1) {
          window.requestAnimationFrame(scrollStep);
        }
      }

      window.requestAnimationFrame(scrollStep);

      return (window.innerHeight + window.scrollY) >= document.body.scrollHeight;
    })();""";

    // Execute JavaScript to scroll down and check if the bottom is reached
    Object result =
        await _controller.runJavaScriptReturningResult(jsScrollDown);

    // The result will be "true" or "false", convert to boolean
    hasBottomReached = result == true;

    // Capture the screenshot if the bottom is not reached
    if (!hasBottomReached) {
      Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final box = await openImagesBox();
        box.add(imageBytes);
      }
    }
  }

  Future<Box<Uint8List>> openImagesBox() async {
    return await Hive.openBox<Uint8List>('imagesBox');
  }

}
