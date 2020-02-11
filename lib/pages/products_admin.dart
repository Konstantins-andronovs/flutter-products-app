import 'package:flutter/material.dart';
import 'package:products_app/scoped-models/main.dart';
import 'package:products_app/widgets/ui_elements/loguot_list_tile.dart';

import 'product_edit.dart';
import 'product_list.dart';

class ProductsAdminPage extends StatelessWidget {
  final MainModel model;

  ProductsAdminPage(this.model);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildSideDrawer(context),
        appBar: AppBar(
          title: Text('Manage Products'),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.create),
                text: 'Create Product',
              ),
              Tab(
                icon: Icon(Icons.list),
                text: 'My Products',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            ProductEditPage(),
            ProductListPage(model),
          ],
        ),
      ),
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
            leading: Icon(Icons.shop),
            title: Text('All Products'),
            onTap: () {
              Navigator.pushReplacementNamed(
                context,
                '/',
              );
            },
          ),
          Divider(),
          LogoutListTile(),
        ],
      ),
    );
  }
}
