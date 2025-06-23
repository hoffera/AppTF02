import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:tf02app/components/roundedBox.dart';

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
      title: 'TF02 App',
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
  double tempAtual = 0;
  DateTime? ultimoTimestamp;
  bool index = false;

  @override
  void initState() {
    super.initState();
    connectAndSubscribe(widget.client);

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
        String temp = "$dataTemperature";

        final agora = DateTime.now();

        if (ultimoTimestamp != null) {
          final diferenca =
              agora.difference(ultimoTimestamp!).inMilliseconds /
              1000.0; // segundos

          setState(() {
            tempAtual = double.parse(temp);
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
        backgroundColor: Color(0xFF000000),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: body(), // sua função ou widget
            ),
          ),
        ),
      ),
    );
  }

  Widget body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        index ? _sensores() : _circular(),
        SizedBox(height: 10),
        RoundedBox(widget: _button(widget.client)),
      ],
    );
  }

  Widget _circular() {
    return Column(
      children: [
        SizedBox(height: 250),
        Text(
          "Sensor desconectado",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 50),
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(color: Colors.red),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget _sensores() {
    return Column(
      children: [
        SizedBox(height: 50),
        _getDist(),
        SizedBox(height: 10),
        Row(children: [_getTemp(), SizedBox(width: 10), _getVel()]),
      ],
    );
  }

  Widget _getDist() {
    return RoundedBox(
      widget: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          child: Column(
            children: [
              Text(
                "Distância : $distAtual metros",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(
                height: 250,
                child: SfLinearGauge(
                  minimum: 0.0,
                  maximum: 45.0,
                  tickPosition: LinearElementPosition.cross,
                  orientation: LinearGaugeOrientation.vertical,
                  minorTicksPerInterval: 4,
                  animationDuration: 3000,
                  useRangeColorForAxis: true,
                  animateAxis: true,
                  interval: 5,
                  majorTickStyle: LinearTickStyle(
                    length: 200,
                    color: Colors.white,
                  ),
                  axisLabelStyle: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white,
                  ),
                  axisTrackStyle: LinearAxisTrackStyle(
                    color: Colors.white,
                    thickness: 2,
                    edgeStyle: LinearEdgeStyle.bothFlat,
                  ),
                  markerPointers: [
                    LinearShapePointer(
                      value: distInicial,
                      color: Colors.white,
                      borderColor: Colors.grey,
                      borderWidth: 2,
                      offset: 0,
                      height: 20,
                      width: 20,
                      shapeType: LinearShapePointerType.invertedTriangle,
                      position: LinearElementPosition.outside,
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
                        colors: [Colors.red, Colors.green],
                      ).createShader(bounds),
                    ),

                    LinearGaugeRange(
                      startWidth: 0,
                      endWidth: 100,
                      position: LinearElementPosition.inside,
                      shaderCallback: (bounds) => RadialGradient(
                        center: Alignment.bottomLeft,
                        radius: 1.5,
                        colors: [Colors.red, Colors.green],
                      ).createShader(bounds),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTemp() {
    return RoundedBox(
      widget: SizedBox(
        width: 110,
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                "Temperatura\n $tempAtual °C",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 150,

                child: SfLinearGauge(
                  animationDuration: 3000,
                  minimum: 0.0,
                  maximum: 100.0,
                  interval: 20,
                  tickPosition: LinearElementPosition.inside,
                  orientation: LinearGaugeOrientation.vertical,
                  minorTicksPerInterval: 4,
                  useRangeColorForAxis: true,
                  animateAxis: true,
                  majorTickStyle: LinearTickStyle(
                    length: 10,
                    color: Colors.white,
                  ),
                  axisLabelStyle: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white,
                  ),
                  axisTrackStyle: LinearAxisTrackStyle(
                    thickness: 15,
                    // color: Colors.transparent,
                    borderColor: Colors.white,
                    borderWidth: 2,
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.orange, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    edgeStyle: LinearEdgeStyle.bothCurve,
                  ),
                  markerPointers: [
                    LinearShapePointer(
                      value: tempAtual,
                      offset: 0,
                      borderColor: Colors.white,
                      color: Colors.white,
                      height: 10,
                      width: 10,
                      shapeType: LinearShapePointerType.invertedTriangle,
                      position: LinearElementPosition.outside,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getVel() {
    return RoundedBox(
      widget: SizedBox(
        height: 250,
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SfRadialGauge(
            title: GaugeTitle(
              text: "Velocidade",
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            enableLoadingAnimation: true,
            animationDuration: 3000,
            axes: <RadialAxis>[
              RadialAxis(
                maximum: 100,
                interval: 10,
                minimum: 0,
                axisLabelStyle: GaugeTextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                annotations: [
                  GaugeAnnotation(
                    axisValue: 50,
                    positionFactor: 0.3,
                    widget: Text(
                      '${velocidade.toStringAsFixed(2)}\nKm/h',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: velocidade,
                    needleStartWidth: 1,
                    needleEndWidth: 5,
                    knobStyle: KnobStyle(
                      knobRadius: 0.05,
                      borderColor: Colors.black,
                      borderWidth: 0.02,
                      color: Colors.white,
                    ),
                  ),
                  RangePointer(
                    value: velocidade,
                    dashArray: <double>[8, 2],
                    gradient: const SweepGradient(
                      colors: <Color>[Colors.green, Colors.red],
                      stops: <double>[0.25, 0.75],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(MqttServerClient client) {
    return SizedBox(
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "Status do Sensor:",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Switch(
              value: index,
              activeColor: Colors.green,
              onChanged: (bool value) {
                setState(() {
                  index = value;
                });
                if (index == true) {
                  publishMessage(client, "1");
                } else {
                  publishMessage(client, "0");
                }
              },
            ),
          ],
        ),
      ),
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
}
