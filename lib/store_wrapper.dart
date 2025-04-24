import 'package:flutter/material.dart';
import 'circular_buffer.dart';
import 'ecg_simulator/ecg_simulator.dart';
import 'graph_mode.dart';
import 'utils.dart';

List<int> rowData = List<int>.filled(256, 0);

class StoreWrapper {

  final int _drawSeriesLength;  //  Drawable data size per second
  final int _seriesNumber;      //  Data buffer size
  final int _seriesLength;      //  Number of displayed drawable data pieces
  late GraphMode _mode;  //  Mode

  late  CircularBuffer<int> buffer_;

  final EcgSimulator simulator = EcgSimulator();

  late  double  step;
  late  Path    path;
  late  Path    pathBefore;
  late  Path    pathAfter;
  late  Offset  point;

  late bool full;
  late int writeIndex;
  late int readIndex;
  late int size;

  StoreWrapper(this._seriesLength, this._seriesNumber, this._drawSeriesLength, this._mode) {
    buffer_ = CircularBuffer<int>(_seriesLength*_seriesNumber);
  }

  CircularBuffer<int> buffer() {
    return buffer_;
  }

  int drawingFrequency() {
    //return ((rowData.length).toDouble()/_drawSeriesLength).toInt();
    return ((256).toDouble()/_drawSeriesLength).toInt();
  }

  int seriesLength() {
    return _drawSeriesLength;
  }

  void updateBuffer(final int counter) {
    int seriesSize = seriesLength();

    if ((counter-1) == 0) {
      List<int> buffer = simulator.generateBuffer();
      for (int i = 0; i < buffer.length; i++) {
        rowData[i] = buffer[i];
      }
    }

    List<int> dataExtracted = extractRangeData(rowData, (counter-1)*seriesSize, seriesSize);
    //print ('seriesSize->$seriesSize, counter->$counter, dataExtracted.len->${dataExtracted.length}');
    buffer_.writeRow(dataExtracted);
  }

  double getMin() {
    int minV = 0;
    List<int?> rowData = buffer_.buffer();
    if (buffer_.size() == buffer_.capacity()-1) {
      minV = getMinForFullBuffer(buffer_);
      for (int i = 1; i < buffer_.capacity(); i++) {
        int? value = rowData[i];
        if (value != null) {
          if (value < minV) {
            minV = value;
          }
        }
      }
    }
    else {
      minV = rowData[0]!;
      for (int i = 1; i < buffer_.size(); i++) {
        if (rowData[i]! < minV) {
          minV = rowData[i]!;
        }
      }
    }
    return minV.toDouble();
  }

  double getMax() {
    int maxV = 0;
    List<int?> rowData = buffer_.buffer();
    if (buffer_.size() == buffer_.capacity()-1) {
      maxV = getMinForFullBuffer(buffer_);
      for (int i = 1; i < buffer_.capacity(); i++) {
        int? value = rowData[i];
        if (value != null) {
          if (value > maxV) {
            maxV = value;
          }
        }
      }
    }
    else {
      maxV = rowData[0]!;
      for (int i = 1; i < buffer_.size(); i++) {
        if (rowData[i]! > maxV) {
          maxV = rowData[i]!;
        }
      }
    }
    return maxV.toDouble();
  }

  List<double>  prepareData(final Size size, final double shiftH) {
    List<double> data = [];

    double width  = size.width;
    double height = size.height;

    double minV = getMin();
    double maxV = getMax();

    if (minV == maxV) {
      minV = minV/2;
      maxV = maxV + minV/2;
    }

    double dv = maxV - minV;
    step = width/(buffer_.capacity()).toDouble();
    double coeff = (height - 2 * shiftH).toDouble()/dv;

    List<int> dataTemp = (_mode == GraphMode.overlay)
        ? dataSeriesOverlay(buffer_)
        : dataSeriesNormal(this);
    data = List<double>.filled(dataTemp.length, 0.0);
    for (int i = 0; i < dataTemp.length; i++) {
      data[i] = (maxV - dataTemp[i].toDouble()) * coeff + shiftH;
    }
    return data;
  }

  Path preparePath(final List<double> data) {
    Path path = Path();
    path.moveTo(0, data[0]);
    for (int i = 1; i < data.length; i++) {
      path.lineTo(i * step, data[i]);
    }
    return path;
  }

  Path preparePathBefore(final List<double> data) {
    int idx_ = buffer_.writeIndex()-1;
    int idx = idx_ < 0 ? 0 : idx_;
    Path path = Path();
    path.moveTo(0, data[0]);
    for (int i = 1; i < idx; i++) {
      path.lineTo(i * step, data[i]);
    }
    return path;
  }

  Path preparePathAfter(final List<double> data) {
    int idx_ = buffer_.writeIndex()-1;
    int idx = idx_ < 0 ? 0 : idx_;
    Path path = Path();
    path.moveTo(idx * step, data[idx]);
    for (int i = idx; i < data.length; i++) {
      path.lineTo(i * step, data[i]);
    }
    return path;
  }

  Offset preparePoint(final List<double> data) {
    int idx_ = buffer_.writeIndex()-1;
    int idx = idx_ < 0 ? 0 : idx_;
    Offset? point = Offset(idx * step, data[idx]);
    return point;
  }

  void prepareDrawing(final Size size, final double shiftH) {
    List<double> data = prepareData(size, shiftH);
    path = preparePath(data);
    pathBefore = preparePathBefore(data);
    pathAfter = preparePathAfter(data);
    point = preparePoint(data);
  }

  void storeCircularBufferParams() {
    full = buffer_.isFull();
    writeIndex = buffer_.writeIndex();
    readIndex = buffer_.readIndex();
    size = buffer_.size();
  }

  void restoreCircularBufferParams() {
    buffer_.setFull(full);
    buffer_.setWriteIndex(writeIndex);
    buffer_.setReadIndex(readIndex);
    buffer_.setSize(size);
  }

  GraphMode mode() {
    return _mode;
  }

  void setMode(GraphMode mode) {
    _mode = mode;
  }

  bool isFull() {
    return buffer_.isFull();
  }

}
