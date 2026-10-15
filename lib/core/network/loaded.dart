import '../errors/failure.dart';

/// Data a screen shows, from the cache or the network, and how the latest
/// load went. A failed refresh keeps the data it already had, so the screen
/// can show it with an "offline" note instead of an error page.
final class Loaded<T> {
  const Loaded({this.value, this.failure, this.isLoading = false});

  final T? value;
  final Failure? failure;
  final bool isLoading;

  Loaded<T> loading() => Loaded(value: value, isLoading: true);

  Loaded<T> failed(Failure failure) => Loaded(value: value, failure: failure);
}
