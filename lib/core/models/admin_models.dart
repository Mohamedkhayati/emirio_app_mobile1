// ============== CUSTOMER MODELS ==============
class AdminCustomer {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String statutCompte;
  final DateTime dateDeCreation;
  final String? phone;

  AdminCustomer({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.statutCompte,
    required this.dateDeCreation,
    this.phone,
  });

  String get fullName => '$prenom $nom';
  String get initials => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  factory AdminCustomer.fromJson(Map<String, dynamic> json) => AdminCustomer(
    id: json['id'],
    nom: json['nom'] ?? '',
    prenom: json['prenom'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'CLIENT',
    statutCompte: json['statutCompte'] ?? 'ACTIVE',
    dateDeCreation: json['dateDeCreation'] != null ? DateTime.parse(json['dateDeCreation']) : DateTime.now(),
    phone: json['phone'],
  );
}

class CustomerHistoryEntry {
  final int id;
  final String action;
  final String? details;
  final DateTime createdAt;
  final String? actorEmail;

  CustomerHistoryEntry({
    required this.id,
    required this.action,
    this.details,
    required this.createdAt,
    this.actorEmail,
  });

  factory CustomerHistoryEntry.fromJson(Map<String, dynamic> json) => CustomerHistoryEntry(
    id: json['id'],
    action: json['action'] ?? '',
    details: json['details'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    actorEmail: json['actorEmail'],
  );
}

class CreateCustomerRequest {
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String role;
  final String statutCompte;

  CreateCustomerRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.role,
    required this.statutCompte,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'password': password,
    'role': role,
    'statutCompte': statutCompte,
  };
}

// ============== DASHBOARD MODELS ==============
class AdminDashboardStats {
  final int totalVisits;
  final int visitsToday;
  final int visitsLast30Days;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final Map<String, int> ordersByPaymentStatus;
  final List<DailySale> dailySales;
  final List<TopItem> topArticles;
  final List<TopItem> topCategories;
  final List<RadarCategory> radarCategories;

  AdminDashboardStats({
    required this.totalVisits,
    required this.visitsToday,
    required this.visitsLast30Days,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.ordersByPaymentStatus,
    required this.dailySales,
    required this.topArticles,
    required this.topCategories,
    required this.radarCategories,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalVisits: json['totalVisits'] ?? 0,
      visitsToday: json['visitsToday'] ?? 0,
      visitsLast30Days: json['visitsLast30Days'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      ordersByStatus: Map<String, int>.from(json['ordersByStatus'] ?? {}),
      ordersByPaymentStatus: Map<String, int>.from(json['ordersByPaymentStatus'] ?? {}),
      dailySales: (json['dailySales'] as List? ?? []).map((d) => DailySale.fromJson(d)).toList(),
      topArticles: (json['topArticles'] as List? ?? []).map((a) => TopItem.fromJson(a)).toList(),
      topCategories: (json['topCategories'] as List? ?? []).map((c) => TopItem.fromJson(c)).toList(),
      radarCategories: (json['radarCategories'] as List? ?? []).map((r) => RadarCategory.fromJson(r)).toList(),
    );
  }
}

class DailySale {
  final String label;
  final double sales;

  DailySale({required this.label, required this.sales});

  factory DailySale.fromJson(Map<String, dynamic> json) {
    return DailySale(label: json['label'] ?? '', sales: (json['sales'] ?? 0).toDouble());
  }
}

class TopItem {
  final String name;
  final double revenue;

  TopItem({required this.name, required this.revenue});

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(name: json['name'] ?? '', revenue: (json['revenue'] ?? 0).toDouble());
  }
}

class RadarCategory {
  final String name;
  final double value;

  RadarCategory({required this.name, required this.value});

  factory RadarCategory.fromJson(Map<String, dynamic> json) {
    return RadarCategory(name: json['name'] ?? '', value: (json['value'] ?? 0).toDouble());
  }
}

// ============== ORDER MODELS ==============
enum OrderTab { pending, send, cancelled, delivered }

extension OrderTabExtension on OrderTab {
  String get label {
    switch (this) {
      case OrderTab.pending:
        return 'Pending';
      case OrderTab.send:
        return 'Send';
      case OrderTab.cancelled:
        return 'Cancelled';
      case OrderTab.delivered:
        return 'Delivered';
    }
  }

