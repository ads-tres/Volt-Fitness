import 'gq1.dart';

/// What the phone needs to make QR codes on its own, offline included.
final class AccessCredential {
  const AccessCredential({required this.id, required this.secret, this.algorithm = 'GQ1'});

  /// Reads the 64 hex characters the API sends.
  factory AccessCredential.fromHex({required String id, required String secretHex, String algorithm = 'GQ1'}) {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(secretHex)) {
      throw const FormatException('The secret must be 64 hex characters');
    }
    return AccessCredential(
      id: id,
      secret: [for (var i = 0; i < 64; i += 2) int.parse(secretHex.substring(i, i + 2), radix: 16)],
      algorithm: algorithm,
    );
  }

  final String id;
  final List<int> secret;
  final String algorithm;

  String get secretHex => [for (final byte in secret) byte.toRadixString(16).padLeft(2, '0')].join();

  /// The QR content at [serverNow].
  String payloadAt(DateTime serverNow) => Gq1.payload(secret, id, Gq1.stepAt(serverNow));
}

/// Where the API stands on this phone's credential.
final class CredentialStatus {
  const CredentialStatus({required this.credentialId, required this.isActive, this.revokedReason});

  final String credentialId;
  final bool isActive;

  /// `replaced` (a newer phone took over), `signed_out`, `device_removed` or
  /// `staff`.
  final String? revokedReason;
}
