import 'dart:async';
import 'dart:isolate';

import 'package:mts/core/config/constants.dart';

/// A utility class for managing isolates to perform work in background threads.
class IsolateUtils {
  /// A map to store active isolates by their unique IDs
  static final Map<String, Isolate> _isolates = {};

  /// A map to store send ports for communication with isolates
  static final Map<String, SendPort> _sendPorts = {};

  /// Maximum number of concurrent isolates allowed
  static const int _maxConcurrentIsolates = isolateMaxConcurrent;

  /// Current count of running isolates
  static int _runningIsolatesCount = 0;

  /// Queue of pending isolate tasks
  static final List<_PendingIsolateTask> _pendingTasks = [];

  /// Executes a function in a separate isolate to avoid blocking the main UI thread.
  /// Limits concurrent isolates to [_maxConcurrentIsolates] (default: 4).
  ///
  /// Parameters:
  /// - [uniqueId]: A unique identifier for this isolate task
  /// - [function]: The function to execute in the isolate
  /// - [message]: The data to pass to the function
  /// - [onResult]: Callback function to handle the result from the isolate
  /// - [onError]: Optional callback function to handle errors
  /// - [debugName]: Optional name for debugging purposes
  ///
  /// Returns a [Future] that completes when the isolate is set up (not when work is done)
  static Future<void> execute<T, R>({
    required String uniqueId,
    required Function(T message) function,
    required T message,
    required Function(R result) onResult,
    Function(dynamic error)? onError,
    String? debugName,
  }) async {
    // Queue the task if we've hit the max concurrent limit
    if (_runningIsolatesCount >= _maxConcurrentIsolates) {
      final completer = Completer<void>();
      _pendingTasks.add(
        _PendingIsolateTask(
          uniqueId: uniqueId,
          function: function,
          message: message,
          onResult: onResult,
          onError: onError,
          debugName: debugName,
          completer: completer,
        ),
      );
      // Wait for this task to be executed
      await completer.future;
      return;
    }

    _runningIsolatesCount++;

    try {
      await _executeIsolate<T, R>(
        uniqueId: uniqueId,
        function: function,
        message: message,
        onResult: onResult,
        onError: onError,
        debugName: debugName,
      );
    } finally {
      _runningIsolatesCount--;
      // Process any pending tasks
      _processPendingTasks();
    }
  }

  /// Internal method that executes the isolate
  static Future<void> _executeIsolate<T, R>({
    required String uniqueId,
    required Function(T message) function,
    required T message,
    required Function(R result) onResult,
    Function(dynamic error)? onError,
    String? debugName,
  }) async {
    // Create a receive port for this isolate
    final receivePort = ReceivePort();

    // Create a completer to handle the initial handshake with the isolate
    final completer = Completer<SendPort>();

    // Listen for messages from the isolate
    receivePort.listen((data) {
      if (data is SendPort) {
        // Store the send port for future communication
        _sendPorts[uniqueId] = data;
        completer.complete(data);
      } else if (data is _IsolateResponse) {
        if (data.isError) {
          // Handle error if error callback is provided
          if (onError != null) {
            onError(data.data);
          }
        } else {
          // Handle successful result
          onResult(data.data as R);
        }
      } else if (data == 'ISOLATE_DONE') {
        // Clean up when isolate signals it's done
        _cleanupIsolate(uniqueId);
      }
    });

    try {
      // Spawn a new isolate
      final isolate = await Isolate.spawn<_IsolateData<T>>(
        _isolateEntryPoint,
        _IsolateData<T>(
          function: function,
          message: message,
          sendPort: receivePort.sendPort,
        ),
        debugName: debugName ?? 'isolate-$uniqueId',
        errorsAreFatal: true,
      );

      // Store the isolate reference
      _isolates[uniqueId] = isolate;

      // Wait for the send port from the isolate
      await completer.future;
    } catch (e) {
      // Handle any errors during isolate creation
      if (onError != null) {
        onError(e);
      }
      _cleanupIsolate(uniqueId);
    }
  }

