import 'package:flutter/material.dart';
import 'package:products_app/models/product.dart';
import 'package:products_app/scoped-models/main.dart';
import 'package:products_app/widgets/products/product_card.dart';
import 'package:scoped_model/scoped_model.dart';

class Products extends StatelessWidget {
  Widget _buildProductLists(List<Product> products) {
    Widget productCards;
    if (products.length > 0) {
      productCards = ListView.builder(
        itemBuilder: (BuildContext context, int index) =>
            ProductCard(products[index]),
        itemCount: products.length,
      );
    } else {
      productCards = Center(child: Text('No products found, please add some'));
      // productCards = Container(); // Empty container
    }
    return productCards;
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      //Subscription, executes when data changes
      builder: (BuildContext context, Widget child, MainModel model) {
        return _buildProductLists(model.displayedProducts);
      },
    );
  }
}
