import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'ble_controller.dart'; 

void main() async {
  // Garante que o motor do Flutter está rodando antes de chamar bibliotecas nativas
  WidgetsFlutterBinding.ensureInitialized(); 

  // Liga o nosso serviço de notificação
  await NotificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador BLE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginScreen(), 
    );
  }
}

// ============================================================================
// A NOSSA HOMESCREEN: A tela real do aplicativo que se comunica com o Bluetooth
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleController _bleController = BleController();

  @override
  void initState() {
    super.initState();
    _iniciarBuscaComSeguranca();
  }

  // Função nova: espera o app "respirar" antes de ligar a antena
  void _iniciarBuscaComSeguranca() async {
    await Future.delayed(const Duration(seconds: 2)); // Dá 2 segundos para o sistema
    _bleController.startScanning();
  }

  @override
  void dispose() {
    _bleController.stopScanning();
    super.dispose();
  }

  // ... (o resto do seu build continua exatamentre igual, com o Scaffold e o StreamBuilder)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreamento da Pulseira'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // O StreamBuilder reconstrói a tela sempre que uma nova distância chega
            StreamBuilder<double>(
              stream: _bleController.distanceStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      const Text(
                        'Distância Estimada:',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        '${snapshot.data!.toStringAsFixed(2)} metros',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  );
                }
                // Visual de carregamento enquanto não acha o primeiro sinal
                return const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Buscando sinal da pulseira...',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}