  static OrderTab fromOrderStatus(String status) {
    final upper = status.toUpperCase();
    if (upper == 'CONFIRMEE') return OrderTab.send;
    if (upper == 'ANNULEE') return OrderTab.cancelled;
    if (upper == 'LIVREE') return OrderTab.delivered;
    return OrderTab.pending;
  }
}

class AdminOrder {
  final int id;
  final String referenceCommande;
  final String statutCommande;
  final String statutPaiement;
  final String modePaiement;
  final double total;
  final DateTime dateCommande;
  final String prenomClient;
  final String nomClient;
  final String emailClient;
  final String? telephone;
  final String? adresse;
  final String? cardLast4;
  final String? d17Phone;
  final String? d17Reference;
  final String? bankReference;
  final String? paymentInstructions;
  final String? invoiceNumber;
  final String? invoiceUrl;
  final String? signatureDataUrl;
  final List<OrderLine> lignes;

  AdminOrder({
    required this.id,
    required this.referenceCommande,
    required this.statutCommande,
    required this.statutPaiement,
    required this.modePaiement,
    required this.total,
    required this.dateCommande,
    required this.prenomClient,
    required this.nomClient,
    required this.emailClient,
    this.telephone,
    this.adresse,
    this.cardLast4,
    this.d17Phone,
    this.d17Reference,
    this.bankReference,
    this.paymentInstructions,
    this.invoiceNumber,
    this.invoiceUrl,
    this.signatureDataUrl,
    required this.lignes,
  });

  String get customerFullName => '$prenomClient $nomClient'.trim();
  String get customerSub => emailClient;

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'],
      referenceCommande: json['referenceCommande'] ?? '#${json['id']}',
      statutCommande: json['statutCommande'] ?? 'PENDING',
      statutPaiement: json['statutPaiement'] ?? '-',
      modePaiement: json['modePaiement'] ?? '-',
      total: (json['total'] ?? 0).toDouble(),
      dateCommande: json['dateCommande'] != null ? DateTime.parse(json['dateCommande']) : DateTime.now(),
      prenomClient: json['prenomClient'] ?? '',
      nomClient: json['nomClient'] ?? '',
      emailClient: json['emailClient'] ?? '',
      telephone: json['telephone'],
      adresse: json['adresse'],
      cardLast4: json['cardLast4'],
      d17Phone: json['d17Phone'],
      d17Reference: json['d17Reference'],
      bankReference: json['bankReference'],
      paymentInstructions: json['paymentInstructions'],
      invoiceNumber: json['invoiceNumber'],
      invoiceUrl: json['invoiceUrl'],
      signatureDataUrl: json['signatureDataUrl'],
      lignes: (json['lignes'] as List? ?? []).map((l) => OrderLine.fromJson(l)).toList(),
    );
  }
}

class OrderLine {
  final int id;
  final String? articleNom;
  final String? imageUrl;
  final double prix;
  final int quantite;

  OrderLine({
    required this.id,
    this.articleNom,
    this.imageUrl,
    required this.prix,
    required this.quantite,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      id: json['id'],
      articleNom: json['articleNom'] ?? json['nomProduit'],
      imageUrl: json['imageUrl'],
      prix: (json['prix'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 1,
    );
  }
}

class OrderHistoryEntry {
  final int id;
  final String typeAction;
  final String? ancienStatut;
  final String? nouveauStatut;
  final String? details;
  final DateTime dateAction;
  final String? utilisateurNom;

  OrderHistoryEntry({
    required this.id,
    required this.typeAction,
    this.ancienStatut,
    this.nouveauStatut,
    this.details,
    required this.dateAction,
    this.utilisateurNom,
  });

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderHistoryEntry(
      id: json['id'],
      typeAction: json['typeAction'] ?? json['actionType'] ?? 'ACTION',
      ancienStatut: json['ancienStatut'],
      nouveauStatut: json['nouveauStatut'],
      details: json['details'] ?? json['note'],
      dateAction: json['dateAction'] != null ? DateTime.parse(json['dateAction']) : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      utilisateurNom: json['utilisateurNom'] ?? json['userName'],
    );
  }
}

class PaymentTransaction {
  final int id;
  final String modePaiement;
  final String statutPaiement;
  final double montant;
  final DateTime datePaiement;
  final String? referenceTransaction;
  final String? details;

