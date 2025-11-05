// test/user_test.dart
import 'package:flutter_test/flutter_test.dart';

/// Simple User model for testing
class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

/// Simple helper class
class UserUtils {
  static bool isEmailValid(String email) {
    return email.contains('@');
  }

  static bool canAccessAdmin(User user) {
    return user.isAdmin;
  }
}

void main() {
  group('User model', () {
    test('toMap produces expected keys and values', () {
      final user = User(id: 1, name: 'Alice', email: 'alice@test.com', isAdmin: true);
      final map = user.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Alice');
      expect(map['email'], 'alice@test.com');
      expect(map['isAdmin'], isTrue);
    });

    test('fromMap recreates User correctly', () {
      final map = {'id': 2, 'name': 'Bob', 'email': 'bob@test.com', 'isAdmin': false};
      final user = User.fromMap(map);
      expect(user.id, 2);
      expect(user.name, 'Bob');
      expect(user.email, 'bob@test.com');
      expect(user.isAdmin, isFalse);
    });

    test('fromMap sets isAdmin false if key missing', () {
      final map = {'id': 3, 'name': 'Charlie', 'email': 'charlie@test.com'};
      final user = User.fromMap(map);
      expect(user.isAdmin, isFalse);
    });

    test('default isAdmin is false if not provided', () {
      final user = User(id: 4, name: 'Dana', email: 'dana@test.com');
      expect(user.isAdmin, isFalse);
    });
  });

  group('UserUtils helpers', () {
    test('isEmailValid returns true for valid emails', () {
      expect(UserUtils.isEmailValid('test@example.com'), isTrue);
      expect(UserUtils.isEmailValid('invalidEmail'), isFalse);
    });

    test('canAccessAdmin returns true only for admins', () {
      final admin = User(id: 1, name: 'Admin', email: 'admin@test.com', isAdmin: true);
      final user = User(id: 2, name: 'User', email: 'user@test.com', isAdmin: false);
      expect(UserUtils.canAccessAdmin(admin), isTrue);
      expect(UserUtils.canAccessAdmin(user), isFalse);
    });
  });
}
