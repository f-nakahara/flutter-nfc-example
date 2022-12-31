import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NfcReadPage(),
    );
  }
}

class NfcReadPage extends StatefulWidget {
  const NfcReadPage({Key? key}) : super(key: key);

  @override
  State<NfcReadPage> createState() => _NfcReadPageState();
}

class _NfcReadPageState extends State<NfcReadPage> {
  int balance = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: NfcManager.instance.isAvailable(),
          builder: (context, ss) {
            if (ss.data == true) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$balance 円'),
                    ElevatedButton(
                      onPressed: () async {
                        NfcManager.instance.startSession(
                          onDiscovered: (tag) async {
                            final pollingRes = await polling(tag);
                            final idm = pollingRes.sublist(2, 10);
                            final readWithoutEncryptionRes =
                                await readWithoutEncryption(tag, idm: idm);
                            print(readWithoutEncryptionRes);
                          },
                        );
                      },
                      child: const Text('読み込む'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text('対応していません'),
            );
          },
        ),
      ),
    );
  }

  /// Polling
  Future<Uint8List> polling(NfcTag tag) async {
    final systemCode = [0xFE, 0x00];
    final List<int> packet = [];
    if (Platform.isAndroid) {
      packet.add(0x06);
    }
    packet.add(0x00);
    packet.addAll(systemCode.reversed);
    packet.add(0x01);
    packet.add(0x0F);

    final command = Uint8List.fromList(packet);

    late final Uint8List? res;

    if (NfcF.from(tag) != null) {
      final nfcf = NfcF.from(tag);
      res = await nfcf?.transceive(data: command);
    } else if (FeliCa.from(tag) != null) {
      final felica = FeliCa.from(tag);
      res = await felica?.sendFeliCaCommand(command);
    }
    if (res == null) {
      throw Exception();
    }
    return res;
  }

  /// RequestService
  Future<Uint8List> requestService(
    NfcTag tag, {
    required Uint8List idm,
  }) async {
    final serviceCode = [0x50, 0xD7];
    final nodeCodeList = Uint8List.fromList(serviceCode);
    final List<int> packet = [];
    if (Platform.isAndroid) {
      packet.add(0x06);
    }
    packet.add(0x02);
    packet.addAll(idm);
    packet.add(nodeCodeList.elementSizeInBytes);
    packet.addAll(serviceCode.reversed);

    final command = Uint8List.fromList(packet);

    late final Uint8List? res;

    if (NfcF.from(tag) != null) {
      final nfcf = NfcF.from(tag);
      res = await nfcf?.transceive(data: command);
    } else if (FeliCa.from(tag) != null) {
      final felica = FeliCa.from(tag);
      res = await felica?.sendFeliCaCommand(command);
    }
    if (res == null) {
      throw Exception();
    }
    return res;
  }

  /// ReadWithoutEncryption
  Future<Uint8List> readWithoutEncryption(
    NfcTag tag, {
    required Uint8List idm,
  }) async {
    const blockCount = 1;
    final serviceCode = [0x50, 0xD7];
    final List<int> packet = [];
    if (Platform.isAndroid) {
      packet.add(0);
    }
    packet.add(0x06);
    packet.addAll(idm);
    packet.add(serviceCode.length ~/ 2);
    packet.addAll(serviceCode.reversed);
    packet.add(blockCount);

    for (int i = 0; i < blockCount; i++) {
      packet.add(0x80);
      packet.add(i);
    }
    if (Platform.isAndroid) {
      packet[0] = packet.length;
    }

    final command = Uint8List.fromList(packet);

    late final Uint8List? res;

    if (NfcF.from(tag) != null) {
      final nfcf = NfcF.from(tag);
      res = await nfcf?.transceive(data: command);
    } else if (FeliCa.from(tag) != null) {
      final felica = FeliCa.from(tag);
      res = await felica?.sendFeliCaCommand(command);
    }
    if (res == null) {
      throw Exception();
    }
    return res;
  }
}
