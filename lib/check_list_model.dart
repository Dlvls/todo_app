class Checklist {
  final int id;
  final String name;
  final bool checklistCompletionStatus;

  Checklist({
    required this.id,
    required this.name,
    required this.checklistCompletionStatus,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      name: json['name'],
      checklistCompletionStatus: json['checklistCompletionStatus'],
    );
  }
}
