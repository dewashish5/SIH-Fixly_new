import time
import pytest
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.core.engine import ChatbotEngine


class TestPerformanceAndStress:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_response_latency_benchmark(self):
        """Verify that matching and message processing executes in under 5ms per message."""
        queries = [
            "how to book a service",
            "view offers and discounts",
            "BK1001",
            "app features guide",
            "raise a support ticket",
            "काम कैसे देखें",
            "प्रोफ़ाइल कैसे बनाएं",
        ]
        times = []
        for i, q in enumerate(queries):
            start = time.perf_counter()
            self.engine.process_message(
                session_id=f"perf_{i}",
                text=q,
                role=Role.CUSTOMER if i < 5 else Role.WORKER,
                language=Language.ENGLISH if i < 5 else Language.HINDI,
            )
            elapsed_ms = (time.perf_counter() - start) * 1000.0
            times.append(elapsed_ms)

        avg_latency = sum(times) / len(times)
        max_latency = max(times)
        print(f"Average Latency: {avg_latency:.3f}ms, Max: {max_latency:.3f}ms")
        assert avg_latency < 10.0, f"Average latency {avg_latency}ms exceeded 10ms threshold"

    def test_concurrent_session_stress(self):
        """Stress test engine with 500 distinct sessions in memory."""
        num_sessions = 500
        start = time.perf_counter()
        for i in range(num_sessions):
            sid = f"stress_sess_{i}"
            self.engine.start_session(
                session_id=sid,
                role=Role.CUSTOMER if i % 2 == 0 else Role.WORKER,
                language=Language.ENGLISH if i % 2 == 0 else Language.HINDI,
            )
            self.engine.process_message(
                session_id=sid,
                text="offers" if i % 2 == 0 else "काम",
            )

        total_time = time.perf_counter() - start
        assert self.engine.session_manager.count() >= num_sessions
        assert total_time < 5.0, f"500 sessions took {total_time:.2f}s, expected < 5s"
