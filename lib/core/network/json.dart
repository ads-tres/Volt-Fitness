import '../errors/failure.dart';

/// Typed reads from decoded JSON. A missing or mistyped required field
/// throws a [FormatException]; optional fields read as null instead.
extension JsonObject on Map<String, dynamic> {
  T field<T>(String key) => switch (this[key]) {
    final T value => value,
    _ => throw FormatException('Missing or invalid "$key"'),
  };

  T? optional<T>(String key) => switch (this[key]) {
    final T value => value,
    _ => null,
  };

  /// A list of objects, skipping entries that aren't objects.
  List<Map<String, dynamic>> objects(String key) => [
    for (final item in optional<List<dynamic>>(key) ?? const <dynamic>[])
      if (item is Map<String, dynamic>) item,
  ];
}

/// The `data` object of an API response.
Map<String, dynamic> dataObject(Object? response) => switch (response) {
  {'data': final Map<String, dynamic> data} => data,
  _ => throw const UnexpectedFailure(cause: FormatException('Response has no "data" object')),
};

/// Runs [parse] on a response. A response the app can't read is the API
/// breaking the contract, not something the member can fix, so it surfaces
/// as an [UnexpectedFailure].
T readResponse<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException catch (error) {
    throw UnexpectedFailure(cause: error);
  } on TypeError catch (error) {
    throw UnexpectedFailure(cause: error);
  }
}
