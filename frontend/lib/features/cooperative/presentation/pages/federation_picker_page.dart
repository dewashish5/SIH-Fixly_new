import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class FederationPickerPage extends StatefulWidget {
  const FederationPickerPage({super.key});

  @override
  State<FederationPickerPage> createState() => _FederationPickerPageState();
}

class _FederationPickerPageState extends State<FederationPickerPage> {
  final _searchController = TextEditingController();
  List<dynamic> _federations = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFederations();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _federations.where((f) {
        final name = (f['name'] as String?)?.toLowerCase() ?? '';
        final state = (f['state'] as String?)?.toLowerCase() ?? '';
        final district = (f['district'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || state.contains(query) || district.contains(query);
      }).toList();
    });
  }

  Future<void> _loadFederations() async {
    try {
      final res = await ApiServices.client.get('/api/cooperative/federations');
      final data = res['data'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _federations = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load federations. Please try again.';
        _loading = false;
      });
    }
  }

  void _selectFederation(String id) {
    context.read<AppSessionCubit>().setFederationId(id);
    context.push(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Select Federation',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your cooperative federation to proceed with sign up.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _searchController,
            label: 'Search',
            hint: 'Search by name, state, or district...',
            prefixIcon: const Icon(Icons.search),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            SecondaryButton(label: 'Retry', onPressed: _loadFederations),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('No federations found.'));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final f = _filtered[index];
        return AppCard(
          onTap: () => _selectFederation(f['_id'] ?? f['id'] ?? ''),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f['name'] ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${f['district'] ?? ''}, ${f['state'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
