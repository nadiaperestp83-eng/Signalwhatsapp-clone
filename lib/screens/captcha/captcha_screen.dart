import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaScreen extends StatefulWidget {
  static String routeName = '/captcha';
  const CaptchaScreen({super.key});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  late final WebViewController _controller;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _carregando = true),
          onPageFinished: (_) => setState(() => _carregando = false),
          onNavigationRequest: (request) {
            // O Signal redireciona pra signalcaptcha://<token> quando resolvido.
            if (request.url.startsWith('signalcaptcha://')) {
              final token = request.url.replaceFirst('signalcaptcha://', '');
              Navigator.pop(context, token);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://signalcaptchas.org/registration/generate.html'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação de segurança')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_carregando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
