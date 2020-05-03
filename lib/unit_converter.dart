import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'category.dart';
import 'unit.dart';

const _padding = EdgeInsets.all(16.0);

/// [UnitConverter] where users can input amounts to convert in one [Unit]
/// and retrieve the conversion in another [Unit] for a specific [Category].
///
/// UnitConverterはUserが打ち込む内容を反映するUI
class UnitConverter extends StatefulWidget {
  /// The current [Category] for unit conversion.
  final Category category;

  /// This [UnitConverter] takes in a [Category] with [Units]. It can't be null.
  const UnitConverter({
    @required this.category,
  }) : assert(category != null);

  @override
  _UnitConverterState createState() => _UnitConverterState();
}

///State
class _UnitConverterState extends State<UnitConverter> {
  Unit _fromValue;
  Unit _toValue;
  double _inputValue;
  String _convertedValue = '';
  List<DropdownMenuItem> _unitMenuItems;
  bool _showValidationError = false;

  ///初期動作
  ///Dropdownつくって、ドロップダウンの初期設定を格納する
  @override
  void initState() {
    //最初に一回呼ばれる
    super.initState();
    _createDropdownMenuItems();
    _setDefaults();
  }

  ///UnitConverterウィジェットが更新されたら、更新を反映させる
  ///super.didUpdateWidgetで、ウィジェットが更新されたら呼ばれる
  @override
  void didUpdateWidget(UnitConverter old) {
    super.didUpdateWidget(old);
    // We update our [DropdownMenuItem] units when we switch [Categories].
    if (old.category != widget.category) {
      _createDropdownMenuItems();
      _setDefaults();
    }
  }

  /// Creates fresh list of [DropdownMenuItem] widgets, given a list of [Unit]s.
  /// ドロップダウンの中身を決める(Stateの中につくる)
  void _createDropdownMenuItems() {
    // DropdownMenuItemはドロップダウンの中身を設定する関数
    var newItems = <DropdownMenuItem>[];
    // unit郡全てに適応
    for (var unit in widget.category.units) {
      // DropdownMenuItemを郡に格納する
      newItems.add(DropdownMenuItem(
        value: unit.name,
        // DropdownMenuはchild required
        child: Container(
          child: Text(
            unit.name,
            //textを折り返す
            softWrap: true,
          ),
        ),
      ));
    }
    setState(() {
      // 格納したリストを_unitMenuItemsに代入する
      _unitMenuItems = newItems;
    });
  }

  /// Sets the default values for the 'from' and 'to' [Dropdown]s, and the
  /// updated output value if a user had previously entered an input.
  /// fromValueとtoValueをユニット郡に格納
  void _setDefaults() {
    setState(() {
      _fromValue = widget.category.units[0];
      _toValue = widget.category.units[1];
    });
  }

  /// Clean up conversion
  /// 変換した値を整える。returnはoutputNum
  String _format(double conversion) {
    // 数値はconversionの有効数字7けた
    var outputNum = conversion.toStringAsPrecision(7);
    // .と0があったら、、
    if (outputNum.contains('.') && outputNum.endsWith('0')) {
      //小数点以下の桁数iを、0以外がでてくるまで1ずつ減らしていく
      var i = outputNum.length - 1;
      while (outputNum[i] == '0') {
        i -= 1;
      }
      //0以外がでてきたらそれ以下をカットする
      outputNum = outputNum.substring(0, i + 1);
    }
    //.でおわったら、小数点以下をカットする
    if (outputNum.endsWith('.')) {
      return outputNum.substring(0, outputNum.length - 1);
    }
    return outputNum;
  }


  /// 変換を行う関数
  void _updateConversion() {
    setState(() {
      _convertedValue =
          _format(_inputValue * (_toValue.conversion / _fromValue.conversion));
    });
  }

