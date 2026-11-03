import 'package:flutter/material.dart';

import '../formatting.dart';

class RatingField extends FormField<int> {
  RatingField({super.key, super.initialValue, super.validator, required ValueChanged<int> onChanged})
    : super(
        builder: (field) {
          final theme = Theme.of(field.context);
          final rating = field.value ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating', style: theme.textTheme.titleSmall),
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: plural(star, 'star'),
                      icon: Icon(star <= rating ? Icons.star : Icons.star_border, color: theme.colorScheme.primary),
                      onPressed: () {
                        field.didChange(star);
                        onChanged(star);
                      },
                    ),
                ],
              ),
              if (field.errorText case final error?)
                Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
          );
        },
      );
}
