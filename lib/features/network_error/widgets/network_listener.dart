import 'dart:async';
import 'package:blacklist_plus_flutter/features/network_error/screens/network_error_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkListener extends StatefulWidget {
  final Widget child;
  const NetworkListener({super.key, required this.child});

  @override
  State<NetworkListener> createState() => _NetworkListenerState();
}

class _NetworkListenerState extends State<NetworkListener> {
  bool? isOffline;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _checkInitialStatus();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (mounted) {
        setState(() {
          isOffline = !hasConnection;
        });
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        isOffline = !hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return isOffline! ? const NetworkErrorScreen() : widget.child;
  }
}
