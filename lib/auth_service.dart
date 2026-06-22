import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Chave usada para salvar o JSON no armazenamento local
  static const String _usersKey = 'usuarios_json_db';

  // Função para CRIAR a conta e salvar os dados no JSON
  Future<String?> registrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lê o JSON atual do celular
      String? jsonString = prefs.getString(_usersKey);
      
      // Converte o texto JSON numa lista do Dart. Se não existir, cria uma lista vazia.
      List<dynamic> usuarios = jsonString != null ? jsonDecode(jsonString) : [];

      // Verifica se o e-mail já existe na lista
      bool emailJaExiste = usuarios.any((user) => user['email'] == email);
      if (emailJaExiste) {
        return 'Este e-mail já está em uso.';
      }

      // Cria o novo usuário em formato de Mapa (Dictionary)
      Map<String, dynamic> novoUsuario = {
        'nome': nome,
        'email': email,
        'senha': senha, // Apenas para fins acadêmicos/locais
        'data_cadastro': DateTime.now().toIso8601String(),
        'uuid_pulseira': '',
      };

      // Adiciona na lista e salva de volta no armazenamento convertendo para JSON
      usuarios.add(novoUsuario);
      await prefs.setString(_usersKey, jsonEncode(usuarios));

      return null; // Sucesso (nenhum erro)
      
    } catch (e) {
      return 'Erro ao salvar no JSON: $e';
    }
  }

  // Função para FAZER LOGIN lendo do JSON
  Future<String?> entrar({required String email, required String senha}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lê o JSON salvo
      String? jsonString = prefs.getString(_usersKey);
      
      if (jsonString == null) {
        return 'Nenhum usuário cadastrado. Crie uma conta primeiro.';
      }

      List<dynamic> usuarios = jsonDecode(jsonString);

      // Procura um usuário que tenha o e-mail E a senha iguais aos digitados
      var usuarioEncontrado = usuarios.cast<Map<String, dynamic>>().firstWhere(
        (user) => user['email'] == email && user['senha'] == senha,
        orElse: () => {}, // Retorna vazio se não achar
      );

      // Se o mapa estiver vazio, as credenciais estão erradas
      if (usuarioEncontrado.isEmpty) {
        return 'E-mail ou senha incorretos.';
      }

      return null; // Sucesso!
      
    } catch (e) {
      return 'Erro ao ler o arquivo JSON: $e';
    }
  }

  // Função para SAIR (Como o login é local agora, não precisamos derrubar sessão de servidor)
  Future<void> sair() async {
    // Pode ficar vazio para a lógica atual
  }
}