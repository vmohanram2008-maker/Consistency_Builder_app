import 'package:flutter/material.dart';
import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/services/temporary_storage.dart';
import 'package:consistency_builder/widgets/glow_action_button.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.task});

  final DailyTask? task;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskType _selectedTaskType;
  late bool _reminderEnabled;
  late Duration? _reminderDuration;
  late int? _notificationId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.date ?? DateTime.now();
    _selectedTime = widget.task?.time ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedTaskType = widget.task?.taskType ?? TaskType.daily;
    _reminderEnabled = widget.task?.reminderEnabled ?? false;
    _reminderDuration = widget.task?.reminderDuration;
    _notificationId = widget.task?.notificationId;
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickReminderDuration() async {
    final durations = <Duration>[
      const Duration(minutes: 3),
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
    ];

    final picked = await showModalBottomSheet<Duration>(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            const ListTile(title: Text('Select reminder')),
            ...durations.map((duration) => ListTile(
                  title: Text(_formatDuration(duration)),
                  onTap: () => Navigator.of(context).pop(duration),
                )),
            ListTile(
              title: const Text('Custom'),
              onTap: () async {
                Navigator.of(context).pop();
                final custom = await showDialog<Duration>(
                  context: context,
                  builder: (dialogContext) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Custom reminder duration'),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            final value = int.tryParse(controller.text.trim());
                            if (value != null && value > 0) {
                              Navigator.of(dialogContext).pop(Duration(minutes: value));
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
                if (custom != null && mounted) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop(custom);
                }
              },
            ),
          ],
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderDuration = picked;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} Hour';
    }
    return '${duration.inMinutes} Minutes';
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final task = DailyTask(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      time: _selectedTime,
      taskType: _selectedTaskType,
      isCompleted: widget.task?.isCompleted ?? false,
      createdDate: widget.task?.createdDate ?? DateTime.now(),
      lastCompletedDate: widget.task?.lastCompletedDate,
      reminderEnabled: _reminderEnabled,
      reminderDuration: _reminderEnabled ? _reminderDuration : null,
      notificationId: _notificationId,
    );

    if (widget.task == null) {
      TemporaryStorage.instance.addDailyTask(task);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Added Successfully')),
      );
    } else {
      TemporaryStorage.instance.updateDailyTask(task);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Updated Successfully')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Daily Task' : 'Edit Daily Task'),
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
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a task name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFFEAF4FF)),
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Task Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFEAF4FF))),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskType>(
                    segments: TaskType.values.map((type) {
                      final label = switch (type) {
                        TaskType.daily => 'Daily',
                        TaskType.once => 'Once',
                        TaskType.followUp => 'Follow Up',
                      };
                      return ButtonSegment<TaskType>(
                        value: type,
                        label: Text(label),
                      );
                    }).toList(),
                    selected: {_selectedTaskType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedTaskType = selection.first;
                      });
                    },
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
                          Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Color(0xFFEAF4FF))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF102A43).withValues(alpha: 0.7),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_outlined, color: Color(0xFFB9D9FF)),
                          const SizedBox(width: 12),
                          Text('Time: ${_selectedTime.format(context)}', style: const TextStyle(color: Color(0xFFEAF4FF))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reminder Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFEAF4FF))),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reminder'),
                            value: _reminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _reminderEnabled = value;
                                if (!value) {
                                  _reminderDuration = null;
                                }
                              });
                            },
                          ),
                          if (_reminderEnabled)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Reminder Before Task'),
                              subtitle: Text(_reminderDuration == null ? 'Select a reminder duration' : _formatDuration(_reminderDuration!)),
                              trailing: const Icon(Icons.access_time_outlined),
                              onTap: _pickReminderDuration,
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
                          onPressed: _saveTask,
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
