import 'package:flutter/material.dart';
import '../models/custom_marker.dart';

class MarkerListSheet extends StatelessWidget {
  final List<CustomMarker> markers;
  final void Function(CustomMarker) onFocus;
  final void Function(String) onDelete;

  const MarkerListSheet({
    super.key,
    required this.markers,
    required this.onFocus,
    required this.onDelete,
  });

  static const Color _bg = Colors.white;
  static const Color _surface = Color(0xFFF5F5F5);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _accent = Color(0xFF7C6AF7);
  static const Color _textMain = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF888888);

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _accent;
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('신고 목록',
                  style: TextStyle(
                    color: _textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text('${markers.length}',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: markers.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚠️',
                      style: TextStyle(
                          fontSize: 48,
                          color: Colors.grey[300])),
                  const SizedBox(height: 12),
                  const Text(
                    '아직 신고된 위험 지역이 없어요!\n카메라 버튼으로 신고해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: markers.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = markers[i];
                final color = _hexToColor(m.colorHex);
                return Dismissible(
                  key: Key(m.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.red),
                  ),
                  onDismissed: (_) => onDelete(m.id),
                  child: GestureDetector(
                    onTap: () => onFocus(m),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: color.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(m.icon,
                                  style: const TextStyle(
                                      fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.category.isNotEmpty
                                      ? m.category
                                      : m.name,
                                  style: const TextStyle(
                                    color: _textMain,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.description.isNotEmpty
                                      ? m.description
                                      : '${_getCategoryIcon(m.category)} ${m.category}',
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (m.transport.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 6,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A90D9)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF4A90D9)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${m.transport == '도보' ? '🚶' : '🚲'} ${m.transport}',
                                      style: const TextStyle(
                                        color: Color(0xFF4A90D9),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: _textMuted, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}