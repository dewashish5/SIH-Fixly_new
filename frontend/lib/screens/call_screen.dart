import 'package:flutter/material.dart';
import '../services/webrtc_call_service.dart';

class CallScreen extends StatefulWidget {
  final WebRTCCallService? callService;
  final String? bookingId;
  final String? peerName;
  final String? peerRole;
  final String? peerAvatar;
  final String? serviceTitle;
  final bool isIncoming;

  const CallScreen({
    super.key,
    this.callService,
    this.bookingId,
    this.peerName,
    this.peerRole,
    this.peerAvatar,
    this.serviceTitle,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late WebRTCCallService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.callService ?? WebRTCCallService.instance;

    _service.onCallStateChanged = (state) {
      if (!mounted) return;
      setState(() {});
      if (state == CallState.ended) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    };

    _service.onFirewallError = (message) {
      if (!mounted) return;
      _showFirewallDialog(message);
    };

    _service.onPeerNetworkIssue = (message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    };
  }

  void _showFirewallDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF22223B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Wi-Fi Firewall Blocked',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('Switch to Mobile Data & Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.currentState;
    final name = widget.peerName ?? _service.peerName ?? 'Fixly User';
    final role = (widget.peerRole ?? _service.peerRole ?? 'Worker').toUpperCase();
    final title = widget.serviceTitle ?? _service.serviceTitle ?? 'Fixly Service';
    final avatar = widget.peerAvatar ?? _service.peerAvatar;

    String statusText;
    Color statusColor = Colors.white70;

    switch (state) {
      case CallState.initiating:
        statusText = 'Connecting...';
        statusColor = Colors.amberAccent;
        break;
      case CallState.ringing:
        statusText = 'Ringing...';
        statusColor = Colors.lightBlueAccent;
        break;
      case CallState.connected:
        statusText = _formatTimer(_service.callDurationSeconds);
        statusColor = const Color(0xFF10B981);
        break;
      case CallState.ended:
        statusText = 'Call Ended';
        statusColor = Colors.redAccent;
        break;
      case CallState.failed:
        statusText = 'Call Failed';
        statusColor = Colors.redAccent;
        break;
      case CallState.idle:
        statusText = 'Ready';
        break;
    }

    return PopScope(
      canPop: state == CallState.ended || state == CallState.failed || state == CallState.idle,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _service.hangUp();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar with Security Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'End-to-End Encrypted • Private Calling',
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Peer Profile & Call State
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (state == CallState.connected ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                              .withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFF1E293B),
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? NetworkImage(avatar)
                          : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? const Icon(Icons.person, size: 60, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$role • $title',
                      style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),

              // Bottom In-Call Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute / Unmute
                    _CallControlButton(
                      icon: _service.isMuted ? Icons.mic_off : Icons.mic,
                      label: _service.isMuted ? 'Unmute' : 'Mute',
                      isActive: _service.isMuted,
                      onPressed: () {
                        setState(() {
                          _service.toggleMute();
                        });
                      },
                    ),

                    // End Call
                    FloatingActionButton(
                      heroTag: 'endCallFab',
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 6,
                      onPressed: () {
                        _service.hangUp();
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                    ),

                    // Speakerphone Toggle
                    _CallControlButton(
                      icon: _service.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: _service.isSpeakerOn ? 'Speaker On' : 'Speaker',
                      isActive: _service.isSpeakerOn,
                      onPressed: () {
                        setState(() {
                          _service.toggleSpeaker();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : const Color(0xFF1E293B),
          ),
          child: IconButton(
            icon: Icon(icon, color: isActive ? const Color(0xFF0F172A) : Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
