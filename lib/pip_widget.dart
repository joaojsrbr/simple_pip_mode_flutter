import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simple_pip_mode/actions/pip_action.dart';
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
  final VoidCallback? onPipEntered;
  final VoidCallback? onPipExited;
  final SimplePip? simplePip;
  final void Function(PipAction)? onPipAction;
  final Widget Function(BuildContext)? builder;
  final Widget? child;
  final Widget Function(BuildContext)? pipBuilder;
  final Widget? pipChild;
  final PipActionsLayout? pipLayout;
  const PipWidget({
    Key? key,
    this.onPipEntered,
    this.onPipExited,
    this.onPipAction,
    this.simplePip,
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

  late final StreamSubscription<bool> _onPipEnteredSubscription;
  late final StreamSubscription<bool> _onPipExitedSubscription;
  late final StreamSubscription<PipAction> _onPipActionSubscription;

  @override
  void initState() {
    super.initState();

    _pip = widget.simplePip ?? SimplePip();
    _onPipEnteredSubscription = _pip.onPipEntered.listen(_onPipEntered);
    _onPipExitedSubscription = _pip.onPipExited.listen(_onPipExited);
    _onPipActionSubscription = _pip.onPipAction.listen(_onPipAction);
    if (widget.pipLayout != null) _pip.setPipActionsLayout(widget.pipLayout!);
  }

  /// The app entered PIP mode
  void _onPipEntered(bool active) {
    setState(() => _pipMode = true);
    widget.onPipEntered?.call();
  }

  /// The app exited PIP mode
  void _onPipExited(bool active) {
    setState(() => _pipMode = false);
    widget.onPipExited?.call();
  }

  /// The user taps one PIP action
  void _onPipAction(PipAction action) {
    widget.onPipAction?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    return _pipMode ? (widget.pipBuilder?.call(context) ?? widget.pipChild!) : (widget.builder?.call(context) ?? widget.child!);
  }

  @override
  void dispose() {
    _onPipEnteredSubscription.cancel();
    _onPipActionSubscription.cancel();
    _onPipExitedSubscription.cancel();
    _pip.dispose();
    super.dispose();
  }
}
