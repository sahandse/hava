import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/weather/application/weather_controller.dart';
import 'package:latlong2/latlong.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final _mapController = MapController();
  final _dio = Dio();

  List<_RadarFrame> _frames = const [];
  String? _host;
  int _frameIndex = 0;
  bool _loading = true;
  bool _playing = false;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRadar();
  }

  Future<void> _loadRadar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.rainviewer.com/public/weather-maps.json',
      );

      final data = response.data;
      if (data == null) {
        throw StateError('اطلاعات رادار دریافت نشد.');
      }

      final host = data['host'] as String?;
      final radar = data['radar'] as Map<String, dynamic>?;
      final past = radar?['past'] as List<dynamic>? ?? const [];

      final frames = past.map((item) {
        final map = item as Map<String, dynamic>;
        return _RadarFrame(
          time: DateTime.fromMillisecondsSinceEpoch(
            (map['time'] as num).toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          path: map['path'] as String,
        );
      }).toList();

      if (host == null || frames.isEmpty) {
        throw StateError('برای این لحظه فریم رادار موجود نیست.');
      }

      if (!mounted) return;
      setState(() {
        _host = host;
        _frames = frames;
        _frameIndex = frames.length - 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _togglePlayback() {
    if (_frames.length < 2) return;

    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }

    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!mounted || _frames.isEmpty) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رادار بارش'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی رادار',
            onPressed: _loadRadar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: weather.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RadarError(
          message: error.toString(),
          onRetry: () => ref.invalidate(weatherProvider),
        ),
        data: (weatherData) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null || _frames.isEmpty || _host == null) {
            return _RadarError(
              message: _error?.toString() ?? 'فریم رادار موجود نیست.',
              onRetry: _loadRadar,
            );
          }

          final center = LatLng(
            weatherData.latitude,
            weatherData.longitude,
          );
          final frame = _frames[_frameIndex];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 6.5,
                  minZoom: 3,
                  maxZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sahand.hava',
                    maxNativeZoom: 19,
                  ),
                  TileLayer(
                    key: ValueKey(frame.path),
                    urlTemplate:
                        '$_host${frame.path}/256/{z}/{x}/{y}/2/1_1.png',
                    userAgentPackageName: 'com.sahand.hava',
                    maxNativeZoom: 7,
                    maxZoom: 12,
                    tileDisplay: const TileDisplay.fadeIn(),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 46,
                        height: 46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                color: Color(0x33000000),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                left: 12,
                child: _RadarStatusCard(
                  frame: frame,
                  frameIndex: _frameIndex,
                  frameCount: _frames.length,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 132,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'radar_location',
                      onPressed: () => _mapController.move(center, 6.5),
                      child: const Icon(Icons.my_location_rounded),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'radar_zoom_in',
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'radar_zoom_out',
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                      child: const Icon(Icons.remove_rounded),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                left: 12,
                bottom: 18,
                child: _RadarTimeline(
                  frames: _frames,
                  currentIndex: _frameIndex,
                  playing: _playing,
                  onPlayPause: _togglePlayback,
                  onChanged: (value) {
                    setState(() => _frameIndex = value.round());
                  },
                ),
              ),
              Positioned(
                left: 10,
                bottom: 2,
                child: Text(
                  'نقشه: OpenStreetMap • رادار: RainViewer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .65),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RadarStatusCard extends StatelessWidget {
  const _RadarStatusCard({
    required this.frame,
    required this.frameIndex,
    required this.frameCount,
  });

  final _RadarFrame frame;
  final int frameIndex;
  final int frameCount;

  @override
  Widget build(BuildContext context) {
    final hour = toPersianDigits(frame.time.hour.toString().padLeft(2, '0'));
    final minute = toPersianDigits(frame.time.minute.toString().padLeft(2, '0'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.radar_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'فریم ${toPersianDigits(frameIndex + 1)} از '
              '${toPersianDigits(frameCount)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text('$hour:$minute'),
          ],
        ),
      ),
    );
  }
}

class _RadarTimeline extends StatelessWidget {
  const _RadarTimeline({
    required this.frames,
    required this.currentIndex,
    required this.playing,
    required this.onPlayPause,
    required this.onChanged,
  });

  final List<_RadarFrame> frames;
  final int currentIndex;
  final bool playing;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPlayPause,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (frames.length - 1).toDouble(),
                divisions: frames.length > 1 ? frames.length - 1 : null,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarError extends StatelessWidget {
  const _RadarError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_outlined, size: 64),
            const SizedBox(height: 14),
            const Text(
              'رادار در دسترس نیست',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarFrame {
  const _RadarFrame({
    required this.time,
    required this.path,
  });

  final DateTime time;
  final String path;
}
