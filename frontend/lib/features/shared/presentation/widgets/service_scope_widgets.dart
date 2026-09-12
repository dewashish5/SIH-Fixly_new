import 'package:flutter/material.dart';

import '../../data/service_scope_data.dart';

/// Renders the 'What is included ?' card matching the reference design.
/// Shows category tabs, 'The expert is trained to' with green checks,
/// 'What is not included' with orange/red X circles, and an equipment notice.
class WhatIsIncludedCard extends StatefulWidget {
  const WhatIsIncludedCard({
    super.key,
    this.primaryCategoryId,
    List<String>? customIncluded,
    List<String>? customExcluded,
    List<String>? includedTasks,
    List<String>? excludedTasks,
    this.federationName,
    this.showTabs = true,
  })  : customIncluded = customIncluded ?? includedTasks,
        customExcluded = customExcluded ?? excludedTasks;

  final String? primaryCategoryId;
  final List<String>? customIncluded;
  final List<String>? customExcluded;
  final String? federationName;
  final bool showTabs;

  @override
  State<WhatIsIncludedCard> createState() => _WhatIsIncludedCardState();
}

class _WhatIsIncludedCardState extends State<WhatIsIncludedCard> {
  late int _selectedTabIndex;
  late List<CategoryScopeDefinition> _availableTabs;

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  @override
  void didUpdateWidget(covariant WhatIsIncludedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryCategoryId != widget.primaryCategoryId) {
      _initTabs();
    }
  }

  void _initTabs() {
    final primary = ServiceScopeData.getScopeForCategory(widget.primaryCategoryId);

    // If it's domestic/cleaning, provide the 3 subtabs like in the screenshot
    if (primary.id == 'domestic_helper' || primary.id.contains('clean')) {
      _availableTabs = [
        primary,
        ServiceScopeData.definitions.firstWhere((d) => d.id == 'dusting_wiping'),
        ServiceScopeData.definitions.firstWhere((d) => d.id == 'bathroom_cleaning'),
      ];
    } else {
      _availableTabs = [primary];
    }
    _selectedTabIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentScope = _availableTabs[_selectedTabIndex];

    final includedList = (widget.customIncluded != null && widget.customIncluded!.isNotEmpty)
        ? widget.customIncluded!
        : currentScope.included;

    final excludedList = (widget.customExcluded != null && widget.customExcluded!.isNotEmpty)
        ? widget.customExcluded!
        : currentScope.excluded;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'What is included ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          if (widget.federationName != null && widget.federationName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Standardized by ${widget.federationName}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Category Sub-tabs if multiple
          if (widget.showTabs && _availableTabs.length > 1) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_availableTabs.length, (index) {
                  final tab = _availableTabs[index];
                  final isSelected = index == _selectedTabIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 16,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tab.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 'The expert is trained to'
          const Text(
            'The expert is trained to',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),

          // Green check items
          for (final item in includedList)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 'What is not included'
          const Text(
            'What is not included',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),

          // Orange/red X items
          for (final item in excludedList)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Equipment notice banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cleaning_services_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentScope.equipmentNotice,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the 'How it's done?' workflow card matching the reference screenshot.
class HowItsDoneCard extends StatelessWidget {
  const HowItsDoneCard({
    super.key,
    this.primaryCategoryId,
    this.customSteps,
  });

  final String? primaryCategoryId;
  final List<HowItsDoneStep>? customSteps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = ServiceScopeData.getScopeForCategory(primaryCategoryId);
    final steps = customSteps ?? scope.howItsDone;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How it's done?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    steps[i].icon,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        steps[i].description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders the expandable FAQ accordion section matching the reference design.
class ServiceFaqSection extends StatefulWidget {
  const ServiceFaqSection({
    super.key,
    this.primaryCategoryId,
    this.customFaqs,
    this.title = 'FAQs',
  });

  final String? primaryCategoryId;
  final List<ServiceFaq>? customFaqs;
  final String title;

  @override
  State<ServiceFaqSection> createState() => _ServiceFaqSectionState();
}

class _ServiceFaqSectionState extends State<ServiceFaqSection> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = ServiceScopeData.getScopeForCategory(widget.primaryCategoryId);
    final faqs = widget.customFaqs ?? scope.faqs;

    if (faqs.isEmpty) return const SizedBox.shrink();

    final itemBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final itemBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < faqs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildFaqItem(
            index: i,
            faq: faqs[i],
            isDark: isDark,
            itemBg: itemBg,
            itemBorder: itemBorder,
          ),
        ],
      ],
    );
  }

  Widget _buildFaqItem({
    required int index,
    required ServiceFaq faq,
    required bool isDark,
    required Color itemBg,
    required Color itemBorder,
  }) {
    final isExpanded = _expandedIndices.contains(index);

    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIndices.remove(index);
          } else {
            _expandedIndices.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: itemBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: itemBorder),
              const SizedBox(height: 10),
              Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cooperative Federation verification badge.
class CooperativeFederationBadge extends StatelessWidget {
  const CooperativeFederationBadge({
    required this.federationName,
    this.compact = false,
    super.key,
  });

  final String federationName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                federationName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cooperative Federation Protected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  federationName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
