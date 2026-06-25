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
  // 1. Declaramos as variáveis que virão da tela de Login
  final String nomePai;
  final String emailPai;
  final String telefonePai;

  // 2. Obrigamos o Flutter a pedir essas variáveis no construtor
  const HomeScreen({
    super.key,
    this.nomePai = "",
    this.emailPai = "",
    this.telefonePai = "",
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleController _bleController = BleController();

  @override
  void initState() {
    super.initState();
    
    // 3. Alimentamos o BleController com as informações do usuário logado
    // (Acessamos as variáveis da classe pai usando o comando 'widget.')
    _bleController.nomePai = widget.nomePai;
    _bleController.emailContato = widget.emailPai;
    _bleController.telefoneContato = widget.telefonePai;

    // A chamada está correta aqui!
    _iniciarBuscaComSeguranca();
  }
  
  // =========================================================
  // A FUNÇÃO QUE FALTAVA (Gerencia a permissão e liga a antena)
  // =========================================================
  void _iniciarBuscaComSeguranca() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, 
      Permission.notification, 
    ].request();

    await Future.delayed(const Duration(seconds: 2)); 
    
    _bleController.startScanning(); 
  }

  // =========================================================
  // PREVENÇÃO DE VAZAMENTO DE MEMÓRIA (BOA PRÁTICA)
  // =========================================================
  @override
  void dispose() {
    _bleController.stopScanning(); 
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