  ///input値を処理して、変換(_updateConversion)まで誘導する
  void _updateInputValue(String input) {
    setState(() {
      //0なら_convertedValueを計算できないので、直接’’を代入する
      // ||は論理和(または)
      if (input == null || input.isEmpty) {
        _convertedValue = '';
        //inputが0でないなら、、
      } else {
        //try-catch文
        //try内処理実行→例外はcatch内部処理実行
        // Even though we are using the numerical keyboard, we still have to check
        // for non-numerical input such as '5..0' or '6 -3'
        try {
          //inputをdoubleに変換する
          final inputDouble = double.parse(input);
          _showValidationError = false;
          //inputValueにdouble値を代入
          _inputValue = inputDouble;
          //以下関数で変換を行う
          _updateConversion();
          //error時はエラ-メッセージ
        } on Exception catch (e) {
          print('Error: $e');
          _showValidationError = true;
        }
      }
    });
  }

  ///unitNameが一致するunitをunits配列内から探してくる
  Unit _getUnit(String unitName) {
    return widget.category.units.firstWhere(
          (Unit unit) {
        return unit.name == unitName;
      },
      orElse: null,
    );
  }

  ///unitNameから、getUnitして、_fromValueを設定して、変換(_updateConversion)まで誘導する
  //unitNameは型が決まってないので、(nullの可能性あり？)dynamic型で表記する
  void _updateFromConversion(dynamic unitName) {
    setState(() {
      //_getUnitで名前と一致したunitを_fromValueに代入する
      _fromValue = _getUnit(unitName);
    });
    //_inputValueが0でないなら、変換(update)を実行する
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  ///unitNameから、getUnitして、_toValueを設定して、変換(_updateConversion)まで誘導する
  void _updateToConversion(dynamic unitName) {
    setState(() {
      _toValue = _getUnit(unitName);
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  ///dropdownのUI
  Widget _createDropdown(String currentValue, ValueChanged<dynamic> onChanged) {
    return Container(
      margin: EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        // This sets the color of the [DropdownButton] itself
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[400],
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Theme(
        // This sets the color of the [DropdownMenuItem]
        data: Theme.of(context).copyWith(
          canvasColor: Colors.grey[50],
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton(
              //今選ばれている中身
              value: currentValue,
              //リストの中身
              items: _unitMenuItems,
              //ユーザが選んだ中身(選んだ時に呼ばれる)
              onChanged: onChanged,
              style: Theme.of(context).textTheme.title,
            ),
          ),
        ),
      ),
    );
  }

  ///2page目全体のUI
  ///returnは最後のpadding
  @override
  Widget build(BuildContext context) {
    // inputエリア
    final input = Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This is the widget that accepts text input. In this case, it
          // accepts numbers and calls the onChanged property on update.
          // You can read more about it here: https://flutter.io/text-input
          //テキスト入力したら_updateInputFieldを行う
          TextField(
            style: Theme.of(context).textTheme.display1,
            decoration: InputDecoration(
              labelStyle: Theme.of(context).textTheme.display1,
              errorText: _showValidationError ? 'Invalid number entered' : null,
              labelText: 'Input',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
            // Since we only want numerical input, we use a number keyboard. There
            // are also other keyboards for dates, emails, phone numbers, etc.
            keyboardType: TextInputType.number,
            onChanged: _updateInputValue,
          ),
          //_fromValueでドロップダウンをつくる
          //onChangedで_updateFromConversionが実行される→変換が実行される
          _createDropdown(_fromValue.name, _updateFromConversion),
        ],
      ),
    );

    // 矢印アイコン
    final arrows = RotatedBox(
      quarterTurns: 1,
      child: Icon(
        Icons.compare_arrows,
        size: 40.0,
      ),
    );

    // outputエリア
    final output = Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            child: Text(
              _convertedValue,
              style: Theme.of(context).textTheme.display1,
            ),
            decoration: InputDecoration(
              labelText: 'Output',
              labelStyle: Theme.of(context).textTheme.display1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
          ),
          _createDropdown(_toValue.name, _updateToConversion),
        ],
      ),
    );

    // input,矢印,outputを縦に配置
    final converter = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        input,
        arrows,
        output,
      ],
    );

    // 全体余白を作って中にconverter表示
    return Padding(
      padding: _padding,
      child: converter,
    );
  }
}