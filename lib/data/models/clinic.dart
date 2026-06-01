class Clinic {
  final int id;
  final double lat;
  final double lon;
  final String name;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? address;

  Clinic({
    required this.id,
    required this.lat,
    required this.lon,
    required this.name,
    this.phone,
    this.website,
    this.openingHours,
    this.address,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};
    
    // Attempt to construct an address from available OSM tags
    String? fullAddress;
    final houseNumber = tags['addr:housenumber'];
    final street = tags['addr:street'];
    final city = tags['addr:city'];
    
    if (street != null && city != null) {
      fullAddress = '${houseNumber != null ? '$houseNumber ' : ''}$street, $city';
    } else if (city != null) {
      fullAddress = city;
    }

    return Clinic(
      id: json['id'],
      lat: json['lat'],
      lon: json['lon'],
      name: tags['name'] ?? 'Veterinary Clinic',
      phone: tags['phone'] ?? tags['contact:phone'],
      website: tags['website'] ?? tags['contact:website'],
      openingHours: tags['opening_hours'],
      address: fullAddress,
    );
  }
}
