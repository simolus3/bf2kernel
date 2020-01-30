part of 'package:bf2kernel/bf2kernel.dart';

class KernelGenerator {
  /// The source `.dill` file containing the Dart SDK.
  final Component platform;
  final List<Instruction> instructions;
  final int bandSize;
  final Uri inputUri;

  final CoreTypes _coreTypes;
  VariableDeclaration _pointerDeclaration;

  Member _listSet;
  Member _listGet;
  Member _objectEquals;
  Member _stdin;
  Member _stdout;
  Member _readByteSync;
  Member _ioSinkAdd;
  Member _numAdd;

  Expression _pointer;
  Expression _band;

  KernelGenerator(this.platform, this.instructions,
      {this.bandSize = 10000, this.inputUri})
      : _coreTypes = CoreTypes(platform) {
    _listSet = _coreTypes.index.getMember('dart:core', 'List', '[]=');
    _listGet = _coreTypes.index.getMember('dart:core', 'List', '[]');
    _objectEquals = _coreTypes.objectEquals;
    _stdin = _coreTypes.index.getTopLevelMember('dart:io', 'get:stdin');
    _stdout = _coreTypes.index.getTopLevelMember('dart:io', 'get:stdout');
    _ioSinkAdd = _coreTypes.index.getMember('dart:io', 'IOSink', 'add');
    _readByteSync =
        _coreTypes.index.getMember('dart:io', 'Stdin', 'readByteSync');
    _numAdd = _coreTypes.index.getMember('dart:core', 'num', '+');
  }

  void compile() {
    final function = _compileToFunction();
    final library = Library(
      Uri.parse('brainfuck_output'),
      dependencies: [
        LibraryDependency.import(_coreTypes.coreLibrary),
        LibraryDependency.import(_coreTypes.index.getLibrary('dart:io')),
      ],
    )..isNonNullableByDefault = true;
    platform.libraries.add(library);

    final main = Procedure(
      Name('main', library),
      ProcedureKind.Method,
      function,
    );
    library.addProcedure(main);

    if (inputUri != null) {
      library.fileUri = inputUri;
      main.fileUri = inputUri;
    }

    platform
      ..mainMethod = main
      ..computeCanonicalNamesForLibrary(library)
      ..adoptChildren();
  }

  FunctionNode _compileToFunction() {
    _pointerDeclaration = VariableDeclaration(
      'pointer',
      type: _coreTypes.intRawType(Nullability.nonNullable),
      initializer: IntLiteral(0),
    );
    _pointer = VariableGet(_pointerDeclaration);

    final int32List = _coreTypes.index.getClass('dart:typed_data', 'Int32List');
    final bandDeclaration = VariableDeclaration(
      'memory',
      type: int32List.thisType,
      // this is the new Int32List(<length>) call. Note that Dart factories are
      // procedures in Kernel
      initializer: StaticInvocation(
        int32List.procedures.singleWhere((c) => c.name.name == ''),
        Arguments([IntLiteral(bandSize)]),
      ),
      isFinal: true,
    );
    _band = VariableGet(bandDeclaration);

    final stmt = Block([
      _pointerDeclaration,
      bandDeclaration,
      ...instructions.map(_compileInstruction),
    ]);
    return FunctionNode(
      stmt,
      returnType: const VoidType(),
    );
  }

  Statement _compileInstruction(Instruction i) {
    if (i is ChangePointer) {
      return _changePointerBy(i.delta);
    } else if (i is ChangeCell) {
      return _changeCellValueBy(i.delta);
    } else if (i is While) {
      return WhileStatement(
        // while (band[pointer] != 0) { ... }
        Not(
          MethodInvocation(
            _getCellValue(),
            _objectEquals.name,
            Arguments([IntLiteral(0)]),
          ),
        ),
        Block(i.body.map(_compileInstruction).toList()),
      );
    } else if (i is Output) {
      // stdout.add(<int>[band[pointer]]);
      return ExpressionStatement(
        MethodInvocation(
          StaticInvocation(_stdout, Arguments([])),
          _ioSinkAdd.name,
          Arguments([
            ListLiteral(
              [_getCellValue()],
              typeArgument: _coreTypes.intNonNullableRawType,
            ),
          ]),
        ),
      );
    } else if (i is Input) {
      // band[pointer] = stdin.readByteSync();
      return _setCellValue(
        MethodInvocation(
          StaticInvocation(_stdin, Arguments([])),
          _readByteSync.name,
          Arguments([]),
        ),
      );
    }

    throw AssertionError('Unknown instruction: $i');
  }

  Statement _changePointerBy(int value) {
    // pointer = pointer + <value>, the plus is an operator function on int
    return ExpressionStatement(
      VariableSet(
        _pointerDeclaration,
        MethodInvocation(
          _pointer,
          _numAdd.name,
          Arguments([
            IntLiteral(value),
          ]),
        ),
      ),
    );
  }

  Expression _getCellValue() {
    return MethodInvocation(
      _band,
      _listGet.name,
      Arguments([_pointer]),
    );
  }

  Statement _setCellValue(Expression value) {
    return ExpressionStatement(
      MethodInvocation(
        _band,
        _listSet.name,
        Arguments([
          _pointer,
          value,
        ]),
      ),
    );
  }

  Statement _changeCellValueBy(int value) {
    return _setCellValue(
      MethodInvocation(
        _getCellValue(),
        _numAdd.name,
        Arguments([IntLiteral(value)]),
      ),
    );
  }
}
