part of 'package:bf2kernel/bf2kernel.dart';

List<Instruction> parseBf(List<int> input) {
  // stack to keep track of nested loops
  final instructionStack = <List<Instruction>>[[]];

  // helper function to add an instruction to the current block
  void addSimple(Instruction s) {
    instructionStack.last.add(s);
  }

  for (final char in input) {
    switch (char) {
      case 60: // <, decrease pointer
        addSimple(const ChangePointer.decrement());
        break;
      case 62: // >
        addSimple(const ChangePointer.increment());
        break;
      case 43: // +
        addSimple(const ChangeCell.add());
        break;
      case 45: // -
        addSimple(const ChangeCell.subtract());
        break;
      case 46: // .
        addSimple(const Output());
        break;
      case 44: // ,
        addSimple(const Input());
        break;
      case 91: // [, begin while loop by pushing a new block
        instructionStack.add([]);
        break;
      case 93: // ], make a while loop from the matching [
        addSimple(While(instructionStack.removeLast()));
        break;
      default:
        // Ignore unknown characters
        break;
    }
  }

  final result = instructionStack.removeLast();
  if (result.isEmpty) {
    throw ArgumentError('Invalid source: Missing ] to close while loops');
  }
  return result;
}
