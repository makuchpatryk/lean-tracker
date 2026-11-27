/// Public entry of the auth module: sign-up, sign-in, social sign-in, password reset, sign-out and the
/// session (FR-001). `app/` reaches the module only through this file.
library;

export 'application/auth_gateway.dart';
export 'application/request_password_reset.dart';
export 'application/set_new_password.dart';
export 'application/sign_in.dart';
export 'application/sign_in_with_provider.dart';
export 'application/sign_out.dart';
export 'application/sign_up.dart';
export 'domain/auth_failure.dart';
export 'domain/auth_status.dart';
export 'domain/email.dart';
export 'domain/password.dart';
export 'infrastructure/secure_session_storage.dart';
export 'infrastructure/supabase_auth_gateway.dart';
export 'presentation/auth_providers.dart';
export 'presentation/auth_controller.dart';
export 'presentation/auth_failure_text.dart';
export 'presentation/check_email_screen.dart';
export 'presentation/forgot_password_screen.dart';
export 'presentation/login_screen.dart';
export 'presentation/new_password_screen.dart';
