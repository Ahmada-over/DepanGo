import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class QuoteService {
  final String baseUrl;
  final String token;

  QuoteService({required this.baseUrl, required this.token});

  Future<List<Quote>> getQuotesForBooking(String bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/booking/$bookingId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des devis');
    }
  }

  Future<Quote> updateQuoteStatus(String quoteId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/quotes/$quoteId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Quote.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la mise à jour du devis');
    }
  }
}
