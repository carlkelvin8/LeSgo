import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../controllers/merchantside/merchant_add_category_form_controller.dart';
import '../../../provider/main/merchantside/merchant_add_category_form_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/main/merchantside/menu/add_category/merchant_category_image_upload_section.dart';

class MerchantMenuAddCategoryScreen extends ConsumerStatefulWidget {
  final MenuCategoryDto? editingCategory;

  const MerchantMenuAddCategoryScreen({
    super.key,
    this.editingCategory,
  });

  @override
  ConsumerState<MerchantMenuAddCategoryScreen> createState() =>
      _MerchantMenuAddCategoryScreenState();
}

class _MerchantMenuAddCategoryScreenState
    extends ConsumerState<MerchantMenuAddCategoryScreen>
    with TickerProviderStateMixin {
  late MerchantAddCategoryFormController _controller;
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  bool get _isEditMode => widget.editingCategory != null;

  @override
  void initState() {
    super.initState();
    final category = widget.editingCategory;
    _controller = MerchantAddCategoryFormController(
      initialCategoryName: category?.name,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(merchantAddCategoryFormProvider.notifier);
      if (category != null) {
        notifier.initForEdit(
          categoryId: category.id,
          name: category.name,
          iconEmoji: category.iconEmoji,
          imageUrl: category.imageUrl,
        );
      } else {
        notifier.reset();
      }
    });
    _controller.categoryNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entrance.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((i * .10).clamp(0.0, .5), 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: fade.drive(
          Tween(begin: const Offset(0, .04), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        HapticFeedback.lightImpact();
        ref
            .read(merchantAddCategoryFormProvider.notifier)
            .updateImagePath(image.path);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to pick image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(merchantAddCategoryFormProvider);
    final notifier = ref.read(merchantAddCategoryFormProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(merchantAddCategoryFormProvider, (previous, next) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
      }
      if (next.isSubmitting == false &&
          previous?.isSubmitting == true &&
          next.errorMessage == null) {
        SnackBarUtils.showSuccess(
          context,
          _isEditMode ? 'Category updated!' : 'Category created!',
        );
        Navigator.pop(context);
      }
    });

    return MerchantFormLayout(
      formKey: _controller.formKey,
      stickyBottomAction: MerchantFormActionButtonsSection(
        onDiscard: () => Navigator.pop(context),
        onSubmit: () {
          HapticFeedback.lightImpact();
          if (_controller.formKey.currentState!.validate()) {
            notifier.updateCategoryName(
                _controller.categoryNameController.text);
            notifier.attemptSubmit();
          }
        },
        submitLabel: _isEditMode ? 'Save Changes' : 'Create Category',
        isSubmitting: formState.isSubmitting,
      ),
      children: [
        // ── Title ─────────────────────────────────────────────────────
        _reveal(
          0,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Category' : 'New Category',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditMode
                    ? 'Update this menu category.'
                    : 'Add a new section to your menu.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF9A85B8)
                      : const Color(0xFFAA90C0),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Name field ────────────────────────────────────────────────
        _reveal(
          1,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label: 'CATEGORY NAME', isDark: isDark),
              const SizedBox(height: 8),
              _StyledTextField(
                controller: _controller.categoryNameController,
                hint: 'e.g., Coffee, Appetizers, Desserts',
                icon: Icons.category_outlined,
                isDark: isDark,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Category name is required'
                        : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Category Image (full width) ───────────────────────────────
        _reveal(
          2,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label: 'CATEGORY IMAGE', isDark: isDark),
              const SizedBox(height: 8),
              MerchantCategoryImageUploadSection(
                uploadedImagePath: formState.previewImageSource,
                onTap: _pickImage,
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const SizedBox(height: 20),

        // ── Pro tip ───────────────────────────────────────────────────
        _reveal(
          4,
          _ProTip(
            text: _isEditMode
                ? 'Updating the name or image will reflect across all items in this category.'
                : 'Use clear, descriptive names so customers can quickly find what they\'re looking for.',
            isDark: isDark,
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: isDark ? const Color(0xFF9A85B8) : const Color(0xFFAA90C0),
    ),
  );
}

// ─── Styled text field ────────────────────────────────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF1A0A2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 14,
          color: isDark
              ? const Color(0xFF9A85B8).withValues(alpha: .6)
              : const Color(0xFFCCBBDD),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Icon(icon, size: 18, color: const Color(0xFF9B70CC)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: .05)
            : const Color(0xFFFAF7FD),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2540)
                : const Color(0xFFEAE0F2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2540)
                : const Color(0xFFEAE0F2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFF7B3FAA), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFFE05050), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFFE05050), width: 1.8),
        ),
      ),
    );
  }
}

// ─── Pro tip ──────────────────────────────────────────────────────────────────
class _ProTip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _ProTip({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF5F2D82).withValues(alpha: .12)
            : const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5F2D82).withValues(alpha: .18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF5F2D82).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 15,
              color: Color(0xFF8B55CC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12.5,
                height: 1.5,
                color: isDark
                    ? const Color(0xFFD4C8E8)
                    : const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
