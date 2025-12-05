import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../logic/bloc/task/task_bloc.dart';
import '../../logic/bloc/category/category_bloc.dart';
import '../../data/models/task_model.dart';

class TaskListWidget extends StatelessWidget {
  const TaskListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black12 : Colors.white70;
    final dropdownBackgroundColor = isDarkMode
        ? Colors.grey[900]
        : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        // This will be called whenever the TaskBloc state changes
        // You can add any specific logic here if needed when tasks change
        if (state is TaskErrorState) {
          // Show error snackbar if there's an error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, catState) {
          // derive categories to show; always include 'All' and 'General'
          List<Category> categories = [];
          if (catState is CategoriesLoadedState) {
            categories = List.from(catState.categories);
          }

          // ensure primitive categories exist in the dropdown (they are UI placeholders)
          final defaultTitles = ['All', 'General', 'Completed', 'Pending'];
          for (final t in defaultTitles.reversed) {
            if (!categories.any((c) => c.title == t)) {
              categories.insert(0, Category(id: t.toLowerCase(), title: t));
            }
          }

          // ADD THIS SORTING CODE HERE:
          // Sort categories: protected ones first, then alphabetically
          final sortedCategories = List<Category>.from(categories)
            ..sort((a, b) {
              final isAProtected = _isProtectedCategory(a);
              final isBProtected = _isProtectedCategory(b);

              if (isAProtected == isBProtected) {
                return a.title.compareTo(b.title);
              }
              return isAProtected ? -1 : 1;
            });

          // determine currently selected category id from state
          String? selectedId;
          if (catState is CategoriesLoadedState) {
            selectedId = catState.selectedCategoryId;
          }
          selectedId ??= sortedCategories.isNotEmpty
              ? sortedCategories.first.id
              : 'all';
          final selectedCategory = sortedCategories.firstWhere(
            (c) => c.id == selectedId,
            orElse: () => sortedCategories.isNotEmpty
                ? sortedCategories.first
                : Category(id: 'all', title: 'All'),
          );

          return Column(
            children: [
              // Category selector row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: backgroundColor,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<Category>(
                            value: selectedCategory,
                            items: sortedCategories.map((Category category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    category.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? newCategory) {
                              if (newCategory != null) {
                                context.read<CategoryBloc>().add(
                                  SelectCategoryEvent(newCategory.id),
                                );
                              }
                            },
                            buttonStyleData: ButtonStyleData(
                              height: 50,
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: backgroundColor,
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: const Icon(Icons.arrow_drop_down),
                              iconEnabledColor: textColor,
                              iconSize: 24,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 350,
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: dropdownBackgroundColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              offset: const Offset(0, -8),
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(40),
                                thickness: MaterialStateProperty.all<double>(6),
                                thumbVisibility:
                                    MaterialStateProperty.all<bool>(true),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 48,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort button

                    // Category management button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'manage') {
                          _showCategoryManagementDialog(
                            context,
                            categories,
                            selectedCategory,
                          );
                        } else if (value == 'add') {
                          _showAddCategoryDialog(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text('Add Category'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'manage',
                          child: Row(
                            children: [
                              Icon(Icons.manage_search, size: 20),
                              SizedBox(width: 8),
                              Text('Manage Categories'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tasks area
              Expanded(
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    if (state is TasksLoadedState) {
                      final displayedTasks = selectedCategory.title == 'All'
                          ? state.tasks
                          : (selectedCategory.title == 'Completed')
                          ? state.tasks.where((t) => t.isCompleted).toList()
                          : (selectedCategory.title == 'Pending')
                          ? state.tasks.where((t) => !t.isCompleted).toList()
                          : state.tasks
                                .where(
                                  (t) => t.category.id == selectedCategory.id,
                                )
                                .toList();

                      if (displayedTasks.isEmpty) {
                        return const Center(
                          child: Text(
                            textAlign: TextAlign.center,
                            "No tasks added yet! \nTap the '+' to add your first task!",
                          ),
                        );
                      }
                      displayedTasks.sort((a, b) => a.title.compareTo(b.title));
                      return ListView.builder(
                        itemCount: displayedTasks.length,
                        itemBuilder: (context, index) {
                          final task = displayedTasks[index];
                          return TaskCardsad(task: task);
                        },
                      );
                    }

                    if (state is TaskErrorState) {
                      return Center(child: Text('Error: ${state.message}'));
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditTaskDialog(TaskModel task, BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime? selectedDate = task.dueDate;
    bool isRecurring = task.isRecurring;
    String? selectedRecurrencePattern = task.recurrencePattern;
    Category? selectedCategory = task.category;

    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);
    final recurrencePatterns = ['Daily', 'Weekly', 'Monthly'];

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
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

                    // Content
                    Padding(
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

                              // Ensure default categories exist
                              final defaultTitles = [
                                'All',
                                'General',
                                'Completed',
                                'Pending',
                              ];
                              for (final t in defaultTitles.reversed) {
                                if (!categories.any((c) => c.title == t)) {
                                  categories.insert(
                                    0,
                                    Category(id: t.toLowerCase(), title: t),
                                  );
                                }
                              }

                              // Sort categories
                              final sortedCategories =
                                  List<Category>.from(categories)..sort((a, b) {
                                    final isAProtected = _isProtectedCategory(
                                      a,
                                    );
                                    final isBProtected = _isProtectedCategory(
                                      b,
                                    );
                                    if (isAProtected == isBProtected) {
                                      return a.title.compareTo(b.title);
                                    }
                                    return isAProtected ? -1 : 1;
                                  });

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<Category>(
                                    value: selectedCategory,
                                    items: sortedCategories.map((
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
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (Category? newCategory) {
                                      setState(() {
                                        selectedCategory = newCategory;
                                      });
                                    },
                                    buttonStyleData: ButtonStyleData(
                                      height: 50,
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        right: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    iconStyleData: const IconStyleData(
                                      icon: Icon(Icons.arrow_drop_down),
                                      iconSize: 24,
                                    ),
                                    dropdownStyleData: DropdownStyleData(
                                      maxHeight: 350,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
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
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    selectedDate != null
                                        ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                        : 'mm/dd/yyyy',
                                    style: TextStyle(
                                      color: selectedDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? now,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: DateTime(now.year + 10),
                                  );
                                  if (picked != null) {
                                    setState(() => selectedDate = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
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
                                value: isRecurring,
                                onChanged: (value) {
                                  setState(() {
                                    isRecurring = value ?? false;
                                  });
                                },
                              ),
                              const Text('Is Recurring'),
                            ],
                          ),

                          // Recurrence Pattern (only show if recurring is true)
                          if (isRecurring) ...[
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
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  value: selectedRecurrencePattern,
                                  items: recurrencePatterns.map((
                                    String pattern,
                                  ) {
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
                                    setState(() {
                                      selectedRecurrencePattern = newPattern;
                                    });
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    height: 50,
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      right: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                    final title = titleController.text.trim();
                                    if (title.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Task name cannot be empty',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final updatedTask = task.copyWith(
                                      title: title,
                                      description: descController.text.trim(),
                                      category:
                                          selectedCategory ?? task.category,
                                      dueDate: selectedDate,
                                      isRecurring: isRecurring,
                                      recurrencePattern:
                                          selectedRecurrencePattern
                                              ?.toLowerCase(),
                                    );

                                    context.read<TaskBloc>().add(
                                      UpdateTaskEvent(updatedTask),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryManagementDialog(
    BuildContext context,
    List<Category> categories,
    Category selectedCategory,
  ) {
    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);

    showDialog<void>(
      context: context,
      builder: (context) {
        // Sort categories: protected ones first, then alphabetically
        final sortedCategories = List<Category>.from(categories)
          ..sort((a, b) {
            final isAProtected = _isProtectedCategory(a);
            final isBProtected = _isProtectedCategory(b);

            // If both are protected or both are not protected, sort alphabetically
            if (isAProtected == isBProtected) {
              return a.title.compareTo(b.title);
            }
            // Put protected categories before non-protected ones
            return isAProtected ? -1 : 1;
          });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
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
                    'Manage Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Categories list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, index) {
                            final cat = sortedCategories[index];
                            final isProtected = _isProtectedCategory(cat);
                            final isSelected = cat.id == selectedCategory.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: primaryColor.withOpacity(0.5),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),

                                title: Text(
                                  cat.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? primaryColor
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                                trailing: !isProtected
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: primaryColor,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _showEditCategoryDialog(
                                                context,
                                                cat,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _showDeleteCategoryDialog(
                                                context,
                                                cat,
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.lock,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                onTap: () {
                                  context.read<CategoryBloc>().add(
                                    SelectCategoryEvent(cat.id),
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showAddCategoryDialog(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add New',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to check if a category is protected
  bool _isProtectedCategory(Category category) {
    return category.title == 'All' ||
        category.title == 'General' ||
        category.title == 'Completed' ||
        category.title == 'Pending';
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
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
                    'Add Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Category name...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                final name = controller.text.trim();
                                if (name.isNotEmpty) {
                                  final newCat = Category(title: name);
                                  context.read<CategoryBloc>().add(
                                    AddCategoryEvent(newCat),
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category cat) {
    final controller = TextEditingController(text: cat.title);
    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
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
                    'Edit Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter new category name...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                final newName = controller.text.trim();
                                if (newName.isNotEmpty) {
                                  final updated = Category(
                                    id: cat.id,
                                    title: newName,
                                    taskIds: cat.taskIds,
                                  );
                                  context.read<CategoryBloc>().add(
                                    UpdateCategoryEvent(updated),
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, Category cat) {
    final errorColor = const Color(0xFFE53935);
    final lighterErrorColor = const Color(0xFFEF5350);

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: errorColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient header with error colors
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
                      colors: [errorColor, lighterErrorColor],
                    ),
                  ),
                  child: const Text(
                    'Delete Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete "${cat.title}"?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: errorColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: errorColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                context.read<CategoryBloc>().add(
                                  DeleteCategoryEvent(cat.id),
                                );
                                Navigator.of(context).pop();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: errorColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TaskCardsad extends StatelessWidget {
  final TaskModel task;

  const TaskCardsad({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.white,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onLongPressStart: (details) {
          final overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              overlay.size.width - details.globalPosition.dx,
              overlay.size.height - details.globalPosition.dy,
            ),
            items: [
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () {
                  // Use a post-frame callback to ensure the menu is closed before showing dialog
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showEditTaskDialog(context, task);
                  });
                },
              ),
              PopupMenuItem(
                child: const Text('Delete'),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
                  });
                },
              ),
            ],
          );
        },
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) {
              context.read<TaskBloc>().add(ToggleTaskEvent(task.id));
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(task.description),

          trailing: PopupMenuButton(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditTaskDialog(context, task);
              } else if (value == 'delete') {
                context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskModel task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime? selectedDate = task.dueDate;
    bool isRecurring = task.isRecurring;
    String? selectedRecurrencePattern = task.recurrencePattern;
    Category? selectedCategory = task.category;

    final primaryColor = const Color(0xFF5D5CDE);
    final lighterColor = const Color(0xFF7D7CFF);
    final recurrencePatterns = ['Daily', 'Weekly', 'Monthly'];

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
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

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
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
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (Category? newCategory) {
                                        if (newCategory != null) {
                                          setState(() {
                                            selectedCategory = newCategory;
                                          });
                                        }
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        height: 50,
                                        padding: EdgeInsets.only(
                                          left: 12,
                                          right: 8,
                                        ),
                                      ),
                                      iconStyleData: const IconStyleData(
                                        icon: Icon(Icons.arrow_drop_down),
                                        iconSize: 24,
                                      ),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 350,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
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
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      selectedDate != null
                                          ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                          : 'mm/dd/yyyy',
                                      style: TextStyle(
                                        color: selectedDate != null
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
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate ?? now,
                                      firstDate: DateTime(now.year - 5),
                                      lastDate: DateTime(now.year + 10),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = picked);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                  ),
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
                                  value: isRecurring,
                                  onChanged: (value) {
                                    setState(() {
                                      isRecurring = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Is Recurring'),
                              ],
                            ),

                            // Recurrence Pattern (only show if recurring is true)
                            if (isRecurring) ...[
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
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<String>(
                                    value: selectedRecurrencePattern != null
                                        ? selectedRecurrencePattern![0]
                                                  .toUpperCase() +
                                              selectedRecurrencePattern!
                                                  .substring(1)
                                        : null,
                                    items: recurrencePatterns.map((
                                      String pattern,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: pattern,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            pattern,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newPattern) {
                                      setState(() {
                                        selectedRecurrencePattern = newPattern
                                            ?.toLowerCase();
                                      });
                                    },
                                    buttonStyleData: const ButtonStyleData(
                                      height: 50,
                                      padding: EdgeInsets.only(
                                        left: 12,
                                        right: 8,
                                      ),
                                    ),
                                    iconStyleData: const IconStyleData(
                                      icon: Icon(Icons.arrow_drop_down),
                                      iconSize: 24,
                                    ),
                                    dropdownStyleData: DropdownStyleData(
                                      maxHeight: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                      final title = titleController.text.trim();
                                      if (title.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Task name cannot be empty',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final updatedTask = task.copyWith(
                                        title: title,
                                        description: descController.text.trim(),
                                        category:
                                            selectedCategory ?? task.category,
                                        dueDate: selectedDate,
                                        isRecurring: isRecurring,
                                        recurrencePattern:
                                            selectedRecurrencePattern,
                                      );

                                      context.read<TaskBloc>().add(
                                        UpdateTaskEvent(updatedTask),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Save Changes',
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
          },
        );
      },
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
