import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class MapStoreMarker {
  final String id;
  final String title;
  final String subtitle;
  final LatLng position;
  final bool isHighlighted;

  const MapStoreMarker({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.position,
    this.isHighlighted = false,
  });
}

class StoreMapVisual extends StatefulWidget {
  final String locationQuery;
  final List<MapStoreMarker> markers;
  final LatLng? initialCenter;
  final double initialZoom;

  const StoreMapVisual({
    super.key,
    this.locationQuery = 'Metro Manila, Philippines',
    this.markers = const [],
    this.initialCenter,
    this.initialZoom = 12.0,
  });

  @override
  State<StoreMapVisual> createState() => _StoreMapVisualState();
}

class _StoreMapVisualState extends State<StoreMapVisual> {
  late final MapController _mapController;
  MapStoreMarker? _selectedMarker;

  static const LatLng _defaultMetroManila = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.markers.isNotEmpty) {
      _selectedMarker = widget.markers.firstWhere(
        (m) => m.isHighlighted,
        orElse: () => widget.markers.first,
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (widget.initialCenter != null) return widget.initialCenter!;
    if (widget.markers.isNotEmpty) return widget.markers.first.position;
    return _defaultMetroManila;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1218) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // OpenStreetMap Interactive Map Layer
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: widget.initialZoom,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bimo.app',
                  maxZoom: 19,
                ),
                if (widget.markers.isNotEmpty)
                  MarkerLayer(
                    markers: widget.markers.map((marker) {
                      final isSelected = _selectedMarker?.id == marker.id;
                      return Marker(
                        point: marker.position,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMarker = marker;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emeraldLight
                                  : (isDark ? AppColors.darkSurface : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 24,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.emeraldLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),

            // Top-left Location Badge Header
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.emeraldLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.locationQuery,
                      style: AppTypography.bodySmall(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom Controls
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _buildControlBtn(
                    icon: Icons.add,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom + 1);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildControlBtn(
                    icon: Icons.remove,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom - 1);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildControlBtn(
                    icon: Icons.my_location_rounded,
                    onPressed: () {
                      _mapController.move(_center, widget.initialZoom);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Empty Location State Banner (when no coordinates are supplied)
            if (widget.markers.isEmpty)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.blueAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OpenStreetMap live view: No physical store coordinates currently linked to this build.',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Selected Marker Details Popup
            if (widget.markers.isNotEmpty && _selectedMarker != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emeraldLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.emeraldLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedMarker!.title,
                              style: AppTypography.headingMedium(isDark).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedMarker!.subtitle,
                              style: AppTypography.bodySmall(isDark).copyWith(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigation_rounded, size: 20, color: AppColors.emeraldLight),
                        onPressed: () async {
                          final lat = _selectedMarker!.position.latitude;
                          final lng = _selectedMarker!.position.longitude;
                          final uri = Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(_selectedMarker!.title)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        tooltip: 'Open in Maps',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _selectedMarker = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: isDark ? Colors.white : Colors.black87,
        onPressed: onPressed,
      ),
    );
  }
}
