import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_search_query.dart';
import 'diy_child_ages.dart';
import 'diy_common.dart';
import 'diy_trip_day_card.dart';

/// "Select Rooms and Guests" — Figma `Holiday room`: Rooms, Adults and
/// Children steppers in their own cards, each child's age underneath, and
/// DONE. The one sheet for the home search, Edit Your Search and MODIFY.
///
/// Resolves to the query with the new party, or null when dismissed.
Future<DiySearchQuery?> showDiyRoomsSheet(
  BuildContext context, {
  required DiySearchQuery query,
}) {
  return showModalBottomSheet<DiySearchQuery>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
    ),
    builder: (_) => _RoomsSheet(query: query),
  );
}

/// Rooms, adults and children — with each child's age, which hotels price
/// on. Pops the edited query on DONE.
class _RoomsSheet extends StatefulWidget {
  final DiySearchQuery query;

  const _RoomsSheet({required this.query});

  @override
  State<_RoomsSheet> createState() => _RoomsSheetState();
}

class _RoomsSheetState extends State<_RoomsSheet> {
  late int _rooms = widget.query.rooms;
  late int _adults = widget.query.adults;
  late int _children = widget.query.children;
  late List<int> _ages = widget.query.childAgesFilled;

  @override
  Widget build(BuildContext context) {
    Widget row(String title, String subtitle, int value, int min, int max,
        ValueChanged<int> onChanged) {
      Widget step(IconData icon, bool enabled, VoidCallback onTap) {
        return GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: context.w(36),
            height: context.w(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: DiyTripStyle.divider),
            ),
            child: Icon(icon,
                size: context.w(20),
                color: enabled ? DiyTokens.blue : const Color(0xFFC7CCD6)),
          ),
        );
      }

      return Container(
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(14),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: DiyTripStyle.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F9),
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: context.fs(10), color: DiyTripStyle.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            step(Icons.remove_rounded, value > min, () => onChanged(value - 1)),
            SizedBox(
              width: context.w(40),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            step(Icons.add_rounded, value < max, () => onChanged(value + 1)),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(12),
          context.w(16),
          context.h(16) + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.w(48),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DDE4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),
              Text(
                'Select Rooms and Guests',
                style: TextStyle(fontSize: context.fs(13), color: Colors.black),
              ),
              SizedBox(height: context.h(14)),
              row('Rooms', '', _rooms, 1, 9,
                  (v) => setState(() => _rooms = v)),
              row('Adults', '', _adults, 1, 20,
                  (v) => setState(() => _adults = v)),
              row('Children', '0-17y', _children, 0, 10, (v) {
                setState(() {
                  _children = v;
                  _ages = DiySearchQuery.fitChildAges(_ages, v);
                });
              }),
              DiyChildAgesPanel(
                ages: _ages,
                onChanged: (next) => setState(() => _ages = next),
              ),
              SizedBox(height: context.h(16)),
              SizedBox(
                width: double.infinity,
                height: context.h(48),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(
                    widget.query.copyWith(
                      rooms: _rooms,
                      adults: _adults,
                      children: _children,
                      childAges: _ages,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiyTripStyle.orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
