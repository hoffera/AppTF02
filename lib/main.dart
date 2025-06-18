import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:tf02app/view/home_page.dart';

void main() async {
  final client = MqttServerClient(
    '172.25.120.43',
    'flutter_client',
  ); // IP e ClientID

  client.port = 1883; // Porta do broker, padrão 1883 para MQTT
  client.logging(on: true);

  client.keepAlivePeriod = 20;

  client.secure = false; // Use true se for conexão segura (TLS)

  // Configurar usuário e senha
  client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier('flutter_client')
      .authenticateAs('appix', 'appix102030')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  try {
    await client.connect();
  } catch (e) {
    print('Erro ao conectar: $e');
    client.disconnect();
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Conectado com sucesso!');
  } else {
    print('Falha na conexão, status: ${client.connectionStatus}');
    client.disconnect();
  }
  runApp(HomePage(client: client));
}
