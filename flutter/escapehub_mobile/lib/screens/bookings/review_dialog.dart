import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/form_message.dart';
import '../../widgets/rating_field.dart';

Future<ReviewDto?> showReviewDialog(
  BuildContext context, {
  required int roomId,
  required String roomName,
  required ReviewDto? review,
}) => showDialog<ReviewDto>(
  context: context,
  builder: (context) => _ReviewDialog(roomId: roomId, roomName: roomName, review: review),
);

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({required this.roomId, required this.roomName, required this.review});

  final int roomId;
  final String roomName;
  final ReviewDto? review;

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  late final _comment = TextEditingController(text: widget.review?.comment);
  late int? _rating = widget.review?.rating;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<ReviewDto> _save(int rating) {
    final reviews = ref.read(apiClientProvider).reviews;
    final comment = _comment.text.trim().isEmpty ? null : _comment.text.trim();
    final existing = widget.review;
    return existing == null
        ? reviews.create(roomId: widget.roomId, rating: rating, comment: comment)
        : reviews.update(existing.id, rating: rating, comment: comment);
  }

  Future<void> _submit() async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final saved = await _save(_rating!);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      final message = _serverErrors.apply(error);
      if (!mounted) return;
      _form.currentState!.validate();
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DialogTitle(widget.review == null ? 'Review ${widget.roomName}' : 'Edit your review'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingField(
                initialValue: _rating,
                onChanged: (rating) => _rating = rating,
                validator: _serverErrors.validator<int>(
                  'rating',
                  (value) => value == null ? 'Select a rating from 1 to 5 stars.' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comment,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  helperText: 'At most 2000 characters',
                ),
                validator: _serverErrors.validator('comment', Validators.maxLength('Comment', 2000)),
              ),
              FormMessage(_message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(widget.review == null ? 'Publish' : 'Save')),
      ],
    );
  }
}
