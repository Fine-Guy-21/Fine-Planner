import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/task_model.dart'; // contains Category model

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  late Box<Category> _categoryBox;
  String? _selectedCategoryId;
  StreamSubscription? _boxSub;

  CategoryBloc() : super(const CategoryInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<SelectCategoryEvent>(_onSelectCategory);
  }

  @override
  Future<void> close() async {
    await _boxSub?.cancel();
    await _categoryBox.close();
    return super.close();
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      _categoryBox = Hive.box<Category>('categories');
      // load categories and ensure primitive categories exist
      var categories = _categoryBox.values.toList();
      // primitive categories to ensure in the box
      final primitives = [
        Category(id: 'general', title: 'General'),
        Category(id: 'completed', title: 'Completed'),
        Category(id: 'pending', title: 'Pending'),
      ];
      for (final prim in primitives) {
        final exists = categories.any(
          (c) => c.id == prim.id || c.title == prim.title,
        );
        if (!exists) {
          await _categoryBox.put(prim.id, prim);
        }
      }
      categories = _categoryBox.values.toList();

      // ensure a default selection: prefer General if present
      final generalCat = categories.firstWhere(
        (c) => c.title == 'General',
        orElse: () => categories.isNotEmpty
            ? categories.first
            : Category(id: 'general', title: 'General'),
      );
      _selectedCategoryId ??= generalCat.id;
      emit(
        CategoriesLoadedState(
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
        ),
      );

      // listen for external changes to the categories box and reload when changed
      _boxSub ??= _categoryBox.watch().listen((event) {
        add(LoadCategoriesEvent());
      });
    } catch (e) {
      emit(CategoryErrorState(message: e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      _categoryBox = Hive.box<Category>('categories');
      // prevent adding categories with primitive ids
      final protectedIds = {'general', 'completed', 'pending'};
      if (event.category.id != null &&
          protectedIds.contains(event.category.id)) {
        // ignore attempts to overwrite primitives
      } else {
        await _categoryBox.put(event.category.id, event.category);
      }

      final categories = _categoryBox.values.toList();
      emit(
        CategoriesLoadedState(
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
        ),
      );
    } catch (e) {
      emit(CategoryErrorState(message: e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      _categoryBox = Hive.box<Category>('categories');
      // protect primitive categories from updates
      final protectedIds = {'general', 'completed', 'pending'};
      if (event.category.id != null &&
          protectedIds.contains(event.category.id)) {
        // ignore updates to primitives
      } else {
        await _categoryBox.put(event.category.id, event.category);
      }

      final categories = _categoryBox.values.toList();
      emit(
        CategoriesLoadedState(
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
        ),
      );
    } catch (e) {
      emit(CategoryErrorState(message: e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      _categoryBox = Hive.box<Category>('categories');
      // protect primitive categories from deletion
      final protectedIds = {'general', 'completed', 'pending'};
      if (protectedIds.contains(event.categoryId)) {
        // ignore deletion
      } else {
        await _categoryBox.delete(event.categoryId);
      }

      final categories = _categoryBox.values.toList();
      // if deleted category was selected, reset selection
      if (_selectedCategoryId == event.categoryId)
        _selectedCategoryId = categories.isNotEmpty
            ? categories.first.id
            : 'all';
      emit(
        CategoriesLoadedState(
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
        ),
      );
    } catch (e) {
      emit(CategoryErrorState(message: e.toString()));
    }
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      _selectedCategoryId = event.categoryId;
      final categories = Hive.box<Category>('categories').values.toList();
      emit(
        CategoriesLoadedState(
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
        ),
      );
    } catch (e) {
      emit(CategoryErrorState(message: e.toString()));
    }
  }
}
