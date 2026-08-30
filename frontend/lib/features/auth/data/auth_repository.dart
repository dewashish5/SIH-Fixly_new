import '../../../shared/data/mock/mock_repository.dart';
import '../../../shared/models/models.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String otp);
}

abstract class BookingRepository {
  Future<Booking> createBooking(String serviceId, {String? address});
  Future<Booking> advanceBooking(String bookingId, BookingStatus status);
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._mock);

  final MockRepository _mock;

  @override
  Future<void> sendOtp(String phone) async {
    await _mock.mockDelay();
  }

  @override
  Future<bool> verifyOtp(String phone, String otp) async {
    await _mock.mockDelay();
    return otp == '123456';
  }
}

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this._mock);

  final MockRepository _mock;

  @override
  Future<Booking> createBooking(String serviceId, {String? address}) async {
    await _mock.mockDelay();
    final service = _mock.serviceById(serviceId);
    if (service == null) {
      throw StateError('Service not found');
    }
    return _mock.createBooking(service, address: address);
  }

  @override
  Future<Booking> advanceBooking(String bookingId, BookingStatus status) async {
    await _mock.mockDelay();
    _mock.advanceBooking(status);
    return _mock.activeBooking!;
  }
}
