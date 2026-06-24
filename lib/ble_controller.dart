import 'dart:async';
import 'notification_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'calculadora_distancia_ble.dart'; // Importe a classe refatorada

class BleController {
  // Instancia a calculadora com a sua calibração de 1 metro
  final CalculadoraDistanciaBle _calculadora = CalculadoraDistanciaBle(
    rssiCalibradoA1Metro: -57.0, 
  );

  final double distanciaLimite = 10.0; 
  // O MAC ou ID único da pulseira/ESP32 para evitar ler sinais de terceiros
  final String deviceMacAddress = "00:11:22:33:44:55"; 

  bool _notificacaoJaEnviada = false;
  double _ultimaDistanciaConhecida = 0.0;
  
  Timer? _timerDeAtualizacao;
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

    // LISTENER: Reage a cada pacote recebido na antena
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Filtragem crucial: Só processe se for o SEU dispositivo
        if (result.device.remoteId.str == deviceMacAddress) {
          _ultimoSinalRecebido = DateTime.now(); 
          
          // Alimenta o filtro de Kalman e atualiza a distância imediatamente
          _ultimaDistanciaConhecida = _calculadora.calcularDistancia(result.rssi);
        }
      }
    });

    // RELÓGIO DE VERIFICAÇÃO: Avalia a segurança a cada 3 segundos
    _timerDeAtualizacao = Timer.periodic(const Duration(seconds: 3), (timer) {
      _verificarRegrasDeSegurancaETela();
    });
  }

  void _verificarRegrasDeSegurancaETela() {
    // 1. Regra de Perda de Sinal (Desconexão abrupta ou fora de alcance)
    if (DateTime.now().difference(_ultimoSinalRecebido).inSeconds > 5) {
      if (!_notificacaoJaEnviada) {
        NotificationService.showNotification(
          title: "SINAL PERDIDO! 🚨", 
          body: "A conexão com o dispositivo foi perdida. Verifique imediatamente."
        );
        _notificacaoJaEnviada = true;
      }
      _calculadora.resetarFiltro(); // Limpa a memória do Kalman pois o estado mudou
      return; 
    }

    // 2. Regra de Afastamento (Passou do limite configurado)
    if (_ultimaDistanciaConhecida > distanciaLimite && !_notificacaoJaEnviada) {
      NotificationService.showNotification(
        title: "Atenção! ⚠️", 
        body: "O objeto se afastou mais de $distanciaLimite metros."
      );
      _notificacaoJaEnviada = true;
    } else if (_ultimaDistanciaConhecida <= distanciaLimite) {
      _notificacaoJaEnviada = false; // Reseta o alarme se voltar para perto
    }

    // 3. Atualiza a UI (Tela) com a distância mais estável
    _distanceStreamController.add(_ultimaDistanciaConhecida);
  }

  void stopScanning() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _timerDeAtualizacao?.cancel(); 
    _calculadora.resetarFiltro();
  }
}