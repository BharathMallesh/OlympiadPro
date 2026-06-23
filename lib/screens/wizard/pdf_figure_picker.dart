import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// Pick a page from the uploaded question-paper PDF, then either attach the
/// WHOLE page (option B) or CROP a figure out of it (option D). Returns the
/// chosen image bytes (PNG), or null if cancelled.
class PdfFigurePicker extends StatefulWidget {
  const PdfFigurePicker(
      {super.key, required this.pdfBytes, this.initialPage = 1});
  final Uint8List pdfBytes;
  final int initialPage;

  @override
  State<PdfFigurePicker> createState() => _PdfFigurePickerState();
}

class _PdfFigurePickerState extends State<PdfFigurePicker> {
  final _crop = CropController();
  PdfDocument? _doc;
  int _pageCount = 0;
  int _page = 1;
  Uint8List? _pageImage;
  bool _loadingPage = true;
  bool _cropping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final doc = await PdfDocument.openData(widget.pdfBytes);
      _doc = doc;
      _pageCount = doc.pagesCount;
      await _renderPage(widget.initialPage.clamp(1, _pageCount));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not open the PDF: $e';
          _loadingPage = false;
        });
      }
    }
  }

  Future<void> _renderPage(int n) async {
    if (_doc == null) return;
    setState(() {
      _loadingPage = true;
      _page = n;
    });
    try {
      final page = await _doc!.getPage(n);
      final img = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      if (!mounted) return;
      setState(() {
        _pageImage = img?.bytes;
        _loadingPage = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not render page $n: $e';
          _loadingPage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _doc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title: Text('Add figure from PDF',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium)))
          : Column(children: [
              if (_pageCount > 1)
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.outline)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: _pageCount,
                    itemBuilder: (c, i) {
                      final n = i + 1;
                      final sel = n == _page;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: _loadingPage ? null : () => _renderPage(n),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            width: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.outlineStrong),
                            ),
                            child: Text('$n',
                                style: TextStyle(
                                    color: sel
                                        ? AppColors.onPrimary
                                        : AppColors.onSurface,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: _loadingPage || _pageImage == null
                    ? const Center(child: CircularProgressIndicator())
                    : Crop(
                        image: _pageImage!,
                        controller: _crop,
                        baseColor: AppColors.scaffold,
                        maskColor: Colors.black.withValues(alpha: 0.5),
                        onCropped: (result) {
                          if (!mounted) return;
                          setState(() => _cropping = false);
                          switch (result) {
                            case CropSuccess(:final croppedImage):
                              Navigator.pop(context, croppedImage);
                            case CropFailure():
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Crop failed — try again')));
                          }
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                    'Drag the handles to frame the figure, then "Crop & attach" — '
                    'or "Use whole page".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: AppButton('Use whole page',
                          kind: AppBtnKind.ghost,
                          expand: true,
                          onPressed: _pageImage == null
                              ? null
                              : () => Navigator.pop(context, _pageImage)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(_cropping ? 'Cropping…' : 'Crop & attach',
                          icon: Icons.crop,
                          expand: true,
                          onPressed: (_pageImage == null || _cropping)
                              ? null
                              : () {
                                  setState(() => _cropping = true);
                                  _crop.crop();
                                }),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}
