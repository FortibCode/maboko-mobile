class BookingModel {
  final String id;
  final String artisanId;
  final String clientId;
  final String serviceTitle;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final double amount;
  final DateTime date;

  BookingModel({
    required this.id,
    required this.artisanId,
    required this.clientId,
    required this.serviceTitle,
    required this.status,
    required this.amount,
    required this.date,
  });
}
