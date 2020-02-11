import 'package:flutter/material.dart';
import 'package:products_app/scoped-models/main.dart';

import 'package:products_app/widgets/products/products.dart';
import 'package:products_app/widgets/ui_elements/adaptive_progress_indicator.dart';
import 'package:products_app/widgets/ui_elements/loguot_list_tile.dart';
import 'package:scoped_model/scoped_model.dart';

class ProductsPage extends StatefulWidget {
  final MainModel model;

  ProductsPage(this.model);

  @override
  State<StatefulWidget> createState() {
    return _ProductPageState();
  }
}

class _ProductPageState extends State<ProductsPage> {
  @override
  void initState() {
    widget.model.fetchProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        title: Text('EasyList'),
        actions: <Widget>[
          ScopedModelDescendant<MainModel>(
            builder: (BuildContext context, Widget child, MainModel model) {
              return IconButton(
                icon: Icon(model.displayFavouritesOnly
                    ? Icons.favorite
                    : Icons.favorite_border),
                onPressed: () {
                  model.toggleDisplayMode();
                },
              );
            },
          ),
        ],
      ),
      body: _buildProductsList(),
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading:
                false, // Important removes burger inside drawer
            title: Text('Choose'),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Manage Products'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin');
            },
          ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        Widget content = Center(child: Text('No products Found!'));
        if (model.displayedProducts.length > 0 && !model.isLoading) {
          content = Products();
        } else if (model.isLoading) {
          content = Center(
            child: AdaptiveProgressIndicator(),
          );
        }
        return RefreshIndicator(
          child: content,
          onRefresh: () {
            return model.fetchProducts();
          },
        );
      },
    );
  }
}
