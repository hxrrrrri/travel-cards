import 'place_model.dart';
import 'route_info_model.dart';

enum TravelCardStatus { draft, active, completed }

enum PlaceVisitStatus { pending, visited, skipped }

class TravelCardModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double? originLat;
  final double? originLng;
  final String? originName;
  final int radiusMeters;
  final List<String> selectedCategories;
  final TravelCardStatus status;
  final List<PlaceModel> discoveredPlaces;
  final List<RouteInfoModel> routes;
  final Map<String, PlaceVisitStatus> placeStatuses;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TravelCardModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.originLat,
    this.originLng,
    this.originName,
    this.radiusMeters = 10000,
    this.selectedCategories = const [],
    this.status = TravelCardStatus.draft,
    this.discoveredPlaces = const [],
    this.routes = const [],
    this.placeStatuses = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  int get discoveredCount => discoveredPlaces.length;
  int get visitedCount =>
      placeStatuses.values.where((s) => s == PlaceVisitStatus.visited).length;
  int get pendingCount =>
      placeStatuses.values.where((s) => s == PlaceVisitStatus.pending).length;
  int get skippedCount =>
      placeStatuses.values.where((s) => s == PlaceVisitStatus.skipped).length;

  TravelCardModel copyWith({
    String? title,
    String? description,
    double? originLat,
    double? originLng,
    String? originName,
    int? radiusMeters,
    List<String>? selectedCategories,
    TravelCardStatus? status,
    List<PlaceModel>? discoveredPlaces,
    List<RouteInfoModel>? routes,
    Map<String, PlaceVisitStatus>? placeStatuses,
    DateTime? updatedAt,
  }) =>
      TravelCardModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        originLat: originLat ?? this.originLat,
        originLng: originLng ?? this.originLng,
        originName: originName ?? this.originName,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        status: status ?? this.status,
        discoveredPlaces: discoveredPlaces ?? this.discoveredPlaces,
        routes: routes ?? this.routes,
        placeStatuses: placeStatuses ?? this.placeStatuses,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'originLat': originLat,
        'originLng': originLng,
        'originName': originName,
        'radiusMeters': radiusMeters,
        'selectedCategories': selectedCategories,
        'status': status.name,
        'discoveredPlaces': discoveredPlaces.map((p) => p.toJson()).toList(),
        'routes': routes.map((r) => r.toJson()).toList(),
        'placeStatuses': placeStatuses.map((k, v) => MapEntry(k, v.name)),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TravelCardModel.fromJson(Map<String, dynamic> j) {
    final statusMap = (j['placeStatuses'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
              k,
              PlaceVisitStatus.values.firstWhere((s) => s.name == v,
                  orElse: () => PlaceVisitStatus.pending)),
        ) ??
        {};
    return TravelCardModel(
      id: j['id'] as String,
      userId: j['userId'] as String,
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      originLat: (j['originLat'] as num?)?.toDouble(),
      originLng: (j['originLng'] as num?)?.toDouble(),
      originName: j['originName'] as String?,
      radiusMeters: j['radiusMeters'] as int? ?? 10000,
      selectedCategories:
          (j['selectedCategories'] as List<dynamic>?)?.cast<String>() ?? [],
      status: TravelCardStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => TravelCardStatus.draft),
      discoveredPlaces: (j['discoveredPlaces'] as List<dynamic>?)
              ?.map((p) => PlaceModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      routes: (j['routes'] as List<dynamic>?)
              ?.map((r) => RouteInfoModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      placeStatuses: statusMap,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
    );
  }
}
