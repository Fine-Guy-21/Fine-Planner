import 'package:finetodo/logic/bloc/task_form/task_form_bloc.dart';
import 'package:finetodo/presentation/widgets/update_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../logic/bloc/task/task_bloc.dart';
import '../../logic/bloc/category/category_bloc.dart';
import '../../data/models/task_model.dart';
import '../widgets/task_card.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black12 : Colors.white70;
    final dropdownBackgroundColor = isDarkMode
        ? Colors.grey[900]
        : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!;

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        // derive categories to show; always include 'All' and 'General'
        List<Category> categories = [];
        if (categoryState is CategoriesLoadedState) {
          categories = List.from(categoryState.categories);
        }

        // ensure primitive categories exist in the dropdown (they are UI placeholders)
        final defaultTitles = ['All', 'General', 'Completed', 'Pending'];
        for (final t in defaultTitles.reversed) {
          if (!categories.any((c) => c.title == t)) {
            categories.insert(0, Category(id: t.toLowerCase(), title: t));
          }
        }

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
        if (categoryState is CategoriesLoadedState) {
          selectedId = categoryState.selectedCategoryId;
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            padding: const EdgeInsets.only(left: 12, right: 8),
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
                              thumbVisibility: MaterialStateProperty.all<bool>(
                                true,
                              ),
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

            // Task Lists (filtered by selecterCategory)
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, taskState) {
                  if (taskState is TasksLoadedState) {
                    final displayedTasks = selectedCategory.title == 'All'
                        ? taskState.tasks
                        : (selectedCategory.title == 'Completed')
                        ? taskState.tasks.where((t) => t.isCompleted).toList()
                        : (selectedCategory.title == 'Pending')
                        ? taskState.tasks.where((t) => !t.isCompleted).toList()
                        : taskState.tasks
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
                        return TaskCard(
                          task: task,
                          onEdit: (taskId) {
                            _showEditTaskDialog(context, taskId);
                          },
                          onDelete: (taskId) => context.read<TaskBloc>().add(
                            DeleteTaskEvent(taskId),
                          ),
                        );
                      },
                    );
                  }

                  if (taskState is TaskErrorState) {
                    return Center(child: Text('Error: ${taskState.message}'));
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // category Management functions

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
              border: Border.all(color: primaryColor),
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

  // task Management function

  void _showEditTaskDialog(BuildContext context, String taskId) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return BlocProvider(
          create: (context) => TaskFormBloc(taskBloc: context.read<TaskBloc>()),
          child: UpdateTaskDialog(taskId: taskId),
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
