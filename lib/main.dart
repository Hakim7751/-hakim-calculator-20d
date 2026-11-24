import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorHistoryApp());
}

class CalculatorHistoryApp extends StatelessWidget {
  const CalculatorHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'آلة حاسبة بسجل 20 يوماً',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CalculatorHomeScreen(),
    );
  }
}

class CalcRecord {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalcRecord({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}

class CalculatorHomeScreen extends StatefulWidget {
  const CalculatorHomeScreen({super.key});

  @override
  State<CalculatorHomeScreen> createState() => _CalculatorHomeScreenState();
}

class _CalculatorHomeScreenState extends State<CalculatorHomeScreen> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  final List<CalcRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _cleanExpiredRecords();
  }

  void _cleanExpiredRecords() {
    final now = DateTime.now();
    _history.removeWhere(
      (record) => now.difference(record.timestamp).inDays > 20,
    );
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit == '.' ? '0.' : digit;
        _shouldResetDisplay = false;
      } else {
        if (digit == '.' && _display.contains('.')) return;
        _display += digit;
      }
    });
  }

  void _onOperatorPress(String op) {
    final current = double.tryParse(_display);
    if (current == null) return;

    setState(() {
      _firstOperand = current;
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEqualsPress() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_display);
    if (secondOperand == null) return;

    double calcResult;
    switch (_operator) {
      case '+':
        calcResult = _firstOperand! + secondOperand;
        break;
      case '-':
        calcResult = _firstOperand! - secondOperand;
        break;
      case '×':
        calcResult = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          setState(() {
            _display = 'خطأ: قسمة على صفر';
            _firstOperand = null;
            _operator = null;
            _shouldResetDisplay = true;
          });
          return;
        }
        calcResult = _firstOperand! / secondOperand;
        break;
      default:
        return;
    }

    final formattedResult = _formatNumber(calcResult);
    final formattedFirst = _formatNumber(_firstOperand!);
    final formattedSecond = _formatNumber(secondOperand);
    final expressionText = '$formattedFirst $_operator $formattedSecond';

    _cleanExpiredRecords();

    setState(() {
      _history.insert(
        0,
        CalcRecord(
          expression: expressionText,
          result: formattedResult,
          timestamp: DateTime.now(),
        ),
      );
      _display = formattedResult;
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _onClearPress() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final targetStart = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = targetStart.difference(todayStart).inDays;

    String dayLabel;
    if (dayDiff == 0) {
      dayLabel = 'اليوم';
    } else if (dayDiff == -1) {
      dayLabel = 'أمس';
    } else if (dayDiff == 1) {
      dayLabel = 'غداً';
    } else {
      dayLabel = '${dt.year}/${dt.month}/${dt.day}';
    }

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayLabel • ${dt.year}/${dt.month}/${dt.day} • $hour:$minute';
  }

  void _openHistorySheet() {
    _cleanExpiredRecords();
    setState(() {});

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'سجل العمليات (آخر 20 يوماً)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(
                          child: Text('لا توجد عمليات محفوظة ضمن آخر 20 يوماً.'),
                        )
                      : ListView.separated(
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return ListTile(
                              title: Text(
                                '${item.expression} = ${item.result}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(_formatTimestamp(item.timestamp)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(
    String label, {
    Color? bgColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? Colors.grey.shade200,
            foregroundColor: textColor ?? Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آلة حاسبة (سجل 20 يوماً)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'السجل',
              onPressed: _openHistorySheet,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_firstOperand != null && _operator != null)
                        Text(
                          '${_formatNumber(_firstOperand!)} $_operator',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      Text(
                        _display,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildButton(
                      'C',
                      bgColor: Colors.red.shade100,
                      textColor: Colors.red.shade900,
                      onTap: _onClearPress,
                    ),
                    _buildButton(
                      'السجل',
                      bgColor: Colors.amber.shade100,
                      textColor: Colors.amber.shade900,
                      onTap: _openHistorySheet,
                    ),
                    _buildButton('÷', onTap: () => _onOperatorPress('÷')),
                    _buildButton('×', onTap: () => _onOperatorPress('×')),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7', onTap: () => _onDigitPress('7')),
                    _buildButton('8', onTap: () => _onDigitPress('8')),
                    _buildButton('9', onTap: () => _onDigitPress('9')),
                    _buildButton('-', onTap: () => _onOperatorPress('-')),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4', onTap: () => _onDigitPress('4')),
                    _buildButton('5', onTap: () => _onDigitPress('5')),
                    _buildButton('6', onTap: () => _onDigitPress('6')),
                    _buildButton('+', onTap: () => _onOperatorPress('+')),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1', onTap: () => _onDigitPress('1')),
                    _buildButton('2', onTap: () => _onDigitPress('2')),
                    _buildButton('3', onTap: () => _onDigitPress('3')),
                    _buildButton(
                      '=',
                      bgColor: Colors.indigo,
                      textColor: Colors.white,
                      onTap: _onEqualsPress,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('0', onTap: () => _onDigitPress('0')),
                    _buildButton('.', onTap: () => _onDigitPress('.')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
