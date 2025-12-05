import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:finetodo/logic/bloc/category/category_bloc.dart';
import 'package:finetodo/logic/bloc/task/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finetodo/data/models/task_model.dart';
import 'package:finetodo/presentation/ui/task_page.dart';
import 'package:finetodo/presentation/widgets/calendar_widget.dart';
import 'package:finetodo/presentation/widgets/dashboard_widget.dart';
import 'package:finetodo/presentation/widgets/settings_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to Tasks tab

  final List<Widget> _screens = [
    const DashboardWidget(),
    const TaskPage(),
    const CalendarWidget(),
    const SettingsWidget(),
  ];

  final List<String> _appBarTitles = [
    'Dashboard',
    'My Tasks',
    'Calendar',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CategoryBloc()..add(LoadCategoriesEvent()),
        ),
        BlocProvider(create: (context) => TaskBloc()..add(LoadTasksEvent())),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[_currentIndex]),
          backgroundColor: const Color(0xFF5D5CDE),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Theme toggle button
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                // You'll need to implement theme switching logic here
                // This typically involves using a ThemeBloc or Provider
                _showThemeNotImplementedSnackbar(context);
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        floatingActionButton:
            _currentIndex ==
                1 // Only show FAB on Tasks screen
            ? FloatingActionButton(
                onPressed: () => _showAddTaskDialog(context),
                backgroundColor: const Color(0xFF5D5CDE),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF5D5CDE),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeNotImplementedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme switching will be implemented in settings'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    bool isRecurring = false;
    String? selectedRecurrencePattern;
    Category? selectedCategory;

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
                        'Add Task',
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

                              // Sort categories: protected ones first, then alphabetically
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

                              // Set default category if not set
                              if (selectedCategory == null &&
                                  sortedCategories.isNotEmpty) {
                                final generalCat = sortedCategories.firstWhere(
                                  (c) => c.title == 'General',
                                  orElse: () => sortedCategories.first,
                                );
                                selectedCategory = generalCat;
                              }

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

                                    // Use selected category or default to General
                                    Category chosenCategory =
                                        selectedCategory ??
                                        Category(
                                          id: 'general',
                                          title: 'General',
                                        );

                                    final task = TaskModel(
                                      title: title,
                                      description: descController.text.trim(),
                                      category: chosenCategory,
                                      dueDate: selectedDate,
                                      isRecurring: isRecurring,
                                      recurrencePattern:
                                          selectedRecurrencePattern
                                              ?.toLowerCase(),
                                    );

                                    context.read<TaskBloc>().add(
                                      AddTaskEvent(task),
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
