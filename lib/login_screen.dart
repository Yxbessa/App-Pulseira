import 'package:flutter/material.dart';
import 'auth_service.dart';
// Precisamos importar o main.dart para o login enxergar a HomeScreen
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController(); // Usado só no cadastro
  final _telefoneController = TextEditingController(); // NOVO: Campo de Telefone
  
  bool _isLogin = true; 
  bool _isLoading = false;

void _submeter() async {
    setState(() => _isLoading = true);
    
    String? erro;
    // Variáveis que vão armazenar os dados finais que irão para a HomeScreen
    String nomeFinal = "";
    String emailFinal = _emailController.text.trim();
    String telefoneFinal = "";

    if (_isLogin) {
      // TENTA LOGAR
      var resultado = await _authService.entrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
      );

      if (resultado is String) {
        erro = resultado; // Se retornou String, é uma mensagem de erro
      } else if (resultado is Map<String, dynamic>) {
        // Se retornou um Map, o login foi sucesso! Puxamos os dados do banco local
        nomeFinal = resultado['nome'] ?? "Responsável";
        telefoneFinal = resultado['telefone'] ?? "";
      }
    } else {
      // TENTA CADASTRAR
      erro = await _authService.registrarUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
        telefone: _telefoneController.text.trim(), // Enviando para o banco
      );
      
      if (erro == null) {
        // Se o cadastro deu certo, os dados finais são os que ele acabou de digitar
        nomeFinal = _nomeController.text.trim();
        telefoneFinal = _telefoneController.text.trim();
      }
    }

    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } else {
      // Navegando com os dados garantidos (seja do banco ou da digitação nova)
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            nomePai: nomeFinal, 
            emailPai: emailFinal,
            telefonePai: telefoneFinal,
          )
        ),
      );
    }  
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Entrar' : 'Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLogin) ...[
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              // ==========================================
              // NOVO: Campo para o Telefone de Contato
              // ==========================================
              TextField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone para Contato (com DDD)', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submeter,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(_isLogin ? 'Entrar' : 'Cadastrar', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Não tem conta? Cadastre-se' : 'Já tem conta? Entre aqui'),
            ),
          ],
        ),
      ),
    );
  }
}