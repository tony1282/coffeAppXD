class UserModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String photoUrl;
  final String rol; // 'cliente' | 'admin'

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    this.rol = 'cliente',
  });

  bool get isAdmin => rol == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'photoUrl': photoUrl,
      'rol': rol,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId:    map['userId']    ?? '',
      userName:  map['userName']  ?? '',
      userEmail: map['userEmail'] ?? '',
      photoUrl:  map['photoUrl']  ?? '',
      rol:       map['rol']       ?? 'cliente',
    );
  }
}