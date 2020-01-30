part of 'package:bf2kernel/bf2kernel.dart';

abstract class Instruction {
  const Instruction();
}

class ChangePointer extends Instruction {
  final int delta;

  const ChangePointer(this.delta);

  const ChangePointer.decrement() : delta = -1;
  const ChangePointer.increment() : delta = 1;
}

class ChangeCell extends Instruction {
  final int delta;

  const ChangeCell(this.delta);

  const ChangeCell.subtract() : delta = -1;
  const ChangeCell.add() : delta = 1;
}

/// A while loop in BF, the content between a `[` and the matching `]`. Executes
/// as long as the value referenced by the pointer is not 0.
class While extends Instruction {
  final List<Instruction> body;

  const While(this.body);

  @override
  String toString() {
    return '[${body.join()}]';
  }
}

/// Outputs the ascii value of the cell referenced by the pointer. `.` in BF.
class Output extends Instruction {
  const Output();

  @override
  String toString() => '.';
}

/// Reads a char from stdin and puts its ascii value to the cell referenced by
/// the pointer. `,` in BF.
class Input extends Instruction {
  const Input();

  @override
  String toString() => ',';
}
