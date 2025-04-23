import 'package:list_cards/ecg_simulator/ecg_param.dart';
import 'ecg_generator.dart';
import 'ecg_log.dart';

// Source: A separate Java version of ECGSYN is available from the MIT website at Java ECG Generator,
// where the source code can be downloaded.

class EcgRunner {
  final EcgLogWindow log = EcgLogWindow();
  final EcgParam  param = EcgParam();
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
