import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../pdf/pdf_builder.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String _selectedTemplate = 'Classic';
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseService().getAppSettings();
    setState(() {
      _selectedTemplate = settings.pdfTemplate;
      _currencySymbol = settings.currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Choose PDF Template',
            onSelected: (template) async {
              setState(() {
                _selectedTemplate = template;
              });
              final dbService = DatabaseService();
              final settings = await dbService.getAppSettings();
              await dbService.updateAppSettings(settings.copyWith(pdfTemplate: template));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Classic',
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      color: _selectedTemplate == 'Classic' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Classic Elegant'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Modern',
                child: Row(
                  children: [
                    Icon(
                      Icons.style_outlined,
                      color: _selectedTemplate == 'Modern' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Modern Indigo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Minimal',
                child: Row(
                  children: [
                    Icon(
                      Icons.crop_square_rounded,
                      color: _selectedTemplate == 'Minimal' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Minimal Monochrome'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfBuilder.buildPdf(
          invoice: widget.invoice,
          currencySymbol: _currencySymbol,
          template: _selectedTemplate,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Invoice_${widget.invoice.invoiceNumber}.pdf',
      ),
    );
  }
}
