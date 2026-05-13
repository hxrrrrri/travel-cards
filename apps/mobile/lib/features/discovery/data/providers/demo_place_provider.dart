import 'package:uuid/uuid.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/discovery_models.dart';

const _uuid = Uuid();

class DemoPlaceProvider {
  Future<List<PlaceModel>> searchNearby(DiscoveryRequest req) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final origin = (lat: req.originLat, lng: req.originLng);

    return [
      PlaceModel(
        id: _uuid.v4(), name: 'Abbey Falls', categoryId: 'waterfall',
        lat: origin.lat + 0.042, lng: origin.lng - 0.018,
        rating: 4.6, reviewCount: 2341, address: 'Abbey Falls Rd, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600'],
        reviews: [
          const PlaceReview(author: 'Rahul K', rating: 5, text: 'Stunning waterfall! Best visited after monsoon.', timeAgo: '2 days ago'),
          const PlaceReview(author: 'Priya M', rating: 4, text: 'Beautiful but crowded on weekends.', timeAgo: '1 week ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Raja\'s Seat', categoryId: 'viewpoint',
        lat: origin.lat + 0.010, lng: origin.lng + 0.009,
        rating: 4.4, reviewCount: 4123, address: 'Raja\'s Seat, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600'],
        reviews: [
          const PlaceReview(author: 'Arun S', rating: 5, text: 'Magical sunset views. Must visit!', timeAgo: '3 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Coorg Coffee Works', categoryId: 'cafe',
        lat: origin.lat + 0.005, lng: origin.lng - 0.012,
        rating: 4.7, reviewCount: 892, address: 'MG Road, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600'],
        reviews: [
          const PlaceReview(author: 'Divya R', rating: 5, text: 'Best estate coffee I\'ve had. The plantation view is incredible.', timeAgo: '1 day ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Madikeri Fort', categoryId: 'tourist_attraction',
        lat: origin.lat - 0.003, lng: origin.lng + 0.006,
        rating: 4.2, reviewCount: 3210, address: 'Fort Road, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1587474260584-136574528ed5?w=600'],
        reviews: [
          const PlaceReview(author: 'Kiran B', rating: 4, text: 'Historical fort with good views. Takes 1-2 hours.', timeAgo: '5 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Bylakuppe Monastery', categoryId: 'temple',
        lat: origin.lat - 0.055, lng: origin.lng + 0.043,
        rating: 4.8, reviewCount: 5678, address: 'Bylakuppe, Mysuru',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1578469645742-46cae010e5d4?w=600'],
        reviews: [
          const PlaceReview(author: 'Meera T', rating: 5, text: 'Peaceful and beautiful. The golden temple is breathtaking.', timeAgo: '1 week ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Silver Oak Estate', categoryId: 'cafe',
        lat: origin.lat + 0.022, lng: origin.lng - 0.031,
        rating: 4.5, reviewCount: 412, address: 'Kushalnagar Road, Coorg',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600'],
        reviews: [
          const PlaceReview(author: 'Ravi N', rating: 5, text: 'Estate tour + coffee tasting. A must for coffee lovers.', timeAgo: '3 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Talakaveri', categoryId: 'tourist_attraction',
        lat: origin.lat - 0.078, lng: origin.lng + 0.012,
        rating: 4.5, reviewCount: 6789, address: 'Bhagamandala, Kodagu',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1455156218388-5e61b526818b?w=600'],
        reviews: [
          const PlaceReview(author: 'Anjali V', rating: 5, text: 'Source of Kaveri river. Sacred and scenic.', timeAgo: '2 weeks ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Nagarhole National Park', categoryId: 'bio_park',
        lat: origin.lat + 0.089, lng: origin.lng - 0.065,
        rating: 4.6, reviewCount: 8901, address: 'Nagarhole, Kodagu',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1516426122078-c23e76319801?w=600'],
        reviews: [
          const PlaceReview(author: 'Suresh K', rating: 5, text: 'Spotted elephant herd and deer on safari. Amazing!', timeAgo: '4 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Zara\'s Café Coorg', categoryId: 'restaurant',
        lat: origin.lat + 0.008, lng: origin.lng + 0.003,
        rating: 4.3, reviewCount: 678, address: 'College Road, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600'],
        reviews: [
          const PlaceReview(author: 'Nisha P', rating: 4, text: 'Pandi curry and rice is excellent. Great local food.', timeAgo: '2 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Iruppu Falls', categoryId: 'waterfall',
        lat: origin.lat - 0.092, lng: origin.lng - 0.044,
        rating: 4.4, reviewCount: 3450, address: 'Brahmagiri Hills, Kodagu',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1591366977099-da7d43cba3eb?w=600'],
        reviews: [
          const PlaceReview(author: 'Vikram S', rating: 5, text: 'Sacred waterfall in dense forest. Magical!', timeAgo: '1 week ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Coorg Fuel Station (HP)', categoryId: 'fuel_station',
        lat: origin.lat + 0.002, lng: origin.lng - 0.004,
        rating: 4.0, reviewCount: 234, address: 'NH 275, Madikeri',
        isOpenNow: true,
        photos: [],
        reviews: [],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Mercara Golf Links', categoryId: 'park',
        lat: origin.lat - 0.015, lng: origin.lng - 0.020,
        rating: 4.3, reviewCount: 560, address: 'Golf Course Rd, Madikeri',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=600'],
        reviews: [
          const PlaceReview(author: 'George A', rating: 4, text: 'Beautiful course surrounded by coffee estates.', timeAgo: '5 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Honey Valley Estate', categoryId: 'hotel',
        lat: origin.lat + 0.063, lng: origin.lng + 0.028,
        rating: 4.7, reviewCount: 1234, address: 'Kakkabe, Kodagu',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600'],
        reviews: [
          const PlaceReview(author: 'Sara L', rating: 5, text: 'Eco-stay in coffee plantation. Absolutely peaceful.', timeAgo: '1 week ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Dubare Elephant Camp', categoryId: 'bio_park',
        lat: origin.lat + 0.038, lng: origin.lng + 0.051,
        rating: 4.5, reviewCount: 7823, address: 'Dubare, Kushalnagar',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1561731216-c3a4d99437d5?w=600'],
        reviews: [
          const PlaceReview(author: 'Maya R', rating: 5, text: 'Bathing elephants in the river. Unforgettable experience!', timeAgo: '3 days ago'),
        ],
      ),
      PlaceModel(
        id: _uuid.v4(), name: 'Harangi Reservoir', categoryId: 'viewpoint',
        lat: origin.lat - 0.035, lng: origin.lng - 0.048,
        rating: 4.2, reviewCount: 1890, address: 'Harangi, Kodagu',
        isOpenNow: true,
        photos: ['https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600'],
        reviews: [
          const PlaceReview(author: 'Jay M', rating: 4, text: 'Scenic reservoir surrounded by forests. Good for picnics.', timeAgo: '2 weeks ago'),
        ],
      ),
    ].where((p) => req.categories.isEmpty || req.categories.contains(p.categoryId)).toList();
  }
}
