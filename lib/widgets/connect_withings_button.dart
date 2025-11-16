import 'package:flutter/material.dart';
import '../services/withings_service.dart';

/// Connect Withings Button Widget
///
/// Displays connection status and allows user to:
/// - Connect to Withings (if not connected)
/// - Sync measurements (if connected)
/// - Disconnect (if connected)
class ConnectWithingsButton extends StatefulWidget {
  final VoidCallback? onConnectionChanged;
  final VoidCallback? onSyncComplete;

  const ConnectWithingsButton({
    Key? key,
    this.onConnectionChanged,
    this.onSyncComplete,
  }) : super(key: key);

  @override
  State<ConnectWithingsButton> createState() => _ConnectWithingsButtonState();
}

class _ConnectWithingsButtonState extends State<ConnectWithingsButton> {
  final WithingsService _withingsService = WithingsService();
  bool _isConnected = false;
  bool _isLoading = true;
  String? _error;
  String? _withingsUserId;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await _withingsService.getConnectionStatus();
      setState(() {
        _isConnected = status['connected'] as bool;
        _withingsUserId = status['withings_user_id'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  Future<void> _connectWithings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Start OAuth flow (opens browser)
      await _withingsService.startAuthorization();

      // Show dialog explaining what's happening
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Authorization in Progress'),
            content: const Text(
              'A browser window has opened for you to authorize the app.\n\n'
              'After authorizing, return to the app and tap "Check Status" to complete the connection.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncMeasurements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Sync measurements from last 30 days
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final measurements = await _withingsService.syncMeasurements(
        startDate: startDate,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced ${measurements.length} measurements'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSyncComplete?.call();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    // Confirm disconnect
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Withings?'),
        content: const Text(
          'This will remove your Withings connection. You will need to re-authorize to sync measurements again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _withingsService.disconnect();

      setState(() {
        _isConnected = false;
        _withingsUserId = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from Withings'),
            backgroundColor: Colors.orange,
          ),
        );

        widget.onConnectionChanged?.call();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _checkConnectionStatus,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (!_isConnected) {
      // Not connected - show connect button
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Connect your Withings scale to sync body composition data',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _connectWithings,
            icon: const Icon(Icons.link),
            label: const Text('Connect Withings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    // Connected - show sync and disconnect options
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Connected to Withings',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (_withingsUserId != null) ...[
          const SizedBox(height: 4),
          Text(
            'User ID: $_withingsUserId',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _syncMeasurements,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _checkConnectionStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
