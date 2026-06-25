import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'usuarios_json_db';

  // 1. Adicionamos o 'telefone' nos parâmetros e no mapa do novo usuário
  Future<String?> registrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_usersKey);
      List<dynamic> usuarios = jsonString != null ? jsonDecode(jsonString) : [];

      bool emailJaExiste = usuarios.any((user) => user['email'] == email);
      if (emailJaExiste) {
        return 'Este e-mail já está em uso.';
      }

      Map<String, dynamic> novoUsuario = {
        'nome': nome,
        'email': email,
        'senha': senha, 
        'telefone': telefone, // <-- Salvando o telefone no banco local
        'data_cadastro': DateTime.now().toIso8601String(),
        'uuid_pulseira': '',
      };

      usuarios.add(novoUsuario);
      await prefs.setString(_usersKey, jsonEncode(usuarios));

      return null; 
    } catch (e) {
      return 'Erro ao salvar no JSON: $e';
    }
  }

  // 2. Mudamos o retorno do login para devolver os dados do usuário (Map) ou um Erro (String)
  Future<dynamic> entrar({required String email, required String senha}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_usersKey);
      
      if (jsonString == null) return 'Nenhum usuário cadastrado. Crie uma conta primeiro.';

      List<dynamic> usuarios = jsonDecode(jsonString);

      var usuarioEncontrado = usuarios.cast<Map<String, dynamic>>().firstWhere(
        (user) => user['email'] == email && user['senha'] == senha,
        orElse: () => {}, 
      );

      if (usuarioEncontrado.isEmpty) return 'E-mail ou senha incorretos.';

      // Sucesso! Em vez de retornar null, devolvemos a "ficha" do usuário
      return usuarioEncontrado; 
      
    } catch (e) {
      return 'Erro ao ler o arquivo JSON: $e';
    }
  }
}