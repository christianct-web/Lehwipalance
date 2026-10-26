import 'package:flutter/material.dart';

import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

class LocationFilterPreferencePage extends StatefulWidget {
  const LocationFilterPreferencePage({super.key});

  @override
  State<LocationFilterPreferencePage> createState() =>
      _LocationFilterPreferencePageState();
}

class _LocationFilterPreferencePageState
    extends State<LocationFilterPreferencePage> {
  late final LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    _locationProvider = getIt<LocationProvider>();
    _locationProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _locationProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = _locationProvider.presetFilters;
    final activeFilterId = _locationProvider.activeFilterId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Location Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateFilterDialog(context),
            tooltip: 'Create New Filter',
          ),
        ],
      ),
      body: filters.isEmpty
          ? EmptyFilterState(onTap: () => _showCreateFilterDialog(context))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filters.length} Filters',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCreateFilterDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Filter'),
                      ),
                    ],
                  ),
                ),
                // Filter list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filters.length,
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isActive = filter.id == activeFilterId;

                      return FilterCard(
                        key: ValueKey(filter.id),
                        filter: filter,
                        isActive: isActive,
                        onSelect: () => _selectFilter(filter),
                        onEdit: () => _showEditFilterDialog(context, filter),
                        onDelete: () => _deleteFilter(filter),
                      );
                    },
                  ),
                ),
                // Help text
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '💡 Tap a filter to apply it. Toggle "Exclusive" to auto-deactivate others.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  void _selectFilter(LocationFilter filter) {
    if (filter.id == null) return;

    // If this filter is already active, clear it
    if (_locationProvider.activeFilterId == filter.id) {
      _locationProvider.clearActiveFilter();
      _showSnackBar('Filter deactivated', duration: const Duration(seconds: 1));
      return;
    }

    // If this filter is exclusive, set it as active and deactivate others
    if (filter.isExclusive) {
      _locationProvider.setActivePresetExclusive(filter.id!);
    } else {
      _locationProvider.applyFilterPreset(filter.id!);
    }

    _showSnackBar('✅ Applied filter: ${filter.name}');
  }

  void _showCreateFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateFilterDialog(
        onSave: (filter) {
          // Add the filter
          _locationProvider.addPresetFilter(filter);

          // Auto-select if it's exclusive
          if (filter.isExclusive && filter.id != null) {
            _locationProvider.setActivePresetExclusive(filter.id!);
          }

          _showSnackBar('➕ Filter created: ${filter.name}');
        },
      ),
    );
  }

  void _showEditFilterDialog(BuildContext context, LocationFilter filter) {
    showDialog(
      context: context,
      builder: (context) => CreateFilterDialog(
        initialFilter: filter,
        onSave: (updatedFilter) {
          _locationProvider.updatePresetFilter(updatedFilter);

          // If the filter was active, re-apply it
          if (_locationProvider.activeFilterId == updatedFilter.id) {
            _locationProvider.applyFilterPreset(updatedFilter.id!);
          }

          _showSnackBar('✏️ Filter updated: ${updatedFilter.name}');
        },
      ),
    );
  }

  void _deleteFilter(LocationFilter filter) {
    if (filter.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Filter'),
        content: Text('Are you sure you want to delete "${filter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final wasActive = _locationProvider.activeFilterId == filter.id;
              _locationProvider.removePresetFilter(filter.id!);

              // If the deleted filter was active, clear the active state
              if (wasActive) {
                _locationProvider.clearActiveFilter();
              }

              _showSnackBar('🗑️ Deleted filter: ${filter.name}');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }
}

class FilterCard extends StatelessWidget {
  final LocationFilter filter;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FilterCard({
    super.key,
    required this.filter,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Active indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? colorScheme.primary : Colors.grey[300],
                    ),
                    child: isActive
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Filter name
                  Expanded(
                    child: Text(
                      filter.name ?? 'Unnamed Filter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),

                  // Exclusive badge
                  if (filter.isExclusive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'EXCLUSIVE',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Filter details
              FilterDetails(filter: filter),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit Filter',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete Filter',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateFilterDialog extends StatefulWidget {
  final LocationFilter? initialFilter;
  final Function(LocationFilter) onSave;

  const CreateFilterDialog({
    super.key,
    this.initialFilter,
    required this.onSave,
  });

  @override
  State<CreateFilterDialog> createState() => _CreateFilterDialogState();
}

class _CreateFilterDialogState extends State<CreateFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _searchController;
  late TextEditingController _radiusController;

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  bool _isExclusive = false;

  late final LocationProvider _locationProvider;
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _locationProvider = getIt<LocationProvider>();

    _nameController = TextEditingController(
      text: widget.initialFilter?.name ?? '',
    );
    _searchController = TextEditingController(
      text: widget.initialFilter?.search ?? '',
    );
    _radiusController = TextEditingController(
      text: widget.initialFilter?.radiusKm?.toString() ?? '',
    );

    _selectedCountry = widget.initialFilter?.country;
    _selectedState = widget.initialFilter?.state;
    _selectedCity = widget.initialFilter?.city;
    _isExclusive = widget.initialFilter?.isExclusive ?? false;

    _loadLocationData();
  }

  void _loadLocationData() {
    _countries = _locationProvider.getUniqueCountries();
    _updateStates();
    _updateCities();
  }

  void _updateStates() {
    _states = _locationProvider.getUniqueStates(country: _selectedCountry);
  }

  void _updateCities() {
    _cities = _locationProvider.getUniqueCities(
      country: _selectedCountry,
      state: _selectedState,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialFilter == null
                      ? 'Create Filter'
                      : 'Edit Filter',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Filter Name *',
                    hintText: 'e.g., "New York Office"',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a filter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Search field
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Term',
                    hintText: 'Search by name, address, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Location fields
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Country',
                        value: _selectedCountry,
                        items: _countries,
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedState = null;
                            _selectedCity = null;
                            _updateStates();
                            _updateCities();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'State',
                        value: _selectedState,
                        items: _states,
                        onChanged: (value) {
                          setState(() {
                            _selectedState = value;
                            _selectedCity = null;
                            _updateCities();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'City',
                        value: _selectedCity,
                        items: _cities,
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Radius field
                TextFormField(
                  controller: _radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Radius (km)',
                    hintText: 'e.g., 10',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Radius must be greater than 0';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Exclusive toggle
                SwitchListTile(
                  title: const Text('Exclusive Filter'),
                  subtitle: const Text(
                    'When active, this filter will deactivate all others',
                  ),
                  value: _isExclusive,
                  onChanged: (value) {
                    setState(() {
                      _isExclusive = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                const SizedBox(height: 8),

                // Preview section
                if (_hasLocationCriteria()) _buildFilterPreview(context),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveFilter,
                      child: const Text('Save Filter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Any')),
        ...items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }),
      ],
      onChanged: onChanged,
      isExpanded: true,
      validator: (value) {
        // Country is required when creating a filter
        if (label == 'Country' && value == null) {
          return 'Please select a country';
        }
        return null;
      },
    );
  }

  Widget _buildFilterPreview(BuildContext context) {
    final details = <String>[];
    if (_selectedCountry != null) details.add('🌍 ${_selectedCountry!}');
    if (_selectedState != null) details.add('🏛️ ${_selectedState!}');
    if (_selectedCity != null) details.add('🏙️ ${_selectedCity!}');
    if (_searchController.text.isNotEmpty) {
      details.add('🔍 "${_searchController.text}"');
    }
    if (_radiusController.text.isNotEmpty) {
      details.add('📍 ${_radiusController.text}km radius');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: details.map((detail) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _hasLocationCriteria() {
    return (_selectedCountry != null && _selectedCountry!.isNotEmpty) ||
        (_selectedState != null && _selectedState!.isNotEmpty) ||
        (_selectedCity != null && _selectedCity!.isNotEmpty) ||
        _searchController.text.isNotEmpty ||
        _radiusController.text.isNotEmpty;
  }

  void _saveFilter() {
    if (!_formKey.currentState!.validate()) return;

    // Check for duplicate name
    final existingFilters = _locationProvider.presetFilters;
    final isDuplicate = existingFilters.any(
      (f) =>
          f.id != widget.initialFilter?.id &&
          f.name?.toLowerCase() == _nameController.text.trim().toLowerCase(),
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A filter with this name already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final filter = LocationFilter(
      id:
          widget.initialFilter?.id ??
          'filter_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      country: _selectedCountry,
      state: _selectedState,
      city: _selectedCity,
      radiusKm: _radiusController.text.isNotEmpty
          ? double.parse(_radiusController.text)
          : null,
      isExclusive: _isExclusive,
    );

    widget.onSave(filter);
    Navigator.pop(context);
  }
}

class FilterDetails extends StatelessWidget {
  final LocationFilter filter;

  const FilterDetails({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final details = _buildDetailsList();

    if (details.isEmpty) {
      return Text(
        'No filters applied',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: details.map((detail) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(detail, style: Theme.of(context).textTheme.bodySmall),
        );
      }).toList(),
    );
  }

  List<String> _buildDetailsList() {
    final details = <String>[];

    if (filter.search != null && filter.search!.isNotEmpty) {
      details.add('🔍 "${filter.search}"');
    }

    if (filter.city != null && filter.city!.isNotEmpty) {
      details.add('🏙️ ${filter.city}');
    }

    if (filter.state != null && filter.state!.isNotEmpty) {
      details.add('🏛️ ${filter.state}');
    }

    if (filter.country != null && filter.country!.isNotEmpty) {
      details.add('🌍 ${filter.country}');
    }

    if (filter.radiusKm != null) {
      details.add('📍 ${filter.radiusKm!.toStringAsFixed(1)}km radius');
    }

    return details;
  }
}

class EmptyFilterState extends StatelessWidget {
  final VoidCallback onTap;

  const EmptyFilterState({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Location Filters',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Create filters to quickly switch between\nlocations you care about',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Create First Filter'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
