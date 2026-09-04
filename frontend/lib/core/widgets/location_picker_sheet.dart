import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_x.dart';
import '../../app/theme/app_spacing.dart';
import '../constants/map_constants.dart';
import '../location/app_location.dart';
import '../location/location_service.dart';
import 'fixly_map_view.dart';

/// Interactive modal sheet to search address, pan/drag on map, and change location.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  /// Open bottom sheet and return true if location changed.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => const LocationPickerSheet(),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// The coords that will be CONFIRMED when user taps button.
  late double _confirmedLat;
  late double _confirmedLng;
  String _confirmedAddress = '';

  /// Live coords while dragging (drives map center + address preview label).
  late double _draftLat;
  late double _draftLng;
  String _draftAddress = '';

  MapCoordinate? _mapCenter;

  bool _isSearching = false;
  bool _isDragging = false;       // user is currently dragging the map
  bool _isGeocodingDraft = false; // geocoding the live drag position
  bool _isLocatingGps = false;
  List<PlaceSearchResult> _searchResults = [];
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    final loc = AppLocation.instance;
    _confirmedLat = _draftLat = loc.lat ?? LocationService.debugFallbackLat;
    _confirmedLng = _draftLng = loc.lng ?? LocationService.debugFallbackLng;
    _confirmedAddress = _draftAddress = loc.addressLabel ?? LocationService.debugFallbackAddress;
    _mapCenter = MapCoordinate(lat: _confirmedLat, lng: _confirmedLng);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────── SEARCH ──
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await LocationService.instance.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    });
  }

  void _selectSearchResult(PlaceSearchResult place) {
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
      _searchController.text = place.name;
      _draftLat = _confirmedLat = place.lat;
      _draftLng = _confirmedLng = place.lng;
      _draftAddress = _confirmedAddress = place.address;
      _mapCenter = MapCoordinate(lat: place.lat, lng: place.lng);
    });
  }


  // ──────────────────────────────────────────────── MAP DRAG ──

  /// Called continuously while user is dragging.
  /// ONLY tracks position + shows "Moving…" — NO geocoding here.
  void _onMapLocationMoved(MapCoordinate coord) {
    _draftLat = coord.lat;
    _draftLng = coord.lng;
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
        _isGeocodingDraft = false;
        _draftAddress = 'Moving…';
      });
    }
    // Cancel any in-progress geocode debounce — user is still moving.
    _geocodeDebounce?.cancel();
  }

  /// Called ONCE when map becomes idle (user stopped dragging).
  /// Geocodes the final resting position.
  Future<void> _onMapIdled(MapCoordinate coord) async {
    _draftLat = coord.lat;
    _draftLng = coord.lng;
    if (!mounted) return;
    setState(() {
      _isDragging = false;
      _isGeocodingDraft = true;
    });
    final addr = await LocationService.instance.reverseGeocode(_draftLat, _draftLng);
    if (!mounted) return;
    setState(() {
      _isGeocodingDraft = false;
      _draftAddress = (addr != null && addr.isNotEmpty)
          ? addr
          : '${_draftLat.toStringAsFixed(5)}, ${_draftLng.toStringAsFixed(5)}';
    });
  }

  // ──────────────────────────────────────────────── GPS ──
  Future<void> _useGpsLocation() async {
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);
    try {
      // refreshCurrentPosition already reverse-geocodes internally.
      final ok = await LocationService.instance.refreshCurrentPosition();
      if (!mounted) return;
      if (ok && AppLocation.instance.hasFix) {
        final lat = AppLocation.instance.requireLat;
        final lng = AppLocation.instance.requireLng;
        // Read address from AppLocation (set by refreshCurrentPosition).
        final addr = AppLocation.instance.addressLabel;

        // If address is null/empty, geocode now.
        final resolved = (addr != null && addr.isNotEmpty)
            ? addr
            : await LocationService.instance.reverseGeocode(lat, lng) ?? _draftAddress;

        if (!mounted) return;
        setState(() {
          _draftLat = _confirmedLat = lat;
          _draftLng = _confirmedLng = lng;
          _draftAddress = _confirmedAddress = resolved;
          _searchController.clear();
          _searchResults = [];
          _mapCenter = MapCoordinate(lat: lat, lng: lng);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch GPS location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  // ──────────────────────────────────────────────── CONFIRM ──
  void _confirmLocation() {
    // Commit the latest draft position + address.
    final finalLat = _draftLat;
    final finalLng = _draftLng;
    final finalAddr = _draftAddress.isNotEmpty ? _draftAddress : _confirmedAddress;

    AppLocation.instance.update(
      latitude: finalLat,
      longitude: finalLng,
      address: finalAddr,
    );
    Navigator.of(context).pop(true);
  }

  // ──────────────────────────────────────────────── BUILD ──
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isMovingOrGeocoding = _isDragging || _isGeocodingDraft;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on_rounded, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Your Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                      ),
                      Text(
                        'Search or drag the map to pin your address',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search area, street, landmark…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : (_isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Map + Overlays ──
          Expanded(
            child: Stack(
              children: [
                // Full map
                Positioned.fill(
                  child: FixlyMapView(
                    borderRadius: BorderRadius.zero,
                    center: _mapCenter,
                    zoom: MapConstants.pickerZoom,
                    showDestinationPin: true,
                    claimGestures: true,
                    showZoomControls: true,
                    showRecenterButton: false,
                    expand: true,
                    onLocationChanged: _onMapLocationMoved,  // continuous drag tracking
                    onMapIdled: _onMapIdled,                 // geocode once on idle
                  ),
                ),

                // ── Floating GPS button ──
                Positioned(
                  left: 14,
                  top: 14,
                  child: _GpsButton(
                    loading: _isLocatingGps,
                    onTap: _useGpsLocation,
                  ),
                ),

                // ── Dragging address chip (replaces address bar while moving) ──
                if (isMovingOrGeocoding)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _DraggingAddressChip(
                      address: _draftAddress,
                      geocoding: _isGeocodingDraft,
                    ),
                  ),

                // ── Search Results Dropdown ──
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 8,
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      shadowColor: Colors.black.withValues(alpha: 0.18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: context.hairline),
                          itemBuilder: (context, idx) {
                            final item = _searchResults[idx];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item.address,
                                style: TextStyle(fontSize: 12, color: context.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSearchResult(item),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom: Current Address + Confirm ──
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: context.hairline)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isMovingOrGeocoding
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMovingOrGeocoding ? 'Detecting address…' : 'Pinned address',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              key: ValueKey(_draftAddress),
                              _draftAddress.isNotEmpty
                                  ? _draftAddress
                                  : 'Drag map to pin exact location',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isMovingOrGeocoding ? null : _confirmLocation,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text(
                      'Confirm Location',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating GPS pill button overlaying the map.
class _GpsButton extends StatelessWidget {
  const _GpsButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                loading ? 'Getting location…' : 'Use my location',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Semi-transparent chip shown at bottom of map while user is dragging.
class _DraggingAddressChip extends StatelessWidget {
  const _DraggingAddressChip({required this.address, required this.geocoding});
  final String address;
  final bool geocoding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (geocoding)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.location_pin, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
