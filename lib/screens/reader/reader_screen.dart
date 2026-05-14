import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/theme/app_colors.dart';
import '../../models/document_model.dart';
import '../../providers/document_provider.dart';
import '../../providers/reader_settings_provider.dart';

class ReaderScreen extends StatefulWidget {
  final DocumentModel document;
  const ReaderScreen({super.key, required this.document});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = true;
  bool _showSettings = false;
  late PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _textContent;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _currentPage = widget.document.currentPage > 0 ? widget.document.currentPage : 1;
    if (widget.document.type == DocumentType.txt || widget.document.type == DocumentType.md) {
      _loadTextContent();
    }
  }

  Future<void> _loadTextContent() async {
    try {
      final file = File(widget.document.filePath);
      if (await file.exists()) {
        setState(() => _textContent = file.readAsStringSync());
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  @override
  void dispose() { _pdfController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<ReaderSettingsProvider>();
    return Scaffold(
      backgroundColor: rs.backgroundColor,
      body: Stack(children: [
        GestureDetector(
          onTap: () => setState(() { _showControls = !_showControls; if (!_showControls) _showSettings = false; }),
          child: _buildContent(rs),
        ),
        if (_showControls) ...[
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(context).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0)),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(context, rs).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0)),
        ],
        if (_showSettings) Positioned(bottom: 80, left: 16, right: 16, child: _buildSettingsPanel(rs).animate().fadeIn(duration: 200.ms)),
      ]),
    );
  }

  Widget _buildContent(ReaderSettingsProvider s) {
    if (widget.document.type == DocumentType.pdf) return _buildPdfViewer();
    if (widget.document.type == DocumentType.txt || widget.document.type == DocumentType.md) return _buildTextViewer(s);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warning),
      const SizedBox(height: 16),
      Text('Unsupported Format', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.textOnDark)),
    ]));
  }

  Widget _buildPdfViewer() => SfPdfViewer.file(
    File(widget.document.filePath), controller: _pdfController, initialPageNumber: _currentPage,
    canShowScrollHead: false, pageSpacing: 4,
    onPageChanged: (d) { setState(() => _currentPage = d.newPageNumber); if (_totalPages > 0) context.read<DocumentProvider>().updateReadingProgress(widget.document.id, _currentPage, _totalPages); },
    onDocumentLoaded: (d) => setState(() => _totalPages = d.document.pages.count),
  );

  Widget _buildTextViewer(ReaderSettingsProvider s) {
    if (_textContent == null) return Center(child: CircularProgressIndicator(color: s.textColor));
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 60, 24, MediaQuery.of(context).padding.bottom + 80),
      child: SelectableText(_textContent!, style: TextStyle(color: s.textColor, fontSize: s.fontSize, height: s.lineSpacing, fontFamily: s.fontFamily)),
    );
  }

  Widget _buildTopBar(BuildContext context) => Container(
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 8, bottom: 8),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withAlpha(180), Colors.black.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        if (_totalPages > 0) Text('Page $_currentPage of $_totalPages', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
      ])),
      IconButton(onPressed: _addBookmark, icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white)),
    ]),
  );

  Widget _buildBottomBar(BuildContext context, ReaderSettingsProvider s) => Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, left: 16, right: 16, top: 12),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(180)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    child: Row(children: [
      if (_totalPages > 1) Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), activeTrackColor: AppColors.primary, inactiveTrackColor: Colors.white.withAlpha(50), thumbColor: AppColors.primary),
        child: Slider(value: _currentPage.toDouble(), min: 1, max: _totalPages.toDouble(), onChanged: (v) { setState(() => _currentPage = v.round()); _pdfController.jumpToPage(_currentPage); }))) else const Spacer(),
      const SizedBox(width: 8),
      GestureDetector(onTap: () => setState(() => _showSettings = !_showSettings),
        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _showSettings ? AppColors.primary : Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 22))),
    ]),
  );

  Widget _buildSettingsPanel(ReaderSettingsProvider s) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withAlpha(40)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 20)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Font Size', style: TextStyle(color: Colors.white, fontSize: 14)),
        Row(children: [
          _btn(Icons.text_decrease_rounded, s.decreaseFontSize),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${s.fontSize.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
          _btn(Icons.text_increase_rounded, s.increaseFontSize),
        ]),
      ]),
      const SizedBox(height: 20),
      const Text('Line Spacing', style: TextStyle(color: Colors.white, fontSize: 14)),
      Slider(value: s.lineSpacing, min: 1.0, max: 3.0, divisions: 8, onChanged: (v) => s.setLineSpacing(v), activeColor: AppColors.primary, inactiveColor: Colors.white.withAlpha(30)),
      const SizedBox(height: 12),
      const Text('Theme', style: TextStyle(color: Colors.white, fontSize: 14)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(ReaderSettingsProvider.readerThemes.length, (i) {
        final t = ReaderSettingsProvider.readerThemes[i]; final sel = s.readerThemeIndex == i;
        return GestureDetector(onTap: () => s.setReaderTheme(i), child: Container(width: 48, height: 48,
          decoration: BoxDecoration(color: t['bg'], borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppColors.primary : Colors.white.withAlpha(30), width: sel ? 2.5 : 1)),
          child: Center(child: Text('Aa', style: TextStyle(color: t['text'], fontWeight: FontWeight.w600, fontSize: 14)))));
      })),
    ]),
  );

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: AppColors.primary, size: 20)));

  void _addBookmark() {
    context.read<DocumentProvider>().addBookmark(widget.document.id, _currentPage, title: 'Page $_currentPage');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmarked page $_currentPage'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: AppColors.primary));
  }
}
