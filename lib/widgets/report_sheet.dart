import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReportSheet extends StatefulWidget {
  final String imagePath;
  final String mediaType;
  final String transport;
  final void Function(String description, String dangerLevel, String category) onSubmit;

  const ReportSheet({
    super.key,
    required this.imagePath,
    required this.mediaType,
    required this.transport,
    required this.onSubmit,
  });

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _descCtrl = TextEditingController();
  String _dangerLevel = '중';
  String _category = '보도 깨짐';
  String? _subCategory;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  static const Color _bg = Colors.white;
  static const Color _surface = Color(0xFFF5F5F5);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _textMain = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF888888);
  static const Color _purple = Color(0xFF7C6AF7);

  // 1단계 카테고리
  final List<Map<String, String>> _categories = [
    {'icon': '🧱', 'label': '보도 깨짐'},
    {'icon': '🫨', 'label': '보도 흔들림'},
    {'icon': '⬆️', 'label': '보도 단차'},
    {'icon': '🚫', 'label': '통행 방해물'},
    {'icon': '↔️', 'label': '좁은 보행로'},
    {'icon': '🌿', 'label': '환경 미화 저해'},
    {'icon': '📢', 'label': '불법 광고물'},
    {'icon': '🔧', 'label': '시설물 불량'},
    {'icon': '❓', 'label': '기타'},
  ];

  // 2단계 서브 카테고리
  final Map<String, List<String>> _subCategories = {
    '통행 방해물': ['주정차', '킥보드·자전거', '기타'],
    '좁은 보행로': ['유효 폭 부족', '통행 불가', '기타'],
    '환경 미화 저해': ['쓰레기', '파손', '방치', '노후', '기타'],
    '불법 광고물': ['입간판', '현수막', '전단지', '기타'],
    '시설물 불량': ['고장', '오작동', '파손', '기타'],
  };

  // 서브카테고리 있는 카테고리인지 확인
  bool get _hasSubCategory => _subCategories.containsKey(_category);

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _videoController = VideoPlayerController.file(File(widget.imagePath))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Color _dangerColor(String level) {
    switch (level) {
      case '상': return const Color(0xFFFF4444);
      case '중': return const Color(0xFFFF8C00);
      case '하': return const Color(0xFF4CAF50);
      default: return const Color(0xFFFF8C00);
    }
  }

  String _dangerIcon(String level) {
    switch (level) {
      case '상': return '🔴';
      case '중': return '🟠';
      case '하': return '🟢';
      default: return '🟠';
    }
  }

  // 최종 카테고리 문자열
  String get _finalCategory {
    if (_hasSubCategory && _subCategory != null) {
      return '$_category > $_subCategory';
    }
    return _category;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들 바
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

            // 제목 + 교통수단
            Row(
              children: [
                const Text('위험 지역 발견',
                  style: TextStyle(
                    color: _textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.transport == '도보' ? '🚶' : '🚲',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.transport,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 미디어 미리보기
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.mediaType == 'video'
                  ? _buildVideoPreview()
                  : Image.file(
                File(widget.imagePath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // 신고 유형 라벨
            const Text('신고 유형',
              style: TextStyle(
                color: _textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // 1단계 카테고리 3열 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                final selected = _category == item['label'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _category = item['label']!;
                    _subCategory = null; // 카테고리 바뀌면 서브 초기화
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _purple : const Color(0xFF3A3A3A),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected ? [
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['icon']!,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? _purple : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2단계 서브 카테고리 (애니메이션으로 펼쳐짐)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _hasSubCategory
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('세부 유형',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($_category)',
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subCategories[_category]!.map((sub) {
                      final selected = _subCategory == sub;
                      return GestureDetector(
                        onTap: () => setState(() => _subCategory = sub),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _purple
                                  : const Color(0xFF3A3A3A),
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected ? [
                              BoxShadow(
                                color: _purple.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : [],
                          ),
                          child: Text(
                            sub,
                            style: TextStyle(
                              color: selected
                                  ? _purple
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // 설명 라벨
            const Text('메모',
              style: TextStyle(
                color: _textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // 설명 입력창
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: _textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: '위험한 상황을 설명해주세요',
                hintStyle: const TextStyle(color: _textMuted),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _dangerColor(_dangerLevel)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // 위험도 라벨
            const Text('위험도',
              style: TextStyle(
                color: _textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // 위험도 선택
            Row(
              children: ['상', '중', '하'].map((level) {
                final selected = _dangerLevel == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dangerLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _dangerColor(level)
                              : const Color(0xFF3A3A3A),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected ? [
                          BoxShadow(
                            color: _dangerColor(level)
                                .withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _dangerIcon(level),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 6),
                          Text(level,
                            style: TextStyle(
                              color: selected
                                  ? _dangerColor(level)
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dangerColor(_dangerLevel),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  widget.onSubmit(
                    _descCtrl.text.trim(),
                    _dangerLevel,
                    _finalCategory, // ← 최종 카테고리 (예: "통행 방해물 > 주정차")
                  );
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dangerIcon(_dangerLevel),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '위험 지역 저장하기',
                      style: TextStyle(
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
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null ||
        !_videoController!.value.isInitialized) {
      return Container(
        height: 200,
        color: _surface,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
        ),
      );
    }

    return GestureDetector(
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 200,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          if (!_isVideoPlaying)
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}