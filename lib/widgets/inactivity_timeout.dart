import 'dart:async';
import 'package:flutter/widgets.dart';

/// Délai d'inactivité avant de quitter l'écran diag.
const Duration kDiagInactivityTimeout = Duration(minutes: 3);

/// Appelle [onTimeout] après [timeout] sans event pointeur.
/// Tout toucher réarme le compte à rebours.
class InactivityTimeout extends StatefulWidget {
  const InactivityTimeout({
    super.key,
    required this.timeout,
    required this.onTimeout,
    required this.child,
  });

  final Duration timeout;
  final VoidCallback onTimeout;
  final Widget child;

  @override
  State<InactivityTimeout> createState() => _InactivityTimeoutState();
}

class _InactivityTimeoutState extends State<InactivityTimeout> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _arm(),
      onPointerMove: (_) => _arm(),
      onPointerUp: (_) => _arm(),
      child: widget.child,
    );
  }
}
