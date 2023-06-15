// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:simple_pip_mode/actions/pip_action.dart';
import 'package:simple_pip_mode/actions/pip_actions_layout.dart';

/// Main controller class.
/// It can verify whether the system supports PIP,
/// check whether the app is currently in PIP mode,
/// request entering PIP mode,
/// and call some callbacks when the app changes its mode.
class SimplePip {
  static const MethodChannel _channel = MethodChannel('puntito.simple_pip_mode');

  /// Whether this device supports PIP mode.
  static Future<bool> get isPipAvailable async {
    final bool? isAvailable = await _channel.invokeMethod('isPipAvailable');
    return isAvailable ?? false;
  }

  /// Whether the device supports AutoEnter PIP parameter (Android S)
  static Future<bool> get isAutoPipAvailable async {
    final bool? isAvailable = await _channel.invokeMethod('isAutoPipAvailable');
    return isAvailable ?? false;
  }

  /// Whether the app is currently in PIP mode.
  static Future<bool> get isPipActivated async {
    final bool? isActivated = await _channel.invokeMethod('isPipActivated');
    return isActivated ?? false;
  }

  /// Request entering PIP mode
  Future<bool> enterPipMode({
    aspectRatio = const [16, 9],
    autoEnter = false,
    seamlessResize = false,
  }) async {
    Map params = {'aspectRatio': aspectRatio, 'seamlessResize': seamlessResize};
    final autoEnterSuccessfully = await setAutoEnter(autoEnter: autoEnter);
    final bool? enteredSuccessfully = await _channel.invokeMethod('enterPipMode', params);
    return autoEnterSuccessfully && (enteredSuccessfully ?? false);
  }

  /// Request setting automatic PIP mode.
  /// Android 12 (Android S, API level 31) or newer required.
  Future<bool> setAutoPipMode({
    aspectRatio = const [16, 9],
    seamlessResize = false,
  }) async {
    Map params = {'aspectRatio': aspectRatio, 'seamlessResize': seamlessResize};
    final autoEnterSuccessfully = await setAutoEnter(autoEnter: true);
    final bool? setSuccessfully = await _channel.invokeMethod('setAutoPipMode', params);
    return autoEnterSuccessfully && (setSuccessfully ?? false);
  }

  Future<bool> setAutoEnter({bool autoEnter = false}) async {
    Map params = {'autoEnter': autoEnter};
    final bool? setSuccessfully = await _channel.invokeMethod('setAutoEnter', params);
    return setSuccessfully ?? false;
  }

  /// Updates the current actions layout with a preset layout
  /// The preset layout is defined by [PipActionsLayout] and it's equivalent enum inside Android src
  Future<bool> setPipActionsLayout(PipActionsLayout layout) async {
    Map params = {'layout': layout.name};
    final bool? setSuccessfully = await _channel.invokeMethod('setPipLayout', params);
    return setSuccessfully ?? false;
  }

  /// Updates the actions [PipAction.play] and [PipAction.pause]
  /// When it is called it does re-render the action inside PIP acording with [isPlaying] value
  ///
  /// If [isPlaying] is `true` then PIP will shows [PipAction.pause] action
  /// If [isPlaying] is `false` then PIP will shows [PipAction.play] action
  ///
  /// NOTE: This method should ONLY be used to update PIP action when the player state was changed by
  /// OTHER button that is NOT the PIP's one (ex.: the player play/pause button, notification controller play/pause button
  /// or whatever button you have that calls your playerController's play/pause). When user taps PIP's [PipAction.play] or
  /// [PipAction.pause] it automatically updates the action, WITHOUT NEEDING to call this [setIsPlaying] method.
  ///
  /// Only affects media actions layout presets or presets that uses [PipAction.play] or [PipAction.pause] actions.
  Future<bool> setIsPlaying(bool isPlaying) async {
    Map params = {'isPlaying': isPlaying};
    final bool? setSuccessfully = await _channel.invokeMethod('setIsPlaying', params);
    return setSuccessfully ?? false;
  }

  /// Called when the app enters PIP mode
  VoidCallback? onPipEntered;

  // /// Called when the app exits PIP mode
  VoidCallback? onPipExited;

  // /// Called when the user taps on a PIP action
  void Function(PipAction)? onPipAction;

  final ValueNotifier<bool> pipMode = ValueNotifier(false);

  void _setCallHandler() {
    _channel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case CallMethod.PipEntered:
            onPipEntered?.call();
            pipMode.value = true;
            break;
          case CallMethod.PipExited:
            onPipExited?.call();
            pipMode.value = false;
            break;
          case CallMethod.PipAction:
            String arg = call.arguments;
            PipAction action = PipAction.values.firstWhere((e) => e.name == arg);
            onPipAction?.call(action);
            break;
        }
      },
    );
  }

  SimplePip({
    this.onPipEntered,
    this.onPipExited,
    this.onPipAction,
  }) {
    _setCallHandler();
  }
}

class CallMethod {
  const CallMethod._();
  static const String PipEntered = 'onPipEntered';
  static const String PipExited = 'onPipExited';
  static const String PipAction = 'onPipAction';
}
