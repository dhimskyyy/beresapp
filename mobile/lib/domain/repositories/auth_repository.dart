import '../../data/models/user_model.dart';
import '../../data/models/tukang_model.dart';

abstract class AuthRepository {
  Future<UserModel> loginUserWithEmail(String email, String password);
  Future<UserModel> registerUserWithEmail(String name, String email, String phone, String password);
  Future<UserModel> signInUserWithGoogle();
  
  Future<TukangModel> loginTukangWithEmail(String email, String password);
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
  });
  Future<TukangModel> signInTukangWithGoogle();
  
  Future<void> signOut();
  Future<dynamic> getCurrentUser(); // Returns UserModel or TukangModel
  Future<TukangModel> updateTukangProfile(TukangModel tukang);
}
