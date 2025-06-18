import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:tf02app/view/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Importante para operações assíncronas antes do runApp

  // Criação do cliente MQTT
  final client = MqttServerClient('172.25.120.43', 'flutter_client');
  client.port = 1883;
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.secure = false;

  // Configuração da mensagem de conexão
  client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier('flutter_client')
      .authenticateAs('appix', 'appix102030')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  // Adicionando callbacks para monitorar o estado da conexão
  client.onConnected = () {
    print('Callback: Conectado ao broker MQTT');
  };

  client.onDisconnected = () {
    print('Callback: Desconectado do broker MQTT');
  };

  try {
    print('Tentando conectar ao broker MQTT...');
    await client.connect();

    // Aguarda a conexão ser estabelecida
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Conectado com sucesso!');
    } else {
      print('Falha na conexão, status: ${client.connectionStatus}');
      client.disconnect();
      return;
    }
  } catch (e) {
    print('Erro ao conectar: $e');
    client.disconnect();
    return;
  }

  // Garante que o widget HomePage receba o cliente já conectado
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final MqttServerClient client;

  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App TF02',
      home: HomePage(client: client),
    );
  }
}
