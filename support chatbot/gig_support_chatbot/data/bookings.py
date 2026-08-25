"""
Booking & Order status store and query resolver.
"""

from typing import Dict, List, Optional
from ..core.types import BookingInfo, Language


MOCK_BOOKINGS: Dict[str, BookingInfo] = {
    "BK1001": BookingInfo(
        booking_id="BK1001",
        service_name_en="Deep Home Cleaning (2 BHK)",
        service_name_hi="गहरी घर की सफाई (2 BHK)",
        worker_name="Ramesh Kumar",
        worker_phone="+91 98765-43210",
        status_en="On The Way (Arriving in 12 mins)",
        status_hi="रास्ते में है (12 मिनट में पहुंच रहे हैं)",
        status_code="ON_THE_WAY",
        scheduled_time="Today, 4:30 PM",
        address="Flat 402, Green Glen Heights, Sector 14",
        amount="₹899 (Prepaid UPI)",
    ),
    "BK1002": BookingInfo(
        booking_id="BK1002",
        service_name_en="Electrician - Fan & Switch Repair",
        service_name_hi="इलेक्ट्रीशियन - पंखा और स्विच मरम्मत",
        worker_name="Suresh Sharma",
        worker_phone="+91 98111-22334",
        status_en="Confirmed (Worker Assigned)",
        status_hi="पुष्टि हो गई (कार्यकर्ता नियुक्त)",
        status_code="CONFIRMED",
        scheduled_time="Tomorrow, 10:00 AM",
        address="House #88, Palm Grove Layout",
        amount="₹299 (Cash on Service)",
    ),
    "BK1003": BookingInfo(
        booking_id="BK1003",
        service_name_en="Plumber - Tap Leakage & Pipe Fitting",
        service_name_hi="प्लंबर - नल रिसाव और पाइप फिटिंग",
        worker_name="Anil Verma",
        worker_phone="+91 97234-56789",
        status_en="In Progress (Work ongoing)",
        status_hi="कार्य प्रगति पर है",
        status_code="IN_PROGRESS",
        scheduled_time="Today, 3:00 PM",
        address="Tower B-12, Royal Palms",
        amount="₹449 (Prepaid Wallet)",
    ),
    "BK1004": BookingInfo(
        booking_id="BK1004",
        service_name_en="AC Servicing & Gas Refill",
        service_name_hi="एसी सर्विसिंग और गैस रिफिल",
        worker_name="Vikram Singh",
        worker_phone="+91 99000-11223",
        status_en="Completed (Invoice Generated)",
        status_hi="पूर्ण हुआ (बिल तैयार)",
        status_code="COMPLETED",
        scheduled_time="Yesterday, 5:00 PM",
        address="Villa 15, Silver Oak Enclave",
        amount="₹1,249 (Paid Online)",
    ),
}


class BookingManager:
    def __init__(self):
        self._bookings = dict(MOCK_BOOKINGS)

    def get_booking(self, booking_id: str) -> Optional[BookingInfo]:
        clean_id = (booking_id or "").strip().upper()
        # Direct lookup or fallback without BK prefix if digit entered
        if clean_id in self._bookings:
            return self._bookings[clean_id]
        if clean_id.isdigit():
            padded = f"BK{clean_id}"
            if padded in self._bookings:
                return self._bookings[padded]
        return None

    def list_all_bookings(self) -> List[BookingInfo]:
        return list(self._bookings.values())

    def format_booking_response(self, booking: BookingInfo, lang: Language = Language.ENGLISH) -> str:
        is_hi = lang == Language.HINDI
        if is_hi:
            return (
                f"📦 **बुकिंग विवरण (#{booking.booking_id})**\n\n"
                f"• **सेवा**: {booking.service_name_hi}\n"
                f"• **स्थिति**: {booking.status_hi}\n"
                f"• **कार्यकर्ता**: {booking.worker_name} ({booking.worker_phone})\n"
                f"• **समय**: {booking.scheduled_time}\n"
                f"• **पता**: {booking.address}\n"
                f"• **राशि**: {booking.amount}\n\n"
                f"💡 _कार्यकर्ता को ट्रैक करने के लिए मुख्य ऐप के 'My Bookings' टैब में जाएं।_"
            )
        return (
            f"📦 **Booking Details (#{booking.booking_id})**\n\n"
            f"• **Service**: {booking.service_name_en}\n"
            f"• **Status**: {booking.status_en}\n"
            f"• **Assigned Partner**: {booking.worker_name} ({booking.worker_phone})\n"
            f"• **Scheduled Time**: {booking.scheduled_time}\n"
            f"• **Address**: {booking.address}\n"
            f"• **Amount**: {booking.amount}\n\n"
            f"💡 _You can track live location in the 'My Bookings' screen of the app._"
        )
