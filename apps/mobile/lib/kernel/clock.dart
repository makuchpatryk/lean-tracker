/// The current time. Injected so rules that depend on "now" can be tested with a fixed time
/// (CODE_QUALITY: state and side effects).
abstract interface class Clock {
  DateTime now();
}

/// The device clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
