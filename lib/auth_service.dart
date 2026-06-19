import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para CRIAR a conta e salvar os dados iniciais no Banco
  Future<String?> registrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      // 1. Cria a credencial de segurança no Auth
      UserCredential credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // 2. Salva as informações extras no banco de dados Firestore
      if (credencial.user != null) {
        await _firestore.collection('usuarios').doc(credencial.user!.uid).set({
          'nome': nome,
          'email': email,
          'data_cadastro': DateTime.now(),
          'uuid_pulseira': '', // Pode ser preenchido depois
        });
      }
      return null; // Retorna null se deu tudo certo
      
    } on FirebaseAuthException catch (e) {
      // Traduz os erros clássicos do Firebase
      if (e.code == 'weak-password') return 'A senha é muito fraca.';
      if (e.code == 'email-already-in-use') return 'Este e-mail já está em uso.';
      return e.message;
    } catch (e) {
      return 'Erro desconhecido: $e';
    }
  }

  // Função para FAZER LOGIN
  Future<String?> entrar({required String email, required String senha}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'E-mail ou senha incorretos.';
      }
      return e.message;
    }
  }

  // Função para SAIR
  Future<void> sair() async {
    await _auth.signOut();
  }
}