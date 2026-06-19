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
  
  bool _isLogin = true; // Controla se estamos na tela de Entrar ou Cadastrar
  bool _isLoading = false;

  void _submeter() async {
    setState(() => _isLoading = true);
    
    String? erro;
    if (_isLogin) {
      erro = await _authService.entrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
      );
    } else {
      erro = await _authService.registrarUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
      );
    }

    setState(() => _isLoading = false);
    if(!mounted) {
      return;
    }
    if (erro != null) {
      // Mostra o erro na tela
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } else {
      // Sucesso! Aqui você navega para a tela principal da pulseira
        print("Usuário autenticado com sucesso!");Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuaTelaPrincipal()));
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