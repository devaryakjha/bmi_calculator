import 'package:bmi_calculator/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_listview/infinite_listview.dart';

typedef TextMapper = String Function(String numberText);

class NumberPicker extends StatefulWidget {
  /// Min value user can pick
  final int minValue;

  /// Max value user can pick
  final int maxValue;

  /// Currently selected value
  final int value;

  /// Called when selected value changes
  final ValueChanged<int> onChanged;

  /// Specifies how many items should be shown - defaults to 3
  final int itemCount;

  /// Step between elements. Only for integer datePicker
  /// Examples:
  /// if step is 100 the following elements may be 100, 200, 300...
  /// if min=0, max=6, step=3, then items will be 0, 3 and 6
  /// if min=0, max=5, step=3, then items will be 0 and 3.
  final int step;

  /// height of single item in pixels
  final double itemHeight;

  /// width of single item in pixels
  final double itemWidth;

  /// Direction of scrolling
  final Axis axis;

  /// Style of non-selected numbers. If null, it uses Theme's bodyText2
  final TextStyle? textStyle;

  /// Style of non-selected numbers. If null, it uses Theme's headline5 with accentColor
  final TextStyle? selectedTextStyle;

  final TextStyle? suffixTextStyle;

  /// Whether to trigger haptic pulses or not
  final bool haptics;

  /// Build the text of each item on the picker
  final TextMapper? textMapper;

  /// Pads displayed integer values up to the length of maxValue
  final bool zeroPad;

  /// Decoration to apply to central box where the selected value is placed
  final Decoration? decoration;

  /// Margin to apply to central box where the selected value is placed
  final EdgeInsetsGeometry? margin;

  /// Padding to apply to central box where the selected value is placed
  final EdgeInsetsGeometry? padding;

  final String? suffix;

  final bool infiniteLoop;

  const NumberPicker({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.value,
    required this.onChanged,
    this.itemCount = 3,
    this.step = 1,
    this.itemHeight = 50,
    this.itemWidth = 100,
    this.axis = Axis.vertical,
    this.textStyle,
    this.selectedTextStyle,
    this.suffixTextStyle,
    this.haptics = false,
    this.decoration,
    this.zeroPad = false,
    this.textMapper,
    this.infiniteLoop = false,
    this.margin,
    this.padding,
    this.suffix,
  })  : assert(minValue <= value),
        assert(value <= maxValue),
        super(key: key);

  @override
  NumberPickerState createState() => NumberPickerState();
}

