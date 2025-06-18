import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:toggle_switch/toggle_switch.dart';

void main() {
  final client = MqttServerClient('broker.hivemq.com', 'flutter_client_id');
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final MqttServerClient client;
  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Demo',
      home: HomePage(client: client),
    );
  }
}

class HomePage extends StatefulWidget {
  final MqttServerClient client;
  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String mensagemRecebida = 'Aguardando dados...';

  double distInicial = 0;
  double distAtual = 0;
  double velocidade = 0;
  DateTime? ultimoTimestamp;

  @override
  void initState() {
    super.initState();
    connectAndSubscribe(widget.client);
    publishMessage(widget.client, "1");

    widget.client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payloadString = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      try {
        final data = jsonDecode(payloadString);
        final dataDistance = data['distance'];
        final dataTemperature = data['temperature'];
        final dataStrength = data['strength'];
        String distance = "$dataDistance";

        final agora = DateTime.now();

        if (ultimoTimestamp != null) {
          final diferenca =
              agora.difference(ultimoTimestamp!).inMilliseconds /
              1000.0; // segundos

          setState(() {
            final double calcVelocidade;
            distAtual = double.parse(distance) / 100;
            if (distAtual > distInicial) {
              calcVelocidade = ((distAtual - distInicial) / diferenca) * 3.6;
            } else {
              calcVelocidade = ((distInicial - distAtual) / diferenca) * 3.6;
            }

            velocidade = calcVelocidade;
            distInicial = distAtual;
            ultimoTimestamp = agora;

            mensagemRecebida =
                'Distância: $distAtual\nVelocidade: ${velocidade.toStringAsFixed(2)} Km/h \nTemperatura: $dataTemperature C \nStrength: $dataStrength';
          });
        } else {
          // Primeira leitura, só inicializa valores
          setState(() {
            distInicial = double.parse(distance);
            ultimoTimestamp = agora;
            mensagemRecebida =
                'Distância inicial: $dataDistance\nAguardando próxima leitura para calcular velocidade.';
          });
        }
      } catch (e) {
        setState(() {
          mensagemRecebida = 'Erro ao interpretar JSON:\n$payloadString';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: body(), // sua função ou widget
          ),
        ),
      ),
    );
  }

  Widget body() {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // Text(mensagemRecebida),
          _buttons(widget.client),
          SizedBox(height: 20),
          _getRadialGauge(),
          _getLinearGauge(),
        ],
      ),
    );
  }

  Widget _getLinearGauge() {
    return SizedBox(
      child: Column(
        children: [
          Text(
            "Distância : $distAtual m",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          SizedBox(
            height: 200,
            child: SfLinearGauge(
              minimum: 0.0,
              maximum: 45.0,
              tickPosition: LinearElementPosition.inside,
              orientation: LinearGaugeOrientation.vertical,
              minorTicksPerInterval: 4,
              useRangeColorForAxis: true,
              animateAxis: true,
              majorTickStyle: LinearTickStyle(length: 20),
              axisLabelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
              axisTrackStyle: LinearAxisTrackStyle(
                thickness: 10,
                edgeStyle: LinearEdgeStyle.bothFlat,
              ),
              markerPointers: [
                LinearShapePointer(
                  value: distInicial,
                  offset: 25,
                  shapeType: LinearShapePointerType.triangle,
                  position: LinearElementPosition.inside,
                ),
              ],
              ranges: <LinearGaugeRange>[
                LinearGaugeRange(
                  startWidth: 0,
                  endWidth: 100,
                  position: LinearElementPosition.outside,
                  shaderCallback: (bounds) => RadialGradient(
                    center: Alignment.bottomRight,
                    radius: 1.5,
                    colors: [Colors.red, Colors.orange, Colors.green],
                  ).createShader(bounds),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getRadialGauge() {
    return SizedBox(
      height: 250,
      width: 250,
      child: SfRadialGauge(
        title: GaugeTitle(
          text: 'Velocimetro',
          textStyle: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 150,
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 0,
                endValue: 50,
                color: Colors.green,
                startWidth: 10,
                endWidth: 10,
              ),
              GaugeRange(
                startValue: 50,
                endValue: 100,
                color: Colors.orange,
                startWidth: 10,
                endWidth: 10,
              ),
              GaugeRange(
                startValue: 100,
                endValue: 150,
                color: Colors.red,
                startWidth: 10,
                endWidth: 10,
              ),
            ],
            pointers: <GaugePointer>[NeedlePointer(value: velocidade)],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  velocidade.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                angle: 90,
                positionFactor: 0.5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buttons(MqttServerClient client) {
  return ToggleSwitch(
    minWidth: 90.0,
    cornerRadius: 20.0,
    activeBgColors: [
      [Colors.green[800]!],
      [Colors.red[800]!],
    ],
    activeFgColor: Colors.white,
    inactiveBgColor: Colors.grey,
    inactiveFgColor: Colors.white,
    initialLabelIndex: 0,
    totalSwitches: 2,
    labels: ['On', 'Off'],
    radiusStyle: true,
    onToggle: (index) {
      if (index == 0) {
        publishMessage(client, "1");
        index = 1;
      } else {
        publishMessage(client, "0");
        index = 0;
      }
    },
  );
}

void publishMessage(MqttServerClient client, String message) {
  String topic = "appix/sensor/state";
  final builder = MqttClientPayloadBuilder();
  builder.addString(message);

  client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  print('Mensagem publicada em $topic: $message');
}

Future<void> connectAndSubscribe(MqttServerClient client) async {
  client.logging(on: true);

  client.onDisconnected = () {
    debugPrint('Desconectado do broker');
  };

  client.onConnected = () {
    debugPrint('Conectado ao broker MQTT');
  };

  client.onSubscribed = (String topic) {
    debugPrint('Inscrito no tópico: $topic');
  };

  try {
    await client.connect();
  } catch (e) {
    debugPrint('Erro na conexão MQTT: $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    debugPrint('Conectado com sucesso!');
    const topic = 'appix/sensor/tf02'; // seu tópico MQTT
    client.subscribe(topic, MqttQos.atMostOnce);
  } else {
    debugPrint('Falha na conexão, status: ${client.connectionStatus!.state}');
    client.disconnect();
  }
}
