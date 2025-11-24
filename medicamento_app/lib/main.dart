import 'package:flutter/material.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/home_screen.dart';
import 'screens/agregar_medicamento_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de notificaciones
  await NotificationService().initialize();
  
  runApp(const MedicamentoApp());
}

class MedicamentoApp extends StatelessWidget {
  const MedicamentoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicamento App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 18),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const BienvenidaScreen(),
        '/home': (context) => const HomeScreen(),
        '/agregar': (context) => const AgregarMedicamentoScreen(),
      },
    );
  }
}