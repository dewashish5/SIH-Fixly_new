import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';

class AppStrings {
  AppStrings(this.locale);

  final String locale;
  bool get isHi => locale == 'hi';

  String t(String en, String hi) => isHi ? hi : en;

  String timeGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return isHi ? 'सुप्रभात' : 'Good morning';
    }
    if (hour >= 12 && hour < 17) {
      return isHi ? 'शुभ दोपहर' : 'Good afternoon';
    }
    return isHi ? 'शुभ संध्या' : 'Good evening';
  }

  String get guestUser => isHi ? 'अतिथि' : 'Guest';

  // Brand & auth
  String get appName => isHi ? 'फिक्सली' : 'Fixly';
  String get tagline => isHi ? 'सहकारी गिग सेवाएं' : 'Cooperative Gig Services';
  String get continueLabel => isHi ? 'जारी रखें' : 'Continue';
  String get login => isHi ? 'लॉगिन' : 'Login';
  String get signUp => isHi ? 'साइन अप' : 'Sign up';
  String get createAccount => isHi ? 'खाता बनाएं' : 'Create account';
  String get sendOtp => isHi ? 'OTP भेजें' : 'Send OTP';
  String get verifyOtp => isHi ? 'OTP सत्यापित करें' : 'Verify OTP';
  String get otpSentTo => isHi ? 'OTP भेजा गया' : 'OTP sent to';
  String get resendOtp => isHi ? 'OTP दोबारा भेजें' : 'Resend OTP';
  String resendOtpIn(int seconds) =>
      isHi ? '$seconds सेकंड में दोबारा भेजें' : 'Resend in ${seconds}s';
  String get otpResent => isHi ? 'नया OTP भेज दिया गया' : 'A new OTP has been sent';
  String get fullName => isHi ? 'पूरा नाम' : 'Full name';
  String get fullNameHint => isHi ? 'अपना नाम दर्ज करें' : 'Enter your name';
  String get email => isHi ? 'ईमेल' : 'Email';
  String get password => isHi ? 'पासवर्ड' : 'Password';
  String get passwordHint => isHi ? 'अपना पासवर्ड दर्ज करें' : 'Enter your password';
  String get phoneNumber => isHi ? 'फ़ोन नंबर' : 'Phone number';
  String get phoneHint => isHi ? '10 अंकों का मोबाइल नंबर' : '10-digit mobile number';
  String get continueWithGoogle => isHi ? 'Google' : 'Google';
  String get continueWithFacebook => isHi ? 'Facebook' : 'Facebook';
  String get orContinueWith => isHi ? 'या ईमेल से' : 'Or continue with email';
  String get locationRequiredForSignup => isHi
      ? 'साइन अप के लिए GPS चालू करें और स्थान की अनुमति दें'
      : 'Enable GPS and allow location access to sign up';
  String get locationServicesOffTitle =>
      isHi ? 'स्थान बंद है' : 'Location is off';
  String get locationServicesOffBody => isHi
      ? 'साइन अप के लिए फ़ोन की सेटिंग में GPS चालू करें, फिर वापस आकर दोबारा कोशिश करें।'
      : 'Turn on location in your phone settings so we can send your area with sign-up, then try again.';
  String get turnOnLocation => isHi ? 'स्थान चालू करें' : 'Turn on location';
  String get locationPermissionBlockedTitle =>
      isHi ? 'स्थान अनुमति बंद' : 'Location blocked';
  String get locationPermissionBlockedBody => isHi
      ? 'Fixly को स्थान की अनुमति चाहिए। सेटिंग्स में जाकर चालू करें।'
      : 'Fixly needs location access. Open Settings to enable it.';
  String get openSettings => isHi ? 'सेटिंग्स खोलें' : 'Open Settings';
  String get locationEnableTitle =>
      isHi ? 'स्थान चालू करें' : 'Enable location';
  String get locationEnableBody => isHi
      ? 'Fixly को पास के कार्यकर्ता और बुकिंग पता दिखाने के लिए आपका स्थान चाहिए।'
      : 'Fixly needs your location to find nearby workers and set booking addresses.';
  String get notNow => isHi ? 'अभी नहीं' : 'Not now';
  String get allow => isHi ? 'अनुमति दें' : 'Allow';
  String get dontHaveAccount =>
      isHi ? 'खाता नहीं है?' : "Don't have an account?";
  String get alreadyHaveAccount =>
      isHi ? 'पहले से खाता है?' : 'Already have an account?';
  String get signInAsWorker =>
      isHi ? 'कार्यकर्ता के रूप में साइन इन करें' : 'Sign in as worker';
  String get signInAsWorkerHint => isHi
      ? 'कार्यकर्ता के रूप में लॉगिन — कोई भी विकल्प चुनें'
      : 'Signing in as worker — use any option below';
  String get loginSubtitle => isHi
      ? 'जारी रखने के लिए लॉगिन करें'
      : 'Log in to continue';
  String get signUpSubtitle => isHi
      ? 'शुरू करने के लिए खाता बनाएं'
      : 'Create an account to get started';
  String get authEmailTab => isHi ? 'ईमेल' : 'Email';
  String get authPhoneTab => isHi ? 'फ़ोन' : 'Phone';
  String get customer => isHi ? 'ग्राहक' : 'Customer';
  String get worker => isHi ? 'कार्यकर्ता' : 'Worker';
  String get selectLanguage => isHi ? 'भाषा चुनें' : 'Select Language';
  String get choosePreferredLanguage =>
      isHi ? 'अपनी पसंदीदा भाषा चुनें' : 'Choose your preferred language';
  String get cooperativeWelcomeTitle =>
      isHi ? 'सहकारी में आपका स्वागत है' : 'Welcome to the Cooperative';
  String get cooperativeWelcomeBody => isHi
      ? 'सदस्य-स्वामित्व, 10–15% कमीशन, और निष्पक्ष मजदूरी।'
      : 'Member-owned platform with 10–15% commission and fair wages.';
  String get chooseRole => isHi ? 'अपनी भूमिका चुनें' : 'Choose your role';
  String get customerRoleSubtitle => isHi
      ? 'घरेलू सेवाओं के लिए विश्वसनीय कार्यकर्ता बुक करें'
      : 'Book trusted workers for home services';
  String get workerRoleSubtitle => isHi
      ? 'कौशल दें और निष्पक्ष मजदूरी कमाएं'
      : 'Offer skills and earn fair wages';
  String get fairWages => isHi ? 'निष्पक्ष मजदूरी' : 'Fair wages';
  String get fairWagesDesc => isHi
      ? 'सहकारी सदस्यों को बाजार से बेहतर दर'
      : 'Cooperative members earn above market rates';
  String get memberOwned => isHi ? 'सदस्य-स्वामित्व' : 'Member-owned';
  String get memberOwnedDesc => isHi
      ? 'मुनाफा सदस्यों के बीच बंटता है'
      : 'Profits shared among members';
  String get welfareCoverage => isHi ? 'कल्याण कवरेज' : 'Welfare coverage';
  String get welfareCoverageDesc => isHi
      ? 'e-Shram और बीमा सहायता'
      : 'e-Shram and insurance support';

  // Bottom nav
  String get navHome => isHi ? 'होम' : 'Home';
  String get navSearch => isHi ? 'खोज' : 'Search';
  String get navBookings => isHi ? 'बुकिंग' : 'Bookings';
  String get navAi => isHi ? 'AI' : 'AI';
  String get navProfile => isHi ? 'प्रोफ़ाइल' : 'Profile';
  String get navJobs => isHi ? 'नौकरियां' : 'Jobs';
  String get navWallet => isHi ? 'वॉलेट' : 'Wallet';

  // Customer home
  String get categories => isHi ? 'श्रेणियाँ' : 'Categories';
  String get allCategories => isHi ? 'सभी श्रेणियाँ' : 'All Categories';
  String get viewAll => isHi ? 'सभी देखें' : 'View all';
  String get popularServices => isHi ? 'लोकप्रिय सेवाएं' : 'Popular Services';
  String get aiHelper => isHi ? 'AI सहायक' : 'AI Helper';
  String get homeBooking => isHi ? 'घरेलू बुकिंग' : 'Home Booking';
  String get searchHint => isHi ? 'सेवाएं खोजें...' : 'Search services...';
  String get servicesInCategory =>
      isHi ? 'इस श्रेणी में उपलब्ध सेवाएं' : 'Services in this category';
  String get noServicesFound => isHi ? 'कोई सेवा नहीं मिली' : 'No services found';

  // Shared / profile
  String get settings => isHi ? 'सेटिंग्स' : 'Settings';
  String get hindiLanguage => isHi ? 'हिन्दी भाषा' : 'Hindi language';
  String get appearance => isHi ? 'दिखावट' : 'Appearance';
  String get theme => isHi ? 'थीम' : 'Theme';
  String get themeSystem => isHi ? 'सिस्टम' : 'System';
  String get themeLight => isHi ? 'लाइट' : 'Light';
  String get themeDark => isHi ? 'डार्क' : 'Dark';
  String get pushNotifications => isHi ? 'पुश सूचनाएं' : 'Push notifications';
  String get pushNotificationsHint => isHi
      ? 'बुकिंग अपडेट और ऑफ़र के लिए सूचनाएं'
      : 'Booking updates and offers';
  String get updateYourDetails =>
      isHi ? 'नाम और फ़ोन अपडेट करें' : 'Update your name and phone';
  String get notificationsOn => isHi ? 'सूचनाएं चालू' : 'Notifications on';
  String get notificationsOff => isHi ? 'सूचनाएं बंद' : 'Notifications off';
  String get notificationPreferences =>
      isHi ? 'सूचना प्राथमिकताएं' : 'Notification preferences';
  String get privacySecurity => isHi ? 'गोपनीयता और सुरक्षा' : 'Privacy & security';
  String get aboutCooperative => isHi ? 'सहकारी के बारे में' : 'About cooperative';
  String get screenGallery => isHi ? 'स्क्रीन गैलरी' : 'Screen gallery';
  String get emergencySos => isHi ? 'आपात SOS' : 'Emergency SOS';
  String get languageHindi => isHi ? 'भाषा: हिन्दी' : 'Language: Hindi';
  String get languageEnglish => isHi ? 'भाषा: English' : 'Language: English';
  String get profile => isHi ? 'प्रोफ़ाइल' : 'Profile';
  String get editProfile => isHi ? 'प्रोफ़ाइल संपादित करें' : 'Edit profile';
  String get signOut => isHi ? 'साइन आउट' : 'Sign out';
  String get signOutConfirm => isHi
      ? 'क्या आप साइन आउट करना चाहते हैं?'
      : 'Sign out of this account?';
  String get cancel => isHi ? 'रद्द करें' : 'Cancel';
  String get preferences => isHi ? 'प्राथमिकताएं' : 'Preferences';
  String get account => isHi ? 'खाता' : 'Account';
  String get language => isHi ? 'भाषा' : 'Language';
  String get english => isHi ? 'English' : 'English';
  String get hindi => isHi ? 'हिन्दी' : 'Hindi';
  String get appVersion => isHi ? 'फिक्सली v0.1.0' : 'Fixly v0.1.0';
  String get profileSaved => isHi ? 'प्रोफ़ाइल सहेजी गई' : 'Profile saved';
  String get insuredMember => isHi ? 'बीमा सदस्य' : 'Insured member';
  String get customerMember => isHi ? 'ग्राहक सदस्य' : 'Customer member';
  String get workerMember => isHi ? 'कार्यकर्ता सदस्य' : 'Worker member';
  String get helpSafety => isHi ? 'सहायता और सुरक्षा' : 'Help & safety';
  String get whyFixly => isHi ? 'फिक्सली क्यों?' : 'Why Fixly?';
  String get fairWagesBenefit => isHi
      ? 'कार्यकर्ता 85–90% कमाई रखते हैं — कोई शोषण नहीं।'
      : 'Workers keep 85–90% of earnings — no exploitative cuts.';
  String get memberOwnedBenefit => isHi
      ? 'सहकारी शासन कार्यकर्ता और ग्राहक को प्राथमिकता देता है।'
      : 'Cooperative governance puts workers and customers first.';
  String get welfareBenefit => isHi
      ? 'गिग कार्यकर्ताओं के लिए PMSBY बीमा और e-Shram सहायता।'
      : 'PMSBY insurance and e-Shram support for gig workers.';
  String get howUseFixly =>
      isHi ? 'आप फिक्सली कैसे उपयोग करेंगे?' : 'How will you use Fixly?';
  String get support => isHi ? 'सहायता' : 'Support';
  String get fromPrice => isHi ? '₹%s से' : 'From ₹%s';
  String get orderHistory => isHi ? 'ऑर्डर इतिहास' : 'Order history';
  String get notifications => isHi ? 'सूचनाएं' : 'Notifications';
  String get supportChat => isHi ? 'सहायता चैट' : 'Support chat';
  String get supportTicket => isHi ? 'सहायता टिकट' : 'Support ticket';
  String get sos => isHi ? 'SOS और आपातकाल' : 'SOS & Emergency';

  // Customer flow
  String get search => isHi ? 'खोज' : 'Search';
  String get homeBookingTitle => isHi ? 'घरेलू बुकिंग' : 'Home Booking';
  String get bookService => isHi ? 'सेवा बुक करें' : 'Book Service';
  String get service => isHi ? 'सेवा' : 'Service';
  String get priceEstimate => isHi ? 'मूल्य अनुमान' : 'Price Estimate';
  String get reviewEstimate => isHi ? 'अनुमान देखें' : 'Review estimate';
  String get findingWorker => isHi ? 'कार्यकर्ता खोज रहे हैं' : 'Finding Worker';
  String get workerAssigned => isHi ? 'कार्यकर्ता नियुक्त' : 'Worker Assigned';
  String get workerAccepted => isHi ? 'कार्यकर्ता स्वीकृत' : 'Worker accepted';
  String get liveTracking => isHi ? 'लाइव ट्रैकिंग' : 'Live Tracking';
  String get workInProgress => isHi ? 'कार्य जारी' : 'Work in Progress';
  String get workStarted => isHi ? 'कार्य शुरू' : 'Work started';
  String get payment => isHi ? 'भुगतान' : 'Payment';
  String get completePayment => isHi ? 'भुगतान पूरा करें' : 'Complete payment';
  String get rateService => isHi ? 'सेवा रेट करें' : 'Rate Service';
  String get bookingConfirmed => isHi ? 'बुकिंग पुष्टि' : 'Booking Confirmed';
  String get addParts => isHi ? 'पुर्जे जोड़ें' : 'Add Parts';
  String get availableWorkers => isHi ? 'उपलब्ध कार्यकर्ता' : 'Available Workers';
  String get workerProfile => isHi ? 'कार्यकर्ता प्रोफ़ाइल' : 'Worker Profile';
  String get aiDiscovery => isHi ? 'AI खोज' : 'AI Discovery';
  String get aiMatchedWorkers => isHi ? 'AI मेल कार्यकर्ता' : 'AI Matched Workers';
  String get destination => isHi ? 'गंतव्य' : 'Destination';
  String get skipToWorkStarted =>
      isHi ? 'कार्य शुरू पर जाएं' : 'Skip to Work Started';

  // Worker flow
  String get dashboard => isHi ? 'डैशबोर्ड' : 'Dashboard';
  String get jobFeed => isHi ? 'नौकरी फ़ीड' : 'Job feed';
  String get incomingOrders => isHi ? 'आने वाले ऑर्डर' : 'Incoming orders';
  String get orderDetails => isHi ? 'ऑर्डर विवरण' : 'Order details';
  String get activeJob => isHi ? 'सक्रिय नौकरी' : 'Active job';
  String get navigation => isHi ? 'नेविगेशन' : 'Navigation';
  String get startNavigation => isHi ? 'नेविगेशन शुरू करें' : 'Start navigation';
  String get navigationStarted => isHi
      ? 'टर्न-बाय-टर्न नेविगेशन शुरू'
      : 'Turn-by-turn navigation started';
  String get availability => isHi ? 'उपलब्धता' : 'Availability';
  String get availabilityStatus =>
      isHi ? 'उपलब्धता स्थिति' : 'Availability status';
  String get earnings => isHi ? 'कमाई' : 'Earnings';
  String get wallet => isHi ? 'वॉलेट' : 'Wallet';
  String get myProfile => isHi ? 'मेरी प्रोफ़ाइल' : 'My profile';
  String get reliabilityScore => isHi ? 'विश्वसनीयता स्कोर' : 'Reliability score';

  // Worker onboarding
  String get identityKyc => isHi ? 'पहचान और KYC' : 'Identity & KYC';
  String get workProfile => isHi ? 'कौशल और क्षेत्र' : 'Skills & area';
  String get payoutWelfare => isHi ? 'भुगतान और कल्याण' : 'Payout & welfare';
  String get personalDetails => isHi ? 'व्यक्तिगत विवरण' : 'Personal details';
  String get aadhaarVerification =>
      isHi ? 'आधार सत्यापन' : 'Aadhaar verification';
  String get panVerification => isHi ? 'PAN सत्यापन' : 'PAN verification';
  String get selfieVerification =>
      isHi ? 'सेल्फी सत्यापन' : 'Selfie verification';
  String get skillCertificate => isHi ? 'कौशल प्रमाणपत्र' : 'Skill certificate';
  String get selectSkills => isHi ? 'कौशल चुनें' : 'Select skills';
  String get otherSkills => isHi ? 'अन्य' : 'Others';
  String get otherSkillsHint => isHi
      ? 'कौशल लिखें, कॉमा से अलग करें'
      : 'Type a skill, then comma to add more';
  String get serviceArea => isHi ? 'सेवा क्षेत्र' : 'Service area';
  String get serviceAreaHint => isHi
      ? 'नौकरियों के लिए आप कितनी दूर जा सकते हैं, सेट करें।'
      : 'Set how far you are willing to travel for jobs.';
  String get largerRadiusHint => isHi
      ? 'बड़ा क्षेत्र = अधिक नज़दीकी नौकरियां'
      : 'Larger radius = more nearby jobs';
  String get welfareInsurance => isHi ? 'कल्याण और बीमा' : 'Welfare & insurance';
  String get bankUpi => isHi ? 'बैंक और UPI' : 'Bank & UPI';
  String get kycStatus => isHi ? 'KYC स्थिति' : 'KYC status';

  // Payment methods
  String get upi => 'UPI';
  String get upiSubtitle => isHi
      ? 'Google Pay, PhonePe, Paytm'
      : 'Google Pay, PhonePe, Paytm';
  String get card => isHi ? 'कार्ड' : 'Card';
  String get cardSubtitle => isHi ? 'Visa, Mastercard, RuPay' : 'Visa, Mastercard, RuPay';
  String get cash => isHi ? 'नकद' : 'Cash';
  String get cashSubtitle => isHi ? 'सेवा के बाद भुगतान' : 'Pay after service';

  // Common
  String get goBack => isHi ? 'वापस जाएं' : 'Go back';
  String get showPassword => isHi ? 'पासवर्ड दिखाएं' : 'Show password';
  String get hidePassword => isHi ? 'पासवर्ड छिपाएं' : 'Hide password';
  String get sendMessage => isHi ? 'भेजें' : 'Send';
  String get unknownState => isHi ? 'अज्ञात स्थिति' : 'Unknown state';
  String get etaFormat => isHi ? 'ETA: %s मिनट' : 'ETA: %s min';
  String get arrived => isHi ? 'पहुंच गए' : 'Arrived';
  String get percentComplete => isHi ? '%s%% पूर्ण' : '%s%% complete';

  // System states
  String get noOrdersYet => isHi ? 'अभी कोई ऑर्डर नहीं' : 'No orders yet';
  String get noWorkersNearby => isHi ? 'पास में कोई कार्यकर्ता नहीं' : 'No workers nearby';
  String get noEarningsYet => isHi ? 'अभी कोई कमाई नहीं' : 'No earnings yet';
  String get noNotificationsTitle =>
      isHi ? 'कोई सूचना नहीं' : 'No notifications';
  String get noResultsFound => isHi ? 'कोई परिणाम नहीं' : 'No results found';
  String get noInternet => isHi ? 'इंटरनेट नहीं' : 'No internet connection';
  String get locationDenied => isHi ? 'स्थान अनुमति नहीं' : 'Location access denied';
  String get cameraDenied => isHi ? 'कैमरा अनुमति नहीं' : 'Camera access denied';
  String get otpFailed => isHi ? 'OTP विफल' : 'OTP verification failed';
  String get paymentFailed => isHi ? 'भुगतान विफल' : 'Payment failed';
  String get bookingFailed => isHi ? 'बुकिंग विफल' : 'Booking failed';
  String get kycFailed => isHi ? 'KYC विफल' : 'KYC verification failed';
  String get serverError => isHi ? 'कुछ गलत हुआ' : 'Something went wrong';
  String get sessionExpired => isHi ? 'सत्र समाप्त' : 'Session expired';
  String get paymentSuccessful => isHi ? 'भुगतान सफल' : 'Payment successful';
  String get kycSubmitted => isHi ? 'KYC जमा' : 'KYC submitted';
  String get profileUpdated => isHi ? 'प्रोफ़ाइल अपडेट' : 'Profile updated';
  String get ratingSubmitted => isHi ? 'रेटिंग जमा' : 'Rating submitted';
  String get complaintSubmitted => isHi ? 'शिकायत जमा' : 'Complaint submitted';
}

extension AppStringsX on BuildContext {
  AppStrings strings(String locale) => AppStrings(locale);

  AppStrings get l10n => AppStrings(LocaleScope.of(this).locale);
}
