"""
Convenience server launcher script for Gig Support Chatbot.
"""
import os
import sys

_curr_dir = os.path.dirname(os.path.abspath(__file__))
if _curr_dir not in sys.path:
    sys.path.insert(0, _curr_dir)

from gig_support_chatbot.server.app import run_server

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Gig Support Chatbot Standalone Server")
    parser.add_argument("--host", default="127.0.0.1", help="Host address")
    parser.add_argument("--port", type=int, default=8080, help="Port number")
    args = parser.parse_args()
    run_server(args.host, args.port)
