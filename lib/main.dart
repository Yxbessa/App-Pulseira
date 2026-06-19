import 'package:flutter/material.dart';
import 'ble_controller.dart';
import 'notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Arquivo gerado pelo flutterfire CLI
import 'login_screen.dart';
void main() async {
  // Garante que o motor do Flutter está rodando antes de chamar bibliotecas nativas
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Liga o nosso serviço de notificação
  await NotificationService.initialize();
  // Inicializa o Firebase com as chaves corretas para Android/iOS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
      // Aqui nós apontamos para a tela que criamos abaixo, e não mais para o "MyHomePage"
      home: const HomeScreen(), 
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
  // Instancia o controlador que criamos no outro arquivo
  final BleController _bleController = BleController();
  bool _isScanning = false;

  @override
  void dispose() {
    // Garante que o escaneamento pare se o usuário fechar a tela
    _bleController.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidor de Distância BLE'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // O StreamBuilder reconstrói apenas este texto sempre que uma nova distância chega
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
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }
                // Texto padrão enquanto não acha nenhum sinal
                return const Text(
                  'Nenhum sinal detectado ainda.',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                );
              },
            ),
            const SizedBox(height: 40),
            
            // Botão de Ligar/Desligar a busca
            ElevatedButton.icon(
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Parar Busca' : 'Buscar Dispositivos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              onPressed: () {
                setState(() {
                  if (_isScanning) {
                    _bleController.stopScanning();
                    _isScanning = false;
                  } else {
                    _bleController.startScanning();
                    _isScanning = true;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
