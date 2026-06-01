import 'package:flutter_pet_care_and_veterinary_app/application/services/location_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/places_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/clinic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nearbyClinicsProvider = FutureProvider.autoDispose<List<Clinic>>((ref) async {
  final position = await LocationService().getCurrentPosition();
  if (position == null) {
    throw Exception('Location permission denied or services disabled.');
  }

  final clinics = await PlacesService().getNearbyClinics(position.latitude, position.longitude);
  return clinics;
});
