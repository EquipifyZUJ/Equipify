/// Typed models mirroring the Equipify API contracts 1:1.
library;

class User {
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.emailAddress,
    required this.phoneNumber,
    this.rating,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String name;
  final String emailAddress;
  final String phoneNumber;
  final double? rating;
  final String status;
  final DateTime createdAt;

  bool get isActive => status == 'Active';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        firstName: (j['firstName'] ?? '') as String,
        lastName: (j['lastName'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        emailAddress: (j['emailAddress'] ?? '') as String,
        phoneNumber: (j['phoneNumber'] ?? '') as String,
        rating: (j['rating'] is num
                ? (j['rating'] as num).toDouble()
                : j['totalRates'] is num
                    ? (j['totalRates'] as num).toDouble()
                    : null),
        status: (j['status'] ?? 'Active') as String,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.expiresAtUtc,
    this.refreshToken,
    this.user,
  });

  final String accessToken;
  final DateTime expiresAtUtc;
  final String? refreshToken;
  final User? user;

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        accessToken: j['accessToken'] as String,
        expiresAtUtc: DateTime.tryParse(j['expiresAtUtc'] ?? '') ??
            DateTime.now().toUtc(),
        refreshToken: j['refreshToken'] as String?,
        user: j['user'] == null ? null : User.fromJson(j['user']),
      );
}

class Category {
  Category({required this.id, required this.name, this.nameAr, this.picture});
  final int id;
  final String name;
  final String? nameAr;
  final String? picture;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        nameAr: j['nameAr'] as String?,
        picture: j['picture'] as String?,
      );
}

class ListingSummary {
  ListingSummary({
    required this.id,
    required this.title,
    this.mainImage,
    required this.rentalUnit,
    this.costPerHour,
    required this.costPerDay,
    this.costPerWeek,
    this.costPerMonth,
    this.minRentalDays,
    this.maxRentalDays,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.categoryId,
    required this.categoryName,
    required this.status,
  });

  final int id;
  final String title;
  final String? mainImage;
  final String rentalUnit;
  final double? costPerHour;
  final double costPerDay;
  final double? costPerWeek;
  final double? costPerMonth;
  final int? minRentalDays;
  final int? maxRentalDays;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final int categoryId;
  final String categoryName;
  final String status;

  bool get isPending => status == 'Pending';
  bool get isActive => status == 'Active';

  /// The price for the listing's primary rental unit.
  double? get primaryPrice => switch (rentalUnit) {
    'hour' => costPerHour,
    'week' => costPerWeek,
    'month' => costPerMonth,
    _ => costPerDay,
  };

  factory ListingSummary.fromJson(Map<String, dynamic> j) => ListingSummary(
        id: j['id'] as int,
        title: j['title'] as String,
        mainImage: j['mainImage'] as String?,
        rentalUnit: (j['rentalUnit'] ?? 'day') as String,
        costPerHour: _d(j['costPerHour']),
        costPerDay: _d(j['costPerDay'])!,
        costPerWeek: _d(j['costPerWeek']),
        costPerMonth: _d(j['costPerMonth']),
        minRentalDays: j['minRentalDays'] as int?,
        maxRentalDays: j['maxRentalDays'] as int?,
        locationAddress: j['locationAddress'] as String? ?? '',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        categoryId: j['categoryId'] as int,
        categoryName: j['categoryName'] as String? ?? '',
        status: j['status'] as String? ?? 'Active',
      );

  static double? _d(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
}

class Owner {
  Owner({required this.id, required this.name, this.rating, this.phone});
  final int id;
  final String name;
  final double? rating;
  final String? phone;

  factory Owner.fromJson(Map<String, dynamic> j) => Owner(
        id: j['id'] as int,
        name: j['name'] as String,
        rating: (j['rating'] is num
                ? (j['rating'] as num).toDouble()
                : j['totalRates'] is num
                    ? (j['totalRates'] as num).toDouble()
                    : null),
        phone: j['phoneNumber'] as String?,
      );
}

class Listing {
  Listing({
    required this.id,
    required this.title,
    required this.description,
    this.mainImage,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    required this.locationAddress,
    required this.rentalUnit,
    this.costPerHour,
    required this.costPerDay,
    this.costPerWeek,
    this.costPerMonth,
    this.costPerYear,
    this.minRentalDays,
    this.maxRentalDays,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.owner,
  });

  final int id;
  final String title;
  final String description;
  final String? mainImage;
  final List<String> images;
  final int categoryId;
  final String categoryName;
  final String locationAddress;
  final String rentalUnit;
  final double? costPerHour;
  final double costPerDay;
  final double? costPerWeek;
  final double? costPerMonth;
  final double? costPerYear;
  final int? minRentalDays;
  final int? maxRentalDays;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final Owner? owner;

  /// The price for the listing's primary rental unit.
  double? get primaryPrice => switch (rentalUnit) {
    'hour' => costPerHour,
    'week' => costPerWeek,
    'month' => costPerMonth,
    'year' => costPerYear,
    _ => costPerDay,
  };

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        mainImage: j['mainImage'] as String?,
        images:
            ((j['images'] as List?) ?? const []).map((e) => '$e').toList(),
        categoryId: j['categoryId'] as int,
        categoryName: j['categoryName'] as String? ?? '',
        locationAddress: j['locationAddress'] as String? ?? '',
        rentalUnit: (j['rentalUnit'] ?? 'day') as String,
        costPerHour: ListingSummary._d(j['costPerHour']),
        costPerDay: ListingSummary._d(j['costPerDay'])!,
        costPerWeek: ListingSummary._d(j['costPerWeek']),
        costPerMonth: ListingSummary._d(j['costPerMonth']),
        costPerYear: ListingSummary._d(j['costPerYear']),
        minRentalDays: j['minRentalDays'] as int?,
        maxRentalDays: j['maxRentalDays'] as int?,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        status: j['status'] as String? ?? 'Active',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ??
            DateTime.now(),
        owner: j['owner'] == null
            ? null
            : Owner.fromJson(j['owner'] as Map<String, dynamic>),
      );

