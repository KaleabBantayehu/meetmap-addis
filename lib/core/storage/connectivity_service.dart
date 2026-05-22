import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  late final Connectivity _connectivity;
  
  List<ConnectivityResult> _currentResults = [ConnectivityResult.none];
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  ConnectivityService._();

  static ConnectivityService get instance {
    if (_instance == null) {
      throw Exception('ConnectivityService must be initialized by calling init()');
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    
    final service = ConnectivityService._().._connectivity = Connectivity();
    
    try {
      service._currentResults = await service._connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Failed to get initial connectivity status: $e');
    }

    service._connectivity.onConnectivityChanged.listen((results) {
      service._currentResults = results;
      final connected = service.isConnected;
      service._controller.add(connected);
      debugPrint('Connectivity changed: $results (isConnected: $connected)');
    });

    _instance = service;
  }

  /// Returns true if the device is connected to internet (Wifi, Mobile, VPN, etc.)
  bool get isConnected {
    if (_currentResults.isEmpty) return false;
    if (_currentResults.length == 1 && _currentResults.first == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  /// Broadcast stream of connection changes
  Stream<bool> get onConnectivityChanged => _controller.stream;
}
