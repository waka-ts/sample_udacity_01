// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'category.dart';
import 'unit.dart';

final _backgroundColor = Color.fromARGB(255, 66, 165, 245);

/// Category Route (screen).
///
/// This is the 'home' screen of the Unit Converter. It shows a header and
/// a list of [Categories].
///
/// While it is named CategoryRoute, a more apt name would be CategoryScreen,
/// because it is responsible for the UI at the route's destination.
//Categoryを表示するページ
// Stateの作成
class CategoryRoute extends StatefulWidget {
  @override
  CategoryRouteState createState() => CategoryRouteState();
}

//Stateここから
class CategoryRouteState extends State<CategoryRoute> {
  final _categories = <Category>[];
  final _categoryNames = <String>[
    'Length',
    'Area',
    'Volume',
    'Mass',
    'Time',
    'Digital Storage',
    'Energy',
    'Currency',
  ];

  static const _baseColors = <Color>[
    Colors.teal,
    Colors.orange,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.yellow,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.red,
  ];

  /// Returns a list of mock [Unit]s.
  //2ページ目に表示する単位リスト
  List<Unit> _retrieveUnitList(String categoryName) {
    return List.generate(10, (int i) {
      i += 1;
      return Unit(
        name: '$categoryName Unit $i',
        conversion: i.toDouble(),
      );
    });
  }

  //Initialの状態
  //initStateは最初に1回だけ呼ばれる
  @override
  void initState() {
    //親を
    super.initState();
    //categoryNameの数だけ処理を実行
    for (var i = 0; i < _categoryNames.length; i++) {
      //_categoriesに情報を取り込む
      _categories.add(Category(
        name: _categoryNames[i],
        color: _baseColors[i],
        iconLocation: Icons.category,
        //2ページ目に表示する情報のリスト
        units: _retrieveUnitList(_categoryNames[i]),
      ));
    }
  }

  /// Makes the correct number of rows for the list view.
  ///
  /// For portrait, we use a [ListView]
  //
  Widget _buildCategoryWidgets() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => _categories[index],
      itemCount: _categories.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    final listView = Container(
      color: _backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: _buildCategoryWidgets(),
    );

    final appBar = AppBar(
      elevation: 0.0,
      title: Text(
        'Unit Converter',
        style: TextStyle(
          color: Colors.black,
          fontSize: 30.0,
        ),
      ),
      centerTitle: true,
      backgroundColor: _backgroundColor,
    );

    return Scaffold(
      appBar: appBar,
      body: listView,
    );
  }
}
