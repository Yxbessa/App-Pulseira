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
          _ultimoSinalRecebido = DateTime.now(); 
          
          // Alimenta o filtro de Kalman e atualiza a distância imediatamente
          _ultimaDistanciaConhecida = _calculadora.calcularDistancia(result.rssi);
      }
    });

    // RELÓGIO DE VERIFICAÇÃO: Avalia a segurança a cada 3 segundos
    _timerDeAtualizacao = Timer.periodic(const Duration(seconds: 3), (timer) {
      _verificarRegrasDeSegurancaETela();
    });
  }

  void _verificarRegrasDeSegurancaETela() {
    // 1. REGRA DE PERDA DE SINAL: Se o relógio do sistema avançar 5 segundos e a antena não receber nada
    if (DateTime.now().difference(_ultimoSinalRecebido).inSeconds > 5) {
      if (!_notificacaoJaEnviada) {
        print("🚨 GATILHO DE PERDA DE SINAL: Disparando notificação!");
        NotificationService.showNotification(
          title: "SINAL PERDIDO! 🚨", 
          body: "A pulseira desconectou ou saiu totalmente do alcance."
        );
        _notificacaoJaEnviada = true;
      }
      _calculadora.resetarFiltro(); // Zera o estado do Kalman
      _distanceStreamController.add(0.0); // Zera a tela para o usuário ver que caiu
      return; // Interrompe a função aqui. Não faz cálculo de distância de um sinal fantasma.
    }

    // 2. REGRA DE AFASTAMENTO COM HISTERESE (ZONA DE SEGURANÇA)
    // Dispara a notificação se passar de 8 metros
    if (_ultimaDistanciaConhecida > 8.0 && !_notificacaoJaEnviada) {
      print("⚠️ GATILHO DE AFASTAMENTO: Passou de 8 metros!");
      NotificationService.showNotification(
        title: "Atenção! ⚠️", 
        body: "O objeto ultrapassou a zona de segurança segura."
      );
      _notificacaoJaEnviada = true;
      
    // Só permite o alarme tocar de novo se o objeto voltar a ficar MUITO PERTO (ex: 6 metros)
    } else if (_ultimaDistanciaConhecida <= 6.0) {
      _notificacaoJaEnviada = false; 
    }

    // 3. Atualiza os números na tela
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