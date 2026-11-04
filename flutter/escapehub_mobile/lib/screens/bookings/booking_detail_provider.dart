import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

final bookingProvider = FutureProvider.autoDispose.family<BookingDto, int>((ref, id) {
  ref.watch(bookingsRevisionProvider);
  return ref.watch(apiClientProvider).bookings.get(id);
});

Future<BookingDto> _verifyOpenPayment(ApiClient api, BookingDto booking) async {
  if (booking.paymentStatus != 'Open') return booking;
  try {
    return await api.bookings.verifyPayment(booking.id);
  } on ApiException {
    return booking;
  }
}

final bookingDetailProvider = FutureProvider.autoDispose.family<(BookingDto, ReviewDto?), int>((ref, id) async {
  ref.watch(bookingsRevisionProvider);
  ref.watch(reviewsRevisionProvider);
  final api = ref.watch(apiClientProvider);
  final booking = await _verifyOpenPayment(api, await api.bookings.get(id));
  if (booking.status != BookingStatus.completed) return (booking, null);
  final reviews = await api.reviews.mine(roomId: booking.roomId, pageSize: 1);
  return (booking, reviews.items.firstOrNull);
});
