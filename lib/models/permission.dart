class ModulePermission {
  final int? id;
  final String? name;
  final String? moduleName;
  final String? slug;

  ModulePermission({this.id, this.name, this.moduleName, this.slug});

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      id: json['id'],
      name: json['name'],
      moduleName: json['module_name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'module_name': moduleName,
      'slug': slug,
    };
  }
}

class FunctionalityPermission {
  final int? id;
  final String? name;
  final String? slug;
  final int? moduleId;

  FunctionalityPermission({this.id, this.name, this.slug, this.moduleId});

  factory FunctionalityPermission.fromJson(Map<String, dynamic> json) {
    return FunctionalityPermission(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      moduleId: json['module_id'] is int ? json['module_id'] : int.tryParse(json['module_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'module_id': moduleId,
    };
  }
}

class PermissionsModel {
  final List<ModulePermission> modules;
  final List<FunctionalityPermission> functionalities;
  final bool isAdmin;

  PermissionsModel({
    required this.modules,
    required this.functionalities,
    this.isAdmin = false,
  });

  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    var modulesList = json['modules'] as List? ?? [];
    var functionalitiesList = json['functionalities'] as List? ?? [];

    return PermissionsModel(
      modules: modulesList.map((m) => ModulePermission.fromJson(m)).toList(),
      functionalities: functionalitiesList.map((f) => FunctionalityPermission.fromJson(f)).toList(),
      isAdmin: json['isAdmin'] == true || json['is_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modules': modules.map((m) => m.toJson()).toList(),
      'functionalities': functionalities.map((f) => f.toJson()).toList(),
      'isAdmin': isAdmin,
    };
  }

  factory PermissionsModel.empty() {
    return PermissionsModel(modules: [], functionalities: [], isAdmin: false);
  }
}
