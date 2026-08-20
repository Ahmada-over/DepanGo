import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';

final allTechniciansProvider =
    FutureProvider<List<TechnicianProfileModel>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/technicians');
  if (res.statusCode == 200) {
    final List data = res.data;
    return data.map((e) => TechnicianProfileModel.fromJson(e)).toList();
  }
  return [];
});

final technicianBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, techId) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/bookings/user/$techId?role=technician');
  if (res.statusCode == 200) {
    final List data = res.data;
    return data.map((e) => BookingModel.fromJson(e)).toList();
  }
  return [];
});

final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final selectedRatingFilterProvider = StateProvider<double?>((ref) => null);

final filteredTechniciansProvider =
    Provider<List<TechnicianProfileModel>>((ref) {
  final asyncTechs = ref.watch(allTechniciansProvider);
  final selectedCat = ref.watch(selectedCategoryFilterProvider);
  final selectedRating = ref.watch(selectedRatingFilterProvider);

  return asyncTechs.maybeWhen(
    data: (techs) {
      return techs.where((t) {
        if (selectedCat != null &&
            selectedCat.isNotEmpty &&
            !t.categoryIds.contains(selectedCat)) {
          return false;
        }
        if (selectedRating != null && t.averageRating < selectedRating) {
          return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
