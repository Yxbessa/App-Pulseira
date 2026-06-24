import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'ble_controller.dart'; 
import 'package:permission_handler/permission_handler.dart';
void main() async {
  // Garante que o motor do Flutter está rodando antes de chamar bibliotecas nativas
  WidgetsFlutterBinding.ensureInitialized(); 

  // Liga o nosso serviço de notificação (Essencial para os alertas gerados lá no BleController)
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
  // Aqui instanciamos o controller. 
  // Por baixo dos panos, ele agora instanciará a CalculadoraDistanciaBle com o Filtro de Kalman!
  final BleController _bleController = BleController();

  @override
  void initState() {
    super.initState();
    _iniciarBuscaComSeguranca();
  }

 void _iniciarBuscaComSeguranca() async {
    // 1. Pede todas as permissões críticas juntas antes de qualquer coisa
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Necessário para BLE em Androids mais antigos
      Permission.notification, // Crucial para Android 13+ mostrar o alerta
    ].request();

    // 2. Aguarda o app respirar e o usuário aceitar
    await Future.delayed(const Duration(seconds: 2)); 
    
    // 3. Só agora liga a antena
    _bleController.startScanning(); 
  }

  @override
  void dispose() {
    _bleController.stopScanning(); // Desliga o Bluetooth e reseta a memória do Kalman
    super.dispose();
  }

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
            // Agora, esses dados chegam limpos, sem as flutuações bruscas do RSSI bruto
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
                        // Exibe o cálculo super preciso feito pelo backend
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