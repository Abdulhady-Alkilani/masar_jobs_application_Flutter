import 'user.dart';

class AuthResponse {
  final String? message;
  final String? accessToken;
  final String? tokenType;
  final User? user;

  AuthResponse({this.message, this.accessToken, this.tokenType, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String?,
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}