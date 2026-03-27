import 'package:meta/meta.dart';

@immutable
class Restaurant {
  final String id;
  final String name;
  final String city;
  final String state;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String cuisineType;
  final String? ownerChef;
  final bool? stillOpen;
  final double? googleRating;
  final int? googleRatingCount;
  final String? googleMapsUrl;
  final String? websiteUrl;
  final String? formattedAddress;
  final String? businessStatus;
  final String? googleCurrentName;
  final bool nameChanged;
  final double? yelpRating;
  final List<Visit> visits;
  final List<Dish> dishes;

  const Restaurant({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    this.address,
    this.latitude,
    this.longitude,
    required this.cuisineType,
    this.ownerChef,
    this.stillOpen,
    this.googleRating,
    this.googleRatingCount,
    this.googleMapsUrl,
    this.websiteUrl,
    this.formattedAddress,
    this.businessStatus,
    this.googleCurrentName,
    this.nameChanged = false,
    this.yelpRating,
    required this.visits,
    required this.dishes,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['restaurant_id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown',
      city: json['city'] as String? ?? 'Unknown',
      state: json['state'] as String? ?? 'Unknown',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cuisineType: json['cuisine_type'] as String? ?? 'Unknown',
      ownerChef: json['owner_chef'] as String?,
      stillOpen: json['still_open'] as bool?,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      googleRatingCount: json['google_rating_count'] as int?,
      googleMapsUrl: json['google_maps_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      businessStatus: json['business_status'] as String?,
      googleCurrentName: json['google_current_name'] as String?,
      nameChanged: json['name_changed'] as bool? ?? false,
      yelpRating: (json['yelp_rating'] as num?)?.toDouble(),
      visits:
          (json['visits'] as List<dynamic>?)
              ?.map((v) => Visit.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      dishes:
          (json['dishes'] as List<dynamic>?)
              ?.map((d) => Dish.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? cuisineType,
    String? ownerChef,
    bool? stillOpen,
    double? googleRating,
    int? googleRatingCount,
    String? googleMapsUrl,
    String? websiteUrl,
    String? formattedAddress,
    String? businessStatus,
    String? googleCurrentName,
    bool? nameChanged,
    double? yelpRating,
    List<Visit>? visits,
    List<Dish>? dishes,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cuisineType: cuisineType ?? this.cuisineType,
      ownerChef: ownerChef ?? this.ownerChef,
      stillOpen: stillOpen ?? this.stillOpen,
      googleRating: googleRating ?? this.googleRating,
      googleRatingCount: googleRatingCount ?? this.googleRatingCount,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      businessStatus: businessStatus ?? this.businessStatus,
      googleCurrentName: googleCurrentName ?? this.googleCurrentName,
      nameChanged: nameChanged ?? this.nameChanged,
      yelpRating: yelpRating ?? this.yelpRating,
      visits: visits ?? this.visits,
      dishes: dishes ?? this.dishes,
    );
  }
}

@immutable
class Visit {
  final String videoId;
  final String youtubeUrl;
  final String videoTitle;
  final String? videoType;
  final String? guyIntro;
  final double timestampStart;
  final double? timestampEnd;

  const Visit({
    required this.videoId,
    required this.youtubeUrl,
    required this.videoTitle,
    this.videoType,
    this.guyIntro,
    required this.timestampStart,
    this.timestampEnd,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      videoId: json['video_id'] as String,
      youtubeUrl: json['youtube_url'] as String,
      videoTitle: json['video_title'] as String,
      videoType: json['video_type'] as String?,
      guyIntro: json['guy_intro'] as String?,
      timestampStart: (json['timestamp_start'] as num).toDouble(),
      timestampEnd: (json['timestamp_end'] as num?)?.toDouble(),
    );
  }
}

@immutable
class Dish {
  final String dishName;
  final String description;
  final List<String> ingredients;
  final String? dishCategory;
  final String? guyResponse;
  final String? videoId;
  final double? timestampStart;

  const Dish({
    required this.dishName,
    required this.description,
    required this.ingredients,
    this.dishCategory,
    this.guyResponse,
    this.videoId,
    this.timestampStart,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      dishName: json['dish_name'] as String,
      description: json['description'] as String,
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      dishCategory: json['dish_category'] as String?,
      guyResponse: json['guy_response'] as String?,
      videoId: json['video_id'] as String?,
      timestampStart: (json['timestamp_start'] as num?)?.toDouble(),
    );
  }
}
