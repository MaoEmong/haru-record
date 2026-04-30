part of 'day_detail_screen.dart';

class _SavePlaceDialog extends StatefulWidget {
  const _SavePlaceDialog({required this.item});

  final DayTimelineItem item;

  @override
  State<_SavePlaceDialog> createState() => _SavePlaceDialogState();
}

class _SavePlaceDialogState extends State<_SavePlaceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 머문 곳을 저장할까요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  key: const ValueKey('save-place-map'),
                  height: 180,
                  width: double.infinity,
                  child: PlaceMapPreview(
                    latitude: widget.item.latitude!,
                    longitude: widget.item.longitude!,
                    cacheKey:
                        'save-place-'
                        '${widget.item.latitude!.toStringAsFixed(5)}-'
                        '${widget.item.longitude!.toStringAsFixed(5)}',
                    mapKey: const ValueKey('save-place-preview-map'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${widget.item.timeLabel} · 이 시간대에 머문 곳으로 보여요',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('save-place-name-field'),
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '장소 이름',
                  hintText: '예: 집, 학원, 카페',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
