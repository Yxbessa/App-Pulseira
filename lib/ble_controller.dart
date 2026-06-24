import 'dart:async';
import 'dart:math';
import 'notification_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleController {
  final List<int> _rssiHistory = [];
  final int _maxSamples = 5; 
  final int txPower = -57; // RSSI a 1 metro de distância (em dBm)
  final double n = 4.48;

  final double distanciaLimite = 10.0; 
  bool _notificacaoJaEnviada = false;
  
  // Timer responsável por atualizar a tela a cada X segundos
  Timer? _timerDeAtualizacao;
  // Guarda a hora do último sinal que bateu na antena
  DateTime _ultimoSinalRecebido = DateTime.now();

  final StreamController<double> _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _stateSubscription;

  void startScanning() async {
    if (await FlutterBluePlus.isSupported == false) return;

    List<Guid> servicosAlvo = [Guid("4d6fc88b-be75-6698-da48-6866a36ec78e")];

    _stateSubscription = FlutterBluePlus.adapterState.listen((estado) {
      if (estado == BluetoothAdapterState.on) {
        FlutterBluePlus.startScan(
          withServices: servicosAlvo, 
          continuousUpdates: true, 
        );
      }
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        _rssiHistory.add(result.rssi);
        _ultimoSinalRecebido = DateTime.now(); // Renova o tempo de vida do sinal
        print("RSSI: ${result.rssi}");
        if (_rssiHistory.length > _maxSamples) {
          _rssiHistory.removeAt(0); 
        }
      }
    });

    // O RELÓGIO PRINCIPAL: Crava a distância a cada 3 segundos
    _timerDeAtualizacao = Timer.periodic(const Duration(seconds: 3), (timer) {
      _processarDistanciaETela();
    });
  }

  void _processarDistanciaETela() {
    // 1. Verifica se já faz mais de 5 segundos desde o último sinal (Perda de Conexão)
    if (DateTime.now().difference(_ultimoSinalRecebido).inSeconds > 5) {
      if (!_notificacaoJaEnviada) {
        NotificationService.showNotification(
          title: "SINAL PERDIDO! 🚨", 
          body: "A pulseira parou de transmitir. Verifique a criança imediatamente."
        );
        _notificacaoJaEnviada = true;
      }
      _rssiHistory.clear(); // Limpa o histórico, pois não há sinal
      return; // Interrompe o cálculo, pois não há sinal
    }

    // Se tivermos histórico, calculamos e enviamos para a tela
    if (_rssiHistory.isNotEmpty) {
      double rssiMedio = _rssiHistory.reduce((a, b) => a + b) / _rssiHistory.length;
      double distancia = pow(10, (txPower - rssiMedio) / (10 * n)).toDouble();

      // 2. Verifica se passou do limite de segurança
      if (distancia > distanciaLimite && !_notificacaoJaEnviada) {
        NotificationService.showNotification(
          title: "Atenção! ⚠️", 
          body: "O objeto se afastou mais de $distanciaLimite metros."
        );
        _notificacaoJaEnviada = true;
      } else if (distancia <= distanciaLimite) {
        _notificacaoJaEnviada = false; // Reseta o alarme se voltar para perto
      }

      // Envia a distância calculada para a tela
      _distanceStreamController.add(distancia);
    }
  }

  void stopScanning() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _timerDeAtualizacao?.cancel(); 
    _rssiHistory.clear();
  }
}