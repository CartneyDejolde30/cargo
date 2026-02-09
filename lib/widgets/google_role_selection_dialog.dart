import 'package:flutter/material.dart';

/// Enhanced modal dialog for new Google users to select their role and municipality
class GoogleRoleSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> googleData;
  final Function(String role, String municipality) onComplete;
  final VoidCallback onCancel;

  const GoogleRoleSelectionDialog({
    Key? key,
    required this.googleData,
    required this.onComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<GoogleRoleSelectionDialog> createState() => _GoogleRoleSelectionDialogState();
}

class _GoogleRoleSelectionDialogState extends State<GoogleRoleSelectionDialog> with SingleTickerProviderStateMixin {
  String? _selectedRole;
  String? _selectedMunicipality;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _municipalities = [
    'Bayugan',
    'Bunawan',
    'Esperanza',
    'La Paz',
    'Loreto',
    'Prosperidad',
    'Rosario',
    'San Francisco',
    'San Luis',
    'Santa Josefa',
    'Sibagat',
    'Talacogon',
    'Trento',
    'Veruela'
  ];

  final List<Map<String, dynamic>> _roleOptions = [
    {
      'value': 'Renter',
      'title': 'Renter',
      'subtitle': 'I want to rent vehicles',
      'icon': Icons.car_rental,
      'color': Colors.blue,
    },
    {
      'value': 'Owner',
      'title': 'Owner',
      'subtitle': 'I want to list my vehicles',
      'icon': Icons.key,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _canProceed => _selectedRole != null && _selectedMunicipality != null;

  void _handleContinue() {
    if (_canProceed) {
      widget.onComplete(_selectedRole!, _selectedMunicipality!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: theme.scaffoldBackgroundColor,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.iconTheme.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.googleData['fullName'] ?? 'User',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s set up your account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Role Selection Section
                    Text(
                      'I am a...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Role Cards
                    ..._roleOptions.map((option) {
                      final isSelected = _selectedRole == option['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = option['value'];
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (option['color'] as Color).withValues(alpha: 0.1)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? (option['color'] as Color)
                                    : theme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (option['color'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    option['icon'],
                                    color: option['color'],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['title'],
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.iconTheme.color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option['subtitle'],
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: option['color'],
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 28),

                    // Municipality Selection
                    Text(
                      'Municipality',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMunicipality != null 
                              ? colorScheme.primary 
                              : theme.dividerColor,
                          width: _selectedMunicipality != null ? 2 : 1,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMunicipality,
                        decoration: InputDecoration(
                          hintText: 'Select your municipality',
                          hintStyle: TextStyle(color: theme.hintColor),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: _selectedMunicipality != null 
                                ? colorScheme.primary 
                                : theme.hintColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.iconTheme.color,
                        ),
                        dropdownColor: theme.scaffoldBackgroundColor,
                        style: TextStyle(
                          color: theme.iconTheme.color,
                          fontSize: 15,
                        ),
                        items: _municipalities.map((municipality) {
                          return DropdownMenuItem(
                            value: municipality,
                            child: Text(municipality),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMunicipality = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              foregroundColor: theme.iconTheme.color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _canProceed ? _handleContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              disabledBackgroundColor: theme.disabledColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: _canProceed 
                                      ? colorScheme.onPrimary 
                                      : theme.hintColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Helper text
                    if (!_canProceed) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Please select a role and municipality to continue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
