import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beresapp/core/widgets/app_state_view.dart';
import 'package:beresapp/data/models/tukang_model.dart';
import 'package:beresapp/data/models/user_model.dart';
import 'package:beresapp/domain/repositories/auth_repository.dart';
import 'package:beresapp/features/auth/bloc/auth_bloc.dart';
import 'package:beresapp/features/auth/bloc/auth_event.dart';
import 'package:beresapp/features/auth/bloc/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  TukangModel? lastUpdatedTukang;

  @override
  Future<TukangModel> updateTukangProfile(TukangModel tukang) async {
    lastUpdatedTukang = tukang;
    return tukang;
  }

  @override
  Future<dynamic> getCurrentUser() async => null;

  @override
  Future<TukangModel> loginTukangWithEmail(String email, String password) => throw UnimplementedError();

  @override
  Future<UserModel> loginUserWithEmail(String email, String password) => throw UnimplementedError();

  @override
  Future<TukangModel> registerTukangWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String birthDate,
    required int age,
    required List<String> services,
    required List<PayoutAccount> payoutAccounts,
    required String ktpPath,
  }) => throw UnimplementedError();

  @override
  Future<UserModel> registerUserWithEmail(String name, String email, String phone, String password) => throw UnimplementedError();

  @override
  Future<TukangModel> signInTukangWithGoogle() => throw UnimplementedError();

  @override
  Future<UserModel> signInUserWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  group('Mitra Profile Update Bloc Tests', () {
    test('TukangProfileUpdatedEvent persists profile and emits TukangAuthenticatedState', () async {
      final mockRepo = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: mockRepo);

      final initialTukang = TukangModel(
        id: 'tukang-123',
        name: 'Pak Bambang',
        email: 'bambang@test.com',
        phone: '08123456789',
        birthDate: '1985-05-10',
        age: 39,
        services: ['ac', 'pipa'],
        payoutAccounts: [
          PayoutAccount(
            type: 'bank',
            provider: 'BCA',
            accountNumber: '1234567890',
            accountName: 'Bambang',
          ),
        ],
        ktpUrl: 'https://example.com/ktp.jpg',
        verificationStatus: 'verified',
        isOnline: false,
        workRadiusKm: 15.0,
        createdAt: DateTime.now(),
      );

      final updatedTukang = initialTukang.copyWith(
        isOnline: true,
        workRadiusKm: 25.0,
        services: ['ac', 'pipa', 'listrik'],
        payoutAccounts: [
          PayoutAccount(
            type: 'bank',
            provider: 'MANDIRI',
            accountNumber: '9876543210',
            accountName: 'Bambang M',
          ),
        ],
      );

      authBloc.add(TukangProfileUpdatedEvent(updatedTukang));

      await expectLater(
        authBloc.stream,
        emits(TukangAuthenticatedState(updatedTukang)),
      );

      expect(mockRepo.lastUpdatedTukang, isNotNull);
      expect(mockRepo.lastUpdatedTukang!.isOnline, isTrue);
      expect(mockRepo.lastUpdatedTukang!.workRadiusKm, 25.0);
      expect(mockRepo.lastUpdatedTukang!.services, contains('listrik'));
      expect(mockRepo.lastUpdatedTukang!.payoutAccounts.first.provider, 'MANDIRI');

      await authBloc.close();
    });
  });

  group('Universal App State Widgets Tests', () {
    testWidgets('AppLoadingView renders message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingView(message: 'Sedang memuat data radar...'),
          ),
        ),
      );

      expect(find.text('Sedang memuat data radar...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppEmptyView renders title, subtitle, and action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              title: 'Data Tidak Ditemukan',
              subtitle: 'Tidak ada pekerjaan pada radar.',
              actionLabel: 'Pindai Ulang',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Tidak ada pekerjaan pada radar.'), findsOneWidget);
      expect(find.text('Pindai Ulang'), findsOneWidget);

      await tester.tap(find.text('Pindai Ulang'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorView renders error message and triggers retry', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              title: 'Koneksi Terputus',
              message: 'Gagal terhubung ke Cloud Firestore.',
              retryLabel: 'Coba Lagi',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Koneksi Terputus'), findsOneWidget);
      expect(find.text('Gagal terhubung ke Cloud Firestore.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });
  });
}
