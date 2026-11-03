import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

class RoomGallery extends StatefulWidget {
  const RoomGallery({super.key, required this.images, required this.label});

  final List<String> images;
  final String label;

  @override
  State<RoomGallery> createState() => _RoomGalleryState();
}

class _RoomGalleryState extends State<RoomGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => ApiImage(
              path: images.isEmpty ? null : images[index],
              label: widget.label,
              width: double.infinity,
              height: 220,
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: _PageDots(count: images.length, current: _page),
            ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == current ? colors.primary : colors.surface,
              border: Border.all(color: colors.primary),
            ),
          ),
      ],
    );
  }
}
