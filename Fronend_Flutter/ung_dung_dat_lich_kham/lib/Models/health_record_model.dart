class HealthRecordModel {
  String height;
  String weight;
  String bloodType;
  String gender;
  String currentCondition;
  String personalNotes;

  HealthRecordModel({
    required this.height,
    required this.weight,
    required this.bloodType,
    required this.gender,
    this.currentCondition = '',
    this.personalNotes = '',
  });
}