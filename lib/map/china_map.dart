library map;

import 'package:flutter/material.dart';
import 'package:mapofchina/map/intefaces.dart';

import 'data.dart';

//封装地图实体类
class MapEntity {
  late String name;
  late Path path;
  late bool isSelected;
  Color color = Colors.white;
}

//中国地图控件
class MapWidget extends StatefulWidget {
  final List<CityItem> cityItems;
  final ClickCallback? clickCallback;
  const MapWidget({Key? key, required this.cityItems, this.clickCallback})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MapState();
  }
}

class _MapState extends State<MapWidget> with AutomaticKeepAliveClientMixin {
  /// 计算地图边界
  /// 1.黑龙江是中国最东，最北的省份
  /// 2.新疆是中国最西的省份
  /// 3.海南是中国最南的省份
  /// <p/>
  /// 地图边界为
  /// 0点                  1点
  /// 0,0------------------heilongjiang.right,0
  /// |                      |
  /// |                      |
  /// 0,hainan.bottom------heilongjiang.right,hainan.bottom
  /// 3点                   2点
  /// 地图宽度--->heilongjiang.right
  /// 地图高度--->hainan.bottom
  late double _mapWidth;
  late double _mapHeight;

  //初始缩放系数
  final double _initScaleX = 0.6;
  final double _initScaleY = 0.6;

  double _mapScale = 1.0;
  double _mapOffsetX = 0;
  double _mapOffsetY = 0;
  late Offset _lastOffset;
  double mapScalMax = 2.0;
  double mapScalMin = 1.0;
  double _lastEndMapScale = 1.0;
  double _lastMapScale = 1.0;
  double _nowMapScale = 1.0;
  List<CityItem> _cityNameList = [];

  List<Widget> cityNameListWidget = [];
  final List<MapEntity> _mapEntityList = [];

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  //根据svgPaths 初始化
  void _initMapData() {
    _mapEntityList.clear();
    _cityNameList =
        widget.cityItems.isEmpty ? mockCityItems() : widget.cityItems;
    for (int svgPathListIndex = 0;
        svgPathListIndex < svgPathList.length;
        svgPathListIndex++) {
      String svgPath = svgPathList[svgPathListIndex];
      int svgIndex = 0;
      int svgLength = svgPath.length;
      Path paintPath = Path();
      List<int> cmdPositionList = [];
      while (svgIndex < svgLength) {
        String charResult = svgPath.substring(svgIndex, svgIndex + 1);
        if (charResult.contains(RegExp(r'[A-z]'))) {
          cmdPositionList.add(svgIndex);
        }
        svgIndex++;
      }
      double lastPointX = 0.0;
      double lastPointY = 0.0;
      for (int i = 0; i < cmdPositionList.length; i++) {
        int cmdIndex = cmdPositionList[i];
        String pointString;
        if (i < cmdPositionList.length - 1) {
          pointString = svgPath.substring(cmdIndex + 1, cmdPositionList[i + 1]);
        } else {
          pointString = svgPath.substring(cmdIndex + 1, svgPath.length);
        }

        List<String> pointList = pointString.split(",");
        switch (svgPath.substring(cmdIndex, cmdIndex + 1)) {
          case 'm':
          case 'M':
            {
              lastPointX = double.parse(pointList[0]) * _initScaleX;
              lastPointY = double.parse(pointList[1]) * _initScaleY;
              paintPath.moveTo(lastPointX, lastPointY);
            }
            break;
          case "l":
          case "L":
            {
              lastPointX = double.parse(pointList[0]) * _initScaleX;
              lastPointY = double.parse(pointList[1]) * _initScaleY;
              paintPath.lineTo(lastPointX, lastPointY);
            }
            break;
          case 'h':
          case 'H':
            {
              lastPointX = double.parse(pointList[0]) * _initScaleX;
              paintPath.lineTo(lastPointX, lastPointY);
            }
            break;
          case 'v':
          case 'V':
            {
              lastPointY = double.parse(pointList[0]) * _initScaleY;
              paintPath.lineTo(lastPointX, lastPointY);
            }
            break;
          case 'c':
          case 'C':
            {
              //3次贝塞尔曲线
              lastPointX = double.parse(pointList[4]) * _initScaleX;
              lastPointY = double.parse(pointList[5]) * _initScaleY;
              paintPath.cubicTo(
                  double.parse(pointList[0]) * _initScaleX,
                  double.parse(pointList[1]) * _initScaleY,
                  double.parse(pointList[2]) * _initScaleX,
                  double.parse(pointList[3]) * _initScaleY,
                  lastPointX,
                  lastPointY);
            }
            break;
          case 's':
          case 'S':
            {
              paintPath.cubicTo(
                  lastPointX,
                  lastPointY,
                  double.parse(pointList[0]) * _initScaleX,
                  double.parse(pointList[1]) * _initScaleY,
                  double.parse(pointList[2]) * _initScaleX,
                  double.parse(pointList[3]) * _initScaleY);
              lastPointX = double.parse(pointList[2]) * _initScaleX;
              lastPointY = double.parse(pointList[3]) * _initScaleY;
            }
            break;
          case 'q':
          case 'Q':
            {
              lastPointX = double.parse(pointList[2]) * _initScaleX;
              lastPointY = double.parse(pointList[3]) * _initScaleY;
              paintPath.quadraticBezierTo(
                  double.parse(pointList[0]) * _initScaleX,
                  double.parse(pointList[1]) * _initScaleY,
                  double.parse(pointList[2]) * _initScaleX,
                  double.parse(pointList[3]) * _initScaleY);
            }

            break;
          case 't':
          case 'T':
            {
              paintPath.quadraticBezierTo(
                  lastPointX,
                  lastPointY,
                  double.parse(pointList[0]) * _initScaleX,
                  double.parse(pointList[1]) * _initScaleY);
              lastPointX = double.parse(pointList[0]) * _initScaleX;
              lastPointY = double.parse(pointList[1]) * _initScaleY;
            }
            break;
          case 'a':
          case 'A':
            {
              //画弧
            }
            break;
          case 'z':
          case 'Z':
            {
              paintPath.close();
            }
            break;
        }
      }

      _mapEntityList.add(MapEntity()
        ..color = _cityNameList[svgPathListIndex].cityColor
        ..path = paintPath
        ..isSelected = false
        ..name = _cityNameList[svgPathListIndex].cityName);

      //最下方城市
      if (_cityNameList[svgPathListIndex].cityName == "海南") {
        _mapHeight = paintPath.getBounds().bottom;
      }

      //最右方城市
      if (_cityNameList[svgPathListIndex].cityName == "黑龙江") {
        _mapWidth = paintPath.getBounds().right;
      }
    }
  }

