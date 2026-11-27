/// Where the user is in the auth flow. The route guard decides the screen from it (PRD UF-001).
enum AuthStatus {
  /// The stored session is still being restored.
  loading,
  signedOut,

  /// Signed up, waiting for the user to open the confirmation link.
  awaitingConfirmation,

  /// Opened the password reset link, must set a new password.
  recovering,
  signedIn,
}
