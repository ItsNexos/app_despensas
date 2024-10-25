import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantry_page.dart';
import 'shopping_page.dart';
import 'recipes_page.dart';
import 'user_page.dart';
import 'user_auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  String? selectedPantry;
  List<String> pantryList = [];

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      });
    }
  }

  Stream<List<String>> _getPantryStream() {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_user!.uid)
        .collection('despensas')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['nombre'] as String).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const SizedBox();
    }

    String username = _user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFF124580),
      body: Stack(
        children: [
          // Sección superior azul
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                MediaQuery.of(context).size.height * 0.22, //altura del texto
            child: Container(
              color: const Color(0xFF124580),
              padding:
                  const EdgeInsets.symmetric(horizontal: 25), // Margen lateral
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alineación a la izquierda
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Hola, ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        username, // Color personalizado para el nombre
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC8E2FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "¿Qué quieres hacer hoy?",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.left, // Alineado a la izquierda
                  ),
                ],
              ),
            ),
          ),

          // Contenedor blanco redondeado
          Positioned(
            top:
                MediaQuery.of(context).size.height * 0.17, //posicion del blanco
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Botón de Compras
                    _buildMainButton(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Voy de compras',
                      subtitle: 'Ir a carrito de compras',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ShoppingPage(userId: _user!.uid),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botón de Cocinar
                    _buildMainButton(
                      icon: Icons.restaurant_menu,
                      title: 'Quiero cocinar',
                      subtitle: 'Ver recetas sugeridas',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecipesPage(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sección de Despensa
                    const Text(
                      'Acceso directo despensa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 71, 79, 83),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: StreamBuilder<List<String>>(
                        stream: _getPantryStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child:
                                  CircularProgressIndicator(), // Mientras carga
                            );
                          }
                          pantryList = snapshot.data!;
                          if (pantryList.isNotEmpty && selectedPantry == null) {
                            selectedPantry = pantryList[0];
                          }

                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPantry,
                              isExpanded: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              hint: const Text('Seleccione su despensa'),
                              items: pantryList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 71, 79, 83),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedPantry = newValue;
                                });
                              },
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              menuMaxHeight: 200, // Limita la altura del menú
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Botones de accion
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 35,
                      childAspectRatio: 1.05,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildActionCard(
                          icon: Icons.add_circle,
                          label: 'Agregar\nproductos',
                          color: Color(0XFF4BC157).withOpacity(0.9),
                          onTap: () {
                            // Implementar acción
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.remove_circle,
                          label: 'Eliminar\nproductos',
                          color: Color(0XFFE4352A).withOpacity(0.9),
                          onTap: () {
                            // Implementar acción
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.edit_note_outlined,
                          label: 'Editar\nproductos',
                          color: Color(0XFF6DBDFF),
                          onTap: () {
                            // Implementar acción
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.production_quantity_limits,
                          label: 'Productos de\nbajo stock',
                          color: Color(0XFFFFDA14).withOpacity(0.8),
                          onTap: () {
                            // Implementar acción
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 50, color: const Color(0xFF6DBDFF)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A4247).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0XFF4DAFFF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF3C3F44).withOpacity(0.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3A4247),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFF124580).withOpacity(0.8),
        unselectedItemColor: const Color(0xFF575D65).withOpacity(0.85),
        backgroundColor: Colors.white,
        elevation: 1, // Quitamos la elevación predeterminada
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight:FontWeight.w800, // Letra más negrita para el item seleccionado
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            label: 'Despensas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Compras',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserPage()),
              );
              break;
            case 1:
              if (_user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantryPage(userId: _user!.uid),
                  ),
                );
              }
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipesPage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingPage(userId: _user!.uid),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