  /// Convenience view for cards.
  ListingSummary get summary => ListingSummary(
        id: id,
        title: title,
        mainImage: mainImage ?? (images.isNotEmpty ? images.first : null),
        rentalUnit: rentalUnit,
        costPerHour: costPerHour,
        costPerDay: costPerDay,
        costPerWeek: costPerWeek,
        costPerMonth: costPerMonth,
        minRentalDays: minRentalDays,
        maxRentalDays: maxRentalDays,
        locationAddress: locationAddress,
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        categoryName: categoryName,
        status: status,
      );
}

class Paged<T> {
  Paged({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory Paged.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) =>
      Paged(
        items: ((j['items'] as List?) ?? const [])
            .map((e) => parse(e as Map<String, dynamic>))
            .toList(),
        page: j['page'] as int? ?? 1,
        pageSize: j['pageSize'] as int? ?? 12,
        totalCount: j['totalCount'] as int? ?? 0,
        totalPages: j['totalPages'] as int? ?? 1,
      );
}

class MapMarker {
  MapMarker({
    required this.id,
    required this.title,
    this.image,
    required this.costPerDay,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String title;
  final String? image;
  final double costPerDay;
  final String locationAddress;
  final double latitude;
  final double longitude;

  factory MapMarker.fromJson(Map<String, dynamic> j) => MapMarker(
        id: j['id'] as int,
        title: j['title'] as String,
        image: j['image'] as String?,
        costPerDay: ListingSummary._d(j['costPerDay'])!,
        locationAddress: j['locationAddress'] as String? ?? '',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
      );
}

class OtpSent {
  OtpSent({required this.sent, required this.cooldownSeconds, this.devCode});
  final bool sent;
  final int cooldownSeconds;
  final String? devCode;

  factory OtpSent.fromJson(Map<String, dynamic> j) => OtpSent(
        sent: j['sent'] == true,
        cooldownSeconds: j['cooldownSeconds'] as int? ?? 60,
        devCode: j['devCode'] as String?,
      );
}

class RentalRequest {
  RentalRequest({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImage,
    required this.renter,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
    required this.totalCost,
    required this.status,
    required this.hasRating,
    required this.createdAt,
  });

  final int id;
  final int listingId;
  final String listingTitle;
  final String? listingImage;
  final Renter renter;
  final DateTime fromDate;
  final DateTime toDate;
  final String fromTime;
  final String toTime;
  final double totalCost;
  final String status; // Pending | Accepted | Rejected
  final bool hasRating;
  final DateTime createdAt;

  bool get isPending => status == 'Pending';
  bool get isAccepted => status == 'Accepted';

  factory RentalRequest.fromJson(Map<String, dynamic> j) => RentalRequest(
        id: j['id'] as int,
        listingId: j['listingId'] as int,
        listingTitle: j['listingTitle'] as String? ?? '',
        listingImage: j['listingImage'] as String?,
        renter: Renter.fromJson(j['renter'] as Map<String, dynamic>),
        fromDate: DateTime.parse(j['fromDate'].toString()),
        toDate: DateTime.parse(j['toDate'].toString()),
        fromTime: (j['fromTime'] ?? '').toString().substring(0, 5),
        toTime: (j['toTime'] ?? '').toString().substring(0, 5),
        totalCost: ListingSummary._d(j['totalCost'])!,
        status: j['status'] as String,
        hasRating: j['hasRating'] == true,
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ??
            DateTime.now(),
      );
}

class Renter {
  Renter({required this.id, required this.name, required this.phoneNumber});
  final int id;
  final String name;
  final String phoneNumber;

  factory Renter.fromJson(Map<String, dynamic> j) => Renter(
        id: j['id'] as int,
        name: j['name'] as String,
        phoneNumber: j['phoneNumber'] as String? ?? '',
      );
}

class DashboardStats {
  DashboardStats({
    required this.users,
    required this.listings,
    required this.activeListings,
    required this.pendingListings,
    required this.categories,
    required this.requests,
    required this.pendingRequests,
  });

  final int users;
  final int listings;
  final int activeListings;
  final int pendingListings;
  final int categories;
  final int requests;
  final int pendingRequests;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        users: j['users'] as int? ?? 0,
        listings: j['listings'] as int? ?? 0,
        activeListings: j['activeListings'] as int? ?? 0,
        pendingListings: j['pendingListings'] as int? ?? 0,
        categories: j['categories'] as int? ?? 0,
        requests: j['requests'] as int? ?? 0,
        pendingRequests: j['pendingRequests'] as int? ?? 0,
      );
}

class Review {
  Review({
    required this.id,
    required this.renterId,
    required this.renterName,
    required this.listingId,
    required this.listingTitle,
    required this.rating,
    required this.createdAt,
  });

  final int id;
  final int renterId;
  final String renterName;
  final int listingId;
  final String listingTitle;
  final double rating;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        renterId: j['renterId'] as int,
        renterName: j['renterName'] as String? ?? '',
        listingId: j['listingId'] as int,
        listingTitle: j['listingTitle'] as String? ?? '',
        rating: ListingSummary._d(j['rating']) ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ??
            DateTime.now(),
      );
}
