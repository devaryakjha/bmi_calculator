part of 'bmi_bloc.dart';

abstract class BmiEvent extends Equatable {
  const BmiEvent();

  @override
  List<Object> get props => [];
}

class UpdateGender extends BmiEvent {
  final Gender gender;

  const UpdateGender(this.gender);
}

class UpdateHeightUnit extends BmiEvent {
  final Height height;

  const UpdateHeightUnit(this.height);
}

class UpdateWeightUnit extends BmiEvent {
  final Weight weight;

  const UpdateWeightUnit(this.weight);
}

class UpdateHeight extends BmiEvent {
  final double value;

  const UpdateHeight(this.value);
}

class UpdateWeight extends BmiEvent {
  final double value;

  const UpdateWeight(this.value);
}

class UpdateAge extends BmiEvent {
  final int age;

  const UpdateAge(this.age);
}

class UpdateGlobalKey extends BmiEvent {
  final GlobalKey<State<StatefulWidget>>? key;

  const UpdateGlobalKey(this.key);
}
