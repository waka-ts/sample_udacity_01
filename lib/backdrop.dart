// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'category.dart';

const double _kFlingVelocity = 2.0;

///backdrop(重ね表示)のUI　子ウィジットを指定する　Stateless
class _BackdropPanel extends StatelessWidget {
  const _BackdropPanel({
    Key key,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.title,
    this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget title;
  final Widget child;

  /// UI 計算部(重ね部) タイトルと子ウィジットのExpanded
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      //角丸める
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Column(
        //Column縦並びに対してCrossAxisは横並び、stretchは埋めるように配置される
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          //動作検出
          GestureDetector(
            //検出する範囲の設定(HitTestBehavior)、opaqueは子ウィジットの範囲(padding含む)全体を指定する
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onTap: onTap,
            //GestureDetectorの中身はコンテナ
            child: Container(
              height: 48.0,
              padding: EdgeInsetsDirectional.only(start: 16.0),
              //centerStartは縦のセンターで左はしから
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead,
                child: title,
              ),
            ),
          ),
          //しきり線
          Divider(
            height: 1.0,
          ),
          //子ウィジェットを一定の比率で配置する
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

///titleアニメーション　Select a Category からUnitConverterに変わる
class _BackdropTitle extends AnimatedWidget {
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle({
    Key key,
    Listenable listenable,
    this.frontTitle,
    this.backTitle,
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.listenable;
    return DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      // Here, we do a custom cross fade between backTitle and frontTitle.
      // This makes a smooth animation between the two texts.
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: CurvedAnimation(
              parent: ReverseAnimation(animation),
              curve: Interval(0.5, 1.0),
            ).value,
            child: backTitle,
          ),
          Opacity(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Interval(0.5, 1.0),
            ).value,
            child: frontTitle,
          ),
        ],
      ),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two panels, front and back. The front panel is shown
/// by default, and slides down to show the back panel, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back panel is showing.
/// 表示されるメインUIの中身 Stateful
class Backdrop extends StatefulWidget {
  final Category currentCategory;
  final Widget frontPanel;
  final Widget backPanel;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    @required this.currentCategory,
    @required this.frontPanel,
    @required this.backPanel,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(currentCategory != null),
        assert(frontPanel != null),
        assert(backPanel != null),
        assert(frontTitle != null),
        assert(backTitle != null);

  @override
  _BackdropState createState() => _BackdropState();
}

/// Stateの中身
class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  //Keyは多分RenderBoxのために発行している
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;

  /// backdropの初期化　アニメーションの初期Valueは1
  @override
  void initState() {
    super.initState();
    // This creates an [AnimationController] that can allows for animation for
    // the BackdropPanel. 0.00 means that the front panel is in "tab" (hidden)
    // mode, while 1.0 means that the front panel is open.
    _controller = AnimationController(
      //アニメーションの時間
      duration: Duration(milliseconds: 300),
      //初期value
      value: 1.0,
      //controllerを設定するときにはthisをいれておけばよい、、、？
      vsync: this,
    );
  }

  /// Widgetの状態が変わったら呼ばれる　(backdrop widget)
  /// backdropの状態を更新する
  /// カテゴリー選択時に重ね部が戻ってくるフリングの動きを行う
  @override
  void didUpdateWidget(Backdrop old) {
    super.didUpdateWidget(old);
    // カテゴリーが変化した場合は、
    if (widget.currentCategory != old.currentCategory) {
      setState(() {
        // flingアニメーション (多分フリックにおうじて移動して、摩擦的にだんだん止まるやつ
        // 速度(velocity)がpositiveなら実行
        _controller.fling(
            velocity:
            //アニメーションが完了か進行中ならマイナス、false(開始前)ならプラス
            _backdropPanelVisible ? -_kFlingVelocity : _kFlingVelocity);
      });
    // カテゴリーが変化しておらず、アニメーションが完了か進行中でない場合は、、、
    } else if (!_backdropPanelVisible) {
      setState(() {
        _controller.fling(velocity: _kFlingVelocity);
      });
    }
  }

  /// AnimationControllerを停止させる
  @override void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// getメソッド。アニメーションが完了したか進行中ならTrue
  bool get _backdropPanelVisible {
    //controllerのステータスをstatusと定義
    final AnimationStatus status = _controller.status;
    // 完了(complete)したか、進行中(forward)である
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  /// 重ね部を戻す動き
  void _toggleBackdropPanelVisibility() {
    //FocusScope.of(context)でcontextのFocusScopeNodeを取得
    // focusの優先権をFocusNode()(たぶん全く新しいNodeを設定している)に与えるように要求する
    FocusScope.of(context).requestFocus(FocusNode());
    //flingアニメーションを行う
    _controller.fling(
        velocity: _backdropPanelVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  ///　getメソッド。renderboxの高さを返す
  double get _backdropHeight {
    // renderbox(描画されている箱)の高さを返す
    // findRenderObject(今のrender object(描写するもの))
    // renderboxを設定(renderboxを使うにはキーを設定する必要あり)
    final RenderBox renderBox = _backdropKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  // By design: the panel can only be opened with a swipe. To close the panel
  // the user must either tap its heading or the backdrop's menu icon.

  /// Controller.valueを変化後の値に更新する
  void _handleDragUpdate(DragUpdateDetails details) {
    // アニメーション動作中 or 完了なら、
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    // (現在値)ー((変化量／全体の高さ)(移動の割合))を返す(0~1の間)
    // valueは0ならhidden, 1なら完全に出ている状態
    _controller.value -= details.primaryDelta / _backdropHeight;
  }

  ///
  void _handleDragEnd(DragEndDetails details) {
    // アニメーション動作中 or 完了なら、
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;
    // fling速度を返す
    final double flingVelocity =
        //dyはy成分
        details.velocity.pixelsPerSecond.dy / _backdropHeight;

    if (flingVelocity < 0.0)
      //fling速度が0未満ならflingさせる
      //どちらか大きい方の速度で
      _controller.fling(velocity: math.max(_kFlingVelocity, -flingVelocity));
    else if (flingVelocity > 0.0)
      //fling速度0以上なら反対方向へflingさせる
      _controller.fling(velocity: math.min(-_kFlingVelocity, -flingVelocity));
    else
      // fling速度0なら、半分以上出てたら全部だす、半分以下ならhiddenにする
      _controller.fling(
          velocity:
          _controller.value < 0.5 ? -_kFlingVelocity : _kFlingVelocity);
  }

  ///アニメーションとぱねるのUI（BuildContextとBoxConstraintsで表現）
  //BoxConstraintsはWidgetのサイズ制約
  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    const double panelTitleHeight = 48.0;
    final Size panelSize = constraints.biggest;
    final double panelTop = panelSize.height - panelTitleHeight;

    //Tween　2つの相対長方形の間でcontrollerで設定したアニメーションを行う
    Animation<RelativeRect> panelAnimation = RelativeRectTween(
      //開始　Left,Top,Right,Bottomの順
      begin: RelativeRect.fromLTRB(
          0.0, panelTop, 0.0, panelTop - panelSize.height),
      //終了
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    //animationをcontrollerのダブル形式で行う
    ).animate(_controller.view);

    //
    return Container(
      key: _backdropKey,
      color: widget.currentCategory.color,
      // 複数ウィジェットを重ね合わせる
      child: Stack(
        children: <Widget>[
          widget.backPanel, // ??
          //動きはパネルアニメーション、中身はバックドロップパネル
          PositionedTransition(
            rect: panelAnimation,
            child: _BackdropPanel(
              //タップでとじる。ドラッグアップデートでvalueを更新、End時にはflingアニメーション
              onTap: _toggleBackdropPanelVisibility,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              title: Text(widget.currentCategory.name),
              child: widget.frontPanel,
            ),
          ),
        ],
      ),
    );
  }

  /// 実際の表示内容　bodyは上記buildStack,タイトルは_BackdropTitle
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.currentCategory.color,
        elevation: 0.0,
        leading: IconButton(
          //タップで閉じる
          onPressed: _toggleBackdropPanelVisibility,
          icon: AnimatedIcon(
            icon: AnimatedIcons.close_menu,
            progress: _controller.view,
          ),
        ),
        title: _BackdropTitle(
          listenable: _controller.view,
          frontTitle: widget.frontTitle,
          backTitle: widget.backTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: _buildStack,
      ),
      resizeToAvoidBottomPadding: false,
    );
  }
}