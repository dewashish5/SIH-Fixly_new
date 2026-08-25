import urllib.request
import json
import threading
import time
import pytest
from gig_support_chatbot.server.app import create_server


class TestLiveHTTPServer:
    @classmethod
    def setup_class(cls):
        cls.server = create_server('127.0.0.1', 8992)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        time.sleep(0.3)

    @classmethod
    def teardown_class(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def test_live_health_check(self):
        with urllib.request.urlopen('http://127.0.0.1:8992/api/health') as resp:
            data = json.loads(resp.read().decode('utf-8'))
            assert resp.status == 200
            assert data['status'] == 'healthy'

    def test_live_chat_endpoint(self):
        req_body = json.dumps({
            'session_id': 'live_sess_1',
            'role': 'customer',
            'language': 'en',
            'action': 'start',
        }).encode('utf-8')
        req = urllib.request.Request('http://127.0.0.1:8992/api/chat', data=req_body, headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            assert resp.status == 200
            assert len(data['message']['quick_replies']) == 5

    def test_live_static_demo_file(self):
        with urllib.request.urlopen('http://127.0.0.1:8992/demo/index.html') as resp:
            content = resp.read().decode('utf-8')
            assert resp.status == 200
            assert 'GigCommunity Support Engine' in content
