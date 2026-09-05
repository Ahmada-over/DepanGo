import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class QuoteService {
  final String baseUrl;
  final String token;

  QuoteService({required this.baseUrl, required this.token});

  Future<Quote> createQuote(Quote quote) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quotes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(quote.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Quote.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create quote: ${response.body}');
    }
  }

  Future<List<Quote>> getQuotesForBooking(String bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/booking/$bookingId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes');
    }
  }
}
