import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StatWebViewScreen extends StatefulWidget {
  final String url;
  
  const StatWebViewScreen({super.key, required this.url});

  @override
  State<StatWebViewScreen> createState() => _StatWebViewScreenState();
}

class _StatWebViewScreenState extends State<StatWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFCE000)),
              ),
          ],
        ),
      ),
    );
  }
}
