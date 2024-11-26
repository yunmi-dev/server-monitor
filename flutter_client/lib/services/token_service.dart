// lib/services/token_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class TokenService {
  const TokenService();

  bool isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      return json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } catch (e) {
      return null;
    }
  }

  DateTime? getTokenExpiry(String token) {
    try {
      final payload = getTokenPayload(token);
      if (payload == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    } catch (e) {
      return null;
    }
  }

  bool isTokenExpired(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  Duration? getTokenTimeRemaining(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return null;
    return expiry.difference(DateTime.now());
  }
}
