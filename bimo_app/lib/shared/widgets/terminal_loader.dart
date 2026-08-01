import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class TerminalLoader extends StatefulWidget {
  final bool isComplete;
  final VoidCallback onFinished;

  const TerminalLoader({
    Key? key,
    required this.isComplete,
    required this.onFinished,
  }) : super(key: key);

  @override
  State<TerminalLoader> createState() => _TerminalLoaderState();
}

class _TerminalLoaderState extends State<TerminalLoader> {
  int _progress = 0;
  String _statusText = 'Initializing BiMO NLP Extraction Engine...';
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (mounted) {
        setState(() {
          if (_progress < 35) {
            _statusText = 'Analyzing project prompt & system architecture...';
            _progress += _random.nextInt(12) + 6;
          } else if (_progress < 70) {
            _statusText = 'Extracting components & checking voltage specs...';
            _progress += _random.nextInt(10) + 4;
          } else if (_progress < 96) {
            _statusText = 'Matching local Agora suppliers & pricing in ₱ PHP...';
            _progress += _random.nextInt(4) + 1;
          } else {
            _progress = 99;
            _statusText = 'Finalizing Bill of Materials & optimization...';
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(TerminalLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isComplete && !oldWidget.isComplete) {
      _timer?.cancel();
      setState(() {
        _progress = 100;
        _statusText = 'Extraction & Compatibility Check Complete!';
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) widget.onFinished();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    _windowDot(Colors.red),
                    const SizedBox(width: 6),
                    _windowDot(Colors.amber),
                    const SizedBox(width: 6),
                    _windowDot(Colors.green),
                  ],
                ),
                Expanded(
                  child: Text(
                    'BiMO COMPONENT EXTRACTOR & MATCHING ENGINE',
                    textAlign: TextAlign.center,
                    style: AppTypography.codeFont(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      size: 11,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(width: 48), // Balance dots
              ],
            ),
          ),

          // Terminal Body
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scanner animation visual
                Container(
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D0D11) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emeraldLight.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Container(
                          width: 8,
                          height: 8 + (index % 3) * 12.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Status text and %
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _statusText,
                        style: AppTypography.codeFont(
                          color: AppColors.emeraldLight,
                          size: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${min(_progress, 100)}%',
                      style: AppTypography.codeFont(
                        color: AppColors.emeraldLight,
                        size: 13,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress Bar Track
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 8,
                    color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: min(_progress, 100) / 100,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldLight,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emeraldLight,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
