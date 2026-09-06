import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/auth/token_storage.dart';
import '../core/network/api_config.dart';

enum CallState { idle, initiating, ringing, connected, ended, failed }

class CallSessionInfo {
  final String bookingId;
  final String callSessionId;
  final String peerName;
  final String peerRole;
  final String? peerAvatar;
  final String serviceTitle;

  CallSessionInfo({
    required this.bookingId,
    required this.callSessionId,
    required this.peerName,
    required this.peerRole,
    this.peerAvatar,
    required this.serviceTitle,
  });
}

class WebRTCCallService {
  WebRTCCallService._();
  static final WebRTCCallService instance = WebRTCCallService._();

  io.Socket? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  CallState currentState = CallState.idle;
  String? currentBookingId;
  String? currentCallSessionId;
  String? currentUserId;
  String? peerName;
  String? peerRole;
  String? peerAvatar;
  String? serviceTitle;

  bool isMuted = false;
  bool isSpeakerOn = false;

  int callDurationSeconds = 0;
  Timer? durationTimer;

  final TokenStorage _tokenStorage = TokenStorage();

  // Callbacks for UI updates
  Function(CallState state)? onCallStateChanged;
  Function(CallSessionInfo info)? onIncomingCall;
  Function(String message)? onFirewallError;
  Function(String message)? onPeerNetworkIssue;

  String get serverUrl => ApiConfig.baseUrl;

  /// Initializes the Socket.io connection with auth token
  Future<void> initializeSocket({String? token, String? userId}) async {
    final authToken = token ?? await _tokenStorage.accessToken;
    currentUserId = userId ?? await _tokenStorage.userId;

    if (authToken == null || authToken.isEmpty) {
      debugPrint('[WebRTC] Cannot init socket without auth token');
      return;
    }

    if (socket != null && socket!.connected) {
      return;
    }

    socket?.disconnect();
    socket?.dispose();

    socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .build(),
    );

