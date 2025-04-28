# A realistic ECG waveform generator on flutter

The application below is a runtime ECG simulator using the ECGSYN code, where small batches of samples (e.g. 128, 200, 256, 500 or 1000 samples per second) are generated.

The project code https://github.com/mk590901/ecg_calc/ is modified to support streaming data generation instead of creating the full signal (65K samples) at once. This will minimize memory usage by avoiding storing large vectors and will provide data output as needed. The approach to modifying the source code, including key changes, solution architecture and implementation example are described below.

## Approach to Modification
* Need to create a new class __ECGGenerator__ replaces __EcgCalc__ and allows encapsulating intermedia state and streaming logic.
* Move configuration to the constructor of the __ECGGenerator__ class.

## Perform refactoring of RR-Interval Generation
* Need adapt the __rrprocess__ procedure to generate a small batch of RR-intervals (e.g., 10) on-demand, storing them in a buffer.
* Need preserve the FFT-based spectral synthesis using __ifft__ function.

## Stream PQRST Generation
* Need modify the trajectory integration (__rk4__, __derivspqrst__) to produce samples incrementally for a given buffer size.
* Need to update state (time, phase, coordinates) after generate each buffer.

## Handle Peak Detection:
* Peak detection should be done on each buffer, storing results incrementally if needed.
  
## Scaling and Noise
* Need apply scaling and noise to each buffer, tracking min/max dynamically or using predefined ranges.

## To implement streaming Interface:
Must create __generateBuffer(int size)__ procedure for synchronous buffer generation.

## State Management:
Need store runtime state (current time, RR-intervals, trajectory coordinates, etc.) in the basic class.

## Key Changes and Features

### Class Structure
* __ECGGenerator__ replaces __EcgCalc__, initialized with an __EcgParam__ and __EcgLogWindow__.
* Stores configuration parameters directly from __EcgParam__, adjusting __ti, ai, bi__ in _initializeParameters.

### State Management
Tracks runtime state: _t (current time), _x (trajectory coordinates), _rrBuffer (RR-intervals), _zmin/_zmax (for scaling).
Maintains random number generator state (_rseed, _iy, _iv) for ran1.

### RR-Interval Generation
_generateRRBuffer generates a small batch (512 RR-intervals) using function rrprocess, storing up to 10 in _rrBuffer.
_rrIndex and _nextRRTime ensure smooth transitions between RR-intervals.

### Buffer Generation
* generateBuffer(int bufSize) produces a list of [time, voltage, peak] for bufSize samples.
* Integrates at internal frequency (sf), downsamples to sfecg, detects peaks, and applies scaling/noise.
* Updates _t and _x for continuity.

## Memory Efficiency
Uses small arrays (xt, yt, zt, etc.) sized for one buffer, avoiding large storage.
_rrBuffer is limited to 10 intervals, recomputed as needed.

# Integration.
To visualize the __ECG__ signal, an application created a year ago is used, which can be found in the repository https://github.com/mk590901/list_cards_bloc. In the updateBuffer procedure of the __StoreWrapper__ class, the __rowData__ data buffer is filled by the __simulator.generateBuffer()__ procedure of the simulator. It replaces the giant buffer of static data used in the original version.

# Movie












