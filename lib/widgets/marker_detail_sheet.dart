import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/custom_marker.dart';

class MarkerDetailCard extends StatefulWidget {
  final CustomMarker marker;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final void Function(CustomMarker) onEdit;
  final VoidCallback onImageTap;

  const MarkerDetailCard({
    super.key,
    required this.marker,
    required this.onClose,
    required this.onDelete,
    required this.onEdit,
    required this.onImageTap,
  });

  @override
  State<MarkerDetailCard> createState() => _MarkerDetailCardState();
}

class _MarkerDetailCardState extends State<MarkerDetailCard> {
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _isVideoInitialized = false;

  static const Color _bg = Colors.white;
  static const Color _surface = Color(0xFFF5F5F5);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _textMain = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF888888);
  static const Color _accent = Color(0xFF7C6AF7);

  Color get _dangerColor {
    switch (widget.marker.icon) {
      case '🔴': return const Color(0xFFFF4444);
      case '🟠': return const Color(0xFFFF8C00);
      case '🟢': return const Color(0xFF4CAF50);
      default: return _accent;
    }
  }

  String get _dangerText {
    switch (widget.marker.icon) {
      case '🔴': return '위험도 상';
      case '🟠': return '위험도 중';
      case '🟢': return '위험도 하';
      default: return '위험 지역';
    }
  }

  bool get _isVideo => widget.marker.videoUrl.isNotEmpty;

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

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.marker.videoUrl),
    );
    await _videoController!.initialize();
    setState(() => _isVideoInitialized = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // 이미지 or 영상
          if (_isVideo)
            _buildVideoPlayer()
          else if (widget.marker.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: widget.onImageTap,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: Image.network(
                      widget.marker.imageUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: _surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C6AF7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.marker.category.isNotEmpty
                                ? _getCategoryIcon(widget.marker.category)
                                : widget.marker.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.marker.category.isNotEmpty
                                ? widget.marker.category
                                : _dangerText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _dangerColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.marker.icon,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(_dangerText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 + 닫기 버튼
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _dangerColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(widget.marker.icon,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ← 카테고리로 제목 표시
                          Text(
                            widget.marker.category.isNotEmpty
                                ? widget.marker.category
                                : widget.marker.name,
                            style: const TextStyle(
                              color: _textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // ← 날짜로 부제목 표시
                          Text(
                            _formatDate(widget.marker.createdAt),
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.marker.imageUrl.isEmpty && !_isVideo)
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.black54, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 태그 섹션
                if (widget.marker.category.isNotEmpty ||
                    widget.marker.transport.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.marker.transport.isNotEmpty)
                        _buildTag(
                          icon: widget.marker.transport == '도보'
                              ? '🚶' : '🚲',
                          label: widget.marker.transport,
                          color: const Color(0xFF4A90D9),
                        ),
                      if (widget.marker.category.isNotEmpty)
                        _buildTag(
                          icon: _getCategoryIcon(widget.marker.category),
                          label: widget.marker.category,
                          color: _accent,
                        ),
                      _buildTag(
                        icon: widget.marker.icon,
                        label: _dangerText,
                        color: _dangerColor,
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // 설명
                if (widget.marker.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Text(widget.marker.description,
                      style: const TextStyle(
                        color: _textMain,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 날짜 + 미디어 타입
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: _textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(widget.marker.createdAt),
                          style: const TextStyle(
                              color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    if (_isVideo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded,
                                color: _textMuted, size: 14),
                            SizedBox(width: 4),
                            Text('영상',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 삭제 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4444),
                      side: const BorderSide(
                          color: Color(0xFFFF4444), width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFFFF4444)
                          .withValues(alpha: 0.05),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: _bg,
                          title: const Text('신고 삭제',
                              style: TextStyle(color: _textMain)),
                          content: Text(
                            '${widget.marker.name} 신고를 삭제할까요?',
                            style: const TextStyle(color: _textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소',
                                  style: TextStyle(color: _textMuted)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onDelete();
                              },
                              child: const Text('삭제',
                                  style: TextStyle(
                                      color: Color(0xFFFF4444))),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('신고 삭제',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
          child: _isVideoInitialized
              ? GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                  _isVideoPlaying = false;
                } else {
                  _videoController!.play();
                  _isVideoPlaying = true;
                }
              });
            },
            child: SizedBox(
              width: double.infinity,
              height: 300,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          )
              : Container(
            height: 300,
            color: _surface,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C6AF7),
              ),
            ),
          ),
        ),
        if (_isVideoInitialized && !_isVideoPlaying)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _videoController!.play();
                  _isVideoPlaying = true;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 12, right: 12,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.marker.category.isNotEmpty
                      ? _getCategoryIcon(widget.marker.category)
                      : widget.marker.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.marker.category.isNotEmpty
                      ? widget.marker.category
                      : _dangerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _dangerColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.marker.icon,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(_dangerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}