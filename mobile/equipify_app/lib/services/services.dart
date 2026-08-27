import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class AuthService {
  final _api = ApiClient.I;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String emailAddress,
    required String phoneNumber,
    required String password,
    required String otpCode,
  }) async {
    await _api.post('/api/auth/register', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'emailAddress': emailAddress.trim(),
      'phoneNumber': phoneNumber.trim(),
      'password': password,
      'otpCode': otpCode.trim(),
    });
  }

  /// Sends the registration OTP. Returns the dev code when echoed (dev only).
  Future<String?> sendOtp(String phoneNumber) async {
    final data = await _api.post('/api/auth/send-otp', {
      'phoneNumber': phoneNumber.trim(),
    });
    return data is Map ? data['devCode'] as String? : null;
  }

  Future<AuthSession> login(String phoneNumber, String password) =>
      _login('/api/auth/login', {
        'phoneNumber': phoneNumber.trim(),
        'password': password,
      });

  Future<AuthSession> adminLogin(String username, String password) =>
      _login('/api/auth/admin-login', {
        'username': username.trim(),
        'password': password,
      });

  Future<AuthSession> _login(String path, Map<String, dynamic> body) async {
    final data = await _api.post(path, body);
    final session = AuthSession.fromJson(data as Map<String, dynamic>);
    await ApiClient.I.saveSession(
      access: session.accessToken,
      refresh: session.refreshToken,
    );
    return session;
  }

  Future<String?> forgotPassword(String phoneNumber) async {
    final data = await _api.post('/api/auth/forgot-password', {
      'phoneNumber': phoneNumber.trim(),
    });
    return data is Map ? data['devCode'] as String? : null;
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) =>
      _api.post('/api/auth/reset-password', {
        'phoneNumber': phoneNumber.trim(),
        'otpCode': otpCode.trim(),
        'newPassword': newPassword,
      });

  /// Restores a session from storage; returns null when no valid session.
  Future<User?> restore() async {
    try {
      final data = await _api.get('/api/auth/me');
      return User.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isAuthError) await logout();
      return null;
    }
  }

  Future<User?> me() async {
    final data = await _api.get('/api/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String emailAddress,
    required String phoneNumber,
  }) async {
    final data = await _api.put('/api/auth/me', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'emailAddress': emailAddress.trim(),
      'phoneNumber': phoneNumber.trim(),
    });
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(
          String currentPassword, String newPassword) =>
      _api.post('/api/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {/* session may already be dead */}
    await ApiClient.I.saveSession(access: null, refresh: null);
  }
}

class CategoryService {
  final _api = ApiClient.I;

