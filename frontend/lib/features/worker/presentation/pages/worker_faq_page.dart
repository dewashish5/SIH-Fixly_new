import 'package:flutter/material.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../shared/data/service_scope_data.dart';
import '../../../shared/presentation/widgets/service_scope_widgets.dart';

class WorkerFaqPage extends StatelessWidget {
  const WorkerFaqPage({this.categoryId, super.key});

  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Worker SOP & FAQs',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF0F172A), const Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cooperative Work Guidelines',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'As an affiliated worker, your boundaries are protected. Never perform unsafe, unlisted, or forced tasks without fair compensation.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // How it's done SOP
            HowItsDoneCard(primaryCategoryId: categoryId),

            const SizedBox(height: 20),

            // What is included & What is not included (boundaries)
            WhatIsIncludedCard(
              primaryCategoryId: categoryId,
              showTabs: true,
            ),

            const SizedBox(height: 20),

            // Worker FAQs
            ServiceFaqSection(
              title: 'Worker Rights & Service FAQs',
              customFaqs: ServiceScopeData.workerFaqs,
            ),

            const SizedBox(height: 24),

            // Contact Cooperative Union Helpline
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: scheme.primary, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need dispute or on-site support?',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your cooperative federation officer is available to assist you.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
