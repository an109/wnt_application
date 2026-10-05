import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'diy_common.dart';

/// The "Age of children" panel under the Children stepper — one row per
/// child, each with its own −/+ age stepper (0–17).
///
/// Hotels price children by age, so the price call needs one per child. The
/// list always has exactly as many entries as there are children: the parent
/// trims or pads it with [DiySearchQuery.fitChildAges] whenever the count
/// changes, and this widget only edits ages in place.
class DiyChildAgesPanel extends StatelessWidget {
  final List<int> ages;
  final ValueChanged<List<int>> onChanged;

  static const int minAge = 0;
  static const int maxAge = 17;

  const DiyChildAgesPanel({
    super.key,
    required this.ages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (ages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: context.h(8)),
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(12),
        context.w(14),
        context.h(6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age of children',
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(4)),
          for (var i = 0; i < ages.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(6)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Child ${i + 1}',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.navy,
                      ),
                    ),
                  ),
                  _step(
                    context,
                    icon: Icons.remove,
                    enabled: ages[i] > minAge,
                    onTap: () => _set(i, ages[i] - 1),
                  ),
                  SizedBox(
                    width: context.w(40),
                    child: Text(
                      ages[i] == 0 ? '<1y' : '${ages[i]}y',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                      ),
                    ),
                  ),
                  _step(
                    context,
                    icon: Icons.add,
                    enabled: ages[i] < maxAge,
                    onTap: () => _set(i, ages[i] + 1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _set(int index, int age) {
    final next = List<int>.from(ages);
    next[index] = age.clamp(minAge, maxAge);
    onChanged(next);
  }

  Widget _step(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: context.w(26),
        height: context.w(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(6)),
          border: Border.all(color: DiyTokens.line),
        ),
        child: Icon(
          icon,
          size: context.w(14),
          color: enabled ? DiyTokens.blue : const Color(0xFFC7CCD6),
        ),
      ),
    );
  }
}
