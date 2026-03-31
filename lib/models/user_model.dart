class UserModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String photoUrl;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
  });

  // Para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'photoUrl': photoUrl,
    };
  }

  // Para leer de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }
}