import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:products_app/models/location_data.dart';
import 'package:products_app/models/product.dart';
import 'package:products_app/scoped-models/main.dart';
import 'package:products_app/widgets/form_inputs/location.dart';
import 'package:products_app/widgets/form_inputs/image.dart';
import 'package:products_app/widgets/helpers/ensure_visible.dart';
import 'package:products_app/widgets/ui_elements/adaptive_progress_indicator.dart';
import 'package:scoped_model/scoped_model.dart';

class ProductEditPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProductEditPageState();
  }
}

class _ProductEditPageState extends State<ProductEditPage> {
  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'price': null,
    'image': null,
    'location': null
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // key for form
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _titleTextController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final _priceTextController = TextEditingController();
  final _addressTextController = TextEditingController();

  Widget _buildTitleTextField(Product product) {
    if (product == null && _titleTextController.text.trim() == '') {
      _titleTextController.text = '';
    } else if (product != null && _titleTextController.text.trim() == '') {
      _titleTextController.text = product.title;
    } else if (product != null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else if (product == null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else {
      _titleTextController.text = '';
    }

    return EnsureVisibleWhenFocused(
      focusNode: _titleFocusNode,
      child: TextFormField(
        focusNode: _titleFocusNode,
        controller: _titleTextController,
        decoration: InputDecoration(
          labelText: 'Product Title', // placeholder
        ),
        validator: (String value) {
          if (value.isEmpty || value.length < 5) {
            return 'Title is required should and be longer than 5 characters';
          }
          return null;
        },
        onSaved: (String value) {
          _formData['title'] = value;
        },
      ),
    );
  }

  Widget _buildDescriptionField(Product product) {
    if (product == null && _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = '';
    } else if (product != null &&
        _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = product.title;
    }

    return EnsureVisibleWhenFocused(
        focusNode: _titleFocusNode,
        child: TextFormField(
          focusNode: _descriptionFocusNode,
          controller: _descriptionTextController,
          // initialValue: product == null ? '' : product.description,
          decoration: InputDecoration(
            labelText: 'Product Description',
          ),
          maxLines: 4,
          validator: (String value) {
            if (value.isEmpty || value.length < 10) {
              return 'Description is required and should be longer than 10 characters';
            }
            return null;
          },
          onSaved: (String value) {
            _formData['description'] = value;
          },
        ));
  }

  Widget _buildPriceField(Product product) {
    if (product == null && _priceTextController.text.trim() == '') {
      _priceTextController.text = '';
    } else if (product != null && _priceTextController.text.trim() == '') {
      _priceTextController.text = product.price.toString();
    }

    return EnsureVisibleWhenFocused(
        focusNode: _titleFocusNode,
        child: TextFormField(
          focusNode: _priceFocusNode,
          controller: _priceTextController,
          decoration: InputDecoration(
            labelText: 'Product Price',
          ),
          keyboardType: TextInputType.number, // type of keyboard
          validator: (String value) {
            if (value.isEmpty ||
                !RegExp(r'^(?:[1-9]\d*|0)?(?:[.,]\d+)?$').hasMatch(value)) {
              //Regex for number check
              return 'Price is required and should be number';
            }
            return null;
          },
        ));
  }

  Widget _buildSubmitButton() {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return model.isLoading
          ? Center(
              child: AdaptiveProgressIndicator(),
            )
          : RaisedButton(
              child: Text('Save'),
              textColor: Colors.white,
              onPressed: () => _submitForm(
                    model.addProduct,
                    model.updateProduct,
                    model.selectProduct,
                    model.selectedProductIndex,
                  ));
    });
  }

  void _submitForm(
      Function addProduct, Function updateProduct, Function setSelectedProduct,
      [int selectedProductIndex]) {
    if (!_formKey.currentState.validate() ||
        (_formData['image'] == null && selectedProductIndex == -1)) {
      return;
    }
    _formKey.currentState.save();

    if (selectedProductIndex == -1) {
      addProduct(
        _titleTextController.text,
        _descriptionTextController.text,
        _formData['image'],
        double.parse(_priceTextController.text.replaceFirst(RegExp(r','), '.')),
        _formData['location'],
      ).then((bool success) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/products')
              .then((_) => setSelectedProduct(null));
        } else {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Something went wrong'),
                  content: Text('Please try again'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Okay'),
                    )
                  ],
                );
              });
        }
      });
    } else {
      updateProduct(
        _titleTextController.text,
        _descriptionTextController.text,
        _formData['image'],
        double.parse(_priceTextController.text.replaceFirst(RegExp(r','), '.')),
        _formData['location'],
      ).then((_) => {
            Navigator.pushReplacementNamed(context, '/products')
                .then((_) => setSelectedProduct(null))
          });
    }
  }

  void _setLocation(LocationData locationData) {
    _formData['location'] = locationData;
  }

  void _setImage(File image) {
    _formData['image'] = image;
  }

  Widget _buildPageContent(BuildContext context, Product product) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(
            FocusNode()); // remove focus from  textfields, that will close keyboard
      },
      child: Container(
        width: targetWidth,
        margin: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
            children: <Widget>[
              _buildTitleTextField(product),
              _buildDescriptionField(product),
              _buildPriceField(product),
              SizedBox(
                height: 10.0,
              ),
              LocationInput(_setLocation, product),
              SizedBox(
                height: 10.0,
              ),
              ImageInput(_setImage, product),
              SizedBox(
                height: 10.0,
              ),
              // Any functionality / vs RaisedButton with onPressed
              _buildSubmitButton(),
              // GestureDetector(
              //   onTap: _submitForm,
              //   child: Container(
              //     color: Colors.green,
              //     padding: EdgeInsets.all(5.0),
              //     child: Text('My button'),
              // ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      final Widget pageContent =
          _buildPageContent(context, model.selectedProduct);

      return model.selectedProductIndex == -1
          ? pageContent
          : Scaffold(
              appBar: AppBar(
                title: Text('Edit Product'),
              ),
              body: pageContent,
            );
    });
  }
}
