import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../location/domain/location_point.dart';
import '../../domain/search_models.dart';
import '../tutor_search_card.dart';

/// Điểm thay nhà cung cấp bản đồ; phía màn tìm kiếm không phụ thuộc flutter_map.
class TutorMap extends StatefulWidget {
  const TutorMap({
    super.key,
    required this.center,
    required this.radiusKm,
    required this.hits,
  });
  final LocationPoint center;
  final double radiusKm;
  final List<SearchHit> hits;
  @override
  State<TutorMap> createState() => _TutorMapState();
}

class _TutorMapState extends State<TutorMap> {
  final controller = MapController();
  NetworkTileProvider? tiles;
  bool tileError = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = dotenv.isInitialized ? dotenv.env['MAP_TILE_URL'] : null;
    final agent = dotenv.isInitialized ? dotenv.env['MAP_USER_AGENT'] : null;
    if (url == null ||
        !url.startsWith('https://') ||
        agent == null ||
        agent.isEmpty) {
      return const Center(
        child: Text(
          'Chưa cấu hình bản đồ. Kiểm tra MAP_TILE_URL và MAP_USER_AGENT; danh sách vẫn dùng được.',
        ),
      );
    }
    // Cache đĩa theo HTTP headers, không tải trước hoặc tải hàng loạt tile.
    tiles ??= NetworkTileProvider(
      headers: {'User-Agent': agent},
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(),
    );
    final center = LatLng(widget.center.latitude, widget.center.longitude);
    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: url,
              tileProvider: tiles,
              maxZoom: 19,
              errorTileCallback: (_, _, _) {
                if (!tileError && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => tileError = true);
                  });
                }
              },
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: widget.radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderColor: Colors.teal,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(44, 44),
                markers: widget.hits
                    .map(
                      (h) => Marker(
                        point: LatLng(
                          h.tutor.approxLocation!.latitude,
                          h.tutor.approxLocation!.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: h.tutor.displayName,
                          icon: const Icon(Icons.location_on),
                          color: Colors.teal,
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => SafeArea(
                              child: SingleChildScrollView(
                                child: TutorSearchCard(hit: h),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                builder: (_, markers) => CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    '${markers.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            tooltip: 'Về vị trí tìm kiếm',
            onPressed: () => controller.move(center, 12),
            child: const Icon(Icons.my_location),
          ),
        ),
        if (tileError)
          const Positioned(
            top: 8,
            left: 8,
            right: 65,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Không tải được nền bản đồ. Hãy dùng danh sách hoặc thử lại sau.',
                ),
              ),
            ),
          ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(color: Colors.black, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
