class PaymentService {
  static Future<bool> initiateMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String operator, // 'MTN' ou 'Airtel'
  }) async {
    // Logique d'appel API pour initier le paiement USSD / 
    await Future.delayed(const Duration(seconds: 2));
    return true; // Simulation d'un succès de transaction
  }
}
