class RoomConfig {
  int adults;
  int children;
  List<int> childAges;

  RoomConfig({
    this.adults = 1,
    this.children = 0,
    List<int>? childAges,
  }) : childAges = childAges ?? [];

  // Add a child with age
  void addChild(int age) {
    children++;
    childAges.add(age);
  }

  // Remove last child
  void removeChild() {
    if (children > 0) {
      children--;
      childAges.removeLast();
    }
  }

  // Update child age at index
  void updateChildAge(int index, int age) {
    if (index < childAges.length) {
      childAges[index] = age;
    }
  }

  // Copy method
  RoomConfig copy() {
    return RoomConfig(
      adults: adults,
      children: children,
      childAges: List.from(childAges),
    );
  }
}