import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class RoomData {
  int adults;
  int children;
  List<int> childrenAges;

  RoomData({
    this.adults = 1,
    this.children = 0,
    List<int>? childrenAges,
  }) : childrenAges = childrenAges ?? [];
}

class RoomGuestSelector extends StatefulWidget {
  final List<RoomData> initialRooms;
  final Function(List<RoomData>) onDone;

  const RoomGuestSelector({
    super.key,
    required this.initialRooms,
    required this.onDone,
  });

  @override
  State<RoomGuestSelector> createState() => _RoomGuestSelectorState();
}

class _RoomGuestSelectorState extends State<RoomGuestSelector> {
  late List<RoomData> rooms;

  @override
  void initState() {
    super.initState();
    rooms = widget.initialRooms
        .map(
          (e) => RoomData(
        adults: e.adults,
        children: e.children,
        childrenAges: List<int>.from(e.childrenAges),
      ),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: context.gapMedium),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              children: List.generate(
                rooms.length,
                    (index) => _buildRoomCard(index),
              ),
            ),
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),

          InkWell(
            onTap: _addRoom,
            child: Padding(
              padding: EdgeInsets.all(context.gapMedium),
              child: Row(
                children: [
                  Text(
                    '+ Add Another Room',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: context.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: SizedBox(
              width: double.infinity,
              height: context.buttonHeight + 8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(context.borderRadius),
                  ),
                ),
                onPressed: () {
                  widget.onDone(rooms);
                },
                child: Text(
                  'DONE',
                  style: TextStyle(
                    fontSize: context.labelLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(int index) {
    final room = rooms[index];

    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: index != rooms.length - 1
            ? Colors.grey.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${index + 1}',
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (index != rooms.length - 1)
                      Padding(
                        padding:
                        EdgeInsets.only(top: context.gapSmall),
                        child: Text(
                          '${room.adults} Adults ${room.children} Children',
                          style: TextStyle(
                            fontSize: context.bodyMedium,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (index != rooms.length - 1)
                Icon(
                  Icons.edit_outlined,
                  color: Colors.grey.shade700,
                ),

              SizedBox(width: context.gapMedium),

              GestureDetector(
                onTap: rooms.length == 1
                    ? null
                    : () {
                  setState(() {
                    rooms.removeAt(index);
                  });
                },
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          if (index == rooms.length - 1) ...[
            SizedBox(height: context.gapLarge),

            _counterRow(
              title: 'Adults',
              value: room.adults,
              onMinus: () {
                if (room.adults > 1) {
                  setState(() {
                    room.adults--;
                  });
                }
              },
              onPlus: () {
                setState(() {
                  room.adults++;
                });
              },
            ),

            SizedBox(height: context.gapLarge),

            _counterRow(
              title: 'Children',
              subtitle: '0–12 Years',
              value: room.children,
              onMinus: () {
                if (room.children > 0) {
                  setState(() {
                    room.children--;
                    room.childrenAges.removeLast();
                  });
                }
              },
              onPlus: () {
                setState(() {
                  room.children++;
                  room.childrenAges.add(5);
                });
              },
            ),

            if (room.children > 0) ...[
              SizedBox(height: context.gapLarge),

              Column(
                children: List.generate(
                  room.children,
                      (childIndex) => Padding(
                    padding: EdgeInsets.only(
                      bottom: context.gapMedium,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Child ${childIndex + 1} Age',
                            style: TextStyle(
                              fontSize: context.bodyLarge,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.gapMedium,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(
                              context.borderRadius,
                            ),
                          ),
                          child: DropdownButton<int>(
                            value:
                            room.childrenAges[childIndex],
                            underline:
                            const SizedBox.shrink(),
                            items: List.generate(
                              13,
                                  (age) => DropdownMenuItem(
                                value: age,
                                child: Text('$age'),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                room.childrenAges[childIndex] =
                                    value ?? 5;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _counterRow({
    required String title,
    String? subtitle,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: context.gapSmall),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Text(
          '$value',
          style: TextStyle(
            fontSize: context.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(width: context.gapLarge),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius:
            BorderRadius.circular(context.borderRadius),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addRoom() {
    setState(() {
      rooms.add(RoomData());
    });
  }
}