  PaymentTransaction({
    required this.id,
    required this.modePaiement,
    required this.statutPaiement,
    required this.montant,
    required this.datePaiement,
    this.referenceTransaction,
    this.details,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      modePaiement: json['modePaiement'] ?? json['mode_paiement'] ?? '-',
      statutPaiement: json['statutPaiement'] ?? json['statut_paiement'] ?? '-',
      montant: (json['montant'] ?? 0).toDouble(),
      datePaiement: json['datePaiement'] != null ? DateTime.parse(json['datePaiement']) : (json['date_paiement'] != null ? DateTime.parse(json['date_paiement']) : DateTime.now()),
      referenceTransaction: json['referenceTransaction'],
      details: json['details'],
    );
  }
}

// ============== CATEGORY / COLOR / SIZE MODELS ==============
class CategoryModel {
  final int id;
  final String nom;
  final String? description;
  final int? parentId;
  final int level;
  final int displayOrder;
  final String? iconUrl;
  final bool actif;

  CategoryModel({
    required this.id,
    required this.nom,
    this.description,
    this.parentId,
    required this.level,
    required this.displayOrder,
    this.iconUrl,
    required this.actif,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: int.tryParse(json['id'].toString()) ?? 0,
    nom: json['nom'] ?? '',
    description: json['description'],
    parentId: json['parentId'] != null ? int.tryParse(json['parentId'].toString()) : null,
    level: int.tryParse(json['level'].toString()) ?? 0,
    displayOrder: int.tryParse(json['displayOrder'].toString()) ?? 0,
    iconUrl: json['iconUrl'],
    actif: json['actif'] ?? true,
  );
}
class ColorModel {
  final int id;
  final String nom;
  final String codeHex;

  ColorModel({required this.id, required this.nom, required this.codeHex});

  factory ColorModel.fromJson(Map<String, dynamic> json) => ColorModel(
    id: int.tryParse(json['id'].toString()) ?? 0,
    nom: json['nom'] ?? '',
    codeHex: json['codeHex'] ?? '#000000',
  );
}
class SizeModel {
  final int id;
  final String pointure;

  SizeModel({required this.id, required this.pointure});

  factory SizeModel.fromJson(Map<String, dynamic> json) => SizeModel(
    id: int.tryParse(json['id'].toString()) ?? 0,
    pointure: json['pointure'] ?? '',
  );
}

// ============== VENDEUR MODELS ==============
class VendeurArticle {
  final int id;
  final String nom;
  final String description;
  final String details;
  final double prix;
  final double? salePrice;
  final DateTime? saleStartAt;
  final DateTime? saleEndAt;
  final bool actif;
  final bool recommended;
  final int categorieId;
  final String categorieNom;
  final String marque;
  final String matiere;
  final String sku;
  final List<VendeurVariation> variations;

  VendeurArticle({
    required this.id,
    required this.nom,
    required this.description,
    required this.details,
    required this.prix,
    this.salePrice,
    this.saleStartAt,
    this.saleEndAt,
    required this.actif,
    required this.recommended,
    required this.categorieId,
    required this.categorieNom,
    required this.marque,
    required this.matiere,
    required this.sku,
    this.variations = const [],
  });

