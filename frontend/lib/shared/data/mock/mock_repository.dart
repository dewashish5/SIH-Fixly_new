import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/models.dart';

/// Local fallbacks for surfaces **without** backend APIs yet:
/// support chat, notifications list, worker KYC/onboarding uploads,
/// reliability score, worker job feed. Prefer API repos for auth/home/
/// workers/bookings/payments/reviews/ai.
class MockRepository {
  MockRepository._();
  static final MockRepository instance = MockRepository._();

  String locale = 'en';
  UserRole? selectedRole;
  AppUser? currentUser;
  OnboardingFormData onboardingData = const OnboardingFormData();
  KycReviewStatus kycReviewStatus = KycReviewStatus.submitted;
  bool isAvailable = true;
  Booking? activeBooking;

  final List<Booking> orderHistory = const [];

  final List<WalletTransaction> walletTransactions = [
    WalletTransaction(
      id: 't1',
      label: 'Job payout — AC servicing',
      amount: 1200,
      isCredit: true,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    WalletTransaction(
      id: 't2',
      label: 'Withdrawal to bank',
      amount: 5000,
      isCredit: false,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final List<SupportMessage> supportMessages = [
    SupportMessage(
      id: 'm1',
      text: 'Hi! How can we help you today?',
      isAgent: true,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final List<WorkerJob> _jobs = [
    const WorkerJob(
      id: 'job1',
      title: 'Electrical wiring repair',
      customerName: 'Priya Sharma',
      address: 'Previous job',
      pay: 850,
      status: JobStatus.incoming,
      distanceKm: 2.3,
    ),
    const WorkerJob(
      id: 'job2',
      title: 'Plumbing leak fix',
      customerName: 'Rahul Verma',
      address: 'Nearby job',
      pay: 650,
      status: JobStatus.incoming,
      distanceKm: 4.1,
    ),
    const WorkerJob(
      id: 'job3',
      title: 'AC servicing',
      customerName: 'Anita Das',
      address: 'Active job',
      pay: 1200,
      status: JobStatus.active,
      distanceKm: 1.8,
    ),
  ];

  final List<WorkerProfile> workers = const [
    WorkerProfile(
      id: 'w1',
      name: 'Rajesh Kumar',
      skills: ['Electrician', 'Technician'],
      rating: 4.9,
      jobsCompleted: 234,
      reliabilityScore: 96,
      insured: true,
    ),
    WorkerProfile(
      id: 'w2',
      name: 'Suresh Patel',
      skills: ['Plumber', 'Cleaning'],
      rating: 4.7,
      jobsCompleted: 189,
      reliabilityScore: 92,
      insured: true,
    ),
    WorkerProfile(
      id: 'w3',
      name: 'Meena Devi',
      skills: ['Domestic Helper', 'Caregiving'],
      rating: 4.8,
      jobsCompleted: 156,
      reliabilityScore: 94,
      insured: false,
    ),
  ];

  final List<ServiceItem> services = const [
    ServiceItem(
      id: 's1',
      categoryId: 'electrician',
      title: 'Switch & Socket Repair',
      titleHi: 'स्विच और सॉकेट मरम्मत',
      description: 'Fix faulty switches, sockets, and wiring issues.',
      descriptionHi: 'खराब स्विच, सॉकेट और वायरिंग की मरम्मत।',
      priceFrom: 299,
      rating: 4.8,
    ),
    ServiceItem(
      id: 's2',
      categoryId: 'plumber',
      title: 'Tap & Pipe Leak Fix',
      titleHi: 'नल और पाइप लीक मरम्मत',
      description: 'Quick leak repair for taps, pipes, and fittings.',
      descriptionHi: 'नल, पाइप और फिटिंग की त्वरित लीक मरम्मत।',
      priceFrom: 349,
      rating: 4.7,
    ),
    ServiceItem(
      id: 's3',
      categoryId: 'cleaning',
      title: 'Deep Home Cleaning',
      titleHi: 'गहरी घर की सफाई',
      description: 'Full home deep cleaning with eco-friendly supplies.',
      descriptionHi: 'Eco-friendly सामग्री से पूरे घर की गहरी सफाई।',
      priceFrom: 999,
      rating: 4.9,
    ),
    ServiceItem(
      id: 's4',
      categoryId: 'caregiving',
      title: 'Elder Care Visit',
      titleHi: 'बुजुर्ग देखभाल विज़िट',
      description: 'Trained caregiver for elderly assistance at home.',
      descriptionHi: 'घर पर बुजुर्गों की देखभाल के लिए प्रशिक्षित caregiver।',
      priceFrom: 799,
      rating: 4.8,
    ),
  ];

  final List<NotificationItem> notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Booking confirmed',
      body: 'Your electrician booking is confirmed for today.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: 'n2',
      title: 'Worker on the way',
      body: 'Rajesh Kumar is heading to your location.',
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  Future<void> mockDelay() =>
      Future<void>.delayed(const Duration(milliseconds: AppConstants.mockDelayMs));

  List<WorkerJob> get jobs => List.unmodifiable(_jobs);

  WorkerJob? jobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  void acceptJob(String id) {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index >= 0) {
      _jobs[index] = _jobs[index].copyWith(status: JobStatus.active);
    }
  }

  ServiceItem? serviceById(String id) {
    try {
      return services.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  WorkerProfile? workerById(String id) {
    try {
      return workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ServiceItem> searchServices(String query) {
    if (query.isEmpty) return services;
    final q = query.toLowerCase();
    return services
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ServiceItem> servicesByCategory(String categoryId) {
    return services.where((s) => s.categoryId == categoryId).toList();
  }

  Booking createBooking(ServiceItem service, {String? address}) {
    final booking = Booking(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      serviceId: service.id,
      serviceTitle: service.title,
      status: BookingStatus.draft,
      estimatedPrice: service.priceFrom,
      address: address ?? 'Current location',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
    );
    activeBooking = booking;
    return booking;
  }

  void advanceBooking(BookingStatus status, {String? workerId, String? workerName}) {
    if (activeBooking == null) return;
    activeBooking = activeBooking!.copyWith(
      status: status,
      workerId: workerId ?? activeBooking!.workerId,
      workerName: workerName ?? activeBooking!.workerName,
    );
  }

  double get walletBalance => 12450;
  double get todayEarnings => 1850;
  int get completedJobs => 47;
  int get reliabilityScore => 94;

  KycReviewStatus advanceKycReview() {
    kycReviewStatus = switch (kycReviewStatus) {
      KycReviewStatus.submitted => KycReviewStatus.inReview,
      KycReviewStatus.inReview => KycReviewStatus.approved,
      KycReviewStatus.approved => KycReviewStatus.approved,
      KycReviewStatus.rejected => KycReviewStatus.rejected,
    };
    return kycReviewStatus;
  }

  void toggleAvailability() {
    isAvailable = !isAvailable;
  }

  List<WorkerJob> get incomingJobs =>
      _jobs.where((j) => j.status == JobStatus.incoming).toList();

  WorkerJob? get activeJob {
    try {
      return _jobs.firstWhere((j) => j.status == JobStatus.active);
    } catch (_) {
      return null;
    }
  }

  void addSupportMessage(String text) {
    supportMessages.add(
      SupportMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        isAgent: false,
        time: DateTime.now(),
      ),
    );
    supportMessages.add(
      SupportMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch + 1}',
        text: 'Thanks for reaching out. A cooperative agent will reply shortly.',
        isAgent: true,
        time: DateTime.now(),
      ),
    );
  }
}

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.text,
    required this.isAgent,
    required this.time,
  });

  final String id;
  final String text;
  final bool isAgent;
  final DateTime time;

  @override
  List<Object?> get props => [id, text, isAgent, time];
}
