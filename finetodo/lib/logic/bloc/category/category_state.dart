part of 'category_bloc.dart';

abstract class CategoryState {
  const CategoryState();
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoriesLoadedState extends CategoryState {
  final List<Category> categories;
  final String? selectedCategoryId;

  const CategoriesLoadedState({
    required this.categories,
    this.selectedCategoryId,
  });
}

class CategoryErrorState extends CategoryState {
  final String message;
  const CategoryErrorState({required this.message});
}