  factory VendeurArticle.fromJson(Map<String, dynamic> json) {
    return VendeurArticle(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      details: json['details'] ?? '',
      prix: (json['prix'] ?? 0).toDouble(),
      salePrice: json['salePrice']?.toDouble(),
      saleStartAt: json['saleStartAt'] != null ? DateTime.parse(json['saleStartAt']) : null,
      saleEndAt: json['saleEndAt'] != null ? DateTime.parse(json['saleEndAt']) : null,
      actif: json['actif'] ?? false,
      recommended: json['recommended'] ?? false,
      categorieId: json['categorieId'] ?? 0,
      categorieNom: json['categorieNom'] ?? '',
      marque: json['marque'] ?? '',
      matiere: json['matiere'] ?? '',
      sku: json['sku'] ?? '',
      variations: (json['variations'] as List? ?? []).map((v) => VendeurVariation.fromJson(v)).toList(),
    );
  }
}

class VendeurVariation {
  final int id;
  final int couleurId;
  final String couleurNom;
  final String couleurCodeHex;
  final int? tailleId;
  final String? taillePointure;
  final double prix;
  final int quantiteStock;
  final String? model3dUrl;
  final List<String> imageUrls;

  VendeurVariation({
    required this.id,
    required this.couleurId,
    required this.couleurNom,
    required this.couleurCodeHex,
    this.tailleId,
    this.taillePointure,
    required this.prix,
    required this.quantiteStock,
    this.model3dUrl,
    this.imageUrls = const [],
  });

  factory VendeurVariation.fromJson(Map<String, dynamic> json) {
    return VendeurVariation(
      id: json['id'],
      couleurId: json['couleurId'] ?? 0,
      couleurNom: json['couleurNom'] ?? '',
      couleurCodeHex: json['couleurCodeHex'] ?? '#000000',
      tailleId: json['tailleId'],
      taillePointure: json['taillePointure'],
      prix: (json['prix'] ?? 0).toDouble(),
      quantiteStock: json['quantiteStock'] ?? 0,
      model3dUrl: json['model3dUrl'],
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [],
    );
  }
}

class VendeurSizeStock {
  final int tailleId;
  final String label;
  bool checked;
  int quantiteStock;
  bool disabled;

  VendeurSizeStock({
    required this.tailleId,
    required this.label,
    this.checked = false,
    this.quantiteStock = 0,
    this.disabled = false,
  });

  Map<String, dynamic> toJson() => {
    'tailleId': tailleId,
    'quantiteStock': quantiteStock,
  };
}
// Add these classes to admin_models.dart

class VendeurDashboardStats {
  final double totalSales;
  final int totalOrders;
  final int totalItemsSold;
  final List<VendeurTopArticle> topArticles;
  final List<VendeurTopCategory> topCategories;

  VendeurDashboardStats({
    required this.totalSales,
    required this.totalOrders,
    required this.totalItemsSold,
    required this.topArticles,
    required this.topCategories,
  });

  factory VendeurDashboardStats.fromJson(Map<String, dynamic> json) {
    return VendeurDashboardStats(
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalItemsSold: json['totalItemsSold'] ?? 0,
      topArticles: (json['topArticles'] as List? ?? [])
          .map((a) => VendeurTopArticle.fromJson(a))
          .toList(),
      topCategories: (json['topCategories'] as List? ?? [])
          .map((c) => VendeurTopCategory.fromJson(c))
          .toList(),
    );
  }
}

class VendeurTopArticle {
  final int articleId;
  final String articleNom;
  final int totalQuantitySold;
  final double totalRevenue;

  VendeurTopArticle({
    required this.articleId,
    required this.articleNom,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });

