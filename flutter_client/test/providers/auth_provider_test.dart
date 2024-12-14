// test/providers/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/services/auth_service.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/models/user.dart';
import 'package:flutter_client/models/auth_result.dart';

class MockAuthService extends Mock implements AuthService {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;
  late MockStorageService mockStorageService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockStorageService = MockStorageService();
    authProvider = AuthProvider(
      authService: mockAuthService,
      storageService: mockStorageService,
    );

    when(() => mockStorageService.setToken(any())).thenAnswer((_) async => {});
    when(() => mockStorageService.setRefreshToken(any()))
        .thenAnswer((_) async => {});
    when(() => mockStorageService.clearToken()).thenAnswer((_) async => {});
    when(() => mockStorageService.clearRefreshToken())
        .thenAnswer((_) async => {});
  });

  group('AuthProvider - Initialization', () {
    test('should initialize with stored token and fetch user', () async {
      // Arrange
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        provider: 'email',
        createdAt: DateTime.now(),
      );

      when(() => mockStorageService.getToken())
          .thenAnswer((_) async => 'stored_token');
      when(() => mockStorageService.getRefreshToken())
          .thenAnswer((_) async => 'stored_refresh_token');
      when(() => mockAuthService.getCurrentUser())
          .thenAnswer((_) async => mockUser);

      // Act
      await authProvider.initialize();

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, equals(mockUser));
      expect(authProvider.isInitializing, isFalse);
      verify(() => mockAuthService.getCurrentUser()).called(1);
    });

    test('should handle initialization failure gracefully', () async {
      // Arrange
      when(() => mockStorageService.getToken())
          .thenAnswer((_) async => 'stored_token');
      when(() => mockStorageService.getRefreshToken())
          .thenAnswer((_) async => 'stored_refresh_token');
      when(() => mockAuthService.getCurrentUser())
          .thenThrow(Exception('Failed to fetch user'));

      // Act
      await authProvider.initialize();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isInitializing, isFalse);
      expect(authProvider.error, isNotNull);
    });
  });

  group('AuthProvider - Authentication', () {
    test('successful sign in should update state', () async {
      // Arrange
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        provider: 'email',
        createdAt: DateTime.now(),
      );
      final mockAuthResult = AuthResult(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: mockUser,
      );

      when(() => mockAuthService.signInWithEmail(any(), any()))
          .thenAnswer((_) async => mockAuthResult);

      // Act
      await authProvider.signInWithEmail('test@example.com', 'password');

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, equals(mockUser));
      expect(authProvider.error, isNull);
      verify(() => mockStorageService.setToken('access_token')).called(1);
      verify(() => mockStorageService.setRefreshToken('refresh_token'))
          .called(1);
    });

    test('failed sign in should update error state', () async {
      // Arrange
      when(() => mockAuthService.signInWithEmail(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      // Act
      try {
        await authProvider.signInWithEmail(
            'test@example.com', 'wrong_password');
      } catch (_) {}

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.error, isNotNull);
      expect(authProvider.isLoading, isFalse);
    });
  });

  group('AuthProvider - Sign Out', () {
    test('sign out should clear user and tokens', () async {
      // Arrange
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      // Act
      await authProvider.signOut();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      verify(() => mockStorageService.clearToken()).called(1);
      verify(() => mockStorageService.clearRefreshToken()).called(1);
    });
  });

  group('AuthProvider - Session Management', () {
    test('session refresh should update tokens', () async {
      // Arrange
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        provider: 'email',
        createdAt: DateTime.now(),
      );
      final mockAuthResult = AuthResult(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        user: mockUser,
      );

      when(() => mockStorageService.getRefreshToken())
          .thenAnswer((_) async => 'old_refresh_token');
      when(() => mockAuthService.refreshToken(any()))
          .thenAnswer((_) async => mockAuthResult);

      // Act
      await authProvider.refreshSession();

      // Assert
      verify(() => mockStorageService.setToken('new_access_token')).called(1);
      verify(() => mockStorageService.setRefreshToken('new_refresh_token'))
          .called(1);
      expect(authProvider.user, equals(mockUser));
    });

    test('failed session refresh should trigger sign out', () async {
      // Arrange
      when(() => mockStorageService.getRefreshToken())
          .thenAnswer((_) async => 'old_refresh_token');
      when(() => mockAuthService.refreshToken(any()))
          .thenThrow(Exception('Failed to refresh'));
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      // Act
      try {
        await authProvider.refreshSession();
      } catch (_) {}

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      verify(() => mockStorageService.clearToken()).called(1);
      verify(() => mockStorageService.clearRefreshToken()).called(1);
    });
  });

  group('AuthProvider - Profile Management', () {
    test('update profile should update user data', () async {
      // Arrange
      final mockUser = User(
        id: '1',
        email: 'new@example.com',
        name: 'New Name',
        role: 'user',
        provider: 'email',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthService.updateProfile(
            name: any(named: 'name'),
            email: any(named: 'email'),
          )).thenAnswer((_) async => mockUser);

      // Act
      await authProvider.updateProfile(
        name: 'New Name',
        email: 'new@example.com',
      );

      // Assert
      expect(authProvider.user, equals(mockUser));
      expect(authProvider.error, isNull);
    });

    test('failed profile update should set error', () async {
      // Arrange
      when(() => mockAuthService.updateProfile(
            name: any(named: 'name'),
            email: any(named: 'email'),
          )).thenThrow(Exception('Update failed'));

      // Act
      try {
        await authProvider.updateProfile(
          name: 'New Name',
          email: 'new@example.com',
        );
      } catch (_) {}

      // Assert
      expect(authProvider.error, isNotNull);
    });
  });
}
