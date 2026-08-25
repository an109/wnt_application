import 'package:flutter/material.dart';

/// App-wide route observer — lets any screen's State mix in `RouteAware`
/// and get notified (`didPopNext`) when it becomes visible again after a
/// pushed screen above it is popped, instead of only ever loading its data
/// once in `initState`. Registered on `MaterialApp.navigatorObservers`.
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