class NumberPickerState extends State<NumberPicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final initialOffset =
        (widget.value - widget.minValue) ~/ widget.step * itemExtent;
    if (widget.infiniteLoop) {
      _scrollController =
          InfiniteScrollController(initialScrollOffset: initialOffset);
    } else {
      _scrollController = ScrollController(initialScrollOffset: initialOffset);
    }
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    var indexOfMiddleElement = (_scrollController.offset / itemExtent).round();
    if (widget.infiniteLoop) {
      indexOfMiddleElement %= itemCount;
    } else {
      indexOfMiddleElement = indexOfMiddleElement.clamp(0, itemCount - 1);
    }
    final intValueInTheMiddle =
        _intValueFromIndex(indexOfMiddleElement + additionalItemsOnEachSide);

    if (widget.value != intValueInTheMiddle) {
      widget.onChanged(intValueInTheMiddle);
      if (widget.haptics) {
        HapticFeedback.selectionClick();
      }
    }
    Future.delayed(
      const Duration(milliseconds: 100),
      () => _maybeCenterValue(),
    );
  }

  @override
  void didUpdateWidget(NumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _maybeCenterValue();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get isScrolling => _scrollController.position.isScrollingNotifier.value;

  double get itemExtent =>
      widget.axis == Axis.vertical ? widget.itemHeight : widget.itemWidth;

  int get itemCount => (widget.maxValue - widget.minValue) ~/ widget.step + 1;

  int get listItemsCount => itemCount + 2 * additionalItemsOnEachSide;

  int get additionalItemsOnEachSide => (widget.itemCount - 1) ~/ 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.axis == Axis.vertical
          ? widget.itemWidth
          : widget.itemCount * widget.itemWidth,
      height: widget.axis == Axis.vertical
          ? widget.itemCount * widget.itemHeight
          : widget.itemHeight,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (not) {
          if (not.dragDetails?.primaryVelocity == 0) {
            Future.microtask(() => _maybeCenterValue());
          }
          return true;
        },
        child: Stack(
          children: [
            if (widget.infiniteLoop)
              InfiniteListView.builder(
                scrollDirection: widget.axis,
                controller: _scrollController as InfiniteScrollController,
                itemExtent: itemExtent,
                itemBuilder: _itemBuilder,
                padding: EdgeInsets.zero,
              )
            else
              ListView.builder(
                itemCount: listItemsCount,
                scrollDirection: widget.axis,
                controller: _scrollController,
                itemExtent: itemExtent,
                itemBuilder: _itemBuilder,
                padding: EdgeInsets.zero,
              ),
            _NumberPickerSelectedItemDecoration(
              axis: widget.axis,
              itemExtent: itemExtent,
              decoration: widget.decoration,
              padding: widget.padding,
              margin: widget.margin,
              suffix: widget.suffix,
              textStyle: widget.suffixTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final themeData = Theme.of(context);
    final defaultStyle = widget.textStyle ?? themeData.textTheme.bodyMedium;
    final selectedStyle = widget.selectedTextStyle ??
        themeData.textTheme.headlineSmall
            ?.copyWith(color: themeData.colorScheme.secondary);

    final value = _intValueFromIndex(index % itemCount);
    final isExtra = !widget.infiniteLoop &&
        (index < additionalItemsOnEachSide ||
            index >= listItemsCount - additionalItemsOnEachSide);
    final itemStyle = value == widget.value ? selectedStyle : defaultStyle;
    final selected = value == widget.value;
    final child = isExtra
        ? const SizedBox.shrink()
        : Text(
            _getDisplayedValue(value, selected: selected),
            style: itemStyle,
          );
    return Container(
      width: widget.itemWidth,
      height: widget.itemHeight,
      alignment: Alignment.center,
      child: child,
    );
  }

  String _getDisplayedValue(int value, {bool selected = false}) {
    var text = widget.zeroPad
        ? value.toString().padLeft(widget.maxValue.toString().length, '0')
        : value.toString();

    if (widget.textMapper != null) {
      return widget.textMapper!(text);
    } else {
      return text;
    }
  }

  int _intValueFromIndex(int index) {
    index -= additionalItemsOnEachSide;
    index %= itemCount;
    return widget.minValue + index * widget.step;
  }

  void _maybeCenterValue() {
    if (_scrollController.hasClients && !isScrolling) {
      int diff = widget.value - widget.minValue;
      int index = diff ~/ widget.step;
      if (widget.infiniteLoop) {
        final offset = _scrollController.offset + 0.5 * itemExtent;
        final cycles = (offset / (itemCount * itemExtent)).floor();
        index += cycles * itemCount;
      }
      _scrollController.animateTo(
        index * itemExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _NumberPickerSelectedItemDecoration extends StatelessWidget {
  final Axis axis;
  final double itemExtent;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin, padding;
  final String? suffix;
  final TextStyle? textStyle;

  const _NumberPickerSelectedItemDecoration({
    Key? key,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    required this.axis,
    required this.itemExtent,
    required this.decoration,
    this.suffix,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final textTheme = textThemeOf(context);
    return Center(
      child: IgnorePointer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: margin,
                padding: padding,
                width: isVertical ? double.infinity : itemExtent,
                height: isVertical ? itemExtent : double.infinity,
                decoration: decoration,
              ),
            ),
            if (suffix != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    suffix!,
                    style: textStyle ??
                        textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get isVertical => axis == Axis.vertical;
}
