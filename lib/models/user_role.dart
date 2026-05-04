enum UserRole {
  staff,
  inspector,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.staff:
        return '清掃スタッフ';
      case UserRole.inspector:
        return '点検者';
      case UserRole.admin:
        return '管理者';
    }
  }
}
