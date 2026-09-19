import 'package:flutter/material.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/services/temporary_storage.dart';
import 'package:consistency_builder/widgets/glow_action_button.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key, this.goal});

  final Goal? goal;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _descriptionController = TextEditingController(text: widget.goal?.description ?? '');
    _selectedDate = widget.goal?.targetDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final goal = Goal(
      id: widget.goal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      targetDate: _selectedDate,
      isCompleted: widget.goal?.isCompleted ?? false,
      createdDate: widget.goal?.createdDate ?? DateTime.now(),
    );

    if (widget.goal == null) {
      TemporaryStorage.instance.addGoal(goal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal Added Successfully')),
      );
    } else {
      TemporaryStorage.instance.updateGoal(goal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal Updated Successfully')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071B2D),
              Color(0xFF0C213A),
              Color(0xFF122B4E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Color(0xFFEAF4FF)),
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a goal name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFFEAF4FF)),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF102A43).withValues(alpha: 0.7),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFFB9D9FF)),
                          const SizedBox(width: 12),
                          Text(
                            'Target Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(color: Color(0xFFEAF4FF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GlowActionButton(
                          onPressed: () => Navigator.of(context).pop(),
                          label: const Text('Cancel'),
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlowActionButton(
                          onPressed: _saveGoal,
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
