import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../data/repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';
import 'pdf_figure_picker.dart';

class EditQuestionScreen extends StatefulWidget {
  const EditQuestionScreen({super.key, required this.index, this.returnTo});

  /// Index into the question store, or -1 to author a new question (#11).
  final int index;

  /// Route to fall back to when not pushed (e.g. '/bank').
  final String? returnTo;

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  late final QuestionItem q;
  late final TextEditingController _prompt;
  final _picker = ImagePicker();
  bool _picking = false;
  late final bool _creating;

  static const _types = ['Multiple Choice', 'Numeric', 'Short Answer', 'True/False'];

  String get _fallback => widget.returnTo ?? '/wizard/ai-review';

  @override
  void initState() {
    super.initState();
    _creating = widget.index < 0;
    if (_creating) {
      // New blank question; only added to the store on save.
      q = QuestionItem(
        label: 'Q${questionStore.questions.length + 1}',
        prompt: '',
        type: 'Multiple Choice',
        status: QStatus.parsed,
        options: [QuestionOption(''), QuestionOption('')],
      );
    } else {
      final i = widget.index.clamp(0, questionStore.questions.length - 1);
      q = questionStore.questions[i];
    }
    _prompt = TextEditingController(text: q.prompt);
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _addImage(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => q.images.add(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add image: $e')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Crop a figure out of the uploaded question-paper PDF (option B/D), in-app.
  Future<void> _addFromPdf() async {
    final bytes = examDraft.paperBytes;
    if (bytes == null) return;
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => PdfFigurePicker(pdfBytes: bytes)),
    );
    if (result != null && mounted) setState(() => q.images.add(result));
  }

  void _chooseSource() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            if (examDraft.paperBytes != null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.primary),
                title: const Text('Crop from the uploaded PDF'),
                subtitle: Text('Pick a page and crop the figure',
                    style: Theme.of(context).textTheme.bodySmall),
                onTap: () {
                  Navigator.pop(ctx);
                  _addFromPdf();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              subtitle: Text('Use the device camera',
                  style: Theme.of(context).textTheme.bodySmall),
              onTap: () {
                Navigator.pop(ctx);
                _addImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              subtitle: Text('Pick an image from your device',
                  style: Theme.of(context).textTheme.bodySmall),
              onTap: () {
                Navigator.pop(ctx);
                _addImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    q.prompt = _prompt.text;
    // A teacher-reviewed question counts as parsed/reviewed.
    q.status = QStatus.parsed;
    q.warning = null;
    try {
      if (q.id == null) {
        final created = await Repo.createQuestion(q.toApi());
        q.id = created['id'] as String;
      } else {
        await Repo.updateQuestion(q.id!, q.toApi());
      }
      // Push locally added images through the backend to Cloudinary.
      while (q.images.isNotEmpty) {
        final bytes = q.images.first;
        final updated =
            await Repo.uploadQuestionImage(q.id!, bytes, 'attachment.png');
        q.imageUrls
          ..clear()
          ..addAll((updated['image_urls'] as List).cast<String>());
        q.images.removeAt(0);
      }
      if (_creating) questionStore.questions.add(q);
      questionStore.touch();
      if (mounted) popOrGo(context, _fallback);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeRemoteImage(String url) async {
    if (q.id == null) return;
    try {
      final updated = await Repo.removeQuestionImage(q.id!, url);
      setState(() {
        q.imageUrls
          ..clear()
          ..addAll((updated['image_urls'] as List).cast<String>());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: _fallback,
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => popOrGo(context, _fallback)),
        title: Text(_creating ? 'New Question' : 'Edit ${q.label}',
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          AppButton(_saving ? 'Saving…' : 'Save', kind: AppBtnKind.secondary,
              icon: Icons.check, onPressed: _save),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + type
                Row(children: [
                  StatusChip(
                    q.status == QStatus.parsed ? 'Auto-Parsed' : 'Review Needed',
                    color: q.status == QStatus.parsed
                        ? AppColors.success
                        : AppColors.secondary,
                    icon: q.status == QStatus.parsed ? Icons.check : Icons.visibility,
                  ),
                  const Spacer(),
                  Text('Type', style: AppTheme.mono(10, FontWeight.w500)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _TypeDropdown(
                      value: _types.contains(q.type) ? q.type : _types.first,
                      items: _types,
                      onChanged: (v) => setState(() => q.type = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Question prompt
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Question', icon: Icons.help_outline),
                      const SizedBox(height: 14),
                      const FieldLabel('Question Prompt (LaTeX supported)'),
                      AppInput(controller: _prompt, maxLines: 3,
                          hint: r'e.g. \int_0^\pi \sin(x)\,dx',
                          onChanged: (_) => setState(() {})),
                      const SizedBox(height: 12),
                      // Live preview.
                      const FieldLabel('Preview'),
                      MixedMathText(_prompt.text.isEmpty ? '-' : _prompt.text,
                          fontSize: 16, color: AppColors.onSurface),

                      // ---- Image attachments: directly below the question ----
                      const SizedBox(height: 20),
                      Row(children: [
                        const FieldLabel('Attached Images'),
                        const Spacer(),
                        if (q.images.isNotEmpty || q.imageUrls.isNotEmpty)
                          Text(
                              '${q.images.length + q.imageUrls.length} attached',
                              style: AppTheme.mono(10, FontWeight.w500)),
                      ]),
                      _ImageStrip(
                        images: q.images,
                        imageUrls: q.imageUrls,
                        picking: _picking,
                        onAdd: _chooseSource,
                        onRemove: (i) => setState(() => q.images.removeAt(i)),
                        onRemoveUrl: _removeRemoteImage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Answer options
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: SectionTitle('Answer Options',
                                icon: Icons.checklist_rtl)),
                        Text('Tap the circle to mark correct',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                      const SizedBox(height: 14),
                      if (q.options.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('No options yet — add one below.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      for (var i = 0; i < q.options.length; i++)
                        _OptionRow(
                          key: ObjectKey(q.options[i]),
                          index: i,
                          option: q.options[i],
                          onCorrect: () {
                            setState(() {
                              // single correct answer for MC/TF
                              for (final o in q.options) {
                                o.correct = false;
                              }
                              q.options[i].correct = true;
                            });
                          },
                          onChanged: (v) => q.options[i].text = v,
                          onRemove: () => setState(() => q.options.removeAt(i)),
                        ),
                      const SizedBox(height: 6),
                      AppButton('Add Option',
                          kind: AppBtnKind.ghost,
                          icon: Icons.add,
                          onPressed: () => setState(
                              () => q.options.add(QuestionOption('')))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  AppButton('Cancel', kind: AppBtnKind.ghost,
                      onPressed: () => popOrGo(context, _fallback)),
                  const Spacer(),
                  AppButton(_saving ? 'Saving…' : 'Save Question',
                      kind: AppBtnKind.secondary,
                      trailingIcon: Icons.check,
                      onPressed: _save),
                ]),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Horizontal strip of attachment thumbnails + an "Add" tile. Shows both
/// already-uploaded Cloudinary images and freshly picked local ones.
class _ImageStrip extends StatelessWidget {
  const _ImageStrip({
    required this.images,
    required this.imageUrls,
    required this.picking,
    required this.onAdd,
    required this.onRemove,
    required this.onRemoveUrl,
  });
  final List<Uint8List> images;
  final List<String> imageUrls;
  final bool picking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<String> onRemoveUrl;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final url in imageUrls)
          _Thumb(url: url, onRemove: () => onRemoveUrl(url)),
        for (var i = 0; i < images.length; i++)
          _Thumb(bytes: images[i], onRemove: () => onRemove(i)),
        // Add tile (dashed look)
        InkWell(
          onTap: picking ? null : onAdd,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outlineStrong),
            ),
            child: picking
                ? const Center(
                    child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 26),
                      const SizedBox(height: 6),
                      Text('Add Image',
                          style: AppTheme.mono(9.5, FontWeight.w600,
                              color: AppColors.primary, ls: 0.5)),
                      Text('Camera / Gallery',
                          style: AppTheme.mono(8, FontWeight.w500)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.bytes, this.url, required this.onRemove});
  final Uint8List? bytes;
  final String? url;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: bytes != null
              ? Image.memory(bytes!,
                  width: 110, height: 110, fit: BoxFit.cover)
              : Image.network(url!,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: AppColors.surfaceContainer,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.muted))),
        ),
        Positioned(
          top: 4, right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.index,
    required this.option,
    required this.onCorrect,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final QuestionOption option;
  final VoidCallback onCorrect;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index); // A, B, C...
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        // correct toggle
        InkWell(
          onTap: onCorrect,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Icon(
            option.correct ? Icons.check_circle : Icons.radio_button_unchecked,
            color: option.correct ? AppColors.success : AppColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 26, height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.outline),
          ),
          child: Text(letter,
              style: AppTheme.mono(12, FontWeight.w700, color: AppColors.onSurface)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            initialValue: option.text,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Option $letter',
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.scaffold,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(
                    color: option.correct
                        ? AppColors.success.withValues(alpha: 0.6)
                        : AppColors.outlineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
          tooltip: 'Remove option',
        ),
      ]),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown(
      {required this.value, required this.items, required this.onChanged});
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: AppColors.surfaceHigh,
          style: AppTheme.mono(12, FontWeight.w600, color: AppColors.onSurface),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 18),
          items: [
            for (final t in items)
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}
