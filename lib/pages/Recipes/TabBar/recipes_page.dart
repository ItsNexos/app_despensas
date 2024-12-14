import 'package:app_despensas/pages/Recipes/TabBar/recipes.dart';
import 'package:app_despensas/pages/Recipes/TabBar/suggestions.dart';
import 'package:app_despensas/pages/Recipes/TabBar/explore_recipes.dart';
import 'package:flutter/material.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF124580)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mis Recetas',
          style: TextStyle(
            color: Color(0xFF124580),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF124580),
          tabs: const [
            Tab(
              child: Text(
                'SUGERENCIAS',
                style: TextStyle(fontSize: 13.8),
              ),
            ),
            Tab(
              child: Text(
                'MI RECETARIO',
                style: TextStyle(fontSize: 13.8),
              ),
            ),
            Tab(
              child: Text(
                'EXPLORAR',
                style: TextStyle(fontSize: 13.8),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Suggestions(),
          Recipes(),
          ExploreRecipes(),
        ],
      ),
    );
  }
}
