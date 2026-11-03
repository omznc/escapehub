import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Revision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final bookingsRevisionProvider = NotifierProvider<Revision, int>(Revision.new);

final loyaltyRevisionProvider = NotifierProvider<Revision, int>(Revision.new);

final reviewsRevisionProvider = NotifierProvider<Revision, int>(Revision.new);

enum ShellTab { home, explore, bookings, rewards, profile }

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return ShellTab.home;
  }

  void select(ShellTab tab) => state = tab;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(ShellTabNotifier.new);

class NewBookingNotifier extends Notifier<BookingListItemDto?> {
  @override
  BookingListItemDto? build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return null;
  }

  void show(BookingListItemDto booking) => state = booking;
}

final newBookingProvider = NotifierProvider<NewBookingNotifier, BookingListItemDto?>(NewBookingNotifier.new);

extension BookingChanges on WidgetRef {
  void bookingsChanged() => bookingsRefresh()();

  VoidCallback bookingsRefresh() {
    final bookings = read(bookingsRevisionProvider.notifier);
    final loyalty = read(loyaltyRevisionProvider.notifier);
    return () {
      bookings.bump();
      loyalty.bump();
    };
  }
}
