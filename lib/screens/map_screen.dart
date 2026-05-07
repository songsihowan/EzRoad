import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/custom_marker.dart';
import '../widgets/marker_list_sheet.dart';
import '../widgets/marker_detail_sheet.dart';
import '../widgets/report_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? _mapController;
  List<CustomMarker> _markers = [];
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _isUploading = false;
  CustomMarker? _selectedMarker;
  bool _isFullscreen = false;
  Set<Marker> _kakaoMarkers = {};
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'ezdatebase',
  );
  final _storage = FirebaseStorage.instance;

  static const Color _bg = Color(0xFF0F0F13);
  static const Color _surface = Color(0xFF8B8B94);
  static const Color _accent = Color(0xFF7C6AF7);

  static const String _redMarkerUrl =
      'https://firebasestorage.googleapis.com/v0/b/ezproject-a714d.firebasestorage.app/o/Red.png?alt=media&token=e5264e1b-ce1e-45d5-88bc-3d1ea72949a2';
  static const String _orangeMarkerUrl =
      'https://firebasestorage.googleapis.com/v0/b/ezproject-a714d.firebasestorage.app/o/orange.png?alt=media&token=8ec1f390-96b9-4c6d-b9e8-f889c5f86204';
  static const String _greenMarkerUrl =
      'https://firebasestorage.googleapis.com/v0/b/ezproject-a714d.firebasestorage.app/o/Green.png?alt=media&token=bfb59445-7fa1-4d37-ac6f-bc194431c767';
  static const String _locationMarkerUrl =
      'https://firebasestorage.googleapis.com/v0/b/ezproject-a714d.firebasestorage.app/o/MyPos.png?alt=media&token=fa6511eb-9725-4457-a54a-1f98a7adf465';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkersFromFirebase();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _loadMarkersFromFirebase() {
    _firestore.collection('markers').snapshots().listen((snapshot) {
      print('📦 총 문서 수: ${snapshot.docs.length}');
      setState(() {
        _markers = snapshot.docs.map((doc) {
          try {
            final data = doc.data();

            // colorHex: 엑셀 import 시 double로 깨지는 문제 방어
            String colorHex;
            final rawColor = data['colorHex'];
            if (rawColor is String) {
              colorHex = rawColor;
            } else {
              final hex = rawColor?.toString().split('.')[0] ?? 'FF6B6B';
              colorHex = hex.startsWith('#') ? hex : '#$hex';
            }

            // createdAt: Timestamp or 엑셀 시리얼 숫자 모두 처리
            DateTime createdAt;
            final rawDate = data['createdAt'];
            if (rawDate is Timestamp) {
              createdAt = rawDate.toDate();
            } else if (rawDate is num) {
              createdAt = DateTime(1899, 12, 30)
                  .add(Duration(milliseconds: (rawDate * 86400000).round()));
            } else {
              createdAt = DateTime.now();
            }

            return CustomMarker(
              id: doc.id,
              lat: (data['lat'] as num).toDouble(),
              lng: (data['lng'] as num).toDouble(),
              name: data['name'] ?? '위험 지역',
              description: data['description'] ?? '',
              icon: data['icon'] ?? '⚠️',
              colorHex: colorHex,
              imageUrl: data['imageUrl'] ?? '',
              videoUrl: data['videoUrl'] ?? '',
              mediaType: data['mediaType'] ?? 'image',
              category: data['category'] ?? '',
              transport: data['transport'] ?? '',
              createdAt: createdAt,
            );
          } catch (e) {
            print('❌ 파싱 에러 - doc: ${doc.id}, 에러: $e');
            return null;
          }
        }).whereType<CustomMarker>().toList();
        print('✅ 로드된 마커 수: ${_markers.length}');
        _updateKakaoMarkers();
      });
    });
  }
  void _updateKakaoMarkers() {
    setState(() {
      _kakaoMarkers = _markers.map((m) {
        return Marker(
          markerId: m.id,
          latLng: LatLng(m.lat, m.lng),
          markerImageSrc: _getMarkerImage(m.icon),
          width: 20,
          height: 28,
        );
      }).toSet();

      if (_currentLocation != null) {
        _kakaoMarkers.add(
          Marker(
            markerId: 'current_location',
            latLng: _currentLocation!,
            markerImageSrc: _locationMarkerUrl,
            width: 20,
            height: 20,
          ),
        );
      }
    });
  }

  String _getMarkerImage(String icon) {
    switch (icon) {
      case '🔴': return _redMarkerUrl;
      case '🟠': return _orangeMarkerUrl;
      case '🟢': return _greenMarkerUrl;
      default: return _redMarkerUrl;
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController?.setCenter(_currentLocation!);
    _mapController?.setLevel(3);
    _updateKakaoMarkers();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _updateKakaoMarkers();
    });
  }

  void _showStatsSheet() {
    final dangerHigh = _markers.where((m) => m.icon == '🔴').length;
    final dangerMid = _markers.where((m) => m.icon == '🟠').length;
    final dangerLow = _markers.where((m) => m.icon == '🟢').length;
    final total = _markers.length;

    final categoryCount = <String, int>{};
    for (final m in _markers) {
      if (m.category.isNotEmpty) {
        categoryCount[m.category] = (categoryCount[m.category] ?? 0) + 1;
      }
    }
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final walkCount = _markers.where((m) => m.transport == '도보').length;
    final bikeCount = _markers.where((m) => m.transport == '자전거').length;
    final noTransport = _markers.where((m) => m.transport.isEmpty).length;

    // 요약 데이터
    final topCategory = sortedCategories.isNotEmpty
        ? sortedCategories.first.key : '-';
    final topCategoryCount = sortedCategories.isNotEmpty
        ? sortedCategories.first.value : 0;
    final highRatio = total == 0 ? 0
        : (dangerHigh / total * 100).round();
    final mainTransport = walkCount >= bikeCount ? '🚶 도보' : '🚲 자전거';
    final mainTransportCount = walkCount >= bikeCount
        ? walkCount : bikeCount;
    final mainTransportRatio = total == 0 ? 0
        : (mainTransportCount / total * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 주제목 + 부제목
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔍 신고 데이터 요약',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '도보 환경 위험 신고 현황',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C6AF7)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF7C6AF7)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '총 $total건',
                        style: const TextStyle(
                          color: Color(0xFF7C6AF7),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 요약 카드 3개
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        icon: _getCategoryIcon(topCategory),
                        title: '최다 신고',
                        value: topCategory == '-' ? '-' : topCategory,
                        sub: topCategory == '-'
                            ? '' : '$topCategoryCount건',
                        color: const Color(0xFF7C6AF7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: '🔴',
                        title: '위험도 상',
                        value: '$dangerHigh건',
                        sub: '$highRatio%',
                        color: const Color(0xFFFF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: mainTransport.split(' ')[0],
                        title: '주 이동수단',
                        value: mainTransport.split(' ')[1],
                        sub: '$mainTransportRatio%',
                        color: const Color(0xFF4A90D9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 구분선
                Divider(color: Colors.grey[200]),
                const SizedBox(height: 16),

                // 위험도 섹션
                _buildSectionTitle('위험도'),
                const SizedBox(height: 12),
                _buildDangerBar('🔴 위험도 상', dangerHigh, total,
                    const Color(0xFFFF4444)),
                const SizedBox(height: 8),
                _buildDangerBar('🟠 위험도 중', dangerMid, total,
                    const Color(0xFFFF8C00)),
                const SizedBox(height: 8),
                _buildDangerBar('🟢 위험도 하', dangerLow, total,
                    const Color(0xFF4CAF50)),
                const SizedBox(height: 24),

                // 교통수단 섹션
                _buildSectionTitle('이동 수단'),
                const SizedBox(height: 12),
                _buildDangerBar('🚶 도보', walkCount, total,
                    const Color(0xFF4A90D9)),
                const SizedBox(height: 8),
                _buildDangerBar('🚲 자전거', bikeCount, total,
                    const Color(0xFF7C6AF7)),
                const SizedBox(height: 8),
                if (noTransport > 0)
                  _buildDangerBar('❓ 미분류', noTransport, total,
                      Colors.grey),
                const SizedBox(height: 24),

                // 카테고리 섹션
                _buildSectionTitle('신고 유형'),
                const SizedBox(height: 12),
                if (sortedCategories.isEmpty)
                  const Text('카테고리 데이터 없음',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...sortedCategories.take(8).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDangerBar(
                        '${_getCategoryIcon(entry.key)} ${entry.key}',
                        entry.value,
                        total,
                        const Color(0xFF7C6AF7),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 요약 카드
  Widget _buildSummaryCard({
    required String icon,
    required String title,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub.isNotEmpty)
            Text(sub,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildDangerBar(
      String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$count건',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getCategoryIcon(String category) {
    if (category.contains('보도 깨짐')) return '🧱';
    if (category.contains('보도 흔들림')) return '🫨';
    if (category.contains('보도 단차')) return '⬆️';
    if (category.contains('통행 방해물')) return '🚫';
    if (category.contains('좁은 보행로')) return '↔️';
    if (category.contains('환경 미화')) return '🌿';
    if (category.contains('불법 광고물')) return '📢';
    if (category.contains('시설물')) return '🔧';
    return '❓';
  }

  Future<void> _takePictureAndAddMarker() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 위치를 가져오는 중이에요!'),
          backgroundColor: Color(0xFF1A1A24),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이동 수단 선택',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _openCamera('도보');
                  },
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🚶', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 10),
                        Text('도보',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _openCamera('자전거');
                  },
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🚲', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 10),
                        Text('자전거',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(String transport) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white),
              title: const Text('사진 찍기',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (photo == null || !mounted) return;
                _showReportSheet(photo.path, 'image', transport);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded,
                  color: Colors.white),
              title: const Text('영상 찍기',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(
                  source: ImageSource.camera,
                  maxDuration: const Duration(seconds: 30),
                );
                if (video == null || !mounted) return;
                _showReportSheet(video.path, 'video', transport);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(String path, String mediaType, String transport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        imagePath: path,
        mediaType: mediaType,
        transport: transport,
        onSubmit: (description, dangerLevel, category) async {
          setState(() => _isUploading = true);
          try {
            String colorHex;
            String icon;
            switch (dangerLevel) {
              case '상':
                colorHex = '#FF4444';
                icon = '🔴';
                break;
              case '중':
                colorHex = '#FF8C00';
                icon = '🟠';
                break;
              default:
                colorHex = '#4CAF50';
                icon = '🟢';
            }

            final ext = mediaType == 'video' ? 'mp4' : 'jpg';
            final fileName = '${_uuid.v4()}.$ext';
            final ref = _storage.ref().child('markers/$fileName');
            await ref.putFile(File(path));
            final mediaUrl = await ref.getDownloadURL();

            await _firestore.collection('markers').add({
              'lat': _currentLocation!.latitude,
              'lng': _currentLocation!.longitude,
              'name': '위험 지역 ($dangerLevel)',
              'description': description,
              'icon': icon,
              'colorHex': colorHex,
              'imageUrl': mediaType == 'image' ? mediaUrl : '',
              'videoUrl': mediaType == 'video' ? mediaUrl : '',
              'mediaType': mediaType,
              'category': category,
              'transport': transport,
              'dangerLevel': dangerLevel,
              'createdAt': Timestamp.now(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('위험 지역이 등록되었어요!'),
                  backgroundColor: Color(0xFF1A1A24),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('업로드 실패했어요. 다시 시도해주세요.'),
                  backgroundColor: Color(0xFF1A1A24),
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isUploading = false);
          }
        },
      ),
    );
  }

  Future<void> _deleteMarker(String id) async {
    await _firestore.collection('markers').doc(id).delete();
  }

  void _focusMarker(CustomMarker m) {
    _mapController?.setCenter(LatLng(m.lat, m.lng));
  }

  void _showMarkerDetail(CustomMarker m) {
    setState(() {
      _selectedMarker = m;
      _isFullscreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: _selectedMarker == null,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedMarker != null) {
          setState(() {
            _selectedMarker = null;
            _isFullscreen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            KakaoMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _mapController?.setCenter(_currentLocation!);
                  _mapController?.setLevel(3);
                }
                _updateKakaoMarkers();
              },
              onMapTap: (latLng) {
                setState(() {
                  _selectedMarker = null;
                  _isFullscreen = false;
                });
              },
              onMarkerTap: (markerId, latLng, zoomLevel) {
                if (markerId == 'current_location') return;
                final marker = _markers.firstWhere(
                      (m) => m.id == markerId,
                  orElse: () => _markers.first,
                );
                _showMarkerDetail(marker);
              },
              markers: _kakaoMarkers.toList(),
              center: _currentLocation ?? LatLng(36.5, 127.5),
            ),

            if (!_isFullscreen)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showStatsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: _accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📊',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                '신고 ${_markers.length}건',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isUploading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF7C6AF7)),
                      SizedBox(height: 16),
                      Text('업로드 중...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

            if (!_isFullscreen)
              Positioned(
                bottom: bottomPadding + 60,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'list',
                      backgroundColor: _surface,
                      foregroundColor: Colors.white,
                      mini: true,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => MarkerListSheet(
                            markers: _markers,
                            onFocus: (m) {
                              Navigator.pop(context);
                              _focusMarker(m);
                            },
                            onDelete: (id) {
                              _deleteMarker(id);
                            },
                          ),
                        );
                      },
                      child: const Icon(Icons.list_rounded),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'location',
                      backgroundColor: _surface,
                      foregroundColor: Colors.blue,
                      mini: true,
                      onPressed: () {
                        if (_currentLocation != null) {
                          _mapController?.setCenter(_currentLocation!);
                          _mapController?.setLevel(3);
                        } else {
                          _getCurrentLocation();
                        }
                      },
                      child: const Icon(Icons.my_location_rounded),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'camera',
                      backgroundColor: const Color(0xFFFF4444),
                      foregroundColor: Colors.white,
                      onPressed:
                      _isUploading ? null : _takePictureAndAddMarker,
                      child: const Icon(Icons.camera_alt_rounded),
                    ),
                  ],
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              bottom: _selectedMarker != null ? 0 : -screenHeight,
              left: 0,
              right: 0,
              height: screenHeight,
              child: _selectedMarker != null
                  ? SafeArea(
                top: false,
                child: MarkerDetailCard(
                  marker: _selectedMarker!,
                  onClose: () => setState(() {
                    _selectedMarker = null;
                    _isFullscreen = false;
                  }),
                  onDelete: () {
                    _deleteMarker(_selectedMarker!.id);
                    setState(() {
                      _selectedMarker = null;
                      _isFullscreen = false;
                    });
                  },
                  onEdit: (updated) async {
                    await _firestore
                        .collection('markers')
                        .doc(_selectedMarker!.id)
                        .update({
                      'name': updated.name,
                      'description': updated.description,
                    });
                  },
                  onImageTap: () => setState(
                          () => _isFullscreen = !_isFullscreen),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}