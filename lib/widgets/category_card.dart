import 'package:flutter/material.dart';
import 'package:foodkie_express/models/category.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({Key? key, required this.category, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(),
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.subCategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${category.subCategories.length} sub-categories',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    
    final name = category.name.toLowerCase();

    if (name.contains('pizza') || name.contains('pie')) {
      return Icons.local_pizza;
    } else if (name.contains('burger') || name.contains('sandwich')) {
      return Icons.lunch_dining;
    } else if (name.contains('drink') ||
        name.contains('beverage') ||
        name.contains('juice')) {
      return Icons.local_drink;
    } else if (name.contains('dessert') ||
        name.contains('sweet') ||
        name.contains('cake')) {
      return Icons.cake;
    } else if (name.contains('soup') || name.contains('salad')) {
      return Icons.soup_kitchen;
    } else if (name.contains('breakfast')) {
      return Icons.free_breakfast;
    } else if (name.contains('dinner') || name.contains('meal')) {
      return Icons.dinner_dining;
    } else if (name.contains('special')) {
      return Icons.star;
    }

    
    return Icons.restaurant_menu;
  }
}
