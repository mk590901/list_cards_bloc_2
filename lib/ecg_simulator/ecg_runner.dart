import 'package:list_cards/ecg_simulator/ecg_param2.dart';

import 'ecg_generator.dart';
import 'ecg_log.dart';

class EcgRunner {
  final EcgLogWindow log = EcgLogWindow();
  final EcgParam2  param = EcgParam2();
  late ECGGenerator generator;

  EcgRunner() {
    generator = ECGGenerator(param: param, log: log);
  }

  List<int> generateBuffer() {
    List<int> buffer = [];
    var [time, voltage, peak] = generator.generateBuffer(256);
    for (int j = 0; j < time.length; j++) {
      double doubleValue = voltage[j] as double;
      int intValue = (doubleValue * 1000).toInt();
      buffer.add(intValue);
    }
    return buffer;
  }
}
