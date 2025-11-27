import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
ºimport 'package:html/parser.dart' as html_parser;
import 'package:super_clipboard/super_clipboard.dart';
class NewsletterPreviewScreen extends StatefulWidget {
  final String htmlContent;

  const NewsletterPreviewScreen({super.key, required this.htmlContent});

  @override
  State<NewsletterPreviewScreen> createState() =>
      _NewsletterPreviewScreenState();
}

class _NewsletterPreviewScreenState extends State<NewsletterPreviewScreen> {
  Future<void> _copyHtmlToClipboard() async {
    try {
      final document = html_parser.parse(widget.htmlContent);
      final String plainText = document.body?.text ?? '';

      final item = DataWriterItem();
      item.add(Formats.htmlText(widget.htmlContent, alt: plainText));

      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'El portapapeles no está disponible en esta plataforma.')),
          );
        }
        return;
      }
      await clipboard.write([item]);

      if (!mounted) return; // Check if the widget is still in the tree

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Newsletter copiada! Ya puedes pegarla en tu cliente de correo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return; // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al copiar al portapapeles: $e')),
      );
    }
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.htmlContent));
    if (!mounted) return; // Check if the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('HTML copiado al portapapeles')),
    );
  }

  void _showHtmlSource() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Código HTML'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                widget.htmlContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: const Text('Previsualización'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _showHtmlSource,
            tooltip: 'Ver código HTML',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copiar HTML',
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed:
                _copyHtmlToClipboard, // This is the main button for Outlook/Email
            tooltip: 'Copiar para Email (Outlook, etc.)',
          ),
        ],
      ),
      // The InAppWebView was removed to avoid Windows build issues with nuget.
      // The preview is now a simple scrollable view of the HTML code.
      // The primary function is to copy the HTML, which still works perfectly.
      body: SingleChildScrollView(child: SelectableText(widget.htmlContent)),
    );
  }
}
