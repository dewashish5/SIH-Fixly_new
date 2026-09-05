# Fixly Booking Lifecycle — Task Tracker

## Wave 1: Foundation (Models, Enums, Routes)
- [x] T1: BookingStatus enum — add `arrived` status
- [x] T2: WorkerJob model — add problem details/photos/OTP fields  
- [x] T3: bookings_api_repository.dart — map ARRIVED → arrived, enhance mapWorkerJob
- [x] T4: route_names.dart — add 4 new routes
- [x] T5: app_router.dart — register new routes

## Wave 2: Cubit Logic
- [x] T6: BookingFlowCubit — socket listener, loadFromBooking()
- [x] T7: ActiveJobCubit — verifyOtp(), startJob(), addParts(), submitReview(), phases

## Wave 3: Customer Screens (Redesigns)
- [x] T8: customer_finding_worker_page.dart — Stitch radar design + socket transitions
- [x] T9: customer_worker_accepted_page.dart — Stitch design with OTP display
- [x] T10: customer_worker_arrived_page.dart — NEW screen (OTP verification handshake)
- [x] T11: customer_payment_page.dart — Stitch design (itemized, Razorpay badge)
- [x] T12: customer_rating_page.dart — Stitch design (tag chips, mandatory, no skip)

## Wave 4: Worker Screens
- [x] T13: worker_active_job_page.dart — Full job details + lifecycle phases
- [x] T14: worker_otp_entry_page.dart — NEW (customer profile + OTP input + swipe-start)
- [x] T15: worker_add_parts_page.dart — NEW (optional parts + bill + swipe-confirm)
- [x] T16: worker_rating_page.dart — NEW (rate customer, mandatory, reset to dashboard)

## Wave 5: Navigation & History
- [x] T17: order_history_page.dart — status-based card routing
- [x] T18: booking_detail_page.dart — status-aware CTAs
- [x] T19: customer_worker_profile_page.dart — remove message button in booking context
- [x] T20: customer_tracking_page.dart — auto-arrived transition on 100m
- [x] T21: customer_finding_worker_page.dart nav — rewire post-booking success redirect

## Wave 6: Backend & Docs
- [x] T22: Review model — Option A bidirectional (reviewerRole field)
- [x] T23: changes.md — document all changes
- [x] T24: flutter analyze — verify build
