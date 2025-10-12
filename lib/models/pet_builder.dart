import 'pet.dart';

class PetBuilder {
  int? _id;
  String _name = '';
  String _gender = '';
  String _species = '';
  String _breed = '';
  int _age = 0;

  PetBuilder setId(int? id) {
    _id = id;
    return this;
  }

  PetBuilder setName(String name) {
    _name = name;
    return this;
  }

  PetBuilder setGender(String gender) {
    _gender = gender;
    return this;
  }

  PetBuilder setSpecies(String species) {
    _species = species;
    return this;
  }

  PetBuilder setBreed(String breed) {
    _breed = breed;
    return this;
  }

  PetBuilder setAge(int age) {
    _age = age;
    return this;
  }

  Pet build() {
    return Pet(
      id: _id,
      name: _name,
      gender: _gender,
      species: _species,
      breed: _breed,
      age: _age,
    );
  }
}
