<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

绘制了一个中国地图，支持设置省份颜色，可以响应点击和缩放，以及提示。

## Features

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/818e746630e5493999d0582ad10dd7bd~tplv-k3u1fbpfcp-watermark.image?)

## Getting started

```dart
dependencies:
  flutter:
    sdk: flutter

  mapofchina: ^0.0.4  
  

```
## Usage

 

```dart
import 'package:mapofchina/map/china_map.dart';
import 'package:mapofchina/map/data.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  void initState() {
    super.initState();
    //  OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MapWidget(
          //默认的提示语
          defaultToast: "北京 棒棒的",
          //可以自己编辑省份信息，也可以使用 generatedCityItemsHelper帮助类。
          cityItems: generatedCityItemsHelper((cityName) => CityItem(
                cityName: cityName,
                cityColor: _randomColor(),
                isSelected: cityName == ("山西") ? true : false,
              )),   
          //省份被点击的回调，传回去的String是用来更新提示语的。
          clickCallback: (cityName) {
            return "$cityName baby";
          },
          selectedStorkeColor: const Color(0xFF8BFDF0),
          background: const Color(0xFFF2F2F2),
        ),
      ),
    );
  }

  /// 随机生成颜色
  Color _randomColor() {
    var index = Random().nextInt(3) % 3;
    if (index == 0) return shallowColor;
    if (index == 1) return middleColor;
    if (index == 2) return depthColor;
    return middleColor;
  }
}
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
