import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/locale_service.dart';

class StatWebViewScreen extends StatefulWidget {
  final String url;
  
  const StatWebViewScreen({super.key, required this.url});

  @override
  State<StatWebViewScreen> createState() => _StatWebViewScreenState();
}

class _StatWebViewScreenState extends State<StatWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else {
      _isLoading = false;
      // На Web открываем ссылку во вкладке браузера
      WidgetsBinding.instance.addPostFrameCallback((_) {
        launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_controller != null && await _controller!.canGoBack()) {
          _controller!.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(LocaleService().tr('regCardBtn')),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (_controller != null)
                WebViewWidget(controller: _controller!)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.open_in_browser, size: 56, color: Color(0xFFFCE000)),
                        const SizedBox(height: 16),
                        const Text(
                          "Официальная анкета открыта во вкладке браузера",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCE000),
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Открыть анкету снова"),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFCE000)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
