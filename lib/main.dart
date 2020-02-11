import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:products_app/models/product.dart';
import 'package:products_app/pages/auth.dart';
import 'package:products_app/scoped-models/main.dart';
import 'package:products_app/shared/adaptive_theme.dart';
import 'package:products_app/widgets/helpers/custom_route.dart';
import 'package:scoped_model/scoped_model.dart';
// import 'package:flutter/rendering.dart';
import 'package:cirrus_map_view/map_view.dart';

import 'pages/products_admin.dart';
import 'pages/products.dart';
import 'pages/product.dart';

void main() {
  // debugPaintSizeEnabled = true; // blue lines around elements and other UI debugging stuff
  MapView.setApiKey('AIzaSyDXoJvN6cy9BEzDXeTMSk4yALYQhJ_qC5g');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyState();
  }
}

class _MyState extends State<MyApp> {
  final MainModel _model = MainModel();
  final _platformChannel =
      MethodChannel('flutter-course.com/battery'); // domain name as practice
  bool _isAuthenticated = false;

  Future<Null> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await _platformChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level is $result %.';
    } catch (error) {
      batteryLevel = 'Failed to get battery level';
    }
    print(batteryLevel);
  }

  @override
  void initState() {
    _model.autoAuthenticate();
    _model.userSubject.listen((bool isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });
    _getBatteryLevel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
        title: 'EasyList',
        // debugShowMaterialGrid: true, // mini squares grid
        theme: getAdaptiveThemeData(context),
        // home: AuthPage(), // equals / in routes
        routes: {
          '/': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : ProductsPage(_model),
          '/admin': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : ProductsAdminPage(_model)
        },
        onGenerateRoute: (RouteSettings settings) {
          if (!_isAuthenticated) {
            return CustomRoute<bool>(
              builder: (BuildContext context) => AuthPage(),
            );
          }

          final List<String> pathElements = settings.name.split('/');
          if (pathElements[0] != '') {
            return null;
          }
          if (pathElements[1] == 'product') {
            final String productId = pathElements[2];
            final Product product =
                _model.allProducts.firstWhere((Product product) {
              return product.id == productId;
            });
            return MaterialPageRoute<bool>(
              builder: (BuildContext context) =>
                  !_isAuthenticated ? AuthPage() : ProductPage(product),
            );
          }
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext context) =>
                !_isAuthenticated ? AuthPage() : ProductsPage(_model),
          );
        },
      ),
    );
  }
}
