import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
  final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=14.6928,-17.4467&destination=14.7167,-17.4677&key=$apiKey';
  final res = await http.get(Uri.parse(url));
  print(res.body);
}
