import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.payment});

  final PaymentStart payment;

  static Future<bool?> open(BuildContext context, PaymentStart payment) =>
      Navigator.of(context).push<bool>(MaterialPageRoute(builder: (context) => PaymentScreen(payment: payment)));

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final returnPath = Uri.parse(widget.payment.returnUrl).path;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onNavigationRequest: (request) {
            if (Uri.parse(request.url).path != returnPath) return NavigationDecision.navigate;
            Navigator.of(context).pop(true);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payment.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100) LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100),
        ],
      ),
    );
  }
}
