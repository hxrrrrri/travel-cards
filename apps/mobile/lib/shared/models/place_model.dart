class PlaceModel {
  final String id;
  final String name;
  final String categoryId;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final String address;
  final String? photoUrl;
  final bool isOpenNow;
  final double? distanceMeters;
  final double rankScore;
  final String provider;
  final String providerId;
  final List<String> photos;
  final List<PlaceReview> reviews;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.address,
    this.photoUrl,
    this.isOpenNow = true,
    this.distanceMeters,
    this.rankScore = 0.0,
    this.provider = 'demo',
    this.providerId = '',
    this.photos = const [],
    this.reviews = const [],
  });

  PlaceModel copyWith({
    double? rankScore,
    double? distanceMeters,
    bool? isOpenNow,
    List<PlaceReview>? reviews,
  }) =>
      PlaceModel(
        id: id,
        name: name,
        categoryId: categoryId,
        lat: lat,
        lng: lng,
        rating: rating,
        reviewCount: reviewCount,
        address: address,
        photoUrl: photoUrl,
        isOpenNow: isOpenNow ?? this.isOpenNow,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        rankScore: rankScore ?? this.rankScore,
        provider: provider,
        providerId: providerId,
        photos: photos,
        reviews: reviews ?? this.reviews,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'reviewCount': reviewCount,
        'address': address,
        'photoUrl': photoUrl,
        'isOpenNow': isOpenNow,
        'distanceMeters': distanceMeters,
        'rankScore': rankScore,
        'provider': provider,
        'providerId': providerId,
        'photos': photos,
        'reviews': reviews.map((r) => r.toJson()).toList(),
      };

  factory PlaceModel.fromJson(Map<String, dynamic> j) => PlaceModel(
        id: j['id'] as String,
        name: j['name'] as String,
        categoryId: j['categoryId'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        rating: (j['rating'] as num).toDouble(),
        reviewCount: j['reviewCount'] as int,
        address: j['address'] as String,
        photoUrl: j['photoUrl'] as String?,
        isOpenNow: j['isOpenNow'] as bool? ?? true,
        distanceMeters: (j['distanceMeters'] as num?)?.toDouble(),
        rankScore: (j['rankScore'] as num?)?.toDouble() ?? 0.0,
        provider: j['provider'] as String? ?? 'demo',
        providerId: j['providerId'] as String? ?? '',
        photos: (j['photos'] as List<dynamic>?)?.cast<String>() ?? [],
        reviews: (j['reviews'] as List<dynamic>?)
                ?.map((r) => PlaceReview.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PlaceReview {
  final String author;
  final double rating;
  final String text;
  final String timeAgo;

  const PlaceReview({
    required this.author,
    required this.rating,
    required this.text,
    required this.timeAgo,
  });

  Map<String, dynamic> toJson() =>
      {'author': author, 'rating': rating, 'text': text, 'timeAgo': timeAgo};

  factory PlaceReview.fromJson(Map<String, dynamic> j) => PlaceReview(
        author: j['author'] as String,
        rating: (j['rating'] as num).toDouble(),
        text: j['text'] as String,
        timeAgo: j['timeAgo'] as String,
      );
}
