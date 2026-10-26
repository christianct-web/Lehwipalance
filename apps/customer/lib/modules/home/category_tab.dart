import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/new_widgets.dart';
import 'package:lehwipalancecustomerv1/modules/home/palance_widget.dart';
import 'package:table_calendar/table_calendar.dart';

/// Base category tab that handles filtering and display
class CategoryTab extends StatefulWidget {
  final List<PalanceItem> items;
  final ListingType type;
  final void Function(PalanceItem) onItemTap;
  final Future<void> Function(PalanceItem) onFavoriteToggle;
  final CustomerProvider customerProvider;
  final AuthProvider authProvider;

  const CategoryTab({
    super.key,
    required this.items,
    required this.type,
    required this.onItemTap,
    required this.onFavoriteToggle,
    required this.customerProvider,
    required this.authProvider,
  });

  @override
  State<CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<CategoryTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _subTabController;
  int _selectedSubTabIndex = 0;
  List<PalanceItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: _getSubTabs().length,
      vsync: this,
    );
    _applyFilter(0);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _applyFilter(_selectedSubTabIndex);
    }
  }

  List<String> _getSubTabs() {
    switch (widget.type) {
      case ListingType.event:
        return EventSubTab.values.map((e) => e.label).toList();
      case ListingType.place:
        return PlaceSubTab.values.map((e) => e.label).toList();
      case ListingType.hotel:
        return HotelSubTab.values.map((e) => e.label).toList();
      case ListingType.service:
        return ServiceSubTab.values.map((e) => e.label).toList();
      case ListingType.store:
        return StoreSubTab.values.map((e) => e.label).toList();
      case ListingType.vacation:
        return VacationSubTab.values.map((e) => e.label).toList();
    }
  }

  void _applyFilter(int index) {
    setState(() {
      _selectedSubTabIndex = index;
      _filteredItems = _filterItems(widget.items, index);
    });
  }

  List<PalanceItem> _filterItems(List<PalanceItem> items, int index) {
    if (index == 0) return items;

    switch (widget.type) {
      case ListingType.event:
        return _filterEvents(items, EventSubTab.values[index]);
      case ListingType.place:
        return _filterPlaces(items, PlaceSubTab.values[index]);
      case ListingType.hotel:
        return _filterHotels(items, HotelSubTab.values[index]);
      case ListingType.service:
        return _filterServices(items, ServiceSubTab.values[index]);
      case ListingType.store:
        return _filterStores(items, StoreSubTab.values[index]);
      case ListingType.vacation:
        return _filterVacations(items, VacationSubTab.values[index]);
    }
  }

  List<PalanceItem> _filterEvents(List<PalanceItem> items, EventSubTab subTab) {
    final now = DateTime.now();
    final weekendStart = now.add(Duration(days: (5 - now.weekday) % 7));
    final weekendEnd = weekendStart.add(const Duration(days: 2));

    return items.where((item) {
      final date = item.date;
      if (date == null) return subTab == EventSubTab.all;

      switch (subTab) {
        case EventSubTab.all:
          return true;
        case EventSubTab.today:
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        case EventSubTab.thisWeekend:
          return date.isAfter(weekendStart.subtract(const Duration(days: 1))) &&
              date.isBefore(weekendEnd.add(const Duration(days: 1)));
        case EventSubTab.upcoming:
          return date.isAfter(now);
        case EventSubTab.free:
          return true;
        case EventSubTab.paid:
          return false;
      }
    }).toList();
  }

  List<PalanceItem> _filterPlaces(List<PalanceItem> items, PlaceSubTab subTab) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case PlaceSubTab.all:
          return true;
        case PlaceSubTab.restaurants:
          return sub.contains('restaurant') || sub.contains('food');
        case PlaceSubTab.cafes:
          return sub.contains('cafe') || sub.contains('coffee');
        case PlaceSubTab.nightlife:
          return sub.contains('bar') ||
              sub.contains('club') ||
              sub.contains('night');
        case PlaceSubTab.attractions:
          return sub.contains('attraction') ||
              sub.contains('museum') ||
              sub.contains('park');
        case PlaceSubTab.shopping:
          return sub.contains('shop') ||
              sub.contains('mall') ||
              sub.contains('store');
      }
    }).toList();
  }

  List<PalanceItem> _filterHotels(List<PalanceItem> items, HotelSubTab subTab) {
    return items.where((item) {
      switch (subTab) {
        case HotelSubTab.all:
          return true;
        case HotelSubTab.luxury:
          return item.rating >= 4.5;
        case HotelSubTab.budget:
          return item.rating >= 3.0 && item.rating < 4.0;
        case HotelSubTab.boutique:
          return item.subtitle.toLowerCase().contains('boutique');
        case HotelSubTab.resorts:
          return item.subtitle.toLowerCase().contains('resort');
      }
    }).toList();
  }

  List<PalanceItem> _filterServices(
    List<PalanceItem> items,
    ServiceSubTab subTab,
  ) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case ServiceSubTab.all:
          return true;
        case ServiceSubTab.beauty:
          return sub.contains('beauty') ||
              sub.contains('spa') ||
              sub.contains('salon');
        case ServiceSubTab.fitness:
          return sub.contains('fitness') ||
              sub.contains('gym') ||
              sub.contains('yoga');
        case ServiceSubTab.auto:
          return sub.contains('auto') ||
              sub.contains('car') ||
              sub.contains('mechanic');
        case ServiceSubTab.education:
          return sub.contains('education') ||
              sub.contains('school') ||
              sub.contains('tutor');
        case ServiceSubTab.legal:
          return sub.contains('legal') ||
              sub.contains('lawyer') ||
              sub.contains('attorney');
        case ServiceSubTab.home:
          return sub.contains('home') ||
              sub.contains('repair') ||
              sub.contains('cleaning');
      }
    }).toList();
  }

  List<PalanceItem> _filterStores(List<PalanceItem> items, StoreSubTab subTab) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case StoreSubTab.all:
          return true;
        case StoreSubTab.clothing:
          return sub.contains('cloth') ||
              sub.contains('fashion') ||
              sub.contains('apparel');
        case StoreSubTab.electronics:
          return sub.contains('electronic') ||
              sub.contains('phone') ||
              sub.contains('computer') ||
              sub.contains('tech');
        case StoreSubTab.groceries:
          return sub.contains('grocer') ||
              sub.contains('food') ||
              sub.contains('market');
        case StoreSubTab.pharmacy:
          return sub.contains('pharm') || sub.contains('drug');
        case StoreSubTab.books:
          return sub.contains('book') || sub.contains('stationer');
        case StoreSubTab.toys:
          return sub.contains('toy') || sub.contains('game');
        case StoreSubTab.jewelry:
          return sub.contains('jewel') ||
              sub.contains('gold') ||
              sub.contains('watch');
        case StoreSubTab.furniture:
          return sub.contains('furnit') ||
              sub.contains('home') ||
              sub.contains('decor');
      }
    }).toList();
  }

  List<PalanceItem> _filterVacations(
    List<PalanceItem> items,
    VacationSubTab subTab,
  ) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case VacationSubTab.all:
          return true;
        case VacationSubTab.beach:
          return sub.contains('beach') ||
              sub.contains('coast') ||
              sub.contains('sea');
        case VacationSubTab.mountain:
          return sub.contains('mountain') ||
              sub.contains('hike') ||
              sub.contains('peak');
        case VacationSubTab.city:
          return sub.contains('city') || sub.contains('urban');
        case VacationSubTab.countryside:
          return sub.contains('country') ||
              sub.contains('rural') ||
              sub.contains('farm');
        case VacationSubTab.island:
          return sub.contains('island') || sub.contains('isle');
        case VacationSubTab.adventure:
          return sub.contains('adventure') ||
              sub.contains('safari') ||
              sub.contains('trek');
        case VacationSubTab.cruise:
          return sub.contains('cruise') ||
              sub.contains('boat') ||
              sub.contains('yacht');
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final subTabs = _getSubTabs();
    if (subTabs.length <= 1) {
      return _buildContent();
    }

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            tabs: subTabs.map((tab) => Tab(text: tab)).toList(),
            onTap: _applyFilter,
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final featured = items.take(4).toList();
    final allItems = items.toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (featured.isNotEmpty) ...[
                _buildSectionHeader('Featured ${widget.type.label}s'),
                const SizedBox(height: 12),
                _buildFeaturedCarousel(featured),
                const SizedBox(height: 28),
              ],
              if (allItems.isNotEmpty) ...[
                _buildSectionHeader('All ${widget.type.label}s'),
                const SizedBox(height: 12),
                ...allItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildListCard(item),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getEmptyIcon(), size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No ${widget.type.label}s found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyMessage(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (widget.type) {
      case ListingType.event:
        return Icons.event_busy_rounded;
      case ListingType.place:
        return Icons.location_off_rounded;
      case ListingType.hotel:
        return Icons.hotel_rounded;
      case ListingType.service:
        return Icons.handyman_rounded;
      case ListingType.store:
        return Icons.storefront_rounded;
      case ListingType.vacation:
        return Icons.beach_access_rounded;
    }
  }

  String _getEmptyMessage() {
    switch (widget.type) {
      case ListingType.event:
        return 'Check back soon for upcoming events.';
      case ListingType.place:
        return 'Discover places to eat, lime and explore.';
      case ListingType.hotel:
        return 'Accommodation options will appear here.';
      case ListingType.service:
        return 'Find local businesses and service providers.';
      case ListingType.store:
        return 'Shops and stores near you will appear here.';
      case ListingType.vacation:
        return 'Vacation getaways and escapes will appear here.';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCarousel(List<PalanceItem> items) {
    return SizedBox(
      height: 260,
      child: CarouselSlider.builder(
        itemCount: items.length,
        options: CarouselOptions(
          height: 260,
          viewportFraction: 0.9,
          enableInfiniteScroll: items.length > 1,
          autoPlay: items.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          enlargeCenterPage: true,
          enlargeFactor: 0.1,
        ),
        itemBuilder: (context, index, _) {
          final item = items[index];
          final isFavorite = widget.customerProvider.isFavorite(
            item.type,
            item.id,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PalanceLargeCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              isFavorite: isFavorite,
              onFavoriteToggle: () => widget.onFavoriteToggle(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard(PalanceItem item) {
    final isFavorite = widget.customerProvider.isFavorite(item.type, item.id);

    switch (widget.type) {
      case ListingType.event:
        return PalanceEventListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.place:
        return PalancePlaceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.hotel:
        return PalanceHotelListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.service:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.store:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.vacation:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
    }
  }
}

class EventListTab extends StatefulWidget {
  final List<PalanceItem> items;
  final ListingType type;
  final void Function(PalanceItem) onItemTap;
  final Future<void> Function(PalanceItem) onFavoriteToggle;
  final CustomerProvider customerProvider;
  final AuthProvider authProvider;

  const EventListTab({
    super.key,
    required this.items,
    required this.type,
    required this.onItemTap,
    required this.onFavoriteToggle,
    required this.customerProvider,
    required this.authProvider,
  });

  @override
  State<EventListTab> createState() => _EventListTabState();
}

class _EventListTabState extends State<EventListTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _subTabController;
  int _selectedSubTabIndex = 0;
  List<PalanceItem> _filteredItems = [];

  // Calendar-related state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isCalendarVisible = false;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: _getSubTabs().length,
      vsync: this,
    );
    _applyFilter(0);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _applyFilter(_selectedSubTabIndex);
    }
  }

  List<String> _getSubTabs() {
    // Event type uses its own labels (with a Calendar FAB)
    if (widget.type == ListingType.event) {
      return ['All', 'Today', 'This Weekend', 'Upcoming', 'Free', 'Paid'];
    }

    switch (widget.type) {
      case ListingType.place:
        return PlaceSubTab.values.map((e) => e.label).toList();
      case ListingType.hotel:
        return HotelSubTab.values.map((e) => e.label).toList();
      case ListingType.service:
        return ServiceSubTab.values.map((e) => e.label).toList();
      case ListingType.store:
        return StoreSubTab.values.map((e) => e.label).toList();
      case ListingType.vacation:
        return VacationSubTab.values.map((e) => e.label).toList();
      case ListingType.event:
        return ['All']; // unreachable; satisfies analyzer
    }
  }

  void _applyFilter(int index) {
    setState(() {
      _selectedSubTabIndex = index;
      _filteredItems = _filterItems(widget.items, index);
    });
  }

  List<PalanceItem> _filterItems(List<PalanceItem> items, int index) {
    if (index == 0) return items;

    switch (widget.type) {
      case ListingType.event:
        return _filterEvents(items, index);
      case ListingType.place:
        return _filterPlaces(items, PlaceSubTab.values[index]);
      case ListingType.hotel:
        return _filterHotels(items, HotelSubTab.values[index]);
      case ListingType.service:
        return _filterServices(items, ServiceSubTab.values[index]);
      case ListingType.store:
        return _filterStores(items, StoreSubTab.values[index]);
      case ListingType.vacation:
        return _filterVacations(items, VacationSubTab.values[index]);
    }
  }

  List<PalanceItem> _filterEvents(List<PalanceItem> items, int index) {
    final now = DateTime.now();
    final weekendStart = now.add(Duration(days: (5 - now.weekday) % 7));
    final weekendEnd = weekendStart.add(const Duration(days: 2));

    final subTabs = _getSubTabs();
    final subTab = subTabs[index];

    return items.where((item) {
      final date = _getEventDate(item);
      if (date == null) return subTab == 'All';

      switch (subTab) {
        case 'All':
          return true;
        case 'Today':
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        case 'This Weekend':
          return date.isAfter(weekendStart.subtract(const Duration(days: 1))) &&
              date.isBefore(weekendEnd.add(const Duration(days: 1)));
        case 'Upcoming':
          return date.isAfter(now);
        // case 'Free':
        //   return item.price == null || item.price == 0;
        // case 'Paid':
        //   return item.price != null && item.price > 0;
        default:
          return true;
      }
    }).toList();
  }

  List<PalanceItem> _filterPlaces(List<PalanceItem> items, PlaceSubTab subTab) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case PlaceSubTab.all:
          return true;
        case PlaceSubTab.restaurants:
          return sub.contains('restaurant') || sub.contains('food');
        case PlaceSubTab.cafes:
          return sub.contains('cafe') || sub.contains('coffee');
        case PlaceSubTab.nightlife:
          return sub.contains('bar') ||
              sub.contains('club') ||
              sub.contains('night');
        case PlaceSubTab.attractions:
          return sub.contains('attraction') ||
              sub.contains('museum') ||
              sub.contains('park');
        case PlaceSubTab.shopping:
          return sub.contains('shop') ||
              sub.contains('mall') ||
              sub.contains('store');
      }
    }).toList();
  }

  List<PalanceItem> _filterHotels(List<PalanceItem> items, HotelSubTab subTab) {
    return items.where((item) {
      switch (subTab) {
        case HotelSubTab.all:
          return true;
        case HotelSubTab.luxury:
          return item.rating >= 4.5;
        case HotelSubTab.budget:
          return item.rating >= 3.0 && item.rating < 4.0;
        case HotelSubTab.boutique:
          return item.subtitle.toLowerCase().contains('boutique');
        case HotelSubTab.resorts:
          return item.subtitle.toLowerCase().contains('resort');
      }
    }).toList();
  }

  List<PalanceItem> _filterServices(
    List<PalanceItem> items,
    ServiceSubTab subTab,
  ) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case ServiceSubTab.all:
          return true;
        case ServiceSubTab.beauty:
          return sub.contains('beauty') ||
              sub.contains('spa') ||
              sub.contains('salon');
        case ServiceSubTab.fitness:
          return sub.contains('fitness') ||
              sub.contains('gym') ||
              sub.contains('yoga');
        case ServiceSubTab.auto:
          return sub.contains('auto') ||
              sub.contains('car') ||
              sub.contains('mechanic');
        case ServiceSubTab.education:
          return sub.contains('education') ||
              sub.contains('school') ||
              sub.contains('tutor');
        case ServiceSubTab.legal:
          return sub.contains('legal') ||
              sub.contains('lawyer') ||
              sub.contains('attorney');
        case ServiceSubTab.home:
          return sub.contains('home') ||
              sub.contains('repair') ||
              sub.contains('cleaning');
      }
    }).toList();
  }

  List<PalanceItem> _filterStores(List<PalanceItem> items, StoreSubTab subTab) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case StoreSubTab.all:
          return true;
        case StoreSubTab.clothing:
          return sub.contains('cloth') ||
              sub.contains('fashion') ||
              sub.contains('apparel');
        case StoreSubTab.electronics:
          return sub.contains('electronic') ||
              sub.contains('phone') ||
              sub.contains('computer') ||
              sub.contains('tech');
        case StoreSubTab.groceries:
          return sub.contains('grocer') ||
              sub.contains('food') ||
              sub.contains('market');
        case StoreSubTab.pharmacy:
          return sub.contains('pharm') || sub.contains('drug');
        case StoreSubTab.books:
          return sub.contains('book') || sub.contains('stationer');
        case StoreSubTab.toys:
          return sub.contains('toy') || sub.contains('game');
        case StoreSubTab.jewelry:
          return sub.contains('jewel') ||
              sub.contains('gold') ||
              sub.contains('watch');
        case StoreSubTab.furniture:
          return sub.contains('furnit') ||
              sub.contains('home') ||
              sub.contains('decor');
      }
    }).toList();
  }

  List<PalanceItem> _filterVacations(
    List<PalanceItem> items,
    VacationSubTab subTab,
  ) {
    return items.where((item) {
      final sub = item.subtitle.toLowerCase();
      switch (subTab) {
        case VacationSubTab.all:
          return true;
        case VacationSubTab.beach:
          return sub.contains('beach') ||
              sub.contains('coast') ||
              sub.contains('sea');
        case VacationSubTab.mountain:
          return sub.contains('mountain') ||
              sub.contains('hike') ||
              sub.contains('peak');
        case VacationSubTab.city:
          return sub.contains('city') || sub.contains('urban');
        case VacationSubTab.countryside:
          return sub.contains('country') ||
              sub.contains('rural') ||
              sub.contains('farm');
        case VacationSubTab.island:
          return sub.contains('island') || sub.contains('isle');
        case VacationSubTab.adventure:
          return sub.contains('adventure') ||
              sub.contains('safari') ||
              sub.contains('trek');
        case VacationSubTab.cruise:
          return sub.contains('cruise') ||
              sub.contains('boat') ||
              sub.contains('yacht');
      }
    }).toList();
  }

  // Helper method to get event date from PalanceItem
  // This tries multiple possible date fields
  DateTime? _getEventDate(PalanceItem item) {
    // Try the date field first
    if (item.date != null) {
      return item.date;
    }

    // If your PalanceItem has a startDate field, check that
    // You might need to add this to your PalanceItem model
    // For now, we'll use a fallback

    // If the item has a property that stores startDate, check it
    // This depends on your PalanceItem implementation
    try {
      // If PalanceItem has a 'startDate' property via getter
      final startDate = (item as dynamic).startDate;
      if (startDate is DateTime) {
        return startDate;
      }
    } catch (_) {
      // Ignore - property doesn't exist
    }

    // For events that span multiple days, you might want to show them
    // on multiple calendar days. You'll need to handle this based on
    // your data structure.

    // For now, if no date is found, we'll use a default future date
    // based on the item's id to simulate events on different days
    return _getFallbackDate(item.id);
  }

  // Fallback to simulate events on different dates for demo purposes
  // In production, you would use the actual startDate from your data
  DateTime _getFallbackDate(String id) {
    // Use the id to generate a consistent but varying date
    // This is just for demonstration - replace with actual data
    final hash = id.hashCode.abs();
    final dayOffset = hash % 60; // Spread events over 60 days
    return DateTime.now().add(Duration(days: dayOffset));
  }

  // Calendar helper methods
  List<PalanceItem> _getEventsForDay(DateTime day) {
    return widget.items.where((item) {
      final itemDate = _getEventDate(item);
      if (itemDate == null) return false;

      // For multi-day events, check if the day falls within the range
      // This requires knowing the endDate as well
      // For now, we'll just check the start date

      return itemDate.year == day.year &&
          itemDate.month == day.month &&
          itemDate.day == day.day;
    }).toList();
  }

  bool _hasEvents(DateTime day) {
    return _getEventsForDay(day).isNotEmpty;
  }

  int _getEventCount(DateTime day) {
    return _getEventsForDay(day).length;
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // For event type, show the enhanced view with calendar
    if (widget.type == ListingType.event) {
      return _buildEventView();
    }

    // For other types, show the original CategoryTab view
    return _buildCategoryView();
  }

  Widget _buildEventView() {
    final subTabs = _getSubTabs();

    // Filter items based on selected sub-tab
    final itemsToShow = _filteredItems;

    // Check if we should show events for selected day or all items
    final displayItems = _isCalendarVisible
        ? _getEventsForDay(_selectedDay)
        : itemsToShow;

    return Scaffold(
      body: Stack(
        children: [
          // Main content - same as CategoryTab
          Column(
            children: [
              // Tab Bar for event filtering
              if (subTabs.length > 1)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _subTabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    tabs: subTabs.map((tab) => Tab(text: tab)).toList(),
                    onTap: _applyFilter,
                  ),
                ),
              // Content - same as CategoryTab
              Expanded(
                child: displayItems.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(displayItems),
              ),
            ],
          ),
          // Calendar Popup
          if (_isCalendarVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCalendarPopup(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleCalendar,
        icon: Icon(_isCalendarVisible ? Icons.close : Icons.calendar_month),
        label: Text(_isCalendarVisible ? 'Close Calendar' : 'Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryView() {
    final subTabs = _getSubTabs();
    if (subTabs.length <= 1) {
      return _buildContent(widget.items);
    }

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            tabs: subTabs.map((tab) => Tab(text: tab)).toList(),
            onTap: _applyFilter,
          ),
        ),
        Expanded(child: _buildContent(_filteredItems)),
      ],
    );
  }

  Widget _buildContent(List<PalanceItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final featured = items.take(4).toList();
    final allItems = items.toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (featured.isNotEmpty) ...[
                _buildSectionHeader('Featured ${widget.type.label}s'),
                const SizedBox(height: 12),
                _buildFeaturedCarousel(featured),
                const SizedBox(height: 28),
              ],
              if (allItems.isNotEmpty) ...[
                _buildSectionHeader('All ${widget.type.label}s'),
                const SizedBox(height: 12),
                ...allItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildListCard(item),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPopup() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Calendar
          Container(
            height: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2026, 12, 31),
              selectedDayPredicate: (day) {
                return _isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  // Auto-close calendar when a day is selected
                  _isCalendarVisible = false;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final eventCount = _getEventCount(day);
                  final isSelected = _isSameDay(_selectedDay, day);
                  final hasEvents = _hasEvents(day);
                  final isToday = _isSameDay(DateTime.now(), day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : hasEvents
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Date number
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : hasEvents
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected || hasEvents
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        // Badge below the date number (not overlapping)
                        if (eventCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              eventCount.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final eventCount = _getEventCount(day);
                  final isSelected = _isSameDay(_selectedDay, day);
                  final hasEvents = _hasEvents(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : hasEvents
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Date number
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Badge below the date number (not overlapping)
                        if (eventCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              eventCount.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final eventCount = _getEventCount(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Date number
                        Text(
                          day.day.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Badge below the date number (not overlapping)
                        if (eventCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              eventCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: Colors.red[300],
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: const CalendarStyle(
                isTodayHighlighted: false,
                defaultDecoration: BoxDecoration(),
                weekendDecoration: BoxDecoration(),
                selectedDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Existing methods from original CategoryTab
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getEmptyIcon(), size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No ${widget.type.label}s found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyMessage(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (widget.type) {
      case ListingType.event:
        return Icons.event_busy_rounded;
      case ListingType.place:
        return Icons.location_off_rounded;
      case ListingType.hotel:
        return Icons.hotel_rounded;
      case ListingType.service:
        return Icons.handyman_rounded;
      case ListingType.store:
        return Icons.storefront_rounded;
      case ListingType.vacation:
        return Icons.beach_access_rounded;
    }
  }

  String _getEmptyMessage() {
    switch (widget.type) {
      case ListingType.event:
        return 'Check back soon for upcoming events.';
      case ListingType.place:
        return 'Discover places to eat, lime and explore.';
      case ListingType.hotel:
        return 'Accommodation options will appear here.';
      case ListingType.service:
        return 'Find local businesses and service providers.';
      case ListingType.store:
        return 'Shops and stores near you will appear here.';
      case ListingType.vacation:
        return 'Vacation getaways and escapes will appear here.';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCarousel(List<PalanceItem> items) {
    return SizedBox(
      height: 260,
      child: CarouselSlider.builder(
        itemCount: items.length,
        options: CarouselOptions(
          height: 260,
          viewportFraction: 0.9,
          enableInfiniteScroll: items.length > 1,
          autoPlay: items.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          enlargeCenterPage: true,
          enlargeFactor: 0.1,
        ),
        itemBuilder: (context, index, _) {
          final item = items[index];
          final isFavorite = widget.customerProvider.isFavorite(
            item.type,
            item.id,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PalanceLargeCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              isFavorite: isFavorite,
              onFavoriteToggle: () => widget.onFavoriteToggle(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard(PalanceItem item) {
    final isFavorite = widget.customerProvider.isFavorite(item.type, item.id);

    switch (widget.type) {
      case ListingType.event:
        return PalanceEventListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.place:
        return PalancePlaceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.hotel:
        return PalanceHotelListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.service:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.store:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.vacation:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
    }
  }
}
