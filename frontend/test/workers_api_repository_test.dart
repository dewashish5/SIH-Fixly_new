import 'package:flutter_test/flutter_test.dart';

import 'package:fixly/features/workers/data/workers_api_repository.dart';

void main() {
  test('maps worker list fields returned by the workers API', () {
    final worker = WorkersApiRepository.mapWorker({
      '_id': 'worker-1',
      'name': 'Vaibhav Jain',
      'avatar': 'https://example.com/avatar.jpg',
      'rating': 4.8,
      'category': 'Plumbing',
      'title': 'Master Plumber',
      'skills': ['Pipe Fitting', 'Leak Detection'],
      'totalJobs': 142,
      'rate': 85,
      'minimumCharge': 85,
      'rateFormatted': '₹85',
      'distanceKm': 2.1,
      'distanceFormatted': '2.1 km',
      'isOnline': true,
      'isAvailable': true,
    });

    expect(worker.id, 'worker-1');
    expect(worker.title, 'Master Plumber');
    expect(worker.skills, ['Pipe Fitting', 'Leak Detection']);
    expect(worker.jobsCompleted, 142);
    expect(worker.hourlyRate, 85);
    expect(worker.minimumCharge, 85);
    expect(worker.rateFormatted, '₹85');
    expect(worker.distanceKm, 2.1);
    expect(worker.distanceFormatted, '2.1 km');
    expect(worker.isOnline, isTrue);
    expect(worker.isAvailable, isTrue);
  });

  test(
    'keeps missing worker ratings unavailable instead of inventing a score',
    () {
      final worker = WorkersApiRepository.mapWorker({
        '_id': 'worker-2',
        'name': 'New Worker',
        'reviews': <Map<String, dynamic>>[],
      });

      expect(worker.rating, 0);
      expect(worker.reviewCount, 0);
      expect(worker.reviews, isEmpty);
    },
  );

  test('maps nested reliability and verification data from worker detail', () {
    final worker = WorkersApiRepository.mapWorker({
      'isEmailVerified': true,
      'isOnline': true,
      'kycDocuments': {'status': 'submitted'},
      'reliability': {
        'score': 25,
        'onTimeArrival': 0,
        'completionRate': 0,
        'customerFeedback': 0,
        'cancellationRate': 100,
      },
      'workerProfile': {'totalJobs': 0, 'serviceRadiusKm': 10},
    });

    expect(worker.reliabilityScore, 25);
    expect(worker.cancellationRate, 100);
    expect(worker.serviceRadiusKm, 10);
    expect(worker.kycStatus, 'submitted');
    expect(worker.isEmailVerified, isTrue);
    expect(worker.isOnline, isTrue);
  });
}
