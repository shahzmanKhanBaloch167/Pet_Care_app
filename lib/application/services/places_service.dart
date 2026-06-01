import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_pet_care_and_veterinary_app/data/models/clinic.dart';

class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  /// Fetches nearby veterinary clinics using the free Overpass API.
  /// [radius] is in meters (default 5000m = 5km).
  Future<List<Clinic>> getNearbyClinics(double lat, double lon, {int radius = 5000}) async {
    // Construct the Overpass QL query
    // This query looks for nodes tagged with amenity=veterinary within [radius] meters of [lat, lon]
    final query = '[out:json];node["amenity"="veterinary"](around:$radius,$lat,$lon);out;';
    
    // The Overpass API endpoint
    final uri = Uri.parse('https://overpass-api.de/api/interpreter');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'FlutterPetCareApp/1.0 (fasihkhan@example.com)',
          'Accept': '*/*',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elements = data['elements'] ?? [];
        
        return elements.map((e) => Clinic.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load nearby clinics. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby clinics: $e');
    }
  }
}
