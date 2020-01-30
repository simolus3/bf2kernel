import 'dart:io';

import 'package:bf2kernel/bf2kernel.dart';
import 'package:cli_util/cli_util.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final sdkPath = getSdkPath();
  final platformStrongDill =
      p.join(sdkPath, 'lib', '_internal', 'vm_platform_strong.dill');
  final platform = loadComponentFromBinary(platformStrongDill);

  if (arguments.isEmpty) {
    print('Usage: dart bin/main.dart path-to-bf-file');
    return;
  }

  final inputFile = File(arguments.first);
  final input = inputFile.readAsBytesSync();

  var brainfuckCode = parseBf(input);

  final uri = inputFile.uri;
  final generator = KernelGenerator(platform, brainfuckCode, inputUri: uri);
  generator.compile();

  writeComponentToBinary(platform, 'out.dill');
}
