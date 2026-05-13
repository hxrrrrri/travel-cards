import 'package:flutter/material.dart';

enum TravelCategory {
  cafe('Cafe', '☕', 'cafe', Icons.local_cafe),
  restaurant('Restaurant', '🍽️', 'restaurant', Icons.restaurant),
  viewpoint('Viewpoint', '🔭', 'viewpoint', Icons.landscape),
  touristAttraction('Tourist Attraction', '🏛️', 'tourist_attraction', Icons.account_balance),
  park('Park', '🌳', 'park', Icons.park),
  bioPark('Bio Park', '🦁', 'bio_park', Icons.pets),
  museum('Museum', '🏺', 'museum', Icons.museum),
  hotel('Hotel', '🏨', 'hotel', Icons.hotel),
  fuelStation('Fuel Station', '⛽', 'fuel_station', Icons.local_gas_station),
  shopping('Shopping', '🛍️', 'shopping', Icons.shopping_bag),
  temple('Temple', '🛕', 'temple', Icons.temple_hindu),
  beach('Beach', '🏖️', 'beach', Icons.beach_access),
  waterfall('Waterfall', '💧', 'waterfall', Icons.water);

  final String label;
  final String emoji;
  final String id;
  final IconData icon;

  const TravelCategory(this.label, this.emoji, this.id, this.icon);

  static TravelCategory fromId(String id) => TravelCategory.values.firstWhere(
        (c) => c.id == id,
        orElse: () => TravelCategory.touristAttraction,
      );
}
