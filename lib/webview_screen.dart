import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DojahKYC {
  final String appId;
  final String publicKey;
  final String type;
  final int? amount;
  final String? referenceId;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? metaData;
  final Map<String, dynamic>? govData;
  final Map<String, dynamic>? govId;
  final Map<String, dynamic>? config;
  final Function(dynamic)? onCloseCallback;

  DojahKYC({
    required this.appId,
    required this.publicKey,
    required this.type,
    this.userData,
    this.config,
    this.metaData,
    this.govData,
    this.govId,
    this.amount,
    this.referenceId,
    this.onCloseCallback,
  });

  Future<void> open(BuildContext context,
      {Function(dynamic result)? onSuccess,
      Function(dynamic close)? onClose,
      Function(dynamic error)? onError}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebviewScreen(
          appId: appId,
          publicKey: publicKey,
          type: type,
          userData: userData,
          metaData: metaData,
          govData: govData,
          govId: govId,
          config: config,
          amount: amount,
          referenceId: referenceId,
          success: (result) {
            onSuccess?.call(result);
          },
          close: (close) {
            onClose?.call(close);
          },
          error: (error) {
            onError?.call(error);
          },
        ),
      ),
    );
  }
}

class WebviewScreen extends StatefulWidget {
  final String appId;
  final String publicKey;
  final String type;
  final int? amount;
  final String? referenceId;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? metaData;
  final Map<String, dynamic>? govData;
  final Map<String, dynamic>? govId;
  final Map<String, dynamic>? config;
  final Function(dynamic) success;
  final Function(dynamic) error;
  final Function(dynamic) close;

  const WebviewScreen({
    Key? key,
    required this.appId,
    required this.publicKey,
    required this.type,
    this.userData,
    this.metaData,
    this.govData,
    this.govId,
    this.config,
    this.amount,
    this.referenceId,
    required this.success,
    required this.error,
    required this.close,
  }) : super(key: key);

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late WebViewController _webViewController;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'onSuccessCallback',
        onMessageReceived: (JavaScriptMessage message) {
          widget.success(jsonDecode(message.message));
        },
      )
      ..addJavaScriptChannel(
        'onErrorCallback',
        onMessageReceived: (JavaScriptMessage message) {
          widget.error(jsonDecode(message.message));
        },
      )
      ..addJavaScriptChannel(
        'onCloseCallback',
        onMessageReceived: (JavaScriptMessage message) {
          widget.close(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              progress = 0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              progress = 1;
            });
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.description}')),
            );
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1, maximum-scale=1, minimum-scale=1, shrink-to-fit=no"/>
        <title>Dojah Inc.</title>
      </head>
      <body>
        <script src="https://widget.dojah.io/widget.js"></script>
        <script>
          const options = {
            app_id: "${widget.appId}",
            p_key: "${widget.publicKey}",
            type: "${widget.type}",
            reference_id: "${widget.referenceId}",
            config: ${jsonEncode(widget.config ?? {})},
            user_data: ${jsonEncode(widget.userData ?? {})},
            gov_data: ${jsonEncode(widget.govData ?? {})},
            gov_id: ${jsonEncode(widget.govId ?? {})},
            metadata: ${jsonEncode(widget.metaData ?? {})},
            onSuccess: function (response) {
              onSuccessCallback.postMessage(JSON.stringify(response));
            },
            onError: function (error) {
              onErrorCallback.postMessage(JSON.stringify(error));
            },
            onClose: function () {
              onCloseCallback.postMessage('close');
            }
          };

          const connect = new Connect(options);
          connect.setup();
          connect.open();
        </script>
      </body>
    </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dojah Verification'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (progress < 1)
            LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}