  /// Process pending tasks in queue
  static void _processPendingTasks() {
    while (_pendingTasks.isNotEmpty &&
        _runningIsolatesCount < _maxConcurrentIsolates) {
      final task = _pendingTasks.removeAt(0);
      _runningIsolatesCount++;

      // Execute the pending task asynchronously
      unawaited(
        _executeIsolate<dynamic, dynamic>(
              uniqueId: task.uniqueId,
              function: task.function(),
              message: task.message,
              onResult: task.onResult(),
              onError: task.onError != null ? task.onError!() : null,
              debugName: task.debugName,
            )
            .then((_) {
              _runningIsolatesCount--;
              task.completer.complete();
              _processPendingTasks();
            })
            .catchError((e) {
              _runningIsolatesCount--;
              task.completer.completeError(e);
              _processPendingTasks();
            }),
      );
    }
  }

  /// Sends a message to an existing isolate
  ///
  /// Parameters:
  /// - [uniqueId]: The unique identifier of the target isolate
  /// - [message]: The message to send
  ///
  /// Returns [true] if the message was sent successfully, [false] otherwise
  static bool sendMessage<T>(String uniqueId, T message) {
    final sendPort = _sendPorts[uniqueId];
    if (sendPort != null) {
      sendPort.send(message);
      return true;
    }
    return false;
  }

  /// Terminates an isolate by its unique ID
  ///
  /// Parameters:
  /// - [uniqueId]: The unique identifier of the isolate to terminate
  static void terminateIsolate(String uniqueId) {
    final isolate = _isolates[uniqueId];
    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      _cleanupIsolate(uniqueId);
    }
  }

  /// Checks if an isolate with the given ID is currently running
  ///
  /// Parameters:
  /// - [uniqueId]: The unique identifier to check
  ///
  /// Returns [true] if the isolate exists, [false] otherwise
  static bool hasIsolate(String uniqueId) {
    return _isolates.containsKey(uniqueId);
  }

  /// Cleans up isolate resources
  static void _cleanupIsolate(String uniqueId) {
    _isolates.remove(uniqueId);
    _sendPorts.remove(uniqueId);
  }

  /// The entry point function that runs in the isolate
  static void _isolateEntryPoint<T>(_IsolateData<T> data) {
    // Create a receive port for receiving messages from the main isolate
    final receivePort = ReceivePort();

    // Send the send port back to the main isolate
    data.sendPort.send(receivePort.sendPort);

    // Listen for messages from the main isolate
    receivePort.listen((message) {
      // Handle additional messages if needed
    });

    try {
      // Execute the function with the provided message
      final result = data.function(data.message);

      // Send the result back to the main isolate
      if (result is Future) {
        // Handle async functions
        result.then(
          (value) =>
              data.sendPort.send(_IsolateResponse(data: value, isError: false)),
          onError:
              (error) => data.sendPort.send(
                _IsolateResponse(data: error.toString(), isError: true),
              ),
        );
      } else {
        // Handle synchronous functions
        data.sendPort.send(_IsolateResponse(data: result, isError: false));
      }
    } catch (e) {
      // Send any errors back to the main isolate
      data.sendPort.send(_IsolateResponse(data: e.toString(), isError: true));
    } finally {
      // Signal that the isolate has completed its work
      data.sendPort.send('ISOLATE_DONE');
    }
  }
}

/// A class to hold data sent to the isolate
class _IsolateData<T> {
  final Function function;
  final T message;
  final SendPort sendPort;

  _IsolateData({
    required this.function,
    required this.message,
    required this.sendPort,
  });
}

/// A class to represent responses from the isolate
class _IsolateResponse {
  final dynamic data;
  final bool isError;

  _IsolateResponse({required this.data, required this.isError});
}

/// A class to hold pending isolate tasks
class _PendingIsolateTask {
  final String uniqueId;
  final Function function;
  final dynamic message;
  final Function onResult;
  final Function? onError;
  final String? debugName;
  final Completer<void> completer;

  _PendingIsolateTask({
    required this.uniqueId,
    required this.function,
    required this.message,
    required this.onResult,
    required this.onError,
    required this.debugName,
    required this.completer,
  });
}

/// A simple mutex implementation for synchronization
class Mutex {
  Completer<void>? _completer;

  /// Acquire the lock
  Future<void> acquire() async {
    if (_completer != null) {
      await _completer!.future;
    }
  }

  /// Release the lock
  void release() {
    if (_completer != null) {
      _completer!.complete();
      _completer = null;
    }
  }
}
