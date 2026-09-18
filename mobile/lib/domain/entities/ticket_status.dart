/// Ticket and Job Lifecycle State Machine for Beres
/// Corresponds to prd.md, database_schema.md, and architecture.md
enum TicketStatus {
  open('OPEN', 'Mencari Penawaran'),
  bidding('BIDDING', 'Penawaran Masuk'),
  locked('LOCKED', 'Tukang Dipilih'),
  onTheWay('ON_THE_WAY', 'Menuju Lokasi'),
  arrived('ARRIVED', 'Tiba di Lokasi'),
  inProgress('IN_PROGRESS', 'Pengerjaan Berlangsung'),
  workCompleted('WORK_COMPLETED', 'Pekerjaan Selesai'),
  paymentPending('PAYMENT_PENDING', 'Menunggu Pembayaran'),
  completed('COMPLETED', 'Pesanan Selesai'),
  canceled('CANCELED', 'Dibatalkan');

  final String code;
  final String label;
  const TicketStatus(this.code, this.label);

  static TicketStatus fromCode(String code) {
    return TicketStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => TicketStatus.open,
    );
  }

  /// Whether user can cancel without on-site negotiation
  bool get canUserCancelDirectly => this == open || this == bidding || this == locked;

  /// Whether GPS tracking is actively broadcasted
  bool get isTrackingActive => this == onTheWay;

  /// Whether ticket is considered active/in-flight
  bool get isActive => this != completed && this != canceled;
}
