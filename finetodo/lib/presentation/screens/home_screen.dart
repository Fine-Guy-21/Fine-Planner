import 'package:finetodo/logic/bloc/task_form/task_form_bloc.dart';
import 'package:finetodo/presentation/widgets/add_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:finetodo/logic/bloc/task/task_bloc.dart';
import 'package:finetodo/logic/bloc/theme/theme_bloc.dart';

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
  int _currentIndex = 0; // Default to Tasks tab

  final List<Widget> _screens = [
    const TaskPage(),
    const CalendarWidget(),
    const SettingsWidget(),
    const DashboardWidget(),
  ];

  final List<String> _appBarTitles = [
    'Dashboard',
    'My Tasks',
    'Calendar',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex]),
        backgroundColor: const Color(0xFF5D5CDE),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6_outlined),
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleThemeEvent());
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog2(context),
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
        fixedColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined, color: Colors.white),
            label: 'Tasks',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.white),
            label: 'Calendar',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_alarms_outlined, color: Colors.white),
            label: 'Alarms',
            backgroundColor: Color(0xFF5D5CDE),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white),
            label: 'Dashboard',
            backgroundColor: Color(0xFF5D5CDE),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog2(BuildContext context) {
    debugPrint("Showing Add Task Dialog");
    showDialog<void>(
      context: context,
      builder: (context) {
        return BlocProvider(
          create: (context) => TaskFormBloc(taskBloc: context.read<TaskBloc>()),
          child: AddTaskDialog(),
        );
      },
    );
  }
}
