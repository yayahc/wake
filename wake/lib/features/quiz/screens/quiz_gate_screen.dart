import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wake/services/alarm_scheduler.dart';
import 'package:wake/services/pending_quiz.dart';

class QuizGateScreen extends StatefulWidget {
  const QuizGateScreen({super.key, required this.quiz});

  final PendingQuiz quiz;

  @override
  State<QuizGateScreen> createState() => _QuizGateScreenState();
}

class _QuizGateScreenState extends State<QuizGateScreen> {
  late _Challenge _challenge = _Challenge.random();
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _wrong = false;
  bool _solving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final answer = int.tryParse(_controller.text.trim());
    if (answer == null) return;

    if (answer != _challenge.answer) {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _challenge = _Challenge.random();
        _controller.clear();
      });
      _focus.requestFocus();
      return;
    }

    setState(() => _solving = true);
    await AlarmScheduler.markQuizSolved(widget.quiz.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icon(
                  Icons.alarm_on,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.quiz.message.isEmpty ? 'Wake up' : widget.quiz.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                if (widget.quiz.retryCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dismissed ${widget.quiz.retryCount} '
                    'time${widget.quiz.retryCount == 1 ? '' : 's'}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  _challenge.question,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  enabled: !_solving,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Answer',
                    errorText: _wrong
                        ? 'Not quite. Here is another one.'
                        : null,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
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
  const _Challenge({required this.question, required this.answer});

  final String question;
  final int answer;

  factory _Challenge.random() {
    final random = Random();
    final a = 12 + random.nextInt(88);
    final b = 12 + random.nextInt(88);
    return switch (random.nextInt(3)) {
      0 => _Challenge(question: '$a + $b', answer: a + b),
      1 => _Challenge(question: '$a - $b', answer: a - b),
      _ => _Challenge(
        question: '${a % 13 + 2} x ${b % 9 + 3}',
        answer: (a % 13 + 2) * (b % 9 + 3),
      ),
    };
  }
}
