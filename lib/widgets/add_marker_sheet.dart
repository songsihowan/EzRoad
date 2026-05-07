import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_marker.dart';

// 네이버 지도 스타일 마커 상세 카드
class MarkerDetailCard extends StatelessWidget {
  final CustomMarker marker;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final void Function(CustomMarker) onEdit;
  final VoidCallback? onImageTap; // ← 추가

  const MarkerDetailCard({
    super.key,
    required this.marker,
    required this.onClose,
    required this.onDelete,
    required this.onEdit,
    this.onImageTap, // ← 추가
  });

  static const Color _bg = Color(0xFF1A1A24);
  static const Color _surface2 = Color(0xFF24243A);
  static const Color _accent = Color(0xFF7C6AF7);
  static const Color _textMuted = Color(0xFF888888);

  Color get _markerColor {
    try {
      return Color(int.parse('FF${marker.colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _accent;
    }
  }

  Color get _dangerColor {
    switch (marker.icon) {
      case '🔴': return const Color(0xFFFF4444);
      case '🟠': return const Color(0xFFFF8C00);
      case '🟢': return const Color(0xFF4CAF50);
      default: return _accent;
    }
  }

  String get _dangerText {
    switch (marker.icon) {
      case '🔴': return '위험도 상';
      case '🟠': return '위험도 중';
      case '🟢': return '위험도 하';
      default: return '위험 지역';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (marker.imageUrl.isNotEmpty)
            Stack(
              children: [
                GestureDetector(
                  onTap: onImageTap,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      marker.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: _surface2,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C6AF7),
                            ),
                          ),
                        );
                      },
                    ),
                  ), // ClipRRect
                ), // GestureDetector
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: onClose,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _dangerColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(marker.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(_dangerText,
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
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _dangerColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(marker.icon, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(marker.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(_dangerText,
                            style: TextStyle(
                              color: _dangerColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (marker.imageUrl.isEmpty)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _surface2,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (marker.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(marker.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: '${marker.lat}, ${marker.lng}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('좌표가 복사되었습니다'),
                            backgroundColor: Color(0xFF1A1A24),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF7C6AF7), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${marker.lat.toStringAsFixed(4)}, ${marker.lng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Color(0xFF7C6AF7),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded,
                                color: Color(0xFF7C6AF7), size: 12),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(marker.createdAt),
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4444),
                      side: const BorderSide(color: Color(0xFFFF4444), width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: _bg,
                          title: const Text('마커 삭제',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                            '${marker.name} 마커를 삭제할까요?',
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
                                onDelete();
                              },
                              child: const Text('삭제',
                                  style: TextStyle(color: Color(0xFFFF4444))),
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}