  //处理点击事件
  void _dealClickEvent(TapUpDetails details) {
    //寻找点击范围的城市
    for (var mapEntity in _mapEntityList) {
      if (mapEntity.path.contains(Offset(
          (details.localPosition.dx - _mapOffsetX) / _mapScale,
          (details.localPosition.dy - _mapOffsetY) / _mapScale))) {
        mapEntity.isSelected = true;
        widget.clickCallback?.call(mapEntity.name);
      } else {
        mapEntity.isSelected = false;
      }
    }
    setState(() {});
  }

  //处理地图移动、缩放事件
  void _dealScaleEvent(ScaleUpdateDetails details) {
    _nowMapScale = details.scale;

    if (_nowMapScale == 1.0) {
      //未缩放时，只处理位移
      double offsetX = details.localFocalPoint.dx - _lastOffset.dx;
      double offsetY = details.localFocalPoint.dy - _lastOffset.dy;
      //控制边界
      if (offsetX <= -(_mapWidth * (_lastEndMapScale - 1) + _mapOffsetX)) {
        offsetX = -(_mapWidth * (_lastEndMapScale - 1) + _mapOffsetX);
      } else if (offsetX >= -_mapOffsetX) {
        offsetX = -_mapOffsetX;
      }

      if (offsetY <= -(_mapHeight * (_lastEndMapScale - 1) + _mapOffsetY)) {
        offsetY = -(_mapHeight * (_lastEndMapScale - 1) + _mapOffsetY);
      } else if (offsetX >= -_mapOffsetY) {
        offsetY = -_mapOffsetY;
      }
      _mapOffsetX += offsetX;
      _mapOffsetY += offsetY;
      _lastOffset = details.localFocalPoint;
    } else {
      _mapScale = (_nowMapScale * _lastEndMapScale).clamp(1.0, 2.0);
      double _shouldOffsetX = (_mapScale - _lastMapScale) * _mapWidth / 2 -
          _mapOffsetX * (_mapScale - _lastMapScale);
      double _shouldOffsetY = (_mapScale - _lastMapScale) * _mapHeight / 2 -
          _mapOffsetY * (_mapScale - _lastMapScale);
      _mapOffsetX += -_shouldOffsetX;
      _mapOffsetY += -_shouldOffsetY;
      _lastMapScale = _mapScale;
    }
    setState(() {});
  }