  factory VendeurTopArticle.fromJson(Map<String, dynamic> json) {
    return VendeurTopArticle(
      articleId: json['articleId'] ?? 0,
      articleNom: json['articleNom'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}

class VendeurTopCategory {
  final int categoryId;
  final String categoryNom;
  final int totalQuantitySold;
  final double totalRevenue;

  VendeurTopCategory({
    required this.categoryId,
    required this.categoryNom,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });

  factory VendeurTopCategory.fromJson(Map<String, dynamic> json) {
    return VendeurTopCategory(
      categoryId: json['categoryId'] ?? 0,
      categoryNom: json['categoryNom'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
// Add these classes to admin_models.dart

class VendeurOrder {
  final int id;
  final String referenceCommande;
  final String statutCommande;
  final double total;
  final DateTime dateCommande;
  final String prenomClient;
  final String nomClient;
  final String emailClient;
  final List<VendeurOrderLine> lignesVendeur;

  VendeurOrder({
    required this.id,
    required this.referenceCommande,
    required this.statutCommande,
    required this.total,
    required this.dateCommande,
    required this.prenomClient,
    required this.nomClient,
    required this.emailClient,
    required this.lignesVendeur,
  });

  String get customerFullName => '$prenomClient $nomClient'.trim();

  factory VendeurOrder.fromJson(Map<String, dynamic> json) {
    return VendeurOrder(
      id: json['id'],
      referenceCommande: json['referenceCommande'] ?? '#${json['id']}',
      statutCommande: json['statutCommande'] ?? 'PENDING',
      total: (json['total'] ?? 0).toDouble(),
      dateCommande: json['dateCommande'] != null ? DateTime.parse(json['dateCommande']) : DateTime.now(),
      prenomClient: json['prenomClient'] ?? '',
      nomClient: json['nomClient'] ?? '',
      emailClient: json['emailClient'] ?? '',
      lignesVendeur: (json['lignesVendeur'] as List? ?? [])
          .map((l) => VendeurOrderLine.fromJson(l))
          .toList(),
    );
  }
}

class VendeurOrderLine {
  final int id;
  final String articleNom;
  final String? imageUrl;
  final int quantite;
  final double prix;

  VendeurOrderLine({
    required this.id,
    required this.articleNom,
    this.imageUrl,
    required this.quantite,
    required this.prix,
  });

  factory VendeurOrderLine.fromJson(Map<String, dynamic> json) {
    return VendeurOrderLine(
      id: json['id'],
      articleNom: json['articleNom'] ?? '',
      imageUrl: json['imageUrl'],
      quantite: json['quantite'] ?? 1,
      prix: (json['prix'] ?? 0).toDouble(),
    );
  }
}

class VendeurOrderHistoryEntry {
  final int id;
  final String typeAction;
  final String? ancienStatut;
  final String? nouveauStatut;
  final String? details;
  final DateTime dateAction;

  VendeurOrderHistoryEntry({
    required this.id,
    required this.typeAction,
    this.ancienStatut,
    this.nouveauStatut,
    this.details,
    required this.dateAction,
  });

  factory VendeurOrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VendeurOrderHistoryEntry(
      id: json['id'],
      typeAction: json['typeAction'] ?? json['actionType'] ?? 'ACTION',
      ancienStatut: json['ancienStatut'],
      nouveauStatut: json['nouveauStatut'],
      details: json['details'] ?? json['note'],
      dateAction: json['dateAction'] != null
          ? DateTime.parse(json['dateAction'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }
}
// Add these classes to admin_models.dart

class AdminWorker {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String statutCompte;
  final DateTime dateDeCreation;
  final String? phone;

  AdminWorker({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.statutCompte,
    required this.dateDeCreation,
    this.phone,
  });

  String get fullName => '$prenom $nom';
  String get initials => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  factory AdminWorker.fromJson(Map<String, dynamic> json) => AdminWorker(
    id: json['id'],
    nom: json['nom'] ?? '',
    prenom: json['prenom'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? '',
    statutCompte: json['statutCompte'] ?? 'ACTIVE',
    dateDeCreation: json['dateDeCreation'] != null ? DateTime.parse(json['dateDeCreation']) : DateTime.now(),
    phone: json['phone'],
  );
}

class WorkerHistoryEntry {
  final int id;
  final String action;
  final String? details;
  final DateTime createdAt;
  final String? actorEmail;

  WorkerHistoryEntry({
    required this.id,
    required this.action,
    this.details,
    required this.createdAt,
    this.actorEmail,
  });

  factory WorkerHistoryEntry.fromJson(Map<String, dynamic> json) => WorkerHistoryEntry(
    id: json['id'],
    action: json['action'] ?? '',
    details: json['details'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    actorEmail: json['actorEmail'],
  );
}

class CreateWorkerRequest {
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String role;
  final String statutCompte;

  CreateWorkerRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.role,
    required this.statutCompte,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'password': password,
    'role': role,
    'statutCompte': statutCompte,
  };
}