    _bindSocketListeners();
    socket!.connect();
  }

  void _bindSocketListeners() {
    if (socket == null) return;

    // 1. Room Joined Confirmation
    socket!.on('webrtc:room-joined', (data) {
      debugPrint('[WebRTC] Joined room: ${data['room']} for booking: ${data['bookingId']}');
    });

    // 2. In-App Incoming Call (Foreground)
    socket!.on('webrtc:incoming-call', (data) {
      if (currentState == CallState.idle) {
        currentBookingId = data['bookingId']?.toString();
        final caller = Map<String, dynamic>.from(data['caller'] ?? {});
        peerName = caller['name'] ?? 'User';
        peerRole = caller['role'] ?? 'worker';
        peerAvatar = caller['avatar'];
        serviceTitle = data['serviceTitle'] ?? 'Audio Calling';

        _setCallState(CallState.ringing);

        final info = CallSessionInfo(
          bookingId: currentBookingId ?? '',
          callSessionId: data['callSessionId'] ?? '',
          peerName: peerName!,
          peerRole: peerRole!,
          peerAvatar: peerAvatar,
          serviceTitle: serviceTitle!,
        );
        onIncomingCall?.call(info);
      }
    });

    // 3. Caller receives call accepted -> Creates Offer
    socket!.on('webrtc:call-accepted', (data) async {
      debugPrint('[WebRTC] Call accepted by receiver');
      _setCallState(CallState.connected);
      _startDurationTimer();

      if (peerConnection != null) {
        try {
          RTCSessionDescription offer = await peerConnection!.createOffer({
            'offerToReceiveAudio': 1,
            'offerToReceiveVideo': 0,
          });
          await peerConnection!.setLocalDescription(offer);

          socket?.emit('webrtc:offer', {
            'bookingId': currentBookingId,
            'sdp': offer.toMap(),
          });
        } catch (e) {
          debugPrint('[WebRTC] Create offer error: $e');
        }
      }
    });

    // 4. Receiver receives offer -> Creates Answer
    socket!.on('webrtc:offer', (data) async {
      debugPrint('[WebRTC] Received offer from caller');
      if (peerConnection != null && data['sdp'] != null) {
        try {
          final sdpMap = Map<String, dynamic>.from(data['sdp']);
          await peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdpMap['sdp'], sdpMap['type']),
          );

          RTCSessionDescription answer = await peerConnection!.createAnswer({
            'offerToReceiveAudio': 1,
            'offerToReceiveVideo': 0,
          });
          await peerConnection!.setLocalDescription(answer);

          socket?.emit('webrtc:answer', {
            'bookingId': currentBookingId,
            'sdp': answer.toMap(),
          });
        } catch (e) {
          debugPrint('[WebRTC] Create answer error: $e');
        }
      }
    });

    // 5. Caller receives answer
    socket!.on('webrtc:answer', (data) async {
      debugPrint('[WebRTC] Received answer from receiver');
      if (peerConnection != null && data['sdp'] != null) {
        try {
          final sdpMap = Map<String, dynamic>.from(data['sdp']);
          await peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdpMap['sdp'], sdpMap['type']),
          );
        } catch (e) {
          debugPrint('[WebRTC] Set remote description answer error: $e');
        }
      }
    });

    // 6. ICE Candidate Exchange
    socket!.on('webrtc:ice-candidate', (data) async {
      final cand = data['candidate'];
      if (peerConnection != null && cand != null) {
        try {
          await peerConnection!.addCandidate(
            RTCIceCandidate(cand['candidate'], cand['sdpMid'], cand['sdpMLineIndex']),
          );
        } catch (e) {
          debugPrint('[WebRTC] Add ICE candidate error: $e');
        }
      }
    });

    // 7. Call Rejected or User Busy
    socket!.on('webrtc:call-rejected', (data) {
      debugPrint('[WebRTC] Call rejected');
      _setCallState(CallState.ended);
      cleanupCall();
    });

    // 8. Call Ended by Peer
    socket!.on('webrtc:call-ended', (data) {
      debugPrint('[WebRTC] Call ended by peer');
      _setCallState(CallState.ended);
      cleanupCall();
    });

    // 9. Wi-Fi Firewall Error Detected
    socket!.on('webrtc:error', (error) {
      if (error['errorCode'] == 'FIREWALL_BLOCKED_WIFI_RESTRICTION') {
        _setCallState(CallState.failed);
        onFirewallError?.call(
          error['message'] ?? 'Wi-Fi firewall blocking audio call.',
        );
      }
    });

    // 10. Peer Network Issue Warning
    socket!.on('webrtc:peer-network-issue', (data) {
      onPeerNetworkIssue?.call(
        data['message'] ?? 'Peer having firewall/network difficulties.',
      );
    });
  }

  // ===========================================================================
  // START OUTGOING CALL
  // ===========================================================================
  Future<bool> startCall({
    required String bookingId,
    String? token,
    String? expectedPeerName,
    String? expectedPeerRole,
    String? expectedPeerAvatar,
    String? expectedServiceTitle,
  }) async {
    currentBookingId = bookingId;
    peerName = expectedPeerName ?? 'User';
    peerRole = expectedPeerRole ?? 'participant';
    peerAvatar = expectedPeerAvatar;
    serviceTitle = expectedServiceTitle ?? 'Audio Calling';
    isMuted = false;
    isSpeakerOn = false;

    _setCallState(CallState.initiating);

    // Request Microphone Permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      _setCallState(CallState.failed);
      return false;
    }

    try {
      final authToken = token ?? await _tokenStorage.accessToken;
      if (authToken == null || authToken.isEmpty) {
        _setCallState(CallState.failed);
        return false;
      }

      await initializeSocket(token: authToken);

      // Hit REST API to initiate call session
      final initRes = await http.post(
        Uri.parse('$serverUrl/api/webrtc/call/initiate'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );

      final initData = jsonDecode(initRes.body);
      if (initRes.statusCode != 200 || initData['success'] != true) {
        debugPrint('[WebRTC] Initiate call API failed: ${initRes.body}');
        _setCallState(CallState.failed);
        return false;
      }

      currentCallSessionId = initData['callSessionId'];
      final receiver = initData['receiver'] ?? {};
      peerName = receiver['name'] ?? peerName;
      peerRole = receiver['role'] ?? peerRole;
      peerAvatar = receiver['avatar'] ?? peerAvatar;
      serviceTitle = initData['serviceTitle'] ?? serviceTitle;

      // Fetch ICE Servers (STUN/TURN)
      final iceRes = await http.get(
        Uri.parse('$serverUrl/api/webrtc/config/ice-servers'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      final iceData = jsonDecode(iceRes.body);
      final iceServers = (iceData['iceServers'] as List<dynamic>?) ?? [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ];

      // Create PeerConnection
      Map<String, dynamic> rtcConfig = {
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      };
      peerConnection = await createPeerConnection(rtcConfig);

      // Get Microphone Track
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      // Listen for local ICE candidates
      peerConnection!.onIceCandidate = (candidate) {
        socket?.emit('webrtc:ice-candidate', {
          'bookingId': bookingId,
          'candidate': candidate.toMap(),
        });
      };

      // Listen for ICE connection state (Firewall / strict NAT detection)
      peerConnection!.onIceConnectionState = (state) async {
        debugPrint('[WebRTC] ICE Connection State: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          final connectivityList = await Connectivity().checkConnectivity();
          final isWifi = connectivityList.contains(ConnectivityResult.wifi);

          socket?.emit('webrtc:ice-failed', {
            'bookingId': bookingId,
            'networkType': isWifi ? 'wifi' : 'cellular',
            'iceState': 'failed',
          });

          if (isWifi) {
            _setCallState(CallState.failed);
            onFirewallError?.call(
              'Aapke Wi-Fi network ya router firewall ne audio call ports block kar diye hain. Kripya apna Wi-Fi band karke mobile data chalu karein aur call dobara lagayein.',
            );
          }
        }
      };

      // Join room & trigger ring
      socket?.emit('webrtc:join-room', {
        'bookingId': bookingId,
        'userId': currentUserId,
      });

      socket?.emit('webrtc:call-initiate', {
        'bookingId': bookingId,
        'callerId': currentUserId,
        'callerRole': initData['caller']?['role'],
        'callerName': initData['caller']?['name'],
        'callerAvatar': initData['caller']?['avatar'],
        'callSessionId': currentCallSessionId,
        'serviceTitle': serviceTitle,
      });

      _setCallState(CallState.ringing);
      return true;
    } catch (e) {
      debugPrint('[WebRTC] Start call exception: $e');
      _setCallState(CallState.failed);
      return false;
    }
  }

  // ===========================================================================
  // ACCEPT INCOMING CALL
  // ===========================================================================
  Future<bool> acceptCall({
    required String bookingId,
    String? token,
    String? callerName,
    String? callerRole,
    String? callerAvatar,
    String? serviceTitleParam,
  }) async {
    currentBookingId = bookingId;
    if (callerName != null) peerName = callerName;
    if (callerRole != null) peerRole = callerRole;
    if (callerAvatar != null) peerAvatar = callerAvatar;
    if (serviceTitleParam != null) serviceTitle = serviceTitleParam;
    isMuted = false;
    isSpeakerOn = false;

    _setCallState(CallState.connected);
    _startDurationTimer();

    await Permission.microphone.request();

    try {
      final authToken = token ?? await _tokenStorage.accessToken;
      if (authToken == null || authToken.isEmpty) {
        _setCallState(CallState.failed);
        return false;
      }

      await initializeSocket(token: authToken);

      final iceRes = await http.get(
        Uri.parse('$serverUrl/api/webrtc/config/ice-servers'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      final iceData = jsonDecode(iceRes.body);
      final iceServers = (iceData['iceServers'] as List<dynamic>?) ?? [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ];

      peerConnection = await createPeerConnection({
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      });

      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      peerConnection!.onIceCandidate = (candidate) {
        socket?.emit('webrtc:ice-candidate', {
          'bookingId': bookingId,
          'candidate': candidate.toMap(),
        });
      };

      peerConnection!.onIceConnectionState = (state) async {
        debugPrint('[WebRTC] Receiver ICE Connection State: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          final connectivityList = await Connectivity().checkConnectivity();
          final isWifi = connectivityList.contains(ConnectivityResult.wifi);

          socket?.emit('webrtc:ice-failed', {
            'bookingId': bookingId,
            'networkType': isWifi ? 'wifi' : 'cellular',
            'iceState': 'failed',
          });
        }
      };

      socket?.emit('webrtc:join-room', {
        'bookingId': bookingId,
        'userId': currentUserId,
      });

      socket?.emit('webrtc:call-accept', {
        'bookingId': bookingId,
        'receiverId': currentUserId,
      });

      return true;
    } catch (e) {
      debugPrint('[WebRTC] Accept call error: $e');
      _setCallState(CallState.failed);
      return false;
    }
  }

  // ===========================================================================
  // REJECT CALL
  // ===========================================================================
  void rejectCall({String? reason}) {
    if (currentBookingId != null) {
      socket?.emit('webrtc:call-reject', {
        'bookingId': currentBookingId,
        'reason': reason ?? 'DECLINED',
      });
    }
    _setCallState(CallState.ended);
    cleanupCall();
  }

  // ===========================================================================
  // HANGUP / END CALL
  // ===========================================================================
  void hangUp({String? endReason}) {
    if (currentBookingId != null) {
      socket?.emit('webrtc:call-hangup', {
        'bookingId': currentBookingId,
        'durationSeconds': callDurationSeconds,
        'endReason': endReason ?? 'NORMAL_HANGUP',
      });
    }
    _setCallState(CallState.ended);
    cleanupCall();
  }

  // ===========================================================================
  // AUDIO CONTROLS (Mute / Speaker)
  // ===========================================================================
  void toggleMute() {
    isMuted = !isMuted;
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
    onCallStateChanged?.call(currentState);
  }

  void toggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    localStream?.getAudioTracks().forEach((track) {
      track.enableSpeakerphone(isSpeakerOn);
    });
    onCallStateChanged?.call(currentState);
  }

  void cleanupCall() {
    durationTimer?.cancel();
    durationTimer = null;
    callDurationSeconds = 0;
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.dispose();
    peerConnection?.close();
    peerConnection?.dispose();
    peerConnection = null;
    localStream = null;
  }

  void _startDurationTimer() {
    durationTimer?.cancel();
    callDurationSeconds = 0;
    durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callDurationSeconds++;
      onCallStateChanged?.call(currentState);
    });
  }

  void _setCallState(CallState state) {
    currentState = state;
    onCallStateChanged?.call(state);
  }
}
