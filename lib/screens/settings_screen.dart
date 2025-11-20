import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio output options
enum AudioOutput {
  earpiece,  // Earpiece/Bluetooth headphones (default behavior)
  speaker,   // iPhone's built-in speaker
}

/// Settings Screen
///
/// Allows user to configure app settings including:
/// - Audio output (Earpiece/Headphones vs Speaker)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AudioOutput _audioOutput = AudioOutput.earpiece;
  bool _isLoading = true;

  static const String _audioOutputKey = 'audio_output_preference';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOutput = prefs.getString(_audioOutputKey);

      setState(() {
        if (savedOutput == 'speaker') {
          _audioOutput = AudioOutput.speaker;
        } else {
          _audioOutput = AudioOutput.earpiece;
        }
        _isLoading = false;
      });

      print('⚙️ [Settings] Loaded audio output: $_audioOutput');
    } catch (e) {
      print('❌ [Settings] Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAudioOutput(AudioOutput output) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _audioOutputKey,
        output == AudioOutput.speaker ? 'speaker' : 'earpiece'
      );

      setState(() {
        _audioOutput = output;
      });

      print('⚙️ [Settings] Saved audio output: $output');

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              output == AudioOutput.speaker
                ? 'Audio will play through speaker'
                : 'Audio will play through earpiece/headphones'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [Settings] Error saving audio output: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio Settings Card
                  _buildAudioSettingsCard(),
                  const SizedBox(height: 16),

                  // Info Card
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAudioSettingsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue.shade400, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Audio Output',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where Hera\'s voice will be played',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Earpiece/Headphones Option
            RadioListTile<AudioOutput>(
              title: const Text('Earpiece / Headphones'),
              subtitle: Text(
                'Uses earpiece when no headphones connected, or plays through connected Bluetooth/wired headphones',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: AudioOutput.earpiece,
              groupValue: _audioOutput,
              onChanged: (value) {
                if (value != null) {
                  _saveAudioOutput(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // Speaker Option
            RadioListTile<AudioOutput>(
              title: const Text('iPhone Speaker'),
              subtitle: Text(
                'Always plays through the iPhone\'s built-in speaker, even when headphones are connected',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: AudioOutput.speaker,
              groupValue: _audioOutput,
              onChanged: (value) {
                if (value != null) {
                  _saveAudioOutput(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This setting affects where Hera\'s voice responses are played. '
                'The change takes effect on the next voice response.',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static helper to get current audio output preference
class AudioSettings {
  static const String _audioOutputKey = 'audio_output_preference';

  /// Get the current audio output preference
  /// Returns true if speaker is selected, false for earpiece/headphones
  static Future<bool> shouldUseSpeaker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOutput = prefs.getString(_audioOutputKey);
      return savedOutput == 'speaker';
    } catch (e) {
      print('❌ [AudioSettings] Error reading preference: $e');
      return false; // Default to earpiece/headphones
    }
  }
}