  void _dealScaleEndEvent() {
    _lastEndMapScale = (_nowMapScale * _lastEndMapScale).clamp(1.0, 2.0);
    if (_mapScale == 1.0) {
      //精度矫正
      _mapOffsetX = 0.0;
      _mapOffsetY = 0.0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapUp: (value) {
          _dealClickEvent(value);
        },
        onScaleStart: (value) {
          _lastOffset = value.localFocalPoint;
        },
        onScaleUpdate: (value) {
          _dealScaleEvent(value);
        },
        onScaleEnd: (value) {
          _dealScaleEndEvent();
        },
        child: Container(
          color: const Color(0xFFF2F2F2),
          width: _mapWidth,
          height: _mapHeight,
          child: ClipRect(
            child: CustomPaint(
              painter: MapPainter(
                  offsetX: _mapOffsetX,
                  offsetY: _mapOffsetY,
                  scale: _mapScale,
                  mapEntityList: _mapEntityList),
              child: Stack(
                children: _cityNameListWidget(),
              ),
            ),
          ),
        ));
  }

  List<Widget> _cityNameListWidget() {
    cityNameListWidget.clear();
    for (var element in _mapEntityList) {
      TextPainter textPainter =
          calculateText(element.name, 12.0, FontWeight.normal, 1);
      double textWidth = textPainter.width;
      double textHeight = textPainter.height;
      Rect mapBounds = element.path.getBounds();
      double textPositionX =
          (mapBounds.right - mapBounds.left) * _mapScale / 2 +
              mapBounds.left * _mapScale -
              textWidth / 2;
      double textPositionY =
          (mapBounds.bottom - mapBounds.top) * _mapScale / 2 +
              mapBounds.top * _mapScale -
              textHeight / 2;
      //cityname 位置微调
      double offsetX = textPositionX + _mapOffsetX;
      double offsetY = textPositionY + _mapOffsetY;

      if (element.name == "甘肃") {
        offsetY -= 20 * _mapScale;
        offsetX -= 20 * _mapScale;
      } else if (element.name == "内蒙") {
        offsetY += 23 * _mapScale;
        offsetX += 23 * _mapScale;
      } else if (element.name == "陕西") {
        offsetY += 12 * _mapScale;
        offsetX += 6 * _mapScale;
      } else if (element.name == "上海") {
        offsetX += 15 * _mapScale;
      } else if (element.name == "黑龙江") {
        offsetY += 8 * _mapScale;
        offsetX += 8 * _mapScale;
      } else if (element.name == "河北") {
        offsetY += 8 * _mapScale;
        offsetX -= 8 * _mapScale;
      } else if (element.name == "天津") {
        offsetX += 15 * _mapScale;
        offsetY += 6 * _mapScale;
      } else if (element.name == "江苏") {
        offsetX += 6 * _mapScale;
      } else if (element.name == "澳门") {
        offsetY += 10 * _mapScale;
      } else if (element.name == "香港") {
        offsetX += 18 * _mapScale;
      } else if (element.name == "广东") {
        offsetY -= 6 * _mapScale;
      }

      cityNameListWidget.add(Positioned(
        left: offsetX,
        top: offsetY,
        child: Text(
          element.name,
          style: const TextStyle(fontSize: 9, color: Color(0xFF333333)),
        ),
      ));
    }
    return cityNameListWidget;
  }

  TextPainter calculateText(
      String value, fontSize, FontWeight fontWeight, int maxLines) {
    TextPainter painter = TextPainter(

        ///AUTO：华为手机如果不指定locale的时候，该方法算出来的文字高度是比系统计算偏小的。
        locale: Localizations.localeOf(context),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: fontWeight,
              fontSize: fontSize,
            )));
    painter.layout(maxWidth: 80);
    return painter;
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => false;
}

class MapPainter extends CustomPainter {
  Paint storkePaint = Paint()
    ..color = const Color(0xFF333333)
    ..isAntiAlias = true
    ..strokeWidth = 1;
  Paint fillPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 1;
  double offsetX = 0.0;
  double offsetY = 0.0;
  double scale;
  List<MapEntity> mapEntityList;

  MapPainter({
    required this.offsetX,
    required this.offsetY,
    required this.mapEntityList,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    for (var mapEntity in mapEntityList) {
      // if (mapEntity.isSelected) {
      fillPaint.color = mapEntity.color;
      fillPaint.style = PaintingStyle.fill;
      // fillPaint.color = mapEntity.color;
      // fillPaint.style = PaintingStyle.fill;
      // } else {
      // mapPaint.color =  Colors.white;
      // mapPaint.style = PaintingStyle.stroke;
      // }
      canvas.drawPath(mapEntity.path, storkePaint);
      canvas.drawPath(mapEntity.path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
