/// BBZCloud Mobile - Credentials Model
/// 
/// @version 0.1.0

class Credentials {
  final String? email;
  final String? password;
  final String? bbbPassword;
  final String? webuntisEmail;
  final String? webuntisPassword;

  const Credentials({
    this.email,
    this.password,
    this.bbbPassword,
    this.webuntisEmail,
    this.webuntisPassword,
  });

  /// Check if basic credentials (email) are set
  bool get hasBasicCredentials => email != null && email!.isNotEmpty;

  /// Check if all main credentials are set
  bool get hasAllCredentials => 
      hasBasicCredentials && 
      password != null && 
      password!.isNotEmpty;

  /// Copy with method for immutability
  Credentials copyWith({
    String? email,
    String? password,
    String? bbbPassword,
    String? webuntisEmail,
    String? webuntisPassword,
  }) {
    return Credentials(
      email: email ?? this.email,
      password: password ?? this.password,
      bbbPassword: bbbPassword ?? this.bbbPassword,
      webuntisEmail: webuntisEmail ?? this.webuntisEmail,
      webuntisPassword: webuntisPassword ?? this.webuntisPassword,
    );
  }

  /// Create empty credentials
  factory Credentials.empty() {
    return const Credentials();
  }

  @override
  String toString() {
    return 'Credentials(email: ${email != null ? '***' : 'null'}, hasPassword: ${password != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Credentials &&
        other.email == email &&
        other.password == password &&
        other.bbbPassword == bbbPassword &&
        other.webuntisEmail == webuntisEmail &&
        other.webuntisPassword == webuntisPassword;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        password.hashCode ^
        bbbPassword.hashCode ^
        webuntisEmail.hashCode ^
        webuntisPassword.hashCode;
  }
}
