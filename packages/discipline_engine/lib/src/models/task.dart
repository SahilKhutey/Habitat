// Canonical Task Model with Categories, Difficulties & Proof Rules
enum TaskCategory { morning, physical, personal, mind, environment, routine }
enum TaskDifficulty { easy, medium, hard }
enum ProofType { photo, video, sensor }
enum VerificationType { basic, smartCv, aiAction }

class Task {
  final String id;
  final String? userId;
  final String slug;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final ProofType proofType;
  final VerificationType verificationType;
  final int baseXp;
  final int estimatedDurationSec;
  final String iconName;
  final List<String> instructions;
  final Map<String, dynamic> validationRules;
  final bool isStarter;
  final DateTime createdAt;

  const Task({
    required this.id,
    this.userId,
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    this.difficulty = TaskDifficulty.medium,
    required this.proofType,
    this.verificationType = VerificationType.basic,
    this.baseXp = 50,
    this.estimatedDurationSec = 60,
    this.iconName = 'hotel',
    required this.instructions,
    this.validationRules = const {},
    this.isStarter = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'slug': slug,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name.toUpperCase(),
        'proofType': proofType.name.toUpperCase(),
        'verificationType': verificationType.name.toUpperCase(),
        'baseXp': baseXp,
        'estimatedDurationSec': estimatedDurationSec,
        'iconName': iconName,
        'instructions': instructions,
        'validationRules': validationRules,
        'isStarter': isStarter,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: TaskCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['category'] as String).toLowerCase(),
          orElse: () => TaskCategory.routine,
        ),
        difficulty: TaskDifficulty.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['difficulty'] as String? ?? 'medium').toLowerCase(),
          orElse: () => TaskDifficulty.medium,
        ),
        proofType: ProofType.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['proofType'] as String).toLowerCase(),
          orElse: () => ProofType.photo,
        ),
        verificationType: VerificationType.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['verificationType'] as String? ?? 'basic').toLowerCase(),
          orElse: () => VerificationType.basic,
        ),
        baseXp: json['baseXp'] as int? ?? 50,
        estimatedDurationSec: json['estimatedDurationSec'] as int? ?? 60,
        iconName: json['iconName'] as String? ?? 'hotel',
        instructions: (json['instructions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        validationRules: json['validationRules'] as Map<String, dynamic>? ?? {},
        isStarter: json['isStarter'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
