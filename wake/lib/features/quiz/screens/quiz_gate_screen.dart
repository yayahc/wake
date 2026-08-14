import 'package:flutter/material.dart';
import 'package:wake/core/domain/usecases/alarm_usecases.dart';

class QuizGateScreen extends StatefulWidget {
  const QuizGateScreen({super.key, required this.alarmId});

  final int alarmId;

  @override
  State<QuizGateScreen> createState() => _QuizGateScreenState();
}

class _QuizGateScreenState extends State<QuizGateScreen> {
  final _controller = TextEditingController();
  late _Challenge _challenge = _Challenge.random(widget.alarmId);
  bool _wrong = false;
  bool _resolving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_resolving) return;
    if (int.tryParse(_controller.text.trim()) != _challenge.answer) {
      setState(() {
        _wrong = true;
        _challenge = _Challenge.random(widget.alarmId + _challenge.answer);
        _controller.clear();
      });
      return;
    }

    setState(() => _resolving = true);
    final result = await AlarmUsecases.resolveQuiz(widget.alarmId);
    if (!mounted) return;
    result.fold(
      (error) {
        setState(() => _resolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyErrorMessage)),
        );
      },
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solve to stop the alarm',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  _challenge.question,
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: _wrong ? 'Not quite. New question.' : null,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _resolving ? null : _submit,
                  child: Text(_resolving ? 'Stopping...' : 'Stop alarm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Challenge {
  const _Challenge(this.question, this.answer);

  final String question;
  final int answer;

  factory _Challenge.random(int seed) {
    final a = 12 + (seed * 7) % 76;
    final b = 13 + (seed * 13) % 74;
    return _Challenge('$a + $b', a + b);
  }
}
