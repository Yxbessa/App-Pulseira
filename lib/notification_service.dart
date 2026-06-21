import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Cria a instância do plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Função para configurar tudo quando o app abre
  static Future<void> initialize() async {
    // Aqui estamos dizendo para ele usar o ícone padrão do seu app (aquele do Flutter)
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);

    // Inicializa o plugin
await _notificationsPlugin.initialize(settings: initializationSettings);
}

  // Função que será chamada para exibir a notificação de fato
  static Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ble_alarme_channel', // Um ID interno do canal
      'Alarmes de Distância', // O nome que aparece nas configurações do celular
      channelDescription: 'Avisa quando o beacon se afasta muito ou perde o sinal.',
      importance: Importance.max,   // Faz a notificação fazer barulho
      priority: Priority.high,      // Faz a notificação pular no topo da tela
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Mostra a notificação. O ID 0 significa que se houver outra notificação antiga nossa, 
    // ela será substituída pela nova, para não lotar o celular do usuário.
await _notificationsPlugin.show(
  id: 0, 
  title: title, 
  body: body, 
  notificationDetails: platformDetails, // <-- É só adicionar esta linha!
);  }
}