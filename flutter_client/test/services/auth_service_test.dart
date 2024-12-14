// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_client/services/auth_service.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/models/user.dart';
import 'package:flutter_client/models/auth_result.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class MockApiService extends Mock implements ApiService {}

class MockStorageService extends Mock implements StorageService {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFacebookAuth extends Mock implements FacebookAuth {
  static final instance = MockFacebookAuth();
}

class MockLoginResult extends Mock implements LoginResult {
  @override
  AccessToken? get accessToken => MockAccessToken();
}

class MockAccessToken extends Mock implements AccessToken {
  String get token => 'mock_token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthService authService;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    mockGoogleSignIn = MockGoogleSignIn();

    // Facebook Auth mock 설정
    FacebookAuth.instance = MockFacebookAuth();
    when(() => FacebookAuth.instance.logOut()).thenAnswer((_) async => {});
    when(() => FacebookAuth.instance.login())
        .thenAnswer((_) async => MockLoginResult());

    authService = AuthService(
      apiService: mockApiService,
      storageService: mockStorageService,
      googleSignIn: mockGoogleSignIn,
    );

    // Storage 서비스 mock 응답 설정
    when(() => mockStorageService.setToken(any())).thenAnswer((_) async => {});
    when(() => mockStorageService.setRefreshToken(any()))
        .thenAnswer((_) async => {});
    when(() => mockStorageService.clearToken()).thenAnswer((_) async => {});
    when(() => mockStorageService.clearRefreshToken())
        .thenAnswer((_) async => {});
  });

  group('AuthService - Email Sign In', () {
    test('successful sign in should update user and tokens', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final mockUser = User(
        id: '1',
        email: email,
        name: 'Test User',
        role: 'user',
        provider: 'email',
        createdAt: DateTime.now(),
      );

      final responseData = {
        'token': 'access_token',
        'refresh_token': 'refresh_token',
        'user': mockUser.toJson(),
      };

      when(() => mockApiService.request(
            path: '/auth/login',
            method: 'POST',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/login'),
          ));

      // 스토리지 서비스 mock 응답 추가
      when(() => mockStorageService.setToken(any()))
          .thenAnswer((_) async => {});
      when(() => mockStorageService.setRefreshToken(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.signInWithEmail(email, password);

      // Assert
      expect(result.accessToken, equals('access_token'));
      expect(result.refreshToken, equals('refresh_token'));
      verify(() => mockStorageService.setToken('access_token')).called(1);
      verify(() => mockStorageService.setRefreshToken('refresh_token'))
          .called(1);
    });
    test('failed sign in should throw AuthException', () async {
      // Arrange
      when(() => mockApiService.request(
            path: '/auth/login',
            method: 'POST',
            data: any(named: 'data'),
          )).thenThrow(DioException(
        response: Response(
          data: {'message': 'Invalid credentials'},
          statusCode: 401,
          requestOptions: RequestOptions(path: '/auth/login'),
        ),
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse, // 추가: type 파라미터 필요
      ));

      // Act & Assert
      expect(
        () => authService.signInWithEmail('test@example.com', 'wrong_password'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Google Sign In', () {
    test('successful google sign in should update user and tokens', () async {
      // Arrange
      final mockGoogleAccount = MockGoogleSignInAccount();
      final mockGoogleAuth = MockGoogleSignInAuthentication();
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user', // 추가: 필수 파라미터
        provider: 'google', // 추가: 필수 파라미터
        createdAt: DateTime.now(),
      );
      final mockAuthResult = AuthResult(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: mockUser,
      );

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(() => mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAccount.email).thenReturn('test@example.com');
      when(() => mockGoogleAuth.idToken).thenReturn('google_id_token');

      when(() => mockApiService.request(
            path: '/auth/social-login',
            method: 'POST',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: mockAuthResult.toJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/social-login'),
          ));

      // Act
      final result = await authService.signInWithGoogle();

      // Assert
      expect(result.user, equals(mockUser));
      expect(result.accessToken, equals('access_token'));
      expect(result.refreshToken, equals('refresh_token'));
    });
  });

  group('AuthService - Token Management', () {
    test('refresh token should get new tokens', () async {
      // Arrange
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user', // 추가: 필수 파라미터
        provider: 'email', // 추가: 필수 파라미터
        createdAt: DateTime.now(),
      );
      final mockAuthResult = AuthResult(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        user: mockUser,
      );

      when(() => mockApiService.request(
            path: '/auth/refresh',
            method: 'POST',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: mockAuthResult.toJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ));

      // Act
      final result = await authService.refreshToken('old_refresh_token');

      // Assert
      expect(result.accessToken, equals('new_access_token'));
      expect(result.refreshToken, equals('new_refresh_token'));
      verify(() => mockStorageService.setToken('new_access_token')).called(1);
      verify(() => mockStorageService.setRefreshToken('new_refresh_token'))
          .called(1);
    });
  });

  group('AuthService - Sign Out', () {
    test('sign out should clear tokens and user data', () async {
      // Arrange
      when(() => mockApiService.request(
            path: '/auth/logout',
            method: 'POST',
          )).thenAnswer((_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/logout'),
          ));
      when(() => mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => true);
      when(() => mockGoogleSignIn.signOut())
          .thenAnswer((_) async => MockGoogleSignInAccount());

      // Act
      await authService.signOut();

      // Assert
      verify(() => mockStorageService.clearToken()).called(1);
      verify(() => mockStorageService.clearRefreshToken()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
