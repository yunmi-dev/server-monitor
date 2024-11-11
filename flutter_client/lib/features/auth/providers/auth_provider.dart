// lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Google Sign In
      await Future.delayed(Duration(seconds: 2)); // 임시 딜레이
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Apple Sign In
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithKakao() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Kakao Sign In
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
