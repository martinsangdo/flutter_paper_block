import 'package:flutter/widgets.dart';

/// App-wide route observer. Screens can subscribe as [RouteAware] to be
/// notified (via `didPopNext`) when a route pushed above them is popped and
/// they become visible again — e.g. the level-select screen refreshing unlock
/// progress after returning from gameplay.
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();
