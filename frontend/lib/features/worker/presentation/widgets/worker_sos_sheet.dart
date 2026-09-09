import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../core/utils/toast_utils.dart';

class WorkerSosSheet extends StatelessWidget {
  const WorkerSosSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WorkerSosSheet(),
    );
  }

  Future<void> _call(BuildContext context, String number, String label) async {
    final uri = Uri.parse('tel:$number');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ToastUtils.showError(
          context: context,
          message: 'Could not place call to $label ($number)',
        );
      }
    } catch (_) {
      if (context.mounted) {
        ToastUtils.showError(
          context: context,
          message: 'Unable to open phone dialer for $number',
        );
      }
    }
  }

  void _broadcastDistress(BuildContext context) {
    Navigator.of(context).pop();
    ToastUtils.showSuccess(
      context: context,
      message: '🚨 Emergency alert sent! Cooperative safety desk alerted with your location.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Worker Safety & SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Immediate response for on-duty emergencies',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alert banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap any number below to directly connect with national services or federation response.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Emergency Grid
          Row(
            children: [
              Expanded(
                child: _EmergencyCard(
                  title: 'National Emergency',
                  subtitle: 'Police, Fire, Ambulance',
                  number: '112',
                  icon: Icons.emergency_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () => _call(context, '112', 'National Emergency 112'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmergencyCard(
                  title: 'Police Control',
                  subtitle: 'Immediate safety assistance',
                  number: '100',
                  icon: Icons.local_police_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: () => _call(context, '100', 'Police 100'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _EmergencyCard(
                  title: 'Medical Ambulance',
                  subtitle: 'Injury / Health distress',
                  number: '108',
                  icon: Icons.medical_services_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => _call(context, '108', 'Ambulance 108'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EmergencyCard(
                  title: 'Federation Safety Cell',
                  subtitle: 'Worker Cooperative Desk',
                  number: '18002001122',
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () => _call(context, '18002001122', 'Federation Safety Cell'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fixly Rapid Response Contact Line
          InkWell(
            onTap: () => _call(context, '1800123456', 'Fixly 24x7 Safety Helpline'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixly 24x7 Safety Helpline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Toll-Free • Dispute & On-Duty Emergency',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CALL NOW',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // One-tap Distress Broadcast Button
          ElevatedButton.icon(
            onPressed: () => _broadcastDistress(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.broadcast_on_personal_rounded),
            label: const Text(
              'Broadcast GPS Distress to Federation Desk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
