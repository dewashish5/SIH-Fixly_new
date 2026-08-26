"""
Master Test Runner for Fair Price Estimation Module.
"""

import os
import sys
import pytest

_curr_dir = os.path.dirname(os.path.abspath(__file__))
_pkg_root = os.path.abspath(os.path.join(_curr_dir, ".."))
if _pkg_root not in sys.path:
    sys.path.insert(0, _pkg_root)

# Set UTF-8 encoding for stdout on Windows
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def run_tests():
    print("==================================================")
    print("[TEST RUNNER] Running Fair Price Estimation Test Suite")
    print(f"[INFO] Base Directory: {_pkg_root}")
    print("==================================================\n")

    pytest_args = [
        os.path.join(_pkg_root, "tests"),
        "-v",
        "--tb=short",
        "--cov=gig_fair_pricing",
        "--cov-report=term-missing",
    ]

    exit_code = pytest.main(pytest_args)
    if exit_code == 0:
        print("\n==================================================")
        print("[RESULT] ALL TESTS PASSED SUCCESSFULLY! (100% PASS)")
        print("==================================================")
    else:
        print(f"\n[RESULT] Tests completed with exit code {exit_code}")

    sys.exit(exit_code)


if __name__ == "__main__":
    run_tests()
