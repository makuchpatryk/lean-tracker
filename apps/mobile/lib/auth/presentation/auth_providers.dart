import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_gateway.dart';
import '../application/request_password_reset.dart';
import '../application/set_new_password.dart';
import '../application/sign_in.dart';
import '../application/sign_in_with_provider.dart';
import '../application/sign_out.dart';
import '../application/sign_up.dart';

/// The identity service. The module does not know which adapter runs: `app/` overrides this provider
/// with the Supabase gateway (composition root), and tests override it with a fake.
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => throw UnimplementedError(
    'Override authGatewayProvider in the ProviderScope.',
  ),
);

final signUpProvider = Provider(
  (ref) => SignUp(ref.watch(authGatewayProvider)),
);
final signInProvider = Provider(
  (ref) => SignIn(ref.watch(authGatewayProvider)),
);
final signInWithProviderProvider = Provider(
  (ref) => SignInWithProvider(ref.watch(authGatewayProvider)),
);
final requestPasswordResetProvider = Provider(
  (ref) => RequestPasswordReset(ref.watch(authGatewayProvider)),
);
final setNewPasswordProvider = Provider(
  (ref) => SetNewPassword(ref.watch(authGatewayProvider)),
);
final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authGatewayProvider)),
);
