import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:finetodo/logic/bloc/task/task_bloc.dart';
import 'package:finetodo/logic/bloc/task_form/task_form_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finetodo/logic/bloc/category/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:finetodo/data/models/task_model.dart';

class UpdateTaskDialog extends StatelessWidget {
  final String taskId;

  const UpdateTaskDialog({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);
    final recurrencePatterns = ['Daily', 'Weekly', 'Monthly'];

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              TaskFormBloc(taskBloc: context.read<TaskBloc>())
                ..add(LoadTaskForEditEvent(taskId: taskId)),
        ),
      ],
      child: _UpdateTaskDialogContent(
        primaryColor: primaryColor,
        lighterColor: lighterColor,
        recurrencePatterns: recurrencePatterns,
      ),
    );
  }
}

class _UpdateTaskDialogContent extends StatelessWidget {
  final Color primaryColor;
  final Color lighterColor;
  final List<String> recurrencePatterns;

  // Use late final variables to store form data
  late final TextEditingController titleController = TextEditingController();
  late final TextEditingController descController = TextEditingController();

  _UpdateTaskDialogContent({
    required this.primaryColor,
    required this.lighterColor,
    required this.recurrencePatterns,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskFormBloc, TaskFormState>(
      listener: (context, state) {
        if (state is TaskFormSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is TaskFormFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );

          if (state.errorMessage.contains('not found')) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop();
            });
          }
        }
      },
      builder: (context, state) {
        // Initialize form data when we first load the task
        if (state is TaskFormLoadingState) {
          // Load the task data into controllers
          final task = state.initialTask;
          if (titleController.text.isEmpty) {
            titleController.text = task.title;
          }
          if (descController.text.isEmpty && task.description != "") {
            descController.text = task.description;
          }
        }

        // Show loading while initializing
        if (state is TaskFormSubmittingState) {
          return _buildLoadingDialog('Updating task...');
        }

        // Show initial loading
        if (state is! TaskFormLoadingState && state is! TaskFormReadyState) {
          return _buildLoadingDialog('Loading task...');
        }

        // Now build the form with the loaded data
        return _buildForm(context, state);
      },
    );
  }

  Widget _buildLoadingDialog(String message) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading task...'),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, TaskFormState state) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: primaryColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, lighterColor],
                ),
              ),
              child: const Text(
                'Edit Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task Name
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TASK NAME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      onChanged: (value) {
                        context.read<TaskFormBloc>().add(
                          UpdateFormTitleEvent(value),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter task name...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, catState) {
                        List<Category> categories = [];
                        if (catState is CategoriesLoadedState) {
                          categories = List.from(catState.categories);
                        }

                        // Filter out protected categories except 'General'
                        final availableCategories = categories.where((
                          category,
                        ) {
                          return category.title == 'General' ||
                              (!_isProtectedCategory(category) &&
                                  category.title != 'All' &&
                                  category.title != 'Completed' &&
                                  category.title != 'Pending');
                        }).toList();

                        // Sort categories alphabetically
                        availableCategories.sort(
                          (a, b) => a.title.compareTo(b.title),
                        );

                        // Find the current selected category by ID
                        Category? selectedCategory;
                        if (state.categoryId != null) {
                          selectedCategory = availableCategories.firstWhere(
                            (cat) => cat.id == state.categoryId,
                            orElse: () => availableCategories.firstWhere(
                              (cat) => cat.title == 'General',
                              orElse: () => availableCategories.isNotEmpty
                                  ? availableCategories.first
                                  : Category(id: 'general', title: 'General'),
                            ),
                          );
                        } else if (state is TaskFormLoadingState) {
                          // Use the task's category when first loading
                          final task = state.initialTask;
                          selectedCategory = availableCategories.firstWhere(
                            (cat) => cat.id == task.category?.id,
                            orElse: () => availableCategories.firstWhere(
                              (cat) => cat.title == 'General',
                              orElse: () => availableCategories.isNotEmpty
                                  ? availableCategories.first
                                  : Category(id: 'general', title: 'General'),
                            ),
                          );
                        } else if (availableCategories.isNotEmpty) {
                          selectedCategory = availableCategories.firstWhere(
                            (cat) => cat.title == 'General',
                            orElse: () => availableCategories.first,
                          );
                        }

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<Category>(
                              value: selectedCategory,
                              items: availableCategories.map((
                                Category category,
                              ) {
                                return DropdownMenuItem<Category>(
                                  value: category,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      category.title,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (Category? newCategory) {
                                if (newCategory != null) {
                                  context.read<TaskFormBloc>().add(
                                    UpdateFormCategoryEvent(newCategory.id),
                                  );
                                }
                              },
                              buttonStyleData: const ButtonStyleData(
                                height: 50,
                                padding: EdgeInsets.only(left: 12, right: 8),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 350,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      onChanged: (value) {
                        context.read<TaskFormBloc>().add(
                          UpdateFormDescriptionEvent(value),
                        );
                      },
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add description...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              state.dueDate != null
                                  ? '${state.dueDate!.month}/${state.dueDate!.day}/${state.dueDate!.year}'
                                  : (state is TaskFormLoadingState &&
                                        state.initialTask.dueDate != null)
                                  ? '${state.initialTask.dueDate!.month}/${state.initialTask.dueDate!.day}/${state.initialTask.dueDate!.year}'
                                  : 'mm/dd/yyyy',
                              style: TextStyle(
                                color:
                                    (state.dueDate != null ||
                                        (state is TaskFormLoadingState &&
                                            state.initialTask.dueDate != null))
                                    ? Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            DateTime? initialDate;

                            if (state is TaskFormLoadingState) {
                              initialDate = state.initialTask.dueDate ?? now;
                            } else {
                              initialDate = state.dueDate ?? now;
                            }

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(now.year - 5),
                              lastDate: DateTime(now.year + 10),
                            );
                            if (picked != null) {
                              context.read<TaskFormBloc>().add(
                                UpdateFormDueDateEvent(picked),
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Is Recurring
                    Row(
                      children: [
                        Checkbox(
                          value:
                              state.isRecurring ||
                              (state is TaskFormLoadingState &&
                                  state.initialTask.isRecurring),
                          onChanged: (value) {
                            context.read<TaskFormBloc>().add(
                              UpdateFormRecurringEvent(value ?? false),
                            );
                          },
                        ),
                        const Text('Is Recurring'),
                      ],
                    ),

                    // Recurrence Pattern
                    if (state.isRecurring ||
                        (state is TaskFormLoadingState &&
                            state.initialTask.isRecurring)) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RECURRENCE PATTERN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            value: state.recurrencePattern != null
                                ? state.recurrencePattern![0].toUpperCase() +
                                      state.recurrencePattern!.substring(1)
                                : (state is TaskFormLoadingState &&
                                      state.initialTask.recurrencePattern !=
                                          null)
                                ? state.initialTask.recurrencePattern![0]
                                          .toUpperCase() +
                                      state.initialTask.recurrencePattern!
                                          .substring(1)
                                : null,
                            items: recurrencePatterns.map((String pattern) {
                              return DropdownMenuItem<String>(
                                value: pattern,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    pattern,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newPattern) {
                              context.read<TaskFormBloc>().add(
                                UpdateFormRecurrencePatternEvent(
                                  newPattern?.toLowerCase(),
                                ),
                              );
                            },
                            buttonStyleData: const ButtonStyleData(
                              height: 50,
                              padding: EdgeInsets.only(left: 12, right: 8),
                            ),
                            iconStyleData: const IconStyleData(
                              icon: Icon(Icons.arrow_drop_down),
                              iconSize: 24,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            hint: const Text('Select pattern...'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<TaskFormBloc>().add(
                                ResetFormEvent(),
                              );
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              // Validate title
                              if (titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task name cannot be empty'),
                                  ),
                                );
                                return;
                              }

                              // Trigger update
                              context.read<TaskFormBloc>().add(
                                UpdateTaskFormEvent(),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to check if a category is protected
  bool _isProtectedCategory(Category category) {
    return category.title == 'All' ||
        category.title == 'General' ||
        category.title == 'Completed' ||
        category.title == 'Pending';
  }
}
