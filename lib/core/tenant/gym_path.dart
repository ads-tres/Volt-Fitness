import '../errors/failure.dart';

/// The API path of [path] within the gym with [slug]: `/me/gyms/{slug}{path}`.
/// The API takes the gym from the path, and answers 404 for a gym the member
/// doesn't belong to. With no gym chosen there is nothing to ask for.
String gymPath(String? slug, String path) {
  if (slug == null) throw const NotFoundFailure(message: 'No gym is selected.');
  return '/me/gyms/${Uri.encodeComponent(slug)}$path';
}
