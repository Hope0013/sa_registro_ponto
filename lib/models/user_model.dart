class UserModel {
  final int? id;
  final String nif;
  final String name;
  final String email;
  final String password;

  UserModel({
    this.id,
    required this.nif,
    required this.name,
    required this.email,
    required this.password,
  });

  // Converte o objeto usuario em um mapa para salvar no banco de dados SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nif': nif,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  // Cria um objeto usuario a partir de um registro retornado do banco
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      nif: map['nif'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
