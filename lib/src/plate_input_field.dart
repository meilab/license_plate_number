import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/widgets.dart';
import 'package:license_plate_number/license_plate_number.dart';
import 'package:license_plate_number/src/plate_keyboard.dart';

class PlateInputField extends StatefulWidget {
  const PlateInputField({
    this.placeHolder = '',
    this.readOnly = false,
    this.styles = PlateStyles.dark,
    this.inputFieldWidth = 40,
    this.inputFieldHeight = 54,
    this.keyboardController,
    this.onChanged,
  })  : assert(placeHolder != null, 'plateNumber must be non-null.'),
        assert(placeHolder.length <= 8,
            'plateNumber\'s length should be less than 8.');

  /// 车牌号
  final String placeHolder;

  final bool readOnly;

  /// 主题
  final PlateStyles styles;

  /// 输入框宽度
  final double inputFieldWidth;

  /// 输入框高度
  final double inputFieldHeight;

  /// 键盘控制器
  final KeyboardController keyboardController;

  /// 输入变化监听器
  ///
  /// * [array] - 车牌号字符数组
  /// * [value] - 车牌号字符串
  final void Function(List<String> array, String value) onChanged;

  @override
  _PlateInputFieldState createState() => _PlateInputFieldState();
}

class _PlateInputFieldState extends State<PlateInputField>
    with SingleTickerProviderStateMixin {
  /// 当前光标位置
  int _cursorIndex = 0;

  /// 键盘进入和退出动画控制器
  AnimationController _controller;

  /// 键盘控制器
  KeyboardController _keyboardController;

  @override
  void initState() {
    super.initState();
    String plateNumber = widget.placeHolder;
    List<String> plateNumbers = List.filled(8, "");
    if (plateNumber.isNotEmpty) {
      List<String> numbers = plateNumber.split('');
      plateNumbers.replaceRange(0, numbers.length, numbers);
      _cursorIndex = numbers.length;
    }
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _keyboardController = widget.keyboardController;
    if (null == _keyboardController) {
      _keyboardController = KeyboardController();
    }
    _keyboardController.plateNumbers = plateNumbers;
    _keyboardController.onPlateNumberChanged = onPlateNumberChanged;
    _keyboardController.animationController = _controller;
  }

  @override
  void dispose() {
    super.dispose();
    _keyboardController.dispose();
  }

  void onPlateNumberChanged(int index, String value) {
    List<String> plateNumbers = _keyboardController.getPlateNumbers();
    plateNumbers[index] = value;
    if (value.isNotEmpty) {
      _cursorIndex = index < 7 ? index + 1 : 7;
      if (index >= 6 && _cursorIndex >= 6) {
        _keyboardController.hideKeyboard();
      }
    } else if (value.isEmpty) {
      _cursorIndex = index > 0 ? index - 1 : 0;
    }
    if (widget.onChanged != null) {
      widget.onChanged(plateNumbers, plateNumbers.join());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _keyboardController.cursorIndex = _cursorIndex;
    _keyboardController.styles = widget.styles;
    return WillPopScope(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 4.0,
        direction: Axis.horizontal,
        children: _buildInputFields(),
      ),
      onWillPop: () {
        if (_keyboardController.isKeyboardShowing()) {
          _keyboardController.hideKeyboard();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
    );
  }

  List<Widget> _buildInputFields() {
    List<String> plateNumbers = _keyboardController.getPlateNumbers();
    List<Widget> children = [];
    for (int i = 0; i < plateNumbers.length; i++) {
      children.add(_buildSingleField(plateNumbers[i], i));
      if (6 == i) {
        children.add(_buildSeparator());
      }
    }
    return children;
  }

  Widget _buildSingleField(String data, int index) {
    bool focused = _cursorIndex == index;
    bool newEnergy = index == 7;
    Border border = widget.readOnly
        ? widget.styles.plateInputBorderReadOnly
        : focused
            ? widget.styles.plateInputFocusedBorder
            : widget.styles.plateInputBorder;
    var text = Text(
      data.isEmpty && newEnergy ? '新能源' : data,
      style: newEnergy && data.isEmpty
          ? widget.styles.newEnergyPlaceHolderTextStyle
          : widget.styles.plateInputFieldTextStyle,
    );
    var container = Container(
      // color: widget.readOnly ? Colors.grey : Colors.black,
      width: widget.inputFieldWidth,
      height: widget.inputFieldHeight,
      alignment: Alignment.center,
      decoration: newEnergy
          ? null
          : BoxDecoration(
              color: widget.styles.plateInputFieldColor,
              border: border,
              borderRadius:
                  BorderRadius.all(widget.styles.plateInputBorderRadius),
            ),
      child: text,
    );
    var newEnergyField = DottedBorder(
      child: container,
      color: Color(0xFF666666),
      borderType: BorderType.RRect,
      radius: widget.styles.plateInputBorderRadius,
      padding: const EdgeInsets.all(0),
    );
    return GestureDetector(
      child: newEnergy ? newEnergyField : container,
      onTap: widget.readOnly
          ? () {}
          : () {
              _cursorIndex = index;
              _keyboardController.cursorIndex = _cursorIndex;
              _keyboardController.showKeyboard(context);
              setState(() {});
            },
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: widget.inputFieldHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text("+"),
          ),
        ],
      ),
    );
  }
}

/// 键盘控制器
class KeyboardController {
  KeyboardController();

  /// 车牌号码数组
  List<String> _plateNumbers;

  /// 当前光标位置
  int _cursorIndex = 0;

  /// 键盘悬浮窗口
  OverlayEntry _keyboardOverlay;

  /// 键盘进入和退出动画控制器
  AnimationController _controller;

  /// 键盘可见状态
  bool _isKeyboardShowing = false;

  /// 主题
  PlateStyles _styles;
  Function(int index, String value) _onPlateNumberChanged;

  List<String> getPlateNumbers() => _plateNumbers;

  set plateNumbers(List<String> plateNumbers) {
    print(plateNumbers);
    _plateNumbers = plateNumbers;
  }

  set cursorIndex(int cursorIndex) => _cursorIndex = cursorIndex;

  set animationController(AnimationController controller) =>
      _controller = controller;

  set styles(PlateStyles styles) => _styles = styles;

  set onPlateNumberChanged(onPlateNumberChanged(int index, String value)) =>
      _onPlateNumberChanged = onPlateNumberChanged;

  /// 显示键盘
  void showKeyboard(BuildContext context) {
    if (_keyboardOverlay != null) {
      _keyboardOverlay.remove();
    }
    _keyboardOverlay = OverlayEntry(
      builder: (context) {
        return PlateKeyboard(
          plateNumbers: _plateNumbers,
          currentIndex: _cursorIndex,
          styles: _styles,
          newEnergy: _cursorIndex == 7,
          onChange: _onPlateNumberChanged,
          animationController: _controller,
        );
      },
    );
    Overlay.of(context).insert(_keyboardOverlay);
    if (!_isKeyboardShowing) {
      _controller.forward();
      _isKeyboardShowing = true;
    }
  }

  /// 隐藏键盘
  void hideKeyboard() {
    if (isKeyboardShowing()) {
      _controller.reverse();
    }
    _isKeyboardShowing = false;
  }

  /// 键盘是否可见
  bool isKeyboardShowing() {
    return _keyboardOverlay != null && _isKeyboardShowing;
  }

  /// 移除悬浮窗口
  void dispose() {
    if (_keyboardOverlay != null) {
      _keyboardOverlay.remove();
      _keyboardOverlay = null;
    }
  }
}
