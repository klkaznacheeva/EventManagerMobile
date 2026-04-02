class RegisterRequest {
  final String firstName;
  final String secondName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final String birthDate;

  RegisterRequest({
    required this.firstName,
    required this.secondName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'second_name': secondName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'birth_date': birthDate,
    };
  }
}