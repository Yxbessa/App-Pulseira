import 'dart:async';
import 'notification_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'calculadora_distancia_ble.dart'; 
import 'api_service.dart'; // <-- IMPORTAÇÃO DO SERVIÇO DE API

class BleController {
  final CalculadoraDistanciaBle _calculadora = CalculadoraDistanciaBle(
    rssiCalibradoA1Metro: -56.6, 
  );
  String nomePai = "";
  String emailContato = "";
  String telefoneContato = "";
  final double distanciaLimite = 10.0; 
  // O MAC do seu aparelho anotado dos testes
  final String deviceMacAddress = "74:4D:BD:65:D1:37"; 

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

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        _ultimoSinalRecebido = DateTime.now(); 
        _ultimaDistanciaConhecida = _calculadora.calcularDistancia(result.rssi);
      }
    });

    _timerDeAtualizacao = Timer.periodic(const Duration(seconds: 3), (timer) {
      _verificarRegrasDeSegurancaETela();
    });
  }

  void _verificarRegrasDeSegurancaETela() {
    int statusConexaoDaVez = 1; // 1 = Conectado, 0 = Desconectado

    // 1. REGRA DE PERDA DE SINAL
    if (DateTime.now().difference(_ultimoSinalRecebido).inSeconds > 5) {
      statusConexaoDaVez = 0; // Marca como desconectado para a API
      if (!_notificacaoJaEnviada) {
        NotificationService.showNotification(
          title: "SINAL PERDIDO! 🚨", 
          body: "A pulseira desconectou ou saiu totalmente do alcance."
        );
        _notificacaoJaEnviada = true;
      }
      _calculadora.resetarFiltro(); 
      _distanceStreamController.add(0.0); 
    } 
    // 2. REGRA DE AFASTAMENTO
    else {
      if (_ultimaDistanciaConhecida > 8.0 && !_notificacaoJaEnviada) {
        NotificationService.showNotification(
          title: "Atenção! ⚠️", 
          body: "O objeto ultrapassou a zona de segurança segura."
        );
        _notificacaoJaEnviada = true;
      } else if (_ultimaDistanciaConhecida <= 6.0) {
        _notificacaoJaEnviada = false; 
      }
      _distanceStreamController.add(_ultimaDistanciaConhecida);
    }

    // =========================================================
    // 3. COMUNICAÇÃO EXTERNA (A MÁGICA DA API ACONTECE AQUI)
    // =========================================================
    // Dispara os dados calculados assincronamente.
    // Como não usamos 'await' aqui, o Timer nunca trava, 
    // mesmo se a internet do celular estiver lenta.
   // =========================================================
    // 3. COMUNICAÇÃO EXTERNA (A MÁGICA DA API ACONTECE AQUI)
    // =========================================================
    // O envio agora leva os dados humanos em vez do MAC Address
    ApiService.enviarDadosRastreio(
      nomeResponsavel: nomePai,
      emailContato: emailContato,
      telefoneContato: telefoneContato,
      distancia: statusConexaoDaVez == 1 ? _ultimaDistanciaConhecida : 0.0,
      statusConexao: statusConexaoDaVez,
    );
  } // Fim da função _verificarRegrasDeSegurancaETela

  void stopScanning() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _timerDeAtualizacao?.cancel(); 
    _calculadora.resetarFiltro();
  }
}