class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String statutCompte;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.statutCompte,
  });

  String get fullName => '$prenom $nom';
  String get initials => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Normalize role
    String role = json['role'] ?? '';
    if (role == 'ADMIN_GENERAL' || role == 'ADMIN') role = 'Administrateur';
    if (role == 'VENDEUR' || role == 'SELLER') role = 'Gestionnaire de catalogue';
    if (role == 'CONTROLEUR' || role == 'CONTROLLER') role = 'Responsable e-commerce';
    if (role.toLowerCase() == 'responsable e-commerce') role = 'Responsable e-commerce';
    if (role.toLowerCase() == 'ecommerce_manager') role = 'Responsable e-commerce';

    return UserModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: role,
      statutCompte: json['statutCompte'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'role': role,
    'statutCompte': statutCompte,
  };
}