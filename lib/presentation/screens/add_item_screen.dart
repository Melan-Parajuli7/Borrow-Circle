import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/app_static.dart';
import '../utils/validators.dart';
import '../widgets/app_widgets.dart';
import '../viewmodels/item_viewmodel.dart';
import '../../data/models/item_model.dart';

/// Screen for creating or editing an item listing.
class AddItemScreen extends StatefulWidget {
  /// The item being edited, if any.
  final ItemModel? editItem;

  /// When set, the item is created as a group item under this group name.
  final String? presetGroupName;
  const AddItemScreen({super.key, this.editItem, this.presetGroupName});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _groupName = TextEditingController();

  String _condition = 'good';
  bool _isGroupItem = false;
  XFile? _image;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _populateFields(widget.editItem!);
    } else if (widget.presetGroupName != null) {
      _isGroupItem = true;
      _groupName.text = widget.presetGroupName!;
    }
  }

  void _populateFields(ItemModel item) {
    _title.text = item.title;
    _description.text = item.description ?? '';
    _category.text = item.category ?? '';
    _condition = item.condition;
    _isGroupItem = item.isGroupItem;
    _groupName.text = item.groupName ?? '';
    _existingImageUrl = item.imageUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _image = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final itemViewModel = context.read<ItemViewModel>();
    final bool ok;
    if (widget.editItem != null) {
      ok = await itemViewModel.updateItem(
        widget.editItem!.id,
        title: _title.text,
        description: _description.text.isEmpty ? null : _description.text,
        category: _category.text.isEmpty ? null : _category.text,
        condition: _condition,
        isGroupItem: _isGroupItem,
        groupName: _isGroupItem ? _groupName.text.trim() : null,
        imagePath: _image?.path,
      ) != null;
    } else {
      ok = await itemViewModel.createItem(
        title: _title.text,
        description: _description.text.isEmpty ? null : _description.text,
        category: _category.text.isEmpty ? null : _category.text,
        condition: _condition,
        isGroupItem: _isGroupItem,
        groupName: _isGroupItem ? _groupName.text.trim() : null,
        imagePath: _image?.path,
      ) != null;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showSnack(context, itemViewModel.error ?? 'Failed to save item', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemViewModel = context.watch<ItemViewModel>();
    final loading = itemViewModel.isSaving;
    final isEditing = widget.editItem != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(title: isEditing ? 'Edit item' : 'List an item'),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Update the details below.'
                      : 'Fill in the details below to list your item.',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Image picker
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      color: AppColors.surface,
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  AppStatic.imageUrl(_existingImageUrl)!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.textGrey),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.textGrey),
                                    SizedBox(height: 8),
                                    Text('Tap to add photo', style: TextStyle(color: AppColors.textGrey)),
                                  ],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                AppTextField(
                  controller: _title,
                  label: 'Title',
                  hint: 'e.g., MacBook Pro 13"',
                  validator: Validators.itemTitle,
                ),
                const SizedBox(height: 16),

                // Description
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  hint: 'Condition, accessories, etc.',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Category
                AppTextField(
                  controller: _category,
                  label: 'Category (optional)',
                  hint: 'Electronics, Textbooks, etc.',
                ),
                const SizedBox(height: 16),

                // Condition
                Text('Condition', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppStatic.conditions.map((c) {
                    final selected = c == _condition;
                    return ChoiceChip(
                      label: Text(AppStatic.pretty(c)),
                      selected: selected,
                      onSelected: (_) => setState(() => _condition = c),
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Group item toggle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Group item',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark),
                      ),
                    ),
                    Switch(
                      value: _isGroupItem,
                      onChanged: (v) => setState(() => _isGroupItem = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                if (_isGroupItem) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _groupName,
                    label: 'Group name',
                    hint: 'e.g., IoT Club',
                    validator: Validators.groupName,
                  ),
                ],

                const SizedBox(height: 32),
                PrimaryButton(
                  text: isEditing ? 'Save Changes' : 'List Item',
                  icon: Icons.arrow_forward,
                  isLoading: loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
