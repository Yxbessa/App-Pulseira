import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String urlServidor = 'https://seu-site-externo.com/api/rastreio';

  static Future<void> enviarDadosRastreio({
    required String nomeResponsavel,
    required String emailContato,
    required String telefoneContato,
    required double distancia,
    required int statusConexao, 
  }) async {
    try {
      // O JSON limpo e direto para o painel de atendimento
      Map<String, dynamic> dadosJson = {
        'nome_pai': nomeResponsavel,
        'email_contato': emailContato,
        'telefone_contato': telefoneContato,
        'distancia_metros': double.parse(distancia.toStringAsFixed(2)),
        'status': statusConexao,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(urlServidor),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dadosJson),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("⚠️ Erro na API (Status ${response.statusCode})");
      }
    } catch (e) {
      print("❌ Sem conexão com o servidor externo.");
    }
  }
}