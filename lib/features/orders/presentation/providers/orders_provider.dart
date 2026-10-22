import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';

/// Available order filters in My Orders.
enum OrderFilter {
  all,
  inProgress,
  delivered,
  cancelled;

  String get label => switch (this) {
    OrderFilter.all => 'All',
    OrderFilter.inProgress => 'In Progress',
    OrderFilter.delivered => 'Delivered',
    OrderFilter.cancelled => 'Cancelled',
  };
}

/// Normalized order lifecycle status.
enum QuickBiteOrderStatus {
  placed,
  preparing,
  readyForPickup,
  onTheWay,
  delivered,
  cancelled;

  static QuickBiteOrderStatus fromString(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'placed' || s == 'confirmed') {
      return QuickBiteOrderStatus.placed;
    }
    if (s == 'preparing' || s.contains('prep')) {
      return QuickBiteOrderStatus.preparing;
    }
    if (s == 'ready for pickup' || s.contains('pickup')) {
      return QuickBiteOrderStatus.readyForPickup;
    }
    if (s == 'on the way' || s.contains('way') || s.contains('delivery')) {
      return QuickBiteOrderStatus.onTheWay;
    }
    if (s == 'delivered') {
      return QuickBiteOrderStatus.delivered;
    }
    if (s == 'cancelled' || s.contains('cancel')) {
      return QuickBiteOrderStatus.cancelled;
    }
    return QuickBiteOrderStatus.placed;
  }

  String get label => switch (this) {
    QuickBiteOrderStatus.placed => 'Placed',
    QuickBiteOrderStatus.preparing => 'Preparing',
    QuickBiteOrderStatus.readyForPickup => 'Ready for Pickup',
    QuickBiteOrderStatus.onTheWay => 'On the Way',
    QuickBiteOrderStatus.delivered => 'Delivered',
    QuickBiteOrderStatus.cancelled => 'Cancelled',
  };

  bool get isInProgress =>
      this == QuickBiteOrderStatus.placed ||
      this == QuickBiteOrderStatus.preparing ||
      this == QuickBiteOrderStatus.readyForPickup ||
      this == QuickBiteOrderStatus.onTheWay;
}

/// State holding orders and active filter selection.
class OrdersState {
  final List<Order> orders;
  final OrderFilter activeFilter;

  const OrdersState({
    this.orders = const [],
    this.activeFilter = OrderFilter.all,
  });

  bool get isEmpty => orders.isEmpty;
  bool get isNotEmpty => orders.isNotEmpty;

  /// Returns orders matching the active filter.
  List<Order> get filteredOrders {
    switch (activeFilter) {
      case OrderFilter.all:
        return orders;
      case OrderFilter.inProgress:
        return orders.where((order) {
          final status = QuickBiteOrderStatus.fromString(order.status);
          return status.isInProgress;
        }).toList();
      case OrderFilter.delivered:
        return orders.where((order) {
          final status = QuickBiteOrderStatus.fromString(order.status);
          return status == QuickBiteOrderStatus.delivered;
        }).toList();
      case OrderFilter.cancelled:
        return orders.where((order) {
          final status = QuickBiteOrderStatus.fromString(order.status);
          return status == QuickBiteOrderStatus.cancelled;
        }).toList();
    }
  }

  /// Looks up order by ID.
  Order? getOrderById(String orderId) {
    try {
      return orders.firstWhere((order) => order.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  OrdersState copyWith({List<Order>? orders, OrderFilter? activeFilter}) {
    return OrdersState(
      orders: orders ?? this.orders,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

/// Notifier managing Order History state.
class OrdersNotifier extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    final repository = ref.watch(orderRepositoryProvider);
    repository.addListener(_onRepositoryChanged);
    ref.onDispose(() {
      repository.removeListener(_onRepositoryChanged);
    });
    return OrdersState(orders: repository.getOrders());
  }

  void _onRepositoryChanged() {
    final repository = ref.read(orderRepositoryProvider);
    state = state.copyWith(orders: repository.getOrders());
  }

  /// Adds a newly placed order to history and awaits persistence.
  Future<void> addOrder(Order order) async {
    final repository = ref.read(orderRepositoryProvider);
    await repository.addOrder(order);
    state = state.copyWith(orders: repository.getOrders());
  }

  /// Sets active filter chip.
  void setFilter(OrderFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Updates status for an order.
  void updateOrderStatus(String orderId, String newStatus) {
    final repository = ref.read(orderRepositoryProvider);
    repository.updateOrderStatus(orderId, newStatus);
    state = state.copyWith(orders: repository.getOrders());
  }

  /// Clears order history (empty state testing).
  void clearOrders() {
    final repository = ref.read(orderRepositoryProvider);
    repository.clearOrders();
    state = state.copyWith(orders: const []);
  }

  /// Re-loads default mock orders.
  void loadMockOrders() {
    final repository = ref.read(orderRepositoryProvider);
    repository.resetToDefault();
    state = state.copyWith(orders: repository.getOrders());
  }
}

/// Global Riverpod provider for order history.
final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(
  OrdersNotifier.new,
);
