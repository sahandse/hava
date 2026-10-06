import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/weather/application/weather_controller.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final _mapController = MapController();
  final _dio = Dio();
  late final Future<CacheStore> _cacheStoreFuture = _getCacheStore();

  static Future<CacheStore> _getCacheStore() async {
    final dir = await getTemporaryDirectory();
    return FileCacheStore(
      '${dir.path}${Platform.pathSeparator}hava_map_tiles',
    );
  }

  List<_RadarFrame> _frames = const [];
  String? _host;
  int _frameIndex = 0;
  bool _loading = true;
  bool _playing = false;
  bool _showCoverage = false;
  Object? _error;
  Timer? _timer;
  double _playbackSpeed = 1;
  _ProbeMetric _metric = _ProbeMetric.radar;
  _WeatherProbe? _probe;
  bool _probeLoading = false;

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

    Map<String, dynamic>? data;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.rainviewer.com/public/weather-maps.json',
      );
      data = response.data;
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('radar_metadata_cache', jsonEncode(data));
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('radar_metadata_cache');
      if (cached != null) {
        data = jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    try {
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

  Duration get _frameDuration {
    if (_playbackSpeed == .5) return const Duration(milliseconds: 1400);
    if (_playbackSpeed == 2) return const Duration(milliseconds: 350);
    return const Duration(milliseconds: 700);
  }

  void _togglePlayback() {
    if (_frames.length < 2) return;

    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }

    setState(() => _playing = true);
    _startPlayback();
  }

  void _startPlayback() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted || _frames.isEmpty) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
      });
    });
  }

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_playing) _startPlayback();
  }

  Future<void> _loadProbe(LatLng point) async {
    if (_metric == _ProbeMetric.radar) return;

    setState(() => _probeLoading = true);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': point.latitude,
          'longitude': point.longitude,
          'timezone': 'auto',
          'current': [
            'temperature_2m',
            'wind_speed_10m',
            'cloud_cover',
            'surface_pressure',
          ].join(','),
        },
      );
      final current =
          response.data?['current'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      setState(() {
        _probe = _WeatherProbe(
          point: point,
          temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
          windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
          cloudCover: (current['cloud_cover'] as num?)?.toDouble() ?? 0,
          pressure: (current['surface_pressure'] as num?)?.toDouble() ?? 0,
        );
        _probeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _probeLoading = false);
    }
  }

  void _selectMetric(_ProbeMetric metric) {
    _timer?.cancel();
    setState(() {
      _metric = metric;
      _playing = false;
    });
    if (metric != _ProbeMetric.radar) {
      _loadProbe(_mapController.camera.center);
    }
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
        title: const Text('نقشه هوا'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
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

          final center = LatLng(weatherData.latitude, weatherData.longitude);
          final frame = _frames[_frameIndex];

          return FutureBuilder<CacheStore>(
            future: _cacheStoreFuture,
            builder: (context, cacheSnapshot) {
              final cacheStore = cacheSnapshot.data;
              return Stack(
                children: [
                  FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 6.5,
                  minZoom: 3,
                  maxZoom: 12,
                  onTap: (_, point) => _loadProbe(point),
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd &&
                        _metric != _ProbeMetric.radar) {
                      _loadProbe(_mapController.camera.center);
                    }
                  },
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
                    tileProvider: cacheStore == null
                        ? null
                        : CachedTileProvider(
                            store: cacheStore,
                            maxStale: const Duration(days: 30),
                          ),
                  ),
                  if (_metric == _ProbeMetric.radar)
                    TileLayer(
                      key: ValueKey(frame.path),
                      urlTemplate:
                          '$_host${frame.path}/256/{z}/{x}/{y}/2/1_1.png',
                      userAgentPackageName: 'com.sahand.hava',
                      maxNativeZoom: 7,
                      maxZoom: 12,
                      tileDisplay: const TileDisplay.fadeIn(),
                      tileProvider: cacheStore == null
                          ? null
                          : CachedTileProvider(
                              store: cacheStore,
                              maxStale: const Duration(hours: 12),
                            ),
                    ),
                  if (_showCoverage)
                    TileLayer(
                      urlTemplate:
                          '$_host/v2/coverage/0/256/{z}/{x}/{y}/0/0_0.png',
                      userAgentPackageName: 'com.sahand.hava',
                      maxNativeZoom: 7,
                      maxZoom: 12,
                      tileProvider: cacheStore == null
                          ? null
                          : CachedTileProvider(
                              store: cacheStore,
                              maxStale: const Duration(days: 7),
                            ),
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
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_probe != null)
                        Marker(
                          point: _probe!.point,
                          width: 18,
                          height: 18,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                left: 10,
                child: _MapModeBar(
                  metric: _metric,
                  onChanged: _selectMetric,
                ),
              ),
              if (_metric == _ProbeMetric.radar)
                Positioned(
                  top: 70,
                  right: 10,
                  left: 10,
                  child: _RadarStatusCard(
                    frame: frame,
                    frameIndex: _frameIndex,
                    frameCount: _frames.length,
                    showCoverage: _showCoverage,
                    onCoverageChanged: (value) {
                      setState(() => _showCoverage = value);
                    },
                  ),
                ),
              if (_metric != _ProbeMetric.radar)
                Positioned(
                  top: 70,
                  right: 10,
                  left: 10,
                  child: _ProbeCard(
                    metric: _metric,
                    probe: _probe,
                    loading: _probeLoading,
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 150,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'radar_location',
                      onPressed: () {
                        _mapController.move(center, 6.5);
                        _loadProbe(center);
                      },
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
              if (_metric == _ProbeMetric.radar)
                Positioned(
                  right: 10,
                  left: 10,
                  bottom: 18,
                  child: _RadarTimeline(
                    frames: _frames,
                    currentIndex: _frameIndex,
                    playing: _playing,
                    speed: _playbackSpeed,
                    onPlayPause: _togglePlayback,
                    onLatest: () {
                      _timer?.cancel();
                      setState(() {
                        _playing = false;
                        _frameIndex = _frames.length - 1;
                      });
                    },
                    onSpeedChanged: _setSpeed,
                    onChanged: (value) {
                      setState(() => _frameIndex = value.round());
                    },
                  ),
                ),
              if (_metric == _ProbeMetric.radar)
                const Positioned(
                  left: 10,
                  bottom: 120,
                  child: _RadarLegend(),
                ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

enum _ProbeMetric { radar, temperature, wind, clouds, pressure }

class _MapModeBar extends StatelessWidget {
  const _MapModeBar({
    required this.metric,
    required this.onChanged,
  });

  final _ProbeMetric metric;
  final ValueChanged<_ProbeMetric> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              _Chip('رادار', _ProbeMetric.radar, metric, onChanged),
              _Chip('دما', _ProbeMetric.temperature, metric, onChanged),
              _Chip('باد', _ProbeMetric.wind, metric, onChanged),
              _Chip('ابر', _ProbeMetric.clouds, metric, onChanged),
              _Chip('فشار', _ProbeMetric.pressure, metric, onChanged),
            ],
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value, this.current, this.onChanged);

  final String label;
  final _ProbeMetric value;
  final _ProbeMetric current;
  final ValueChanged<_ProbeMetric> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        child: ChoiceChip(
          label: Text(label),
          selected: current == value,
          onSelected: (_) => onChanged(value),
        ),
      );
}

class _ProbeCard extends StatelessWidget {
  const _ProbeCard({
    required this.metric,
    required this.probe,
    required this.loading,
  });

  final _ProbeMetric metric;
  final _WeatherProbe? probe;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    String title;
    String value;

    if (loading || probe == null) {
      title = 'در حال دریافت داده نقطه';
      value = '...';
    } else {
      final result = switch (metric) {
        _ProbeMetric.temperature => (
            'دما',
            '${toPersianDigits(probe!.temperature.toStringAsFixed(1))}°',
          ),
        _ProbeMetric.wind => (
            'باد',
            '${toPersianDigits(probe!.windSpeed.toStringAsFixed(1))} km/h',
          ),
        _ProbeMetric.clouds => (
            'پوشش ابر',
            '${toPersianDigits(probe!.cloudCover.round())}٪',
          ),
        _ProbeMetric.pressure => (
            'فشار',
            '${toPersianDigits(probe!.pressure.round())} hPa',
          ),
        _ProbeMetric.radar => ('رادار', ''),
      };
      title = result.$1;
      value = result.$2;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 8),
            Text(title),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarStatusCard extends StatelessWidget {
  const _RadarStatusCard({
    required this.frame,
    required this.frameIndex,
    required this.frameCount,
    required this.showCoverage,
    required this.onCoverageChanged,
  });

  final _RadarFrame frame;
  final int frameIndex;
  final int frameCount;
  final bool showCoverage;
  final ValueChanged<bool> onCoverageChanged;

  @override
  Widget build(BuildContext context) {
    final hour = toPersianDigits(frame.time.hour.toString().padLeft(2, '0'));
    final minute = toPersianDigits(frame.time.minute.toString().padLeft(2, '0'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.radar_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              '${toPersianDigits(frameIndex + 1)}/${toPersianDigits(frameCount)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text('$hour:$minute'),
            const Spacer(),
            const Text('پوشش'),
            Switch(
              value: showCoverage,
              onChanged: onCoverageChanged,
            ),
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
    required this.speed,
    required this.onPlayPause,
    required this.onLatest,
    required this.onSpeedChanged,
    required this.onChanged,
  });

  final List<_RadarFrame> frames;
  final int currentIndex;
  final bool playing;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onLatest;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                  IconButton(
                    tooltip: 'آخرین فریم',
                    onPressed: onLatest,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [.5, 1.0, 2.0].map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${item}×'),
                      selected: speed == item,
                      onSelected: (_) => onSpeedChanged(item),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
}

class _RadarLegend extends StatelessWidget {
  const _RadarLegend();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendBox(color: Color(0xFF58A7FF), label: 'کم'),
              _LegendBox(color: Color(0xFF38C77A), label: 'متوسط'),
              _LegendBox(color: Color(0xFFFFC928), label: 'زیاد'),
              _LegendBox(color: Color(0xFFE84646), label: 'شدید'),
            ],
          ),
        ),
      );
}

class _LegendBox extends StatelessWidget {
  const _LegendBox({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 3),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _RadarError extends StatelessWidget {
  const _RadarError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
              Text(message, textAlign: TextAlign.center),
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

class _RadarFrame {
  const _RadarFrame({
    required this.time,
    required this.path,
  });

  final DateTime time;
  final String path;
}

class _WeatherProbe {
  const _WeatherProbe({
    required this.point,
    required this.temperature,
    required this.windSpeed,
    required this.cloudCover,
    required this.pressure,
  });

  final LatLng point;
  final double temperature;
  final double windSpeed;
  final double cloudCover;
  final double pressure;
}
