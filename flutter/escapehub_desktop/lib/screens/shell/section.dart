import 'package:flutter/material.dart';

enum SectionGroup {
  overview('Overview'),
  operations('Operations'),
  customers('Customers'),
  insights('Insights'),
  administration('Administration');

  const SectionGroup(this.label);

  final String label;
}

enum Section {
  dashboard('Dashboard', Icons.space_dashboard_outlined, SectionGroup.overview),
  notifications('Notifications', Icons.notifications_outlined, SectionGroup.overview),
  bookings('Bookings', Icons.event_note_outlined, SectionGroup.operations),
  schedules('Schedules', Icons.calendar_month_outlined, SectionGroup.operations),
  rooms('Rooms', Icons.meeting_room_outlined, SectionGroup.operations),
  scenarios('Scenarios', Icons.auto_stories_outlined, SectionGroup.operations),
  promotions('Promotions', Icons.local_offer_outlined, SectionGroup.operations),
  clients('Clients', Icons.groups_outlined, SectionGroup.customers),
  reviews('Reviews', Icons.reviews_outlined, SectionGroup.customers),
  loyalty('Loyalty', Icons.loyalty_outlined, SectionGroup.customers, adminOnly: true),
  reports('Reports', Icons.insert_chart_outlined, SectionGroup.insights),
  users('Users', Icons.manage_accounts_outlined, SectionGroup.administration, adminOnly: true),
  referenceData('Reference data', Icons.dataset_outlined, SectionGroup.administration, adminOnly: true),
  settings('Settings', Icons.settings_outlined, SectionGroup.administration, adminOnly: true);

  const Section(this.label, this.icon, this.group, {this.adminOnly = false});

  final String label;
  final IconData icon;
  final SectionGroup group;
  final bool adminOnly;

  static List<Section> visibleFor({required bool isAdministrator}) => [
    for (final section in values)
      if (isAdministrator || !section.adminOnly) section,
  ];
}
