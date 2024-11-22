import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Pantrys/pantry_page.dart';
import 'shopping_page.dart';
import '../Recipes/TabBar/recipes_page.dart';
import 'user_page.dart';
import '../user_auth/login_page.dart';
import '../Pantrys/Products/voice_page.dart';
import '../Pantrys/pantry_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  String? selectedPantryId;
  List<Map<String, dynamic>> pantryList = [];

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<String> getSelectedPantryName() async {
    if (selectedPantryId == null || _user == null) return '';

    try {
      DocumentSnapshot pantrySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user!.uid)
          .collection('despensas')
          .doc(selectedPantryId)
          .get();

      if (pantrySnapshot.exists) {
        return pantrySnapshot.get('nombre') as String;
      } else {
        return '';
      }
    } catch (e) {
      print('Error al obtener el nombre de la despensa: $e');
      return '';
    }
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

  Stream<List<Map<String, dynamic>>> _getPantryStream() {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_user!.uid)
        .collection('despensas')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, 'nombre': doc['nombre'] as String})
            .toList());
  }

// Método ajustado para evitar conflictos con la fase de construcción
  void validateSelectionSafe(List<Map<String, dynamic>> pantries) {
    if (pantries.isEmpty) {
      // Si no hay despensas, resetear la selección
      if (selectedPantryId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedPantryId = null;
          });
        });
      }
      return;
    }

    // Verificar si el ID seleccionado existe en la lista actual
    bool idExists = pantries.any((p) => p['id'] == selectedPantryId);

    if (!idExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedPantryId = pantries[0]['id'];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const SizedBox();
    }

    String username = _user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFF124580),
      drawer: _buildDrawer(username),
      //AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF124580),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Sección superior azul
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                MediaQuery.of(context).size.height * 0.10, //altura del texto
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
                  const SizedBox(height: 10),
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
                MediaQuery.of(context).size.height * 0.12, //posicion del blanco
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

                    const SizedBox(height: 18),

                    // Sección de Despensa
                    const Text(
                      'Acceso directo despensa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 71, 79, 83),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dropdown de despensas
                    Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getPantryStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              );
                            }

                            pantryList = snapshot.data!;
                            validateSelectionSafe(
                                pantryList); // Actualizamos selección de forma segura

                            if (pantryList.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No hay despensas disponibles'),
                              );
                            }

                            return DropdownButtonHideUnderline(
                              child: ButtonTheme(
                                alignedDropdown: true,
                                child: DropdownButton<String>(
                                  value: selectedPantryId,
                                  isExpanded: true,
                                  hint: const Text('Seleccione su despensa'),
                                  items: pantryList.map((pantry) {
                                    return DropdownMenuItem<String>(
                                      value: pantry['id'],
                                      child: Text(
                                        pantry['nombre'],
                                        style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 71, 79, 83),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedPantryId = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        )),

                    const SizedBox(height: 15),

                    //Botones de acción
                    _buildMainButton(
                      icon: Icons.mic,
                      title: 'Agregar productos',
                      subtitle: 'Agrega productos por voz',
                      onTap: () {
                        if (selectedPantryId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoicePage(
                                despensaId: selectedPantryId!,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Por favor seleccione una despensa')),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildMainButton(
                      icon: Icons.format_list_bulleted,
                      title: 'Ver productos',
                      subtitle: 'Ir a listado de productos',
                      onTap: () async {
                        if (selectedPantryId != null) {
                          String pantryName = await getSelectedPantryName();
                          if (pantryName.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantryView(
                                  despensaId: selectedPantryId!,
                                  despensaNombre: pantryName,
                                  userId: _user!.uid,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No se pudo obtener el nombre de la despensa')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Por favor seleccione una despensa')),
                          );
                        }
                      },
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

  // Método para construir el Drawer (menú lateral)
  Widget _buildDrawer(String username) {
    return Drawer(
      child: Container(
        color: Color(0xFF124580), // Fondo azul
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                username,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _user?.email ?? '',
                style: TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Color(0xFF124580),
                  size: 50,
                ),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF124580),
              ),
            ),
            Divider(color: Colors.white54),
            _buildDrawerItem(
              icon: Icons.home,
              text: 'Inicio',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              text: 'Mi perfil',
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_outline,
              text: 'Cómo funciona DespensApp',
              onTap: () {
                // Acción para "Cómo funciona DespensApp"
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              text: 'Preguntas frecuentes',
              onTap: () {
                // Acción para "Preguntas frecuentes"
              },
            ),
            Divider(color: Colors.white54),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
                icon: Icon(Icons.exit_to_app),
                label: Text("Cerrar sesión"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método helper para crear cada elemento del menú lateral
  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
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
                      fontSize: 16,
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
        currentIndex: 0,
        selectedItemColor: const Color(0xFF124580).withOpacity(0.8),
        unselectedItemColor: const Color(0xFF575D65).withOpacity(0.85),
        backgroundColor: Colors.white,
        elevation: 1, // Quitamos la elevación predeterminada
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight:
              FontWeight.w800, // Letra más negrita para el item seleccionado
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            label: 'Despensas',
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
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipesPage(),
                ),
              );
              break;
            case 3:
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
