import 'package:finetodo/presentation/widgets/alarms_widget.dart';
// import 'package:finetodo/presentation/widgets/task_list_widget%20copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/task/task_bloc.dart';
import '../../logic/bloc/theme/theme_bloc.dart';
import '../../logic/bloc/api_bloc.dart';
import '../../logic/bloc/category/category_bloc.dart';
import '../ui/task_page.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/dashboard_widget.dart';
import '../../data/models/task_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load tasks and initialize API
    final apiToken = dotenv.env['API_TOKEN'] ?? "";
    context.read<TaskBloc>().add(LoadTasksEvent());
    context.read<ApiBloc>().add(InitializeApiEvent(apiToken));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D5CDE),
        // backgroundColor: Theme.of(context).brightness == Brightness.dark
        //     ? Color(0xFF5D5CDE)
        //     : Colors.amber,
        title: const Text(
          'Fine Planner',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleThemeEvent());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.white,
        backgroundColor: Colors.blueGrey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined, color: Colors.white70),
            label: 'Tasks',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
            label: 'Calendar',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_outlined, color: Colors.white70),
            label: 'Alarms',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined, color: Colors.white70),
            label: 'Profile',
            backgroundColor: Color(0xFF5D5CDE),
          ),
        ],
      ),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showAddTaskDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate != null
                                ? 'Due: ${selectedDate!.toLocal().toString().split(' ')[0]}'
                                : 'No due date',
                          ),
                        ),
                        TextButton(
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
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Title cannot be empty')),
                      );
                      return;
                    }

                    // determine a Category instance to attach to the task
                    Category chosenCategory;
                    final catState = context.read<CategoryBloc>().state;
                    if (catState is CategoriesLoadedState) {
                      try {
                        chosenCategory = catState.categories.firstWhere(
                          (c) => c.title == 'General',
                        );
                      } catch (_) {
                        chosenCategory = Category(
                          id: 'general',
                          title: 'General',
                        );
                      }
                    } else {
                      chosenCategory = Category(
                        id: 'general',
                        title: 'General',
                      );
                    }

                    final task = TaskModel(
                      title: title,
                      description: desc,
                      category: chosenCategory,
                      dueDate: selectedDate,
                    );

                    context.read<TaskBloc>().add(AddTaskEvent(task));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const TaskPage();
      case 1:
        return const CalendarWidget();
      case 2:
        return const AlarmsWidget();
      case 3:
        return const DashboardWidget();
      default:
        return const Center(child: Text('Unknown page'));
    }
  }
}
