import 'dart:math';

class CalculadoraDistanciaBle {
  // O valor médio do RSSI recebido a exatamente 1 metro de distância (ex: -57.0)
  final double rssiCalibradoA1Metro; 

  // --- Variáveis do Filtro de Kalman 1D ---
  final double _ruidoDoAmbiente; // Q: O quão rápido a pessoa real se move
  final double _ruidoDoSensor;   // R: O quanto o sinal da antena oscila/falha
  double _estimativaDeErro;      // P: Margem de erro atual
  double? _ultimoRssiFiltrado;   // X: Estado salvo

  CalculadoraDistanciaBle({
    required this.rssiCalibradoA1Metro,
    double ruidoDoAmbiente = 0.05,  
    double ruidoDoSensor = 5.0,     
    double estimativaDeErroInicial = 1.0,
  })  : _ruidoDoAmbiente = ruidoDoAmbiente,
        _ruidoDoSensor = ruidoDoSensor,
        _estimativaDeErro = estimativaDeErroInicial;

  /// Função principal chamada a cada pulso recebido no scan
  double calcularDistancia(int rssiBruto) {
    // 1. Suaviza o sinal eliminando os "picos" falsos
    double rssiSuavizado = _aplicarFiltroKalman(rssiBruto.toDouble());

    // 2. Define o atrito do ambiente dependendo da força do sinal
    double n = _obterFatorDeAtenuacaoDinamico(rssiSuavizado);

    // 3. Aplica a Fórmula de Path Loss
    double distancia = pow(10, ((rssiCalibradoA1Metro - rssiSuavizado) / (10.0 * n))).toDouble();

    return distancia;
  }

  double _aplicarFiltroKalman(double novaLeitura) {
    if (_ultimoRssiFiltrado == null) {
      _ultimoRssiFiltrado = novaLeitura;
      return novaLeitura;
    }

    // Predição
    double estimativaPriori = _ultimoRssiFiltrado!;
    double erroPriori = _estimativaDeErro + _ruidoDoAmbiente;

    // Atualização (Cálculo do Ganho)
    double ganhoKalman = erroPriori / (erroPriori + _ruidoDoSensor);
    _ultimoRssiFiltrado = estimativaPriori + ganhoKalman * (novaLeitura - estimativaPriori);
    _estimativaDeErro = (1 - ganhoKalman) * erroPriori;

    return _ultimoRssiFiltrado!;
  }

  double _obterFatorDeAtenuacaoDinamico(double rssi) {
    if (rssi > (rssiCalibradoA1Metro + 10)) {
      return 1.8; // Campo Próximo (Muito perto)
    } else if (rssi > (rssiCalibradoA1Metro - 10)) {
      return 2.5; // Zona Ideal (1 a 3 metros)
    } else {
      return 3.5; // Longe (Muitas reflexões de parede/chão)
    }
  }

  void resetarFiltro() {
    _ultimoRssiFiltrado = null;
    _estimativaDeErro = 1.0;
  }
}