  Future<List<Category>> all() async {
    final data = await _api.get('/api/categories') as List;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ListingService {
  final _api = ApiClient.I;

  Future<Paged<ListingSummary>> browse({
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? rentalUnit,
    int? minDuration,
    int? maxDuration,
    Bounds? bounds,
    int page = 1,
    int pageSize = 12,
  }) async {
    final q = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (rentalUnit != null) 'rentalUnit': rentalUnit,
      if (minDuration != null) 'minDuration': minDuration,
      if (maxDuration != null) 'maxDuration': maxDuration,
      ...?bounds?.toQuery(),
    };
    final data = await _api.get('/api/listings', q);
    return Paged.fromJson(
        data as Map<String, dynamic>, ListingSummary.fromJson);
  }

  Future<List<MapMarker>> mapMarkers(Bounds bounds, {int? categoryId}) async {
    final data = await _api.get('/api/listings/map', {
      ...bounds.toQuery(required: true),
      if (categoryId != null) 'categoryId': categoryId,
    });
    return (data as List)
        .map((e) => MapMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> details(int id) async =>
      Listing.fromJson(await _api.get('/api/listings/$id'));

  Future<List<ListingSummary>> mine() async {
    final data = await _api.get('/api/listings/mine') as List;
    return data.map((e) => ListingSummary.fromJson(e)).toList();
  }

  static const _listingFields = [
    'title',
    'description',
    'categoryId',
    'locationAddress',
    'rentalUnit',
    'costPerHour',
    'costPerDay',
    'costPerWeek',
    'costPerMonth',
    'costPerYear',
    'minRentalDays',
    'maxRentalDays',
    'latitude',
    'longitude',
  ];

  FormData _form({
    required String title,
    String? description,
    required int categoryId,
    required String locationAddress,
    String? rentalUnit,
    double? costPerHour,
    required double costPerDay,
    double? costPerWeek,
    double? costPerMonth,
    double? costPerYear,
    int? minRentalDays,
    int? maxRentalDays,
    required double latitude,
    required double longitude,
    List<String> newImagePaths = const [],
  }) {
    final values = <String, Object?>{
      'title': title.trim(),
      'description': description?.trim(),
      'categoryId': categoryId,
      'locationAddress': locationAddress.trim(),
      'rentalUnit': rentalUnit ?? 'day',
      'costPerHour': costPerHour,
      'costPerDay': costPerDay,
      'costPerWeek': costPerWeek,
      'costPerMonth': costPerMonth,
      'costPerYear': costPerYear,
      'minRentalDays': minRentalDays,
      'maxRentalDays': maxRentalDays,
      'latitude': latitude,
      'longitude': longitude,
    };
    final form = FormData();
    for (final f in _listingFields) {
      final v = values[f];
      if (v != null) form.fields.add(MapEntry(f, '$v'));
    }
    for (final p in newImagePaths) {
      form.files.add(
        MapEntry(
          'images',
          MultipartFile.fromFileSync(p),
        ),
      );
    }
    return form;
  }

  Future<int?> create({
    required String title,
    String? description,
    required int categoryId,
    required String locationAddress,
    String? rentalUnit,
    double? costPerHour,
    required double costPerDay,
    double? costPerWeek,
    double? costPerMonth,
    double? costPerYear,
    int? minRentalDays,
    int? maxRentalDays,
    required double latitude,
    required double longitude,
    List<String> imagePaths = const [],
  }) async {
    final data = await _api.sendForm(
      'POST',
      '/api/listings',
      _form(
        title: title,
        description: description,
        categoryId: categoryId,
        locationAddress: locationAddress,
        rentalUnit: rentalUnit,
        costPerHour: costPerHour,
        costPerDay: costPerDay,
        costPerWeek: costPerWeek,
        costPerMonth: costPerMonth,
        costPerYear: costPerYear,
        minRentalDays: minRentalDays,
        maxRentalDays: maxRentalDays,
        latitude: latitude,
        longitude: longitude,
        newImagePaths: imagePaths,
      ),
    );
    return data is Map ? data['id'] as int : null;
  }

  Future<void> update(
    int id, {
    required String title,
    String? description,
    required int categoryId,
    required String locationAddress,
    String? rentalUnit,
    double? costPerHour,
    required double costPerDay,
    double? costPerWeek,
    double? costPerMonth,
    double? costPerYear,
    int? minRentalDays,
    int? maxRentalDays,
    required double latitude,
    required double longitude,
    List<String> imagePaths = const [],
  }) =>
      _api.sendForm(
        'PUT',
        '/api/listings/$id',
        _form(
          title: title,
          description: description,
          categoryId: categoryId,
          locationAddress: locationAddress,
          rentalUnit: rentalUnit,
          costPerHour: costPerHour,
          costPerDay: costPerDay,
          costPerWeek: costPerWeek,
          costPerMonth: costPerMonth,
          costPerYear: costPerYear,
          minRentalDays: minRentalDays,
          maxRentalDays: maxRentalDays,
          latitude: latitude,
          longitude: longitude,
          newImagePaths: imagePaths,
        ),
      );

  /// "Active" | "Inactive"
  Future<void> setStatus(int id, String status) =>
      _api.post('/api/listings/$id/status', {'status': status});

  Future<void> delete(int id) => _api.delete('/api/listings/$id');

  Future<List<Review>> userReviews(int userId, {int limit = 20}) async {
    final data = await _api.get('/api/users/$userId/reviews', {'limit': limit}) as List;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Review>> listingReviews(int listingId, {int limit = 20}) async {
    final data = await _api.get('/api/listings/$listingId/reviews', {'limit': limit}) as List;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// Geographic viewport filter.
class Bounds {
  Bounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west, south, east, north;

  Map<String, dynamic> toQuery({bool required = false}) => {
        'west': west,
        'south': south,
        'east': east,
        'north': north,
      };
}

class RequestService {
  final _api = ApiClient.I;

  Future<OtpSent> sendOtp(int listingId) async => OtpSent.fromJson(
      await _api.post('/api/requests/otp/send', {'listingId': listingId}));

  Future<int> create({
    required int listingId,
    required DateTime fromDate,
    required DateTime toDate,
    required TimeOfDayStr fromTime,
    required TimeOfDayStr toTime,
    required String otpCode,
  }) async {
    final data = await _api.post('/api/requests', {
      'listingId': listingId,
      'fromDate': fmtDate(fromDate),
      'toDate': fmtDate(toDate),
      'fromTime': fromTime,
      'toTime': toTime,
      'otpCode': otpCode.trim(),
    });
    return data is Map ? data['id'] as int : -1;
  }

  Future<List<RentalRequest>> mine() => _list('/api/requests/mine');

  Future<List<RentalRequest>> incoming() => _list('/api/requests/incoming');

  Future<void> accept(int id) => _api.post('/api/requests/$id/accept');

  Future<void> reject(int id) => _api.post('/api/requests/$id/reject');

  Future<void> cancel(int id) => _api.delete('/api/requests/$id');

  Future<void> rate(int id, double rating) =>
      _api.post('/api/requests/$id/rating', {'rating': rating});

  Future<List<RentalRequest>> _list(String path) async {
    final data = await _api.get(path) as List;
    return data.map((e) => RentalRequest.fromJson(e)).toList();
  }
}

typedef TimeOfDayStr = String; // "HH:mm:ss"

String fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AdminService {
  final _api = ApiClient.I;

  Future<DashboardStats> dashboard() async => DashboardStats.fromJson(
      await _api.get('/api/admin/dashboard') as Map<String, dynamic>);

  Future<List<User>> users() async {
    final data = await _api.get('/api/admin/users') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleUserStatus(int id) =>
      _api.post('/api/admin/users/$id/toggle-status');

  Future<void> deleteUser(int id) => _api.delete('/api/admin/users/$id');

  Future<List<ListingSummary>> listings({int? page}) async {
    final data =
        await _api.get('/api/admin/listings', {'page': page ?? 1});
    // Endpoint may return a bare list or a paged envelope depending on build.
    if (data is List) {
      return data.map((e) => ListingSummary.fromJson(e)).toList();
    }
    return Paged.fromJson(data as Map<String, dynamic>, ListingSummary.fromJson)
        .items;
  }

  Future<void> approveListing(int id) =>
      _api.post('/api/admin/listings/$id/approve');

  Future<void> deactivateListing(int id) =>
      _api.post('/api/admin/listings/$id/deactivate');

  Future<void> deleteListing(int id) =>
      _api.delete('/api/admin/listings/$id');

  Future<void> createCategory(String name, {String? imagePath}) async {
    final form = FormData();
    form.fields.add(MapEntry('name', name));
    if (imagePath != null) {
      form.files.add(MapEntry('picture', MultipartFile.fromFileSync(imagePath)));
    }
    await _api.sendForm('POST', '/api/admin/categories', form);
  }

  Future<void> updateCategory(int id, String name, {String? imagePath}) async {
    final form = FormData();
    form.fields.add(MapEntry('name', name));
    if (imagePath != null) {
      form.files.add(MapEntry('picture', MultipartFile.fromFileSync(imagePath)));
    }
    await _api.sendForm('PUT', '/api/admin/categories/$id', form);
  }

  Future<void> deleteCategory(int id) =>
      _api.delete('/api/admin/categories/$id');

  Future<List<RentalRequest>> requests() async {
    final data = await _api.get('/api/admin/requests') as List;
    return data.map((e) => RentalRequest.fromJson(e)).toList();
  }
}
