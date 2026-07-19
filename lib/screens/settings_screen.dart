import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_settings.dart';
import '../models/company_profile.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbService = DatabaseService();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _taxIdCtrl;
  late TextEditingController _paymentCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _prefixCtrl;

  CompanyProfile _profile = CompanyProfile();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  final List<String> _currencies = ['\$', '€', '£', '₹', 'Rs', 'C\$', 'A\$', '¥'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _taxIdCtrl = TextEditingController();
    _paymentCtrl = TextEditingController();
    _taxRateCtrl = TextEditingController();
    _prefixCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _profile = await _dbService.getCompanyProfile();
      _settings = await _dbService.getAppSettings();

      _nameCtrl.text = _profile.name;
      _addressCtrl.text = _profile.address;
      _emailCtrl.text = _profile.email;
      _phoneCtrl.text = _profile.phone;
      _taxIdCtrl.text = _profile.taxId;
      _paymentCtrl.text = _profile.paymentDetails ?? '';

      _taxRateCtrl.text = _settings.defaultTaxRate.toStringAsFixed(1);
      _prefixCtrl.text = _settings.invoicePrefix;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profile = _profile.copyWith(logoPath: image.path);
      });
    }
  }

  Future<void> _saveAll() async {
    final updatedProfile = _profile.copyWith(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      taxId: _taxIdCtrl.text.trim(),
      paymentDetails: _paymentCtrl.text.trim(),
    );

    final taxRate = double.tryParse(_taxRateCtrl.text.trim()) ?? 10.0;
    final updatedSettings = _settings.copyWith(
      defaultTaxRate: taxRate,
      invoicePrefix: _prefixCtrl.text.trim().isEmpty ? 'INV-' : _prefixCtrl.text.trim(),
    );

    await _dbService.updateCompanyProfile(updatedProfile);
    await _dbService.updateAppSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.paidColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company & App Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveAll,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo & Business Details Section
                  _buildSectionHeader('Company Profile & Logo', Icons.business_rounded),
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                            image: !kIsWeb &&
                                    _profile.logoPath != null &&
                                    _profile.logoPath!.isNotEmpty &&
                                    File(_profile.logoPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_profile.logoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: kIsWeb ||
                                  _profile.logoPath == null ||
                                  !File(_profile.logoPath!).existsSync()
                              ? const Icon(Icons.business_rounded, size: 48, color: AppTheme.primaryColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                              onPressed: _pickLogo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Company / Business Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Company Address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxIdCtrl,
                    decoration: const InputDecoration(labelText: 'Tax Registration ID (VAT/GST/SSN)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paymentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Default Payment Terms / Bank Details (QR Code Info)',
                      hintText: 'Bank Account #, SWIFT code, UPI ID, or PayPal link',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Invoice Defaults
                  _buildSectionHeader('Invoice Configuration', Icons.tune_rounded),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _settings.currency,
                          decoration: const InputDecoration(labelText: 'Default Currency'),
                          items: _currencies.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _settings = _settings.copyWith(currency: val);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _taxRateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Default Tax Rate (%)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _prefixCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number Prefix',
                      hintText: 'e.g. INV-, BILL-, FACT-',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Appearance & Theme
                  _buildSectionHeader('Appearance & Preferences', Icons.palette_rounded),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Dark Mode Theme'),
                    subtitle: const Text('Toggle between sleek Dark and vibrant Light modes'),
                    value: _settings.isDarkMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) async {
                      setState(() {
                        _settings = _settings.copyWith(isDarkMode: val);
                      });
                      await _dbService.updateAppSettings(_settings);
                      widget.onThemeChanged();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Backup & Maintenance
                  _buildSectionHeader('Backup & Data Management', Icons.cloud_download_rounded),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final path = await BackupService.exportBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Database backup exported to: $path'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export Complete Data Backup (JSON)'),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save All Settings'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
