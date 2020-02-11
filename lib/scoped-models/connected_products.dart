import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:products_app/models/auth.dart';
import 'package:products_app/models/location_data.dart';
import 'package:products_app/models/product.dart';
import 'package:products_app/models/user.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/src/subjects/publish_subject.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;
}

mixin ProductsModel on ConnectedProductsModel {
  bool _showFavourites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (_showFavourites) {
      return _products.where((Product product) => product.isFavourite).toList();
    }
    return List.from(_products);
  }

  String get selectedProductId {
    return _selProductId;
  }

  bool get displayFavouritesOnly {
    return _showFavourites;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  Future<Map<String, dynamic>> uploadImage(File image,
      {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploaodRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'URL to Storage'));

    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploaodRequest.files.add(file);

    if (imagePath != null) {
      imageUploaodRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }
    imageUploaodRequest.headers['Authorization'] =
        'Bearer ${_authenticatedUser.token}';

    try {
      final streamedResponse = await imageUploaodRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Something went wrong');
        print(json.decode(response.body));
        return null;
      }
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<bool> addProduct(String title, String description, File image,
      double price, LocationData locationData) async {
    _isLoading = true;
    notifyListeners();

    final uploadData = await uploadImage(image);

    if (uploadData == null) {
      print('Upload failed');
      return false;
    }

    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'loc_lat': locationData.latitude,
      'loc_lng': locationData.longitude,
      'loc_address': locationData.address,
    };

    try {
      final http.Response response = await http.post(
          'URL to database with authentication',
          body: json.encode(productData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final Product newProduct = Product(
        id: responseData['name'],
        title: title,
        description: description,
        image: uploadData['imageUrl'],
        imagePath: uploadData['imagePath'],
        price: price,
        location: locationData,
        userEmail: _authenticatedUser.email,
        userId: _authenticatedUser.id,
      );
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      print(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String title, String description, File image,
      double price, LocationData locationData) async {
    _isLoading = true;
    notifyListeners();
    String imageUrl = selectedProduct.image;
    String imagePath = selectedProduct.imagePath;

    if (image != null) {
      final uploadData = await uploadImage(image);

      if (uploadData == null) {
        print('Upload failed');
        return false;
      }

      imageUrl = uploadData['imageUrl'];
      imagePath = uploadData['imagePath'];
    }

    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'price': price,
      'userEmail': selectedProduct.userEmail,
      'userId': selectedProduct.userId,
      'loc_lat': locationData.latitude,
      'loc_lng': locationData.longitude,
      'loc_address': locationData.address,
    };

    try {
      final http.Response response = await http.put(
          'url ro database with authentication',
          body: json.encode(updateData));
      _isLoading = false;

      final Product updatedProduct = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          image: imageUrl,
          imagePath: imagePath,
          price: price,
          location: locationData,
          userEmail: selectedProduct.userEmail,
          userId: selectedProduct.userId);

      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final deletedProductId = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();

    return http
        .delete(
            'url to database with authentication')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<Null> fetchProducts({onlyForUser = false, clearExisting = false}) {
    _isLoading = true;
    if (clearExisting) {
      _products = [];
    }
    notifyListeners();

    return http
        .get(
            'url to database with authentication')
        .then<Null>((http.Response response) {
      final List<Product> fetchedProductList = [];
      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      productListData.forEach((String productId, dynamic productData) {
        final Product product = Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            image: productData['imageUrl'],
            imagePath: productData['imagePath'],
            price: productData['price'],
            location: LocationData(
              address: productData['loc_address'],
              latitude: productData['loc_lat'],
              longitude: productData['loc_lng'],
            ),
            userEmail: productData['userEmail'],
            userId: productData['userId'],
            isFavourite: productData['wishlistUsers'] == null
                ? false
                : (productData['wishlistUsers'] as Map<String, dynamic>)
                    .containsKey(_authenticatedUser.id));

        fetchedProductList.add(product);
      });

      _products = onlyForUser
          ? fetchedProductList.where((Product product) {
              return product.userId == _authenticatedUser.id;
            }).toList()
          : fetchedProductList;

      _isLoading = false;
      notifyListeners();
      _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  void toggleProductFavouriteStatus() async {
    final bool isCurrentlyFavourite = selectedProduct.isFavourite;
    final bool newFavouriteStatus = !isCurrentlyFavourite;

    // Local update
    final Product updatedProduct = Product(
      id: selectedProduct.id,
      title: selectedProduct.title,
      description: selectedProduct.description,
      price: selectedProduct.price,
      image: selectedProduct.image,
      imagePath: selectedProduct.imagePath,
      location: selectedProduct.location,
      userEmail: selectedProduct.userEmail,
      userId: selectedProduct.userId,
      isFavourite: newFavouriteStatus,
    );
    _products[selectedProductIndex] = updatedProduct;
    notifyListeners(); // for live update on the page, update without recalling build

    http.Response response;
    if (newFavouriteStatus) {
      response = await http.put(
          'url to database',
          body: json.encode(true));
    } else {
      response = await http.delete(
        'url to database/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        imagePath: selectedProduct.imagePath,
        location: selectedProduct.location,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavourite: !newFavouriteStatus,
      );
      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
    }
    _selProductId = null;
  }

  void toggleDisplayMode() {
    _showFavourites = !_showFavourites;
    notifyListeners();
  }
}

mixin UserModel on ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  User get user {
    return _authenticatedUser;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };

    http.Response response;

    if (mode == AuthMode.Login) {
      response = await http.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=****',
        headers: {'Content-Type': 'application/json'}, // optional vrode.
        body: json.encode(authData),
      );
    } else {
      response = await http.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=****',
        headers: {'Content-Type': 'application/json'}, // optional vrode.
        body: json.encode(authData),
      );
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went wrong.';
    if (responseData.containsKey('idToken')) {
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);

      setAuthTimeout(int.parse(responseData['expiresIn']));

      _userSubject.add(true);

      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));

      final SharedPreferences prefs =
          await SharedPreferences.getInstance(); // mobile local storage
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());

      hasError = false;
      message = 'Authentication succeded.';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email is already exists.';
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'The Password is in invalid.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');

    if (token != null) {
      final DateTime now = DateTime.now();
      final DateTime parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }

      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    print('logout');
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);

    _selProductId = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.clear(); clears all
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
