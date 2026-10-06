import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/weather/application/weather_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  WebViewController? _controller;
  String? _loadedUrl;

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('رادار بارش')),
      body: weather.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (data) {
          final url =
              'https://www.rainviewer.com/map.html?loc=${data.latitude},${data.longitude},7&oFa=0&oC=1&oU=0&oCS=1&oF=0&oAP=1&c=3&o=83&lm=1&layer=radar&sm=1&sn=1';
          if (_controller == null || _loadedUrl != url) {
            _loadedUrl = url;
            _controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(Theme.of(context).colorScheme.surface)
              ..loadRequest(Uri.parse(url));
          }
          return WebViewWidget(controller: _controller!);
        },
      ),
    );
  }
}
