class ICPTicket {
  final String id;
  final String canisterId;
  final String route;
  final String fromStop;
  final String toStop;
  final double price;
  final DateTime purchaseTime;
  final DateTime validUntil;
  final String userPrincipal;
  final TicketStatus status;
  final String transactionHash;

  ICPTicket({
    required this.id,
    required this.canisterId,
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.price,
    required this.purchaseTime,
    required this.validUntil,
    required this.userPrincipal,
    required this.status,
    required this.transactionHash,
  });

  factory ICPTicket.fromJson(Map<String, dynamic> json) {
    return ICPTicket(
      id: json['id'] ?? '',
      canisterId: json['canister_id'] ?? '',
      route: json['route'] ?? '',
      fromStop: json['from_stop'] ?? '',
      toStop: json['to_stop'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      purchaseTime: DateTime.fromMillisecondsSinceEpoch(json['purchase_time'] ?? 0),
      validUntil: DateTime.fromMillisecondsSinceEpoch(json['valid_until'] ?? 0),
      userPrincipal: json['user_principal'] ?? '',
      status: TicketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TicketStatus.active,
      ),
      transactionHash: json['transaction_hash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canister_id': canisterId,
      'route': route,
      'from_stop': fromStop,
      'to_stop': toStop,
      'price': price,
      'purchase_time': purchaseTime.millisecondsSinceEpoch,
      'valid_until': validUntil.millisecondsSinceEpoch,
      'user_principal': userPrincipal,
      'status': status.name,
      'transaction_hash': transactionHash,
    };
  }

  bool get isValid {
    return status == TicketStatus.active && DateTime.now().isBefore(validUntil);
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }
}

enum TicketStatus {
  active,
  used,
  expired,
  refunded,
  cancelled,
}

class ICPWallet {
  final String principal;
  final double icpBalance;
  final List<ICPTicket> tickets;
  final DateTime lastUpdated;

  ICPWallet({
    required this.principal,
    required this.icpBalance,
    required this.tickets,
    required this.lastUpdated,
  });

  factory ICPWallet.fromJson(Map<String, dynamic> json) {
    return ICPWallet(
      principal: json['principal'] ?? '',
      icpBalance: (json['icp_balance'] as num?)?.toDouble() ?? 0.0,
      tickets: (json['tickets'] as List?)
          ?.map((ticket) => ICPTicket.fromJson(ticket))
          .toList() ?? [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['last_updated'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'principal': principal,
      'icp_balance': icpBalance,
      'tickets': tickets.map((ticket) => ticket.toJson()).toList(),
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  List<ICPTicket> get activeTickets {
    return tickets.where((ticket) => ticket.isValid).toList();
  }

  List<ICPTicket> get expiredTickets {
    return tickets.where((ticket) => ticket.isExpired).toList();
  }
}