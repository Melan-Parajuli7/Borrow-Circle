import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/group_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/item_model.dart';

/// "List a New Item" - also used to EDIT an item when [editItem] is given.
class AddItemPage extends StatefulWidget {
  final ItemModel? editItem;

  /// When coming from "Create group" on the groups screen.
  final String? presetGroupName;

  const AddItemPage({super.key, this.editItem, this.presetGroupName});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  static const _newGroupValue = '__new__';

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _newGroupName = TextEditingController();

  bool _isGroup = false;
  String? _groupChoice; // an existing group name, or _newGroupValue
  String? _category;
  String _condition = 'good';

  String? _imagePath; // new photo picked from the gallery
  Uint8List? _imageBytes; // preview of that photo

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description ?? '';
      _isGroup = e.isGroupItem;
      _groupChoice = e.groupName;
      _category = e.category;
      _condition = e.condition;
    } else if (widget.presetGroupName != null) {
      _isGroup = true;
      _newGroupName.text = widget.presetGroupName!;
      _groupChoice = _newGroupValue;
    }
    // we need the list of existing groups for the dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<GroupController>().load());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _newGroupName.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imagePath = picked.path;
      _imageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? groupName;
    if (_isGroup) {
      groupName = _groupChoice == _newGroupValue ? _newGroupName.text.trim() : _groupChoice;
      if (groupName == null || groupName.isEmpty) {
        showSnack(context, 'Please choose or create a group', isError: true);
        return;
      }
    }

    final ctrl = context.read<ItemController>();
    ItemModel? result;
    if (_isEdit) {
      result = await ctrl.updateItem(
        widget.editItem!.id,
        title: _title.text,
        description: _description.text,
        category: _category,
        condition: _condition,
        isGroupItem: _isGroup,
        groupName: groupName,
        imagePath: _imagePath,
      );
    } else {
      result = await ctrl.createItem(
        title: _title.text,
        description: _description.text,
        category: _category,
        condition: _condition,
        isGroupItem: _isGroup,
        groupName: groupName,
        imagePath: _imagePath,
      );
    }

    if (!mounted) return;
    if (result != null) {
      context.read<GroupController>().load(); // a new group may exist now
      Navigator.pop(context);
      showSnack(context, _isEdit ? 'Item updated' : 'Item published!');
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not save the item', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ItemController>().isSaving;
    final groupNames = context.watch<GroupController>().groups.map((g) => g.name).toList();
    // keep the item's current group in the list when editing
    if (_groupChoice != null && _groupChoice != _newGroupValue && !groupNames.contains(_groupChoice)) {
      groupNames.add(_groupChoice!);
    }
    final categories = [...AppStatic.categories];
    if (_category != null && !categories.contains(_category)) categories.add(_category!);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: _isEdit ? 'Edit item' : 'List a New Item'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Who are you listing for?',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeCard(
                              icon: Icons.person_outline,
                              title: 'Individual',
                              subtitle: 'Your own item',
                              selected: !_isGroup,
                              onTap: () => setState(() => _isGroup = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeCard(
                              icon: Icons.groups_outlined,
                              title: 'Group',
                              subtitle: 'Shared inventory',
                              selected: _isGroup,
                              onTap: () => setState(() => _isGroup = true),
                            ),
                          ),
                        ],
                      ),

                      // ---- group dropdown (only for group items) ----
                      if (_isGroup) ...[
                        const SizedBox(height: 18),
                        const Text('List under group', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _groupChoice,
                          isExpanded: true,
                          hint: const Text('Choose a group'),
                          items: [
                            for (final n in groupNames) DropdownMenuItem(value: n, child: Text(n)),
                            const DropdownMenuItem(value: _newGroupValue, child: Text('+ Create a new group')),
                          ],
                          onChanged: (v) => setState(() => _groupChoice = v),
                        ),
                        if (_groupChoice == _newGroupValue) ...[
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _newGroupName,
                            label: 'New group name',
                            hint: 'e.g. IoT Group',
                            maxLength: 100,
                            validator: Validators.groupName,
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),

                      // ---- photo ----
                      Row(
                        children: [
                          if (_imageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(_imageBytes!, width: 100, height: 100, fit: BoxFit.cover),
                            )
                          else if (_isEdit && widget.editItem!.imageUrl != null)
                            NetImage(
                                url: AppStatic.imageUrl(widget.editItem!.imageUrl),
                                width: 100,
                                height: 100,
                                radius: 16),
                          if (_imageBytes != null || (_isEdit && widget.editItem!.imageUrl != null))
                            const SizedBox(width: 12),
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryLightActive),
                              ),
                              child: const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 32),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Show the item\u2019s condition.', style: TextStyle(color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      AppTextField(
                        controller: _title,
                        label: 'Item name',
                        hint: 'Arduino Uno project kit',
                        maxLength: 150,
                        validator: Validators.itemTitle,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  isExpanded: true,
                                  hint: const Text('Select'),
                                  items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
                                  onChanged: (v) => setState(() => _category = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _condition,
                                  isExpanded: true,
                                  items: [
                                    for (final c in AppStatic.conditions)
                                      DropdownMenuItem(value: c, child: Text(AppStatic.pretty(c))),
                                  ],
                                  onChanged: (v) => setState(() => _condition = v ?? 'good'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _description,
                        label: 'Description',
                        hint: 'Uno board, breadboard, USB cable and jumper wires. Tested and ready for projects.',
                        maxLines: 4,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: 12),
                      if (_isGroup)
                        const Text(
                          'Group coordinators can manage requests for this item.',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: _isEdit ? 'Save changes' : (_isGroup ? 'Publish Group Listing' : 'Publish Listing'),
                icon: Icons.send_outlined,
                isLoading: saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                Icon(selected ? Icons.check_circle_outline : Icons.circle_outlined,
                    color: selected ? AppColors.primary : AppColors.primaryLightActive),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Text(subtitle, style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}
