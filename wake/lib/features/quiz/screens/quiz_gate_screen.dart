import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wake/services/alarm_scheduler.dart';
import 'package:wake/services/pending_quiz.dart';

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

    setState(() => _solving = true);
    await AlarmScheduler.markQuizSolved(widget.quiz.id);
    if (mounted) Navigator.of(context).pop();
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
                  onPressed: _solving ? null : _submit,
                  child: _solving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Stop the alarm'),
                ),
                const SizedBox(height: 12),
                Text(
                  // True on both platforms, by different means: Android keeps
                  // ringing, iOS re-arms.
                  'The alarm will not stop until this is solved.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
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