part of 'category_bloc.dart';

abstract class CategoryEvent {}

class LoadCategoriesEvent extends CategoryEvent {}

class AddCategoryEvent extends CategoryEvent {
  final Category category;
  AddCategoryEvent(this.category);
}

class UpdateCategoryEvent extends CategoryEvent {
  final Category category;
  UpdateCategoryEvent(this.category);
}

class DeleteCategoryEvent extends CategoryEvent {
  final String categoryId;
  DeleteCategoryEvent(this.categoryId);
}

class SelectCategoryEvent extends CategoryEvent {
  final String categoryId;
  SelectCategoryEvent(this.categoryId);
}
