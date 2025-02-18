class Item {
  int? id;
  String title;
  String? description;

  Item({this.id, required this.title, this.description});

  // Convert a Map into an Item object
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }

  // Convert an Item object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}
