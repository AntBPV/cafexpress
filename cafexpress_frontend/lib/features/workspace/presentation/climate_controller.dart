import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/climate_trend.dart';

class ClimateController extends ChangeNotifier with WidgetsBindingObserver {
  ClimateController({
    required this.load,
    this.interval = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final Future<ClimateSnapshot> Function() load;
  final Duration interval;
  final DateTime Function() _now;
  ClimateSnapshot data = const ClimateSnapshot();
  Object? error;
  bool loading = false;
  DateTime? updated, _lastModal;
  Timer? _timer;
  bool _disposed = false, _started = false, _resumed = true;
  final Map<String, bool> _shown = {};

  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _resumed = state == null || state == AppLifecycleState.resumed;
    if (_resumed) {
      unawaited(refresh());
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  bool get isResumed => _resumed;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_resumed && !_disposed) {
      if (updated == null || _now().difference(updated!) >= interval) {
        unawaited(refresh());
      }
      _schedule();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_disposed || loading || !_resumed) return;
    loading = true;
    notifyListeners();
    try {
      final result = await load();
      if (_disposed) return;
      data = result;
      updated = _now();
      error = null;
    } catch (failure) {
      if (_disposed) return;
      error = failure;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  List<ClimateReading> get unseen {
    if (!_resumed || error != null || loading) return [];
    if (_lastModal != null &&
        _now().difference(_lastModal!) < const Duration(minutes: 15)) {
      return [];
    }
    return data.readings
        .where((reading) => _shown[reading.origin] != reading.falling)
        .toList();
  }

  void acknowledge(List<ClimateReading> readings) {
    for (final reading in readings) {
      _shown[reading.origin] = reading.falling;
    }
    _lastModal = _now();
  }

  void stop() {
    _timer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}

class ClimateScope extends InheritedNotifier<ClimateController> {
  const ClimateScope({
    super.key,
    required ClimateController controller,
    required super.child,
  }) : super(notifier: controller);
  static ClimateController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClimateScope>()?.notifier;
}
