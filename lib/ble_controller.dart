import 'dart:async';
import 'dart:math';
import 'notification_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleController {
  // Lista para armazenar as últimas leituras de RSSI (Filtro de Média Móvel)
  final List<int> _rssiHistory = [];
  final int _maxSamples = 10; 
  final int txPower = -59; 
  final double n = 2.5;    

  // Variáveis de alarme
  final double distanciaLimite = 10.0; 
  bool _notificacaoJaEnviada = false;
  Timer? _timerPerdaSinal;

  final StreamController<double> _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  StreamSubscription? _scanSubscription;

  void startScanning() async {
    if (await FlutterBluePlus.isSupported == false) return;

    // Filtro oficial do sistema
    List<Guid> servicosAlvo = [Guid("4d6fc88b-be75-6698-da48-6866a36ec78e")];

    await FlutterBluePlus.startScan(
      withServices: servicosAlvo, 
      timeout: const Duration(minutes: 5),
      androidUsesFineLocation: true,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        _adicionarLeituraRssi(result.rssi);
        print("📡 Sinal do ESP32 capturado! Força: ${result.rssi}");
      }
    });
  }

  void _adicionarLeituraRssi(int newRssi) {
    _timerPerdaSinal?.cancel();
    _timerPerdaSinal = Timer(const Duration(seconds: 5), () {
      if (!_notificacaoJaEnviada) {
        _dispararNotificacaoAlarme("Sinal Perdido", "O Beacon parou de transmitir ou saiu de alcance!");
        _notificacaoJaEnviada = true;
      }
    });

    _rssiHistory.add(newRssi);
    if (_rssiHistory.length > _maxSamples) {
      _rssiHistory.removeAt(0); 
    }

    double rssiMedio = _rssiHistory.reduce((a, b) => a + b) / _rssiHistory.length;
    double distancia = pow(10, (txPower - rssiMedio) / (10 * n)).toDouble();

    if (distancia > distanciaLimite && !_notificacaoJaEnviada) {
      _dispararNotificacaoAlarme("Atenção!", "O objeto se afastou mais de $distanciaLimite metros.");
      _notificacaoJaEnviada = true;
    } else if (distancia <= distanciaLimite) {
      _notificacaoJaEnviada = false;
    }

    _distanceStreamController.add(distancia);
  }

  void _dispararNotificacaoAlarme(String titulo, String corpo) {
    NotificationService.showNotification(title: titulo, body: corpo);
  }

  void stopScanning() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _timerPerdaSinal?.cancel(); 
    _rssiHistory.clear();
  }
}