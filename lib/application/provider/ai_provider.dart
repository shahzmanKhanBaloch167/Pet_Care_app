import 'package:flutter_pet_care_and_veterinary_app/application/services/ai_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
