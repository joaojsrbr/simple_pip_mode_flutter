import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simple_pip_mode/actions/pip_actions_layout.dart';
import 'package:simple_pip_mode/simple_pip.dart';

/// Widget that uses PIP callbacks to build some widgets depending on PIP state.
/// At least one of [builder] or [child] must not be null.
/// At least one of [pipBuilder] or [pipChild] must not be null.
///
/// Parameters:
/// * [pipBuilder] function is used when app is in PIP mode.
/// * [pipChild] widget is used when app is in PIP mode and [pipBuilder] is null.
/// * [builder] function is used when app is not in PIP mode.
/// * [child] widget is used when app is not in PIP mode and [builder] is null.
/// * [onPipEntered] function is called when app enters PIP mode.
/// * [onPipExited] function is called when app exits PIP mode.
/// * [pipLayout] defines the PIP actions preset layout.
///
/// See also:
/// * [SimplePip], to handle callbacks.
class PipWidget extends StatefulWidget {
  final Widget Function(BuildContext)? builder;
  final Widget? child;
  final Widget Function(BuildContext)? pipBuilder;
  final Widget? pipChild;
  final PipActionsLayout? pipLayout;
  const PipWidget({
    Key? key,
    this.builder,
    this.child,
    this.pipBuilder,
    this.pipChild,
    this.pipLayout,
  })  : assert(child != null || builder != null),
        assert(pipChild != null || pipBuilder != null),
        super(key: key);

  @override
  State<PipWidget> createState() => _PipWidgetState();
}

class _PipWidgetState extends State<PipWidget> {
  /// Pip controller to handle callbacks
  late final SimplePip _pip;

  /// Whether the app is currently in PIP mode
  bool _pipMode = false;

  StreamSubscription<PipState>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _pip = SimplePip.instance;
    _streamSubscription = _pip.onPipChange.listen(_onPipStateChange);
    if (widget.pipLayout != null) _pip.setPipActionsLayout(widget.pipLayout!);
  }

  void _onPipStateChange(PipState state) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      switch (state) {
        case PipState.pipEntered:
          setState(() => _pipMode = true);
          break;
        case PipState.pipExited:
          setState(() => _pipMode = false);
          break;
        default:
          setState(() => _pipMode = false);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _pipMode ? 0 : 1,
      children: [
        (widget.pipBuilder?.call(context) ?? widget.pipChild!),
        (widget.builder?.call(context) ?? widget.child!),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _pip.dispose();
    super.dispose